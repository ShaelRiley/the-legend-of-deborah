LOD = LOD or {}

local EC = LOD.Config.Encounter
local EncounterDirector = LOD.EncounterDirector
local CombatAudio = LOD.CombatAudio

LOD.DeadcrabCombat = LOD.DeadcrabCombat or {
    leaps = 0,
    latches = 0,
    detonations = 0,
    victims = 0,
    totalDamage = 0
}
local DeadcrabCombat = LOD.DeadcrabCombat

-- DEADCRAB ---------------------------------------------------------------
-- A deliberately fragile suicide-pressure archetype: visually a blood-red
-- classic headcrab, tactically a dodgeable leap followed by a committed
-- 0.75-second face-latched fuse and grenade-like blast.
EC.Archetypes.deadcrab = {
    class = "lod_hostile_deadcrab",
    name = "Deadcrab",
    model = "models/headcrabclassic.mdl",
    baseHP = 8,
    speed = 185,
    meleeDamage = 0,
    meleeCooldown = 99,
    meleeRange = 0,
    leapRange = 250,
    leapSpeed = 520,
    leapCooldown = 1.15,
    latchDistance = 58,
    fuseSeconds = 0.75,
    explosionDamage = 55,
    explosionRadius = 180,
    attackSounds = {
        "npc/headcrab/attack1.wav", "npc/headcrab/attack2.wav", "npc/headcrab/attack3.wav"
    },
    threat = 0.8,
    activity = ACT_RUN
}

EC.Templates.deadcrab_nest = {
    name = "Deadcrab Nest",
    composition = {deadcrab = 3}
}

local DEADCRAB_PAIN = {
    "npc/headcrab/pain1.wav", "npc/headcrab/pain2.wav", "npc/headcrab/pain3.wav"
}
local DEADCRAB_DEATH = {
    "npc/headcrab/die1.wav", "npc/headcrab/die2.wav"
}
local DEADCRAB_ALERT = {
    "npc/headcrab/alert1.wav"
}

local function usable(paths)
    local out = {}
    for _, path in ipairs(paths or {}) do
        if file.Exists("sound/" .. path, "GAME") then out[#out + 1] = path end
    end
    return out
end

local function playRotating(hostile, field, paths, level, pitch, volume)
    local pool = usable(paths)
    if #pool == 0 or not IsValid(hostile) then return end
    hostile[field] = ((hostile[field] or 0) % #pool) + 1
    hostile:EmitSound(pool[hostile[field]], level or 74, pitch or 100, volume or 0.8, CHAN_VOICE)
end

-- Extend the centralized audio API without changing the already validated
-- Shambler/Runner/Soldier sound banks.
if CombatAudio and not CombatAudio.LODDeadcrabAudioWrapped then
    CombatAudio.LODDeadcrabAudioWrapped = true

    local basePain = CombatAudio.PlayHostilePain
    function CombatAudio:PlayHostilePain(hostile)
        if IsValid(hostile) and hostile.LODArchetypeId == "deadcrab" then
            local now = CurTime()
            if now < (hostile.LODNextPainAudio or 0) then return end
            hostile.LODNextPainAudio = now + 0.35
            playRotating(hostile, "LODDeadcrabPainOrdinal", DEADCRAB_PAIN, 72, 118, 0.82)
            return
        end
        return basePain(self, hostile)
    end

    local baseDeath = CombatAudio.PlayHostileDeath
    function CombatAudio:PlayHostileDeath(hostile)
        if IsValid(hostile) and hostile.LODArchetypeId == "deadcrab" then
            playRotating(hostile, "LODDeadcrabDeathOrdinal", DEADCRAB_DEATH, 78, 105, 0.95)
            return
        end
        return baseDeath(self, hostile)
    end

    local baseActivation = CombatAudio.PlayEncounterActivation
    function CombatAudio:PlayEncounterActivation(encounter, anchor)
        if IsValid(anchor) and anchor.LODArchetypeId == "deadcrab" then
            playRotating(anchor, "LODDeadcrabAlertOrdinal", DEADCRAB_ALERT, 77, 112, 0.82)
            return
        end
        return baseActivation(self, encounter, anchor)
    end
end

-- Give Deadcrabs their own wet, rapid scuttle signature. Using the canonical
-- Headcrab footstep sound-script keeps the cue distinct from every other enemy.
hook.Add("Think", "LOD_DeadcrabFootsteps", function()
    local now = CurTime()
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "deadcrab"
            and not hostile.LODDead and hostile.LODActivated ~= false
            and hostile.LODDeadcrabState ~= "latched"
            and hostile:GetVelocity():Length2D() > 20
            and now >= (hostile.LODDeadcrabNextFootstep or 0)
        then
            hostile.LODDeadcrabNextFootstep = now + 0.19
            hostile:EmitSound("NPC_HeadCrab.Footstep", 66, 122, 0.72, CHAN_BODY)
        end
    end
end)

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function deadcrabSetActivity(self, activity)
    if self._SetActivity then self:_SetActivity(activity or ACT_RUN, true) end
end

local function beginLeap(self, target)
    local cfg = self.LODConfig
    if not livingPlayer(target) or CurTime() < (self.LODDeadcrabNextLeap or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.leapRange * cfg.leapRange then return false end
    if self._HasLineOfSight and not self:_HasLineOfSight(target) then return false end

    self.LODDeadcrabState = "leaping"
    self.LODDeadcrabTarget = target
    DeadcrabCombat.leaps = DeadcrabCombat.leaps + 1
    self.LODDeadcrabLeapExpires = CurTime() + 0.85
    self.LODDeadcrabNextLeap = CurTime() + cfg.leapCooldown
    deadcrabSetActivity(self, ACT_RANGE_ATTACK1 or ACT_JUMP or ACT_RUN)

    if CombatAudio and CombatAudio.PlayHostileAttack then
        CombatAudio:PlayHostileAttack(self)
    end

    local start = self:WorldSpaceCenter()
    local finish = target:EyePos()
    local delta = finish - start
    local horizontal = Vector(delta.x, delta.y, 0)
    local travel = math.Clamp(horizontal:Length() / cfg.leapSpeed, 0.28, 0.52)
    local gravity = 600
    local verticalSpeed = (delta.z + 0.5 * gravity * travel * travel) / travel
    local velocity = horizontal / travel + Vector(0, 0, verticalSpeed)

    if self.loco then
        self.loco:SetDesiredSpeed(0)
        if self.loco.Jump then self.loco:Jump() end
        if self.loco.SetVelocity then self.loco:SetVelocity(velocity) else self:SetVelocity(velocity) end
    else
        self:SetVelocity(velocity)
    end
    return true
end

local function blastPlayers(self, origin)
    local cfg = self.LODConfig
    local victims = 0
    local totalDamage = 0
    for _, ply in ipairs(player.GetAll()) do
        if livingPlayer(ply) then
            local distance = origin:Distance(ply:WorldSpaceCenter())
            if distance <= cfg.explosionRadius then
                local closeness = 1 - math.Clamp(distance / cfg.explosionRadius, 0, 1)
                local amount = math.max(8, math.floor(cfg.explosionDamage * (0.30 + 0.70 * closeness) + 0.5))
                local dmg = DamageInfo()
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
                dmg:SetDamageType(DMG_BLAST)
                dmg:SetDamage(amount)
                dmg:SetDamagePosition(origin)
                ply:TakeDamageInfo(dmg)
                victims = victims + 1
                totalDamage = totalDamage + amount
            end
        end
    end
    return victims, totalDamage
end

local function detonate(self)
    if not IsValid(self) or self.LODDead then return end

    local target = self.LODDeadcrabTarget
    local origin = livingPlayer(target) and target:EyePos() or self:WorldSpaceCenter()
    local state = LOD.RunManager and LOD.RunManager.State

    self.LODDead = true
    self.LODActivated = false
    self.LODDeathLevelSeed = state and state.LevelSeed or nil
    self.LODDeadcrabState = "detonated"
    self:SetParent(nil)
    self:SetPos(origin)
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)

    local effect = EffectData()
    effect:SetOrigin(origin)
    effect:SetScale(0.75)
    util.Effect("Explosion", effect, true, true)
    sound.Play("ambient/explosions/explode_4.wav", origin, 92, 108, 1.0)

    local victims, totalDamage = blastPlayers(self, origin)
    DeadcrabCombat.detonations = DeadcrabCombat.detonations + 1
    DeadcrabCombat.victims = DeadcrabCombat.victims + victims
    DeadcrabCombat.totalDamage = DeadcrabCombat.totalDamage + totalDamage
    DeadcrabCombat.lastVictims = victims
    DeadcrabCombat.lastDamage = totalDamage

    -- Suicide detonation still resolves its encounter slot, but hostile blast
    -- damage is applied only to players and therefore cannot create faction
    -- infighting or chain-detonate allied enemies.
    if EncounterDirector and EncounterDirector.OnHostileKilled then
        EncounterDirector:OnHostileKilled(self, nil)
    end
    if CombatAudio and CombatAudio.PlayHostileDeath then
        CombatAudio:PlayHostileDeath(self)
    end

    if self._SpawnPlaceholderLoot then self:_SpawnPlaceholderLoot() end
    timer.Simple(0.08, function()
        sound.Play("items/itempickup.wav", origin, 78, 146, 0.88)
        sound.Play("buttons/button9.wav", origin, 70, 132, 0.62)
    end)

    self:Remove()
end

local function latch(self, target)
    if not livingPlayer(target) or self.LODDead then return false end
    local cfg = self.LODConfig

    self.LODDeadcrabState = "latched"
    self.LODDeadcrabTarget = target
    DeadcrabCombat.latches = DeadcrabCombat.latches + 1
    if self.loco then
        self.loco:SetDesiredSpeed(0)
        if self.loco.SetVelocity then self.loco:SetVelocity(vector_origin) end
    end

    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetParent(target)
    self:SetLocalPos(Vector(8, 0, 62))
    self:SetLocalAngles(Angle(0, 180, 0))
    deadcrabSetActivity(self, ACT_IDLE)

    if file.Exists("sound/npc/headcrab/headbite.wav", "GAME") then
        self:EmitSound("npc/headcrab/headbite.wav", 82, 108, 1.0, CHAN_VOICE)
    else
        self:EmitSound("npc/headcrab/attack2.wav", 82, 108, 1.0, CHAN_VOICE)
    end

    -- Three accelerating fuse warnings make the committed explosion unmistakable.
    for i, delay in ipairs({0.18, 0.38, 0.58}) do
        timer.Simple(delay, function()
            if not IsValid(self) or self.LODDead or self.LODDeadcrabState ~= "latched" then return end
            local pos = livingPlayer(target) and target:EyePos() or self:WorldSpaceCenter()
            sound.Play("buttons/button17.wav", pos, 78, 102 + i * 12, 0.88)
        end)
    end

    timer.Simple(cfg.fuseSeconds, function()
        if IsValid(self) and not self.LODDead and self.LODDeadcrabState == "latched" then
            detonate(self)
        end
    end)
    return true
end

local function processLeap(self)
    local target = self.LODDeadcrabTarget
    if not livingPlayer(target) then
        self.LODDeadcrabState = nil
        self.LODDeadcrabTarget = nil
        self.LODNextRouteRefresh = 0
        return true
    end

    local distance = self:WorldSpaceCenter():DistToSqr(target:EyePos())
    if distance <= self.LODConfig.latchDistance * self.LODConfig.latchDistance then
        latch(self, target)
        return true
    end

    if CurTime() >= (self.LODDeadcrabLeapExpires or 0) then
        self.LODDeadcrabState = nil
        self.LODDeadcrabTarget = nil
        self.LODNextRouteRefresh = 0
        if self.loco then self.loco:SetDesiredSpeed(self.LODConfig.speed) end
        deadcrabSetActivity(self, self.LODConfig.activity or ACT_RUN)
    end
    return true
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODDeadcrabPatched then return false end
    class.LODDeadcrabPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "deadcrab" or not self.LODConfig then return end

        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(205, 32, 32, 255))
        self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 30))
        self.LODDeadcrabState = nil
        self.LODDeadcrabTarget = nil
        self.LODDeadcrabNextLeap = CurTime() + 0.45
        if self.loco then
            self.loco:SetDesiredSpeed(self.LODConfig.speed)
            self.loco:SetStepHeight(20)
            self.loco:SetJumpHeight(120)
        end
        deadcrabSetActivity(self, self.LODConfig.activity or ACT_RUN)
    end

    -- Named archetype dispatch keeps the attack state machine reachable even if
    -- Source installs Motion V2 after this wrapper during OnEntityCreated.
    function class:_RunDeadcrabTick()
        if self.LODArchetypeId ~= "deadcrab" then return false end

        local frame = FrameNumber()
        if self.LODDeadcrabDispatchFrame == frame then return false end
        self.LODDeadcrabDispatchFrame = frame

        if self.LODDead or not self.LODActivated then return true end
        if self.LODDeadcrabState == "latched" or self.LODDeadcrabState == "detonated" then return true end
        if self.LODDeadcrabState == "leaping" then
            processLeap(self)
            return true
        end

        local target = self.LODTarget
        return livingPlayer(target) and beginLeap(self, target) or false
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "deadcrab" and self:_RunDeadcrabTick() then return end
        return baseBehaviourTick(self)
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_DeadcrabInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

-- Make Deadcrab nests part of the authored encounter grammar without rewriting
-- the validated planner. Early sectors use them mainly as ambushes; later sectors
-- may deploy them in ordinary travel/reward cells as a tempo spike.
if EncounterDirector and not EncounterDirector.LODDeadcrabPlannerWrapped then
    EncounterDirector.LODDeadcrabPlannerWrapped = true

    local baseEligible = EncounterDirector._EligibleTemplates
    function EncounterDirector:_EligibleTemplates(sector, role)
        local base = baseEligible(self, sector, role)
        local out = {}
        for _, id in ipairs(base or {}) do out[#out + 1] = id end
        if role == "ambush" or role == "reward" or sector >= 2 then
            out[#out + 1] = "deadcrab_nest"
        end
        return out
    end

    local baseSpawn = EncounterDirector._SpawnEncounter
    function EncounterDirector:_SpawnEncounter(encounter)
        if not encounter or not encounter.composition or not encounter.composition.deadcrab then
            return baseSpawn(self, encounter)
        end
        if encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition) do total = total + count end
        if self:GetActiveCount() + total > EC.ActiveHostileCeiling then return false end

        local center = LOD.MazeNavigator:CellCenter(encounter.cell) + Vector(0, 0, 10)
        local offsets = self:_SpawnOffsets(total)
        local ordinal = 1
        for _, archetypeId in ipairs({"shambler", "runner", "deadcrab", "soldier"}) do
            local count = encounter.composition[archetypeId] or 0
            for _ = 1, count do
                local ent = ents.Create("lod_hostile")
                if IsValid(ent) then
                    ent.LODArchetypeId = archetypeId
                    ent.LODHomeCellKey = encounter.cellKey
                    ent.LODEncounterId = encounter.id
                    ent.LODActivated = true
                    ent:SetPos(center + offsets[ordinal])
                    ent:Spawn()
                    ent:Activate()
                    ent:DropToFloor()
                    encounter.entities[#encounter.entities + 1] = ent
                    self.Entities[#self.Entities + 1] = ent
                end
                ordinal = ordinal + 1
            end
        end

        encounter.spawned = true
        encounter.activated = true
        return true
    end
end

concommand.Add("lod_deadcrab_attack_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local result = DeadcrabCombat.detonations > 0
        and (DeadcrabCombat.lastVictims or 0) > 0
        and (DeadcrabCombat.lastDamage or 0) > 0
        and "PASS" or "FAIL"
    local line = string.format(
        "leaps=%d latches=%d detonations=%d lastVictims=%d lastDamage=%d result=%s",
        DeadcrabCombat.leaps, DeadcrabCombat.latches, DeadcrabCombat.detonations,
        DeadcrabCombat.lastVictims or 0, DeadcrabCombat.lastDamage or 0, result
    )
    print("[LOD:DEADCRAB-ATTACK] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_m3_deadcrab_audio_audit", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local function ok(path) return file.Exists("sound/" .. path, "GAME") and "OK" or "MISSING" end
    local lines = {
        "deadcrab model=" .. (util.IsValidModel(EC.Archetypes.deadcrab.model) and "OK" or "MISSING"),
        "attack=" .. ok("npc/headcrab/attack1.wav"),
        "pain=" .. ok("npc/headcrab/pain1.wav"),
        "death=" .. ok("npc/headcrab/die1.wav"),
        "alert=" .. ok("npc/headcrab/alert1.wav"),
        "bite=" .. ok("npc/headcrab/headbite.wav"),
        "explosion=" .. ok("ambient/explosions/explode_4.wav"),
        "footstepScript=NPC_HeadCrab.Footstep"
    }
    for _, line in ipairs(lines) do
        print("[LOD:DEADCRAB] " .. line)
        if IsValid(ply) then ply:ChatPrint(line) end
    end
end)
