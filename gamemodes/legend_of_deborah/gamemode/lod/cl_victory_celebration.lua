LOD = LOD or {}
LOD.VictoryCelebrationClient = LOD.VictoryCelebrationClient or {}

local Client = LOD.VictoryCelebrationClient
if Client.DisposeFinale then Client:DisposeFinale() end
local CONFETTI_MATERIALS = {
    "effects/fleck_cement1",
    "effects/fleck_cement2"
}
local CONFETTI_COLORS = {
    Color(238, 88, 88),
    Color(76, 156, 238),
    Color(244, 205, 76),
    Color(104, 205, 124),
    Color(202, 102, 224),
    Color(245, 137, 61),
    Color(245, 245, 245)
}
local CHEER_SOUNDS = {
    "vo/npc/female01/fantastic01.wav",
    "vo/npc/male01/nice.wav"
}

surface.CreateFont("LOD_Victory_Title", {
    font = "DejaVu Sans",
    size = 54,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_Victory_Subtitle", {
    font = "DejaVu Sans",
    size = 21,
    weight = 800,
    antialias = true
})

local function soundExists(path)
    return isstring(path) and file.Exists("sound/" .. path, "GAME")
end

local function playCelebrationAudio(current)
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(6, false) end
    -- Garry's Mod itself ships this with its balloon implementation. It gives the
    -- celebration a silly toy-like punctuation before the citizen cheer layer.
    if soundExists("garrysmod/balloon_pop_cute.wav") then
        surface.PlaySound("garrysmod/balloon_pop_cute.wav")
        timer.Simple(0.16, function()
            if current() and soundExists("garrysmod/balloon_pop_cute.wav") then
                surface.PlaySound("garrysmod/balloon_pop_cute.wav")
            end
        end)
    end


    local delay = 0.25
    for _, path in ipairs(CHEER_SOUNDS) do
        local soundPath = path
        if soundExists(soundPath) then
            local scheduledAt = delay
            timer.Simple(scheduledAt, function()
                if current() and soundExists(soundPath) then surface.PlaySound(soundPath) end
            end)
            delay = delay + 1.1
        end
    end
end

local function emitConfettiBurst(center, seedOffset)
    local emitter = ParticleEmitter(center, false)
    if not emitter then return end

    local localPly = LocalPlayer()
    local localCenter = IsValid(localPly) and localPly:GetPos() + Vector(0, 0, 190) or center + Vector(0, 0, 190)
    local count = LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced() and 12 or 60
    for i = 1, count do
        local material = CONFETTI_MATERIALS[((i + (seedOffset or 0)) % #CONFETTI_MATERIALS) + 1]
        local pos = localCenter + Vector(math.Rand(-170, 170), math.Rand(-170, 170), math.Rand(0, 70))
        local p = emitter:Add(material, pos)
        if p then
            local c = CONFETTI_COLORS[((i + (seedOffset or 0)) % #CONFETTI_COLORS) + 1]
            p:SetDieTime(math.Rand(3.6, 5.4))
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(1.8, 3.8))
            p:SetEndSize(math.Rand(1.0, 2.5))
            p:SetColor(c.r, c.g, c.b)
            p:SetVelocity(Vector(math.Rand(-42, 42), math.Rand(-42, 42), math.Rand(-75, -30)))
            p:SetGravity(Vector(0, 0, -42))
            p:SetAirResistance(18)
            p:SetRoll(math.Rand(0, 360))
            p:SetRollDelta(math.Rand(-5.5, 5.5))
            p:SetCollide(false)
        end
    end
    emitter:Finish()
end

local function scheduleConfetti(center, current)
    emitConfettiBurst(center, 0)
    timer.Simple(0.70, function() if current() then emitConfettiBurst(center, 17) end end)
    timer.Simple(1.40, function() if current() then emitConfettiBurst(center, 31) end end)
end

net.Receive("LOD_VictoryCelebration", function()
    if LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return end
    if Client.DisposeFinale then Client:DisposeFinale() end
    Client.center = net.ReadVector()
    Client.duration = math.max(0, net.ReadFloat())
    Client.deborah = net.ReadEntity()
    Client.startedAt = CurTime()
    Client.endsAt = Client.startedAt + Client.duration
    Client.generation = (Client.generation or 0) + 1
    local generation = Client.generation
    local function current()
        local ply = LocalPlayer()
        return generation == Client.generation and CurTime() < (Client.endsAt or 0)
            and IsValid(ply) and ply:Alive()
    end
    playCelebrationAudio(current)
    scheduleConfetti(Client.center, current)
end)

local function celebrationActive()
    return Client.endsAt and CurTime() < Client.endsAt
end

-- A short pulled-back Source-style celebration camera gives the real balloon props
-- and confetti room to read. Hull tracing prevents the camera from clipping through
-- the generated container walls.
hook.Add("CalcView", "LOD_VictoryCelebrationThirdPerson", function(ply, origin, angles, fov)
    if Client.finale then return Client:FinaleView(ply, origin, angles, fov) end
    if not celebrationActive() or not IsValid(ply) or not ply:Alive() then return end

    if LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced() then return end
    local wanted = origin - angles:Forward() * 118 + Vector(0, 0, 34)
    local tr = util.TraceHull({
        start = origin,
        endpos = wanted,
        mins = Vector(-6, -6, -6),
        maxs = Vector(6, 6, 6),
        mask = MASK_SOLID,
        filter = ply
    })

    return {
        origin = tr.HitPos,
        angles = angles,
        fov = fov,
        drawviewer = true
    }
end)

hook.Add("HUDPaint", "LOD_VictoryCelebrationHUD", function()
    if Client.finale then Client:FinaleHUD();return end
    if not celebrationActive() then return end
    local elapsed = CurTime() - (Client.startedAt or CurTime())
    local remaining = math.max(0, (Client.endsAt or CurTime()) - CurTime())
    local fadeIn = math.Clamp(elapsed / 0.30, 0, 1)
    local fadeOut = math.Clamp(remaining / 0.85, 0, 1)
    local alpha = math.floor(255 * math.min(fadeIn, fadeOut))
    if alpha <= 0 then return end

    local y = math.floor(ScrH() * 0.13)
    draw.SimpleText("CONGRATULATIONS", "LOD_Victory_Title", ScrW() * 0.5, y + 3,
        Color(10, 10, 10, math.floor(alpha * 0.7)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("CONGRATULATIONS", "LOD_Victory_Title", ScrW() * 0.5, y,
        Color(248, 213, 105, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText((LOD.Damsels and LOD.Damsels:Current().victory or "LEVEL CLEAR"), "LOD_Victory_Subtitle", ScrW() * 0.5, y + 63,
        Color(238, 238, 238, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText((LOD.Damsels and LOD.Damsels:Current().type=="cash" and "FISCAL LIBERATION." or "ANOTHER SOUL DELIVERED."), "LOD_AdventureAside", ScrW() * 0.5, y + 94,
        Color(246, 218, 158, math.floor(alpha*.85)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

hook.Add("PreCleanupMap", "LOD_VictoryPresentationReset", function()
    if Client.DisposeFinale then Client:DisposeFinale() end
    Client.generation = (Client.generation or 0) + 1
    Client.endsAt, Client.startedAt, Client.deborah = nil, nil, nil
end)

concommand.Add("lod_victory_client_status", function()
    print(string.format("[LOD:VICTORY-CLIENT] active=%s remaining=%.1fs center=%s",
        tostring(celebrationActive()),
        math.max(0, (Client.endsAt or 0) - CurTime()),
        tostring(Client.center or vector_origin)))
end)

-- Deborah's accepted-rescue tableau is a bounded client-only picture. It never
-- moves world actors, changes rewards, freezes a player or replaces progression.
Client.finaleModels = {}
local function reducedFinale()
    return LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
end
local function removeFinaleModels()
    local hidden=Client.finaleHidden
    if hidden and IsValid(hidden.entity) and hidden.entity.RenderOverride==hidden.override then
        hidden.entity.RenderOverride=hidden.previous
    end
    Client.finaleHidden=nil
    for key,actor in pairs(Client.finaleModels) do
        if IsValid(actor) then actor:Remove() end
        Client.finaleModels[key]=nil
    end
end
function Client:DisposeFinale()
    if self.finale then self.finaleRetired=math.max(self.finaleRetired or 0,self.finale.serial) end
    self.finale=nil
    removeFinaleModels()
end
function Client:FinaleValid()
    local f=self.finale
    if not f or CurTime()>=f.endsAt or CurTime()-f.received>.75 then return false end
    if LOD.IntermissionTetrisClient and LOD.IntermissionTetrisClient.active then return false end
    if LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return false end
    local s=LOD.ClientState
    if s and s.synchronized and (s.failed or s.level~=20 or not s.levelCleared) then return false end
    return true
end
function Client:FinaleActive()
    local p=LocalPlayer()
    return self:FinaleValid() and IsValid(p) and p:Alive()
end
local function sequence(actor,names)
    for _,name in ipairs(names) do
        local seq=actor:LookupSequence(name)
        if seq and seq>=0 then actor:ResetSequence(seq);actor:SetCycle(0);actor:SetPlaybackRate(1);return end
    end
    actor:ResetSequence(0);actor:SetPlaybackRate(0)
end
local function createFinaleModel(key,model,level,f)
    local actor
    local ok=pcall(function()
        if not util.IsValidModel(model) then return end
        actor=ClientsideModel(model,RENDERGROUP_OPAQUE)
        if not IsValid(actor) then return end
        -- Register before initialization so partial creation always has an owner.
        Client.finaleModels[key]=actor
        actor:SetNoDraw(true);actor:DrawShadow(false)
        sequence(actor,level and level~=20 and {"wave","cheer1","LineIdle01","idle_subtle"}
            or {"idle_subtle","LineIdle01","idle_all_01"})
        if level==20 and not actor:LookupBone("ValveBiped.Bip01_Head1") then
            sequence(actor,{"wave","cheer1","LineIdle01","idle_subtle"})
        end
        if level and LOD.Damsels and LOD.Damsels.ApplyAppearance then
            LOD.Damsels:ApplyAppearance(actor,level,f.campaignSeed)
        end
    end)
    if not ok and IsValid(actor) then actor:Remove();Client.finaleModels[key]=nil end
end
local function prepareFinaleModels(f)
    if f.visualFault then return end
    if reducedFinale() then removeFinaleModels();return end
    if f.prepared then return end
    f.prepared=true
    local damsels=LOD.Damsels
    createFinaleModel("deborah",LOD.Config.Models.Deborah,20,f)
    for index,hero in ipairs(f.heroes) do createFinaleModel("hero"..index,hero.model,nil,f) end
    if damsels then
        for _,level in ipairs(f.damsels) do
            local def=damsels.Definitions[level]
            if def then createFinaleModel("damsel"..level,damsels:Model(def),level,f) end
        end
    end
    if IsValid(Client.finaleModels.deborah) and IsValid(f.deborah) then
        local suppress=function() end
        Client.finaleHidden={entity=f.deborah,previous=f.deborah.RenderOverride,override=suppress}
        f.deborah.RenderOverride=suppress
    end
end
local function presentHero(hero)
    return hero.present and IsValid(hero.entity) and hero.entity:Alive()
        and not hero.entity:GetNW2Bool("LOD_IsSoldier",false)
end
net.Receive("LOD_DeborahFinale",function()
    if not net.ReadBool() then Client:DisposeFinale();return end
    local opening=net.ReadBool()
    local f={serial=net.ReadUInt(32),startedAt=net.ReadFloat(),endsAt=net.ReadFloat(),
        center=net.ReadVector(),yaw=net.ReadFloat(),campaignSeed=net.ReadUInt(31),
        deborah=net.ReadEntity(),heroes={},damsels={},received=CurTime()}
    local count=net.ReadUInt(3)
    for i=1,count do
        local hero={entity=net.ReadEntity(),identity=net.ReadString(),name=net.ReadString(),model=net.ReadString(),present=net.ReadBool()}
        if i<=4 then f.heroes[i]=hero end
    end
    count=net.ReadUInt(5)
    local seen={}
    for i=1,count do
        local level=net.ReadUInt(5)
        if level>=1 and level<=19 and not seen[level] then seen[level]=true;f.damsels[#f.damsels+1]=level end
    end
    if f.serial<=(Client.finaleRetired or 0) or CurTime()>=f.endsAt then return end
    local previous=Client.finale
    if previous and f.serial<previous.serial then return end
    if previous and previous.serial==f.serial then
        -- Immutable actor/model snapshots; updates only change presence + lease.
        previous.received=f.received
        for i,hero in ipairs(previous.heroes) do
            local fresh=f.heroes[i]
            hero.present=fresh and fresh.identity==hero.identity and fresh.entity==hero.entity and fresh.present or false
        end
        return
    end
    Client:DisposeFinale()
    Client.endsAt=nil;Client.generation=(Client.generation or 0)+1
    Client.finale=f
    if Client:FinaleActive() then prepareFinaleModels(f) end
    -- Late joins use server time and never replay earlier audio or phase beats.
    if opening and Client:FinaleActive() then
        if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(6,false) end
        if soundExists("vo/npc/female01/fantastic01.wav") then surface.PlaySound("vo/npc/female01/fantastic01.wav") end
    end
end)
function Client:FinaleView(ply,origin,angles,fov)
    if not self:FinaleActive() or reducedFinale() or self.finale.visualFault then return end
    local f=self.finale
    local forward=Angle(0,f.yaw,0):Forward()
    local focus=f.center+Vector(0,0,52)
    local elapsed=CurTime()-f.startedAt
    local desired=focus+forward*(245+math.sin(elapsed*.5)*6)+Vector(0,0,65)
    local ok,view=pcall(function()
        local tr=util.TraceHull({start=focus,endpos=desired,mins=Vector(-6,-6,-6),
            maxs=Vector(6,6,6),mask=MASK_SOLID,filter=ply})
        return {origin=tr.HitPos,angles=(focus-tr.HitPos):Angle(),fov=fov,drawviewer=true}
    end)
    if ok then return view end
    f.visualFault=true;removeFinaleModels()
    ErrorNoHalt("[LOD:FINALE] "..tostring(view).."\n")
end
local function currentBeat(f)
    local elapsed=CurTime()-f.startedAt
    if elapsed<1.5 or elapsed>=5.5 then return nil,0 end
    local index=math.floor(elapsed-1.5)+1
    local hero=f.heroes[index]
    if not hero or not presentHero(hero) then return nil,0 end
    return index,math.sin((elapsed-1.5-(index-1))*math.pi)
end
function Client:FinaleHUD()
    if not self:FinaleActive() then return end
    local f=self.finale;local elapsed=CurTime()-f.startedAt
    local beat=currentBeat(f)
    local title=elapsed>=5.5 and "THE RESCUE STORY IS WON" or "DEBORAH RESCUED"
    local subtitle=elapsed>=5.5 and "SECURE THE BAG — LEVEL 21 AWAITS"
        or beat and ("Deborah: Thank you, "..f.heroes[beat].name..".")
        or "The rescued stand together. Hector's direction ends here."
    local y=ScrH()*.13
    draw.SimpleText(title,"LOD_Victory_Title",ScrW()*.5,y,Color(248,213,105),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
    draw.SimpleText(subtitle,"LOD_Victory_Subtitle",ScrW()*.5,y+63,Color(238,238,238),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
    draw.SimpleText("Deborah will welcome you home. Abundance awaits beyond Level 20.",
        "LOD_AdventureAside",ScrW()*.5,y+94,Color(246,218,158),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
end
local function poseAndDraw(actor,pos,ang,lean)
    if not IsValid(actor) then return end
    actor:SetPos(pos);actor:SetAngles(ang)
    for _,name in ipairs({"ValveBiped.Bip01_Spine2","ValveBiped.Bip01_Head1"}) do
        local bone=actor:LookupBone(name)
        if bone then actor:ManipulateBoneAngles(bone,Angle(0,0,(lean or 0)*12)) end
    end
    actor:FrameAdvance(FrameTime());actor:SetupBones();actor:DrawModel()
end
hook.Add("PostDrawOpaqueRenderables","LOD_DeborahFinaleTableau",function(depth,sky)
    if depth or sky or not Client:FinaleActive() or reducedFinale() or Client.finale.visualFault then return end
    local f=Client.finale
    local ok,err=pcall(function()
        prepareFinaleModels(f)
        local angle=Angle(0,f.yaw,0);local forward,right=angle:Forward(),angle:Right()
        local beat,lean=currentBeat(f)
        local pos=f.center
        if beat then pos=pos+right*((48*beat-18)*lean) end
        poseAndDraw(Client.finaleModels.deborah,pos,angle,lean)
        for index,hero in ipairs(f.heroes) do
            if presentHero(hero) then
                poseAndDraw(Client.finaleModels["hero"..index],f.center+right*(48*index),angle,0)
            end
        end
        for index,level in ipairs(f.damsels) do
            local row=math.floor((index-1)/10)
            local col=(index-1)%10
            poseAndDraw(Client.finaleModels["damsel"..level],
                f.center-forward*(48+row*42)+right*((col-4.5)*34),angle,0)
        end
    end)
    if not ok then
        f.visualFault=true;removeFinaleModels()
        ErrorNoHalt("[LOD:FINALE] "..tostring(err).."\n")
    end
end)
hook.Add("PrePlayerDraw","LOD_DeborahFinaleHideParticipants",function(ply)
    if not Client:FinaleActive() or reducedFinale() then return end
    for i,hero in ipairs(Client.finale.heroes) do
        if hero.entity==ply and presentHero(hero) and IsValid(Client.finaleModels["hero"..i]) then return true end
    end
end)
hook.Add("Think","LOD_DeborahFinaleClientLifecycle",function()
    local f=Client.finale;if not f then return end
    if not Client:FinaleValid() then Client:DisposeFinale();return end
    -- Initial spawn and local death are temporary viewing absences. Resume the
    -- elapsed phase on revival; never replay the opening cue or resurrect a
    -- retired participating Hero slot on the server.
    if not Client:FinaleActive() then removeFinaleModels();f.prepared=false;return end
    if reducedFinale() then removeFinaleModels();f.prepared=false
    else prepareFinaleModels(f) end
    -- External target removal/replacement must never leave a suppression behind.
    if Client.finaleHidden and not IsValid(Client.finaleModels.deborah) then removeFinaleModels() end
end)
hook.Add("ShutDown","LOD_DeborahFinaleShutdown",function() Client:DisposeFinale() end)
hook.Add("PostCleanupMap","LOD_DeborahFinalePostCleanup",function() Client:DisposeFinale() end)
