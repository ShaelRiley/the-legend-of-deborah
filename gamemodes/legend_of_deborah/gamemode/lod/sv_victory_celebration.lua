LOD = LOD or {}
LOD.VictoryCelebration = LOD.VictoryCelebration or {}

local Celebration = LOD.VictoryCelebration
local RunManager = LOD.RunManager
local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config and LOD.Config.Maze
if not RunManager or not MC then return end

local CELEBRATION_SECONDS = 6.5
local BALLOON_LIFETIME = 11
local BALLOON_COUNT = 12
local BALLOON_MODEL = "models/maxofs2d/balloon_classic.mdl"
local BALLOON_COLORS = {
    Color(238, 88, 88),
    Color(76, 156, 238),
    Color(244, 205, 76),
    Color(104, 205, 124),
    Color(202, 102, 224),
    Color(245, 137, 61)
}

util.AddNetworkString("LOD_VictoryCelebration")
util.AddNetworkString("LOD_DeborahFinale")

Celebration.Stats = Celebration.Stats or {starts = 0, balloons = 0}
Celebration.ActiveUntil = Celebration.ActiveUntil or 0

local function activeRescueTarget()
    if IsValid(RunManager.State.RescueEntity) then return RunManager.State.RescueEntity end
    for _, ent in ipairs(ents.FindByClass("lod_deborah")) do
        if IsValid(ent) then return ent end
    end
end

local function celebrationCenter(ply)
    local deborah = activeRescueTarget()
    if IsValid(deborah) then return deborah:GetPos() + Vector(0, 0, 42), deborah end
    if IsValid(ply) then return ply:GetPos() + Vector(0, 0, 42), nil end
    return MC.Origin + Vector(0, 0, 64), nil
end

local function registerTemporary(ent)
    if IsValid(ent) and MazeBuilder and MazeBuilder._Register then
        MazeBuilder:_Register(ent)
    end
end

local function spawnBalloon(center, index)
    if not util.IsValidModel(BALLOON_MODEL) then return nil end
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end

    local ring = ((index - 1) / math.max(1, BALLOON_COUNT)) * math.pi * 2
    local radius = 48 + ((index * 37) % 105)
    local spawnZ = center.z + math.min(220, MC.LevelHeight * 0.62) + ((index * 19) % 32)
    ent:SetModel(BALLOON_MODEL)
    ent:SetPos(Vector(
        center.x + math.cos(ring) * radius,
        center.y + math.sin(ring) * radius,
        spawnZ))
    ent:SetAngles(Angle(math.Rand(-8, 8), math.Rand(0, 359), math.Rand(-8, 8)))
    ent:SetSkin((index - 1) % 4)
    ent:SetColor(BALLOON_COLORS[((index - 1) % #BALLOON_COLORS) + 1])
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    ent:Spawn()
    ent:Activate()
    ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    ent:SetModelScale(math.Rand(0.84, 1.16), 0)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(1)
        -- Gravity would make a balloon prop drop like a heavy object. Instead use
        -- a gentle persistent downward drift from the chamber ceiling so the real
        -- physics models visibly descend throughout the short victory tableau.
        phys:EnableGravity(false)
        phys:SetDamping(0.12, 1.6)
        phys:SetVelocity(Vector(math.Rand(-22, 22), math.Rand(-22, 22), math.Rand(-38, -26)))
        phys:AddAngleVelocity(Vector(math.Rand(-15, 15), math.Rand(-15, 15), math.Rand(-15, 15)))
    end

    registerTemporary(ent)
    timer.Simple(BALLOON_LIFETIME, function()
        if IsValid(ent) then ent:Remove() end
    end)
    Celebration.Stats.balloons = (Celebration.Stats.balloons or 0) + 1
    return ent
end

function Celebration:Start(rescuer)
    local center, deborah = celebrationCenter(rescuer)
    local now = CurTime()
    self.ActiveUntil = now + CELEBRATION_SECONDS
    self.Stats.starts = (self.Stats.starts or 0) + 1

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and RunManager:IsActivePlayer(ply) then
            ply:SetNW2Float("LOD_VictoryCelebrationUntil", self.ActiveUntil)
            local cheer = _G.ACT_GMOD_TAUNT_CHEER or _G.ACT_GMOD_GESTURE_WAVE
            if cheer and ply.AnimRestartGesture then
                ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, cheer, true)
            end
        end
    end

    for index = 1, BALLOON_COUNT do spawnBalloon(center, index) end

    net.Start("LOD_VictoryCelebration")
    net.WriteVector(center)
    net.WriteFloat(CELEBRATION_SECONDS)
    net.WriteEntity(IsValid(deborah) and deborah or NULL)
    net.Broadcast()
end

-- A sealed presentation receipt is captured while Hector's rescue gate is
-- live. CompleteLevel remains the only reward/progression authority. Hector's
-- expected corpse/encounter cleanup after settlement must not revoke this seal.
function Celebration:CaptureFinale()
    local s = RunManager.State
    if not s or s.Level ~= 20 or s.LevelCleared or s.Failed
        or s.RescuedDamsels and s.RescuedDamsels[20]
        or not LOD.Hector or not LOD.Hector:RescueAllowed(s) then return nil end
    local h, target = s.Hector, s.RescueEntity
    if not h or not h.rescueReceipt or not IsValid(target) then return nil end
    local record = {state=s, graph=s.Graph, progression=s.Graph.Progression,
        epoch=s.CampaignEpoch, campaignSeed=s.CampaignSeed, runId=s.RunId, seed=s.LevelSeed,
        receipt=h.rescueReceipt, center=LOD.MazeNavigator:CellCenter(h.arena.center), yaw=target:GetAngles().y,
        deborah=target, heroes={}, damsels={}}
    for _, p in ipairs(player.GetAll()) do
        local ps = IsValid(p) and RunManager:GetPlayerState(p)
        if #record.heroes < 4 and ps and p:Alive() and RunManager:IsActivePlayer(p)
            and not RunManager:IsSoldierControl(p) and ps.deploymentComplete == true
            and not ps.eliminated and (ps.lives or 0) > 0 then
            record.heroes[#record.heroes+1] = {entity=p, identity=RunManager:IdentityOf(p),
                playerState=ps, life=ps.equipmentLifeSerial, spawnSerial=p.LODRunSpawnSerial,
                heroGeneration=ps.heroGeneration, model=p:GetModel(),
                name=(p:Nick() .. " as " .. (ps.characterName or "Hero"))}
        end
    end
    for i=1,19 do
        if s.RescuedDamsels and s.RescuedDamsels[i] then record.damsels[#record.damsels+1]=i end
    end
    return record
end

function Celebration:HeroPresent(hero)
    local p, ps = hero.entity, hero.playerState
    if hero.retired then return false end
    local present = IsValid(p) and p:Alive() and RunManager:IsActivePlayer(p)
        and not RunManager:IsSoldierControl(p) and RunManager:IdentityOf(p)==hero.identity
        and RunManager:GetPlayerState(p)==ps and not ps.eliminated and ps.deploymentComplete==true
        and (ps.lives or 0)>0 and ps.equipmentLifeSerial==hero.life
        and ps.heroGeneration==hero.heroGeneration and p.LODRunSpawnSerial==hero.spawnSerial
    if not present then hero.retired=true end
    return present
end

function Celebration:FinaleCurrent(record)
    local s = RunManager.State
    local c = s and s.CampaignClock
    return record and record.accepted and s==record.state and s.DeborahFinaleTransition==record
        and s.Graph==record.graph and s.Graph.Progression==record.progression
        and s.CampaignEpoch==record.epoch and s.CampaignSeed==record.campaignSeed
        and s.RunId==record.runId and s.LevelSeed==record.seed and s.Level==20
        and s.LevelCleared and s.BuildReady and not s.Failed
        and s.RescuedDamsels and s.RescuedDamsels[20] and s.Abundance==true
        and record.receipt and s.IntermissionEnd==record.intermissionEnd
        and not (c and (c.expired or c.scene or c.deadline and SysTime()>=c.deadline))
        and CurTime()<record.endsAt
end

function Celebration:SyncFinale(recipient,opening)
    local f = self.Finale
    local active = self:FinaleCurrent(f) == true
    net.Start("LOD_DeborahFinale")
    net.WriteBool(active)
    if active then
        net.WriteBool(opening==true and not IsValid(recipient))
        net.WriteUInt(f.serial,32);net.WriteFloat(f.startedAt);net.WriteFloat(f.endsAt)
        net.WriteVector(f.center);net.WriteFloat(f.yaw);net.WriteUInt(f.campaignSeed or 1,31)
        net.WriteEntity(IsValid(f.deborah) and f.deborah or NULL)
        net.WriteUInt(#f.heroes,3)
        for _,hero in ipairs(f.heroes) do
            net.WriteEntity(IsValid(hero.entity) and hero.entity or NULL)
            net.WriteString(hero.identity);net.WriteString(hero.name);net.WriteString(hero.model)
            net.WriteBool(self:HeroPresent(hero))
        end
        net.WriteUInt(#f.damsels,5)
        for _,level in ipairs(f.damsels) do net.WriteUInt(level,5) end
    end
    if IsValid(recipient) then net.Send(recipient) else net.Broadcast() end
end

function Celebration:EndFinale()
    local f = self.Finale
    self.Finale=nil
    if not f then return end
    self.ActiveUntil=0
    for _,hero in ipairs(f.heroes) do
        if IsValid(hero.entity) then hero.entity:SetNW2Float("LOD_VictoryCelebrationUntil",0) end
    end
    -- Inactive notification is cosmetic. All authoritative locks are already
    -- cleared; a transport failure must not block advance, rebuild or reset.
    local ok,err=pcall(self.SyncFinale,self)
    if not ok then ErrorNoHalt("[LOD:FINALE] "..tostring(err).."\n") end
end

function Celebration:StartFinale(record)
    local s = RunManager.State
    if not record or not record.accepted or s~=record.state or s.DeborahFinaleTransition
        or s.Graph~=record.graph or not s.LevelCleared or not s.RescuedDamsels
        or not s.RescuedDamsels[20] or not s.Abundance then return false end
    local now=CurTime()
    record.startedAt,record.endsAt,record.intermissionEnd=now,now+CELEBRATION_SECONDS,s.IntermissionEnd
    self.FinaleSerial=(self.FinaleSerial or 0)+1;record.serial=self.FinaleSerial
    s.DeborahFinaleTransition=record
    if not self:FinaleCurrent(record) then return false end
    self.Finale=record;self.ActiveUntil=record.endsAt
    self.Stats.starts=(self.Stats.starts or 0)+1
    for _,hero in ipairs(record.heroes) do
        if self:HeroPresent(hero) then hero.entity:SetNW2Float("LOD_VictoryCelebrationUntil",record.endsAt) end
    end
    self:SyncFinale(nil,true)
    return true
end

-- Release the short lock before canonical transition/build/reset work starts.
for _,name in ipairs({"AdvanceLevel","BuildCurrentLevel","FailCampaign","NewCampaign"}) do
    local base=RunManager[name]
    if base then
        RunManager[name]=function(self,...)
            Celebration:EndFinale()
            return base(self,...)
        end
    end
end
hook.Add("PlayerDisconnected","LOD_DeborahFinaleDisconnect",function(p)
    local f=Celebration.Finale
    if not f then return end
    for _,hero in ipairs(f.heroes) do
        if hero.entity==p then hero.retired=true end
    end
end)
hook.Add("Think","LOD_DeborahFinaleLifecycle",function()
    local f=Celebration.Finale
    if not f then return end
    if not Celebration:FinaleCurrent(f) then Celebration:EndFinale();return end
    for _,hero in ipairs(f.heroes) do
        if IsValid(hero.entity) and not Celebration:HeroPresent(hero) then
            hero.entity:SetNW2Float("LOD_VictoryCelebrationUntil",0)
        end
    end
    if CurTime()>=(f.nextSync or 0) then f.nextSync=CurTime()+.25;Celebration:SyncFinale() end
end)
hook.Add("PlayerInitialSpawn","LOD_DeborahFinaleLateJoin",function(p) Celebration:SyncFinale(p) end)
hook.Add("PreCleanupMap","LOD_DeborahFinaleMapCleanup",function() Celebration:EndFinale() end)

hook.Add("StartCommand", "LOD_VictoryCelebrationMovementLock", function(ply, cmd)
    if not IsValid(ply) then return end
    local f=Celebration.Finale
    if f then
        if not Celebration:FinaleCurrent(f) then Celebration:EndFinale();return end
        local present=false
        for _,hero in ipairs(f.heroes) do
            if hero.entity==ply then present=Celebration:HeroPresent(hero);break end
        end
        if not present then ply:SetNW2Float("LOD_VictoryCelebrationUntil",0);return end
    end
    if not ply:Alive() then return end
    if CurTime() >= ply:GetNW2Float("LOD_VictoryCelebrationUntil", 0) then return end
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

-- Decorate the existing authoritative level-clear path. Intermission Tetris is
-- loaded first and remains the transition owner; this wrapper only begins the
-- audiovisual celebration after that same CompleteLevel call succeeds.
if not RunManager.LODVictoryCelebrationWrapped then
    RunManager.LODVictoryCelebrationWrapped = true
    local baseCompleteLevel = RunManager.CompleteLevel
    function RunManager:CompleteLevel(ply)
        local captured, snapshot = pcall(Celebration.CaptureFinale, Celebration)
        local level = self.State and self.State.Level
        local completed = baseCompleteLevel(self, ply)
        if completed then
            -- Presentation creation/network errors cannot unwind a settled rescue.
            local ok, err = pcall(function()
                if level==20 then
                    if captured and snapshot then snapshot.accepted=true;Celebration:StartFinale(snapshot) end
                else Celebration:Start(ply) end
            end)
            if not ok then
                pcall(Celebration.EndFinale,Celebration)
                ErrorNoHalt("[LOD:FINALE] "..tostring(err).."\n")
            end
        end
        return completed
    end
end

concommand.Add("lod_victory_celebration_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local line = string.format("starts=%d balloons=%d active=%s remaining=%.1fs modelValid=%s",
        Celebration.Stats.starts or 0,
        Celebration.Stats.balloons or 0,
        tostring(CurTime() < (Celebration.ActiveUntil or 0)),
        math.max(0, (Celebration.ActiveUntil or 0) - CurTime()),
        tostring(util.IsValidModel(BALLOON_MODEL)))
    print("[LOD:VICTORY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
