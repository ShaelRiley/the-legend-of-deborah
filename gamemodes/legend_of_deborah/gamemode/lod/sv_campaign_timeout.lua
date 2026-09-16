local T, Run = LOD.CampaignTimeout, LOD.RunManager
local MC, GC = LOD.Config.Maze, LOD.Config.Geometry
util.AddNetworkString(T.Message)

local function log(event, fields)
    if LOD.RPGTestLog then LOD.RPGTestLog:Write(event, fields or {}) end
end

function T:Clock()
    local s = Run.State
    s.CampaignClock = s.CampaignClock or {}
    return s.CampaignClock
end

function T:Sync(ply)
    local c, now = self:Clock(), SysTime()
    local scene = c.scene
    net.Start(self.Message)
    net.WriteUInt(Run.State.CampaignEpoch or 0, 32)
    net.WriteBool(c.deadline ~= nil)
    net.WriteFloat(self:Remaining(c, now))
    net.WriteBool(Run.State.Failed == true)
    net.WriteBool(scene ~= nil)
    if scene then
        net.WriteFloat(scene.started and math.min(self.Settle, now - scene.started) or -1)
        net.WriteVector(scene.center)
        net.WriteFloat(scene.radius)
        net.WriteFloat(scene.ground)
        net.WriteBool(scene.ready == true)
    end
    if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function T:Start(ply)
    local s, c = Run.State, self:Clock()
    if c.deadline or s.Failed or not s.BuildReady or s.LevelCleared
        or not Run:IsDungeonPlayer(ply) or Run:IsSoldierControl(ply) then return false end
    c.deadline = SysTime() + self.Duration
    -- Keep only the cheap clock alive on an empty dedicated server. Ordinary AI
    -- still uses RunManager's SimulationFrozen contract. SysTime also survives
    -- any engine hibernation gap; reconnect checks precede Hero activation.
    local cv = GetConVar("sv_hibernate_think")
    if cv and not cv:GetBool() then c.restoreHibernate = true; RunConsoleCommand("sv_hibernate_think", "1") end
    self:Sync()
    LOD.ProgressionDirector:Announce("PRISON COLLAPSE IN 30:00 — DUNGEON CLOCK STARTED")
    log("CAMPAIGN_CLOCK_START", {epoch=s.CampaignEpoch, level=s.Level, duration=self.Duration})
    return true
end

function T:RestoreHibernate(c)
    if not c or not c.restoreHibernate then return end
    local cv = GetConVar("sv_hibernate_think")
    if cv then RunConsoleCommand("sv_hibernate_think", "0") end
    c.restoreHibernate = nil
end

function T:ResetAfterRescue()
    self:RestoreHibernate(self:Clock())
    -- No deadline means a full, paused clock. Warnings and sync cadence also
    -- belong to the next dungeon, rather than carrying over from this one.
    Run.State.CampaignClock = {}
    self:Sync()
    log("DUNGEON_CLOCK_RESET", {epoch=Run.State.CampaignEpoch, level=Run.State.Level, duration=self.Duration})
end

function T:Bounds()
    local low, high
    for _, cell in pairs(Run.State.Graph and Run.State.Graph.Cells or {}) do
        local p = LOD.MazeNavigator:CellCenter(cell)
        if not low then low = Vector(p.x,p.y,p.z); high = Vector(p.x,p.y,p.z) end
        low.x=math.min(low.x,p.x); low.y=math.min(low.y,p.y); low.z=math.min(low.z,p.z)
        high.x=math.max(high.x,p.x); high.y=math.max(high.y,p.y); high.z=math.max(high.z,p.z)
    end
    low, high = low or MC.Origin, high or MC.Origin
    local center = (low + high) * 0.5 + Vector(0,0,450)
    local radius = math.max(1200, (high - low):Length() * 0.5 + MC.CellSize)
    return center, radius, LOD.MazeBuilder.WorldFloorZ or MC.Origin.z - 16
end

function T:Expire()
    local s, c = Run.State, self:Clock()
    if c.scene or s.Failed or not c.deadline or SysTime() < c.deadline then return false end
    local center, radius, ground = self:Bounds()
    c.scene = {center=center, radius=radius, ground=ground, props={}, geometry={}, samples={}}
    s.IntermissionEnd = nil
    -- This is the ordinary once-only finalization authority, including records.
    Run:FailCampaign("TIME OVER")
    self:Sync()
    log("CAMPAIGN_TIME_OVER", {epoch=s.CampaignEpoch, level=s.Level})
    return true
end

function T:BeginScene(scene)
    if scene.started then return false end
    scene.started = SysTime()
    -- Called from Think, never from a movement, damage or native Touch callback.
    for _, ply in ipairs(player.GetAll()) do
        if LOD.Equipment then LOD.Equipment:ClearTransient(ply) end
        if LOD.DeathTetris then LOD.DeathTetris:EndSession(Run:IdentityOf(ply)) end
        Run:RetireSoldier(ply)
        ply:StripWeapons()
        ply:Spectate(OBS_MODE_FIXED)
        ply:SpectateEntity(NULL)
        ply:SetNW2Float("LOD_VictoryCelebrationUntil",0)
    end
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do if IsValid(ent) then ent:Remove() end end
    for _, ent in ipairs(LOD.MazeBuilder.Entities or {}) do
        if IsValid(ent) then
            scene.geometry[#scene.geometry+1] = {ent=ent, at=self:ReleaseAt(ent:GetPos(),scene.center,scene.radius)}
        end
    end
    table.sort(scene.geometry,function(a,b) return a.at<b.at end)
    scene.nextGeometry = 1
    -- Retain the wall manifest for existing and late clients throughout aftermath.
    local segments = LOD.WallVisuals and LOD.WallVisuals.Segments or {}
    local directions={{0,1,90},{1,0,0},{0,-1,90},{-1,0,0}}
    for i=1,math.min(self.PhysicsLimit,#segments) do
        local seg=segments[math.floor((i-1)*#segments/math.min(self.PhysicsLimit,#segments))+1]
        local d=directions[seg[4]]
        local pos=MC.Origin+Vector((seg[1]-(MC.Width+1)*0.5+d[1]*0.5)*MC.CellSize,
            (seg[2]-(MC.Height+1)*0.5+d[2]*0.5)*MC.CellSize,seg[3]*MC.LevelHeight+GC.ContainerHeight*0.5+900)
        scene.samples[#scene.samples+1]={pos=pos,ang=Angle(0,d[3],0),at=self:ReleaseAt(pos,scene.center,scene.radius)+0.2}
    end
    table.sort(scene.samples,function(a,b) return a.at<b.at end)
    scene.nextSample=1
    self:Sync()
    return true
end

function T:SpawnWreckage(scene, sample)
    local ent=ents.Create("prop_physics")
    if not IsValid(ent) then return end
    ent:SetModel(GC.ContainerModel)
    ent:SetPos(sample.pos)
    ent:SetAngles(sample.ang)
    ent:Spawn()
    local phys=ent:GetPhysicsObject()
    if not IsValid(phys) then ent:Remove();return end
    ent:SetMaterial("models/debug/debugwhite")
    ent:SetColor(Color(105,95,100))
    ent.LODTimeoutWreckage=true
    -- Twenty-four independent stock bodies maximum; no constraints or explosives.
    phys:SetMass(600)
    phys:EnableMotion(true)
    local outward=sample.pos-scene.center;outward.z=0;outward:Normalize()
    phys:SetVelocity(outward*220+Vector(0,0,100))
    phys:AddAngleVelocity(Vector(25,40,30))
    phys:Wake()
    scene.props[#scene.props+1]=ent
end

function T:Step()
    local c, now = self:Clock(), SysTime()
    self:Expire()
    local scene = c.scene
    if scene then
        -- Empty-server expiry commits failure now and defers spectacle to a viewer.
        if not scene.started then
            if #player.GetHumans()==0 then self:RestoreHibernate(c);return end
            self:BeginScene(scene)
        end
        if scene.ready then return end
        local elapsed=now-scene.started
        local budget=96
        while budget>0 do
            local item=scene.geometry[scene.nextGeometry]
            if not item or elapsed<item.at then break end
            if IsValid(item.ent) then item.ent:Remove() end
            scene.nextGeometry=scene.nextGeometry+1;budget=budget-1
        end
        -- At most two native physics creations per service tick.
        for _=1,2 do
            local item=scene.samples[scene.nextSample]
            if not item or elapsed<item.at then break end
            self:SpawnWreckage(scene,item);scene.nextSample=scene.nextSample+1
        end
        if elapsed>=self.Settle and scene.nextGeometry>#scene.geometry and scene.nextSample>#scene.samples then
            for _,ent in ipairs(scene.props) do if IsValid(ent) then
                local phys=ent:GetPhysicsObject()
                if IsValid(phys) then phys:EnableMotion(false);phys:Sleep() end
            end end
            scene.ready=true
            self:RestoreHibernate(c)
            self:Sync()
            log("CAMPAIGN_AFTERMATH_READY",{physics=#scene.props})
        end
        return
    end
    if Run.State.Failed then
        self:RestoreHibernate(c)
        if not c.failureSynced then c.failureSynced=true;self:Sync() end
        return
    end
    if c.deadline and now>=(c.nextSync or 0) then
        c.nextSync=now+1
        local remaining=self:Remaining(c,now)
        for _,seconds in ipairs({600,300,60,30,10}) do
            c.warned=c.warned or {}
            if remaining<=seconds and not c.warned[seconds] then
                c.warned[seconds]=true
                LOD.ProgressionDirector:Announce(string.format("PRISON COLLAPSE IN %d:%02d",math.floor(seconds/60),seconds%60))
            end
        end
        self:Sync()
    end
end

function T:Cleanup()
    local c=Run.State and Run.State.CampaignClock
    self:RestoreHibernate(c)
    for _,ent in ipairs(c and c.scene and c.scene.props or {}) do if IsValid(ent) then ent:Remove() end end
end

local nextStep=0
hook.Add("Think","LOD_CampaignTimeout",function()
    if SysTime()<nextStep then return end
    nextStep=SysTime()+0.05
    T:Step()
end)

-- Catch expiry before reward/progression wrappers and reconnect activation, even
-- when a rescue or generation completes between clock service ticks.
for _,name in ipairs({"CompleteLevel","AdvanceLevel","BuildCurrentLevel","TryActivatePlayer"}) do
    local base=Run[name]
    Run[name]=function(self,...)
        T:Expire()
        if T:Clock().scene then return false,"TIME OVER" end
        local ok,result=base(self,...)
        if name == "CompleteLevel" and ok then T:ResetAfterRescue() end
        return ok,result
    end
end
local newCampaign=Run.NewCampaign
function Run:NewCampaign(...)
    T:Cleanup()
    local ok,result=newCampaign(self,...)
    T:Sync()
    return ok,result
end

hook.Add("PlayerInitialSpawn","LOD_CampaignClockJoin",function(ply)
    T:Expire()
    timer.Simple(1,function() if IsValid(ply) then T:Sync(ply) end end)
end)
hook.Add("SetupPlayerVisibility","LOD_TimeoutVisibility",function()
    local scene=T:Clock().scene
    if not scene then return end
    AddOriginToPVS(T:Camera(scene.center,scene.radius))
    AddOriginToPVS(scene.center)
    for _,ent in ipairs(scene.props) do if IsValid(ent) then AddOriginToPVS(ent:GetPos()) end end
end)
hook.Add("StartCommand","LOD_TimeoutControl",function(_,cmd)
    if not T:Clock().scene then return end
    cmd:ClearMovement();cmd:ClearButtons()
end)
hook.Add("PlayerUse","LOD_TimeoutUse",function() if T:Clock().scene then return false end end)
hook.Add("EntityTakeDamage","LOD_TimeoutDamage",function(_,info)
    if not T:Clock().scene then return end
    info:SetDamage(0);return true
end)
hook.Add("PostCleanupMap","LOD_TimeoutMapCleanup",function()
    local scene=T:Clock().scene
    if not scene then return end
    -- The immutable client ruin survives admin cleanup; never auto-regenerate it.
    scene.props={}
end)
hook.Add("ShutDown","LOD_TimeoutShutdown",function() T:Cleanup() end)

concommand.Add("lod_dev_timeout_in",function(ply,argsCmd,args)
    local cv=GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    local c=T:Clock()
    if not c.deadline or Run.State.Failed then return end
    Run:MarkUnranked("accelerated campaign timer")
    c.deadline=SysTime()+math.Clamp(tonumber(args[1]) or 10,1,1800)
    T:Sync()
end)
concommand.Add("lod_campaign_clock_status",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local c=T:Clock()
    print(string.format("[LOD:CLOCK] epoch=%d level=%d started=%s remaining=%.2f timeout=%s ready=%s physics=%d",
        Run.State.CampaignEpoch or 0,Run.State.Level or 1,tostring(c.deadline~=nil),T:Remaining(c,SysTime()),
        tostring(c.scene~=nil),tostring(c.scene and c.scene.ready==true),c.scene and #c.scene.props or 0))
end)
