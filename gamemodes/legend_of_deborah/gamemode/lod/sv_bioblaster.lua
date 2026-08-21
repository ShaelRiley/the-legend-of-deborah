LOD = LOD or {}

local EC = LOD.Config.Encounter
local EncounterDirector = LOD.EncounterDirector
local CombatAudio = LOD.CombatAudio
local Motion = LOD.HostileMotionV2

local BIO_PAIN = {
    "npc/zombie_poison/pz_pain1.wav", "npc/zombie_poison/pz_pain2.wav", "npc/zombie_poison/pz_pain3.wav"
}
local BIO_DEATH = {
    "npc/zombie_poison/pz_die1.wav", "npc/zombie_poison/pz_die2.wav"
}
local BIO_ALERT = {
    "npc/zombie_poison/pz_alert1.wav", "npc/zombie_poison/pz_warn1.wav"
}
local BIO_FEET = {
    "npc/zombie_poison/pz_left_foot1.wav", "npc/zombie_poison/pz_right_foot1.wav",
    "npc/antlion_guard/foot_heavy1.wav", "npc/antlion_guard/foot_heavy2.wav"
}
local BIO_CHARGE = {
    "npc/zombie_poison/pz_warn1.wav", "npc/antlion_guard/angry3.wav"
}

local function usable(paths)
    local out = {}
    for _, path in ipairs(paths or {}) do
        if file.Exists("sound/" .. path, "GAME") then out[#out + 1] = path end
    end
    return out
end

local function playRotating(hostile, field, paths, level, pitch, volume, channel)
    local pool = usable(paths)
    if #pool == 0 or not IsValid(hostile) then return false end
    hostile[field] = ((hostile[field] or 0) % #pool) + 1
    hostile:EmitSound(pool[hostile[field]], level or 74, pitch or 100, volume or 0.8, channel or CHAN_VOICE)
    return true
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function bioIdle(self)
    if self._SetActivity then self:_SetActivity(ACT_IDLE_ANGRY or ACT_IDLE, true) end
end

local function bioWalk(self)
    if self._SetActivity then self:_SetActivity(ACT_WALK, true) end
end

local function holdAndFace(self, target)
    if not IsValid(self) or not IsValid(target) then return end

    -- Motion V2 is the physical authority for every ground hostile. Driving its
    -- disabled CLuaLocomotion object directly left the Bio Blaster's hold/facing
    -- state outside that authority, so its mouth origin could retain a stale yaw
    -- and the attack state could stall after the locomotion migration.
    if self.LODMotionV2 and Motion then
        Motion:Stop(self)
        Motion:FaceToward(self, target:GetPos())
        return
    end

    if self.loco then
        self.loco:SetDesiredSpeed(0)
        self.loco:FaceTowards(Vector(target:GetPos().x, target:GetPos().y, self:GetPos().z))
    end
end

local function openChestPose(self)
    -- The classic zombie attack-B/C sequences give the broadest arms-open,
    -- chest-exposed silhouette. Fall back to the normal attack activity on a
    -- model/runtime that does not expose those sequence names.
    for _, name in ipairs({"attackB", "attackC", "attackA"}) do
        local seq = self:LookupSequence(name)
        if isnumber(seq) and seq >= 0 then
            self:ResetSequence(seq)
            self:SetCycle(0)
            self:SetPlaybackRate(0.55)
            self.LODCurrentActivity = nil
            return
        end
    end
    if self._SetActivity then self:_SetActivity(ACT_MELEE_ATTACK1 or ACT_RANGE_ATTACK1, true) end
end

local function mawPosition(self)
    local scale = self:GetNW2Float("LOD_SizeScale", 1)
    if scale <= 0 then scale = 1 end
    for _, name in ipairs({"mouth", "eyes"}) do
        local attachment = self:LookupAttachment(name)
        if attachment and attachment > 0 then
            local data = self:GetAttachment(attachment)
            if data and data.Pos then return data.Pos + self:GetForward() * (10 * scale) end
        end
    end
    return self:WorldSpaceCenter() + self:GetForward() * (30 * scale) + Vector(0, 0, 18 * scale)
end

local function bioHasLineOfSight(self, target)
    if not IsValid(self) or not livingPlayer(target) then return false end

    -- Bio Blaster needs a projectile-authentic sightline. The shared Phase Zero
    -- MASK_SOLID perception trace can reject this model at point-blank range and
    -- leave it in generic pursuit forever. Restore the original MASK_SHOT
    -- semantics locally while still treating generated walls as authoritative.
    local tr = util.TraceLine({
        start = self:WorldSpaceCenter() + Vector(0, 0, 12),
        endpos = target:WorldSpaceCenter(),
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == self or ent == target then return false end
            if IsValid(ent) and ent.LODHostile then return false end
            if IsValid(ent) and (ent:GetOwner() == target or ent:GetParent() == target) then return false end
            return true
        end
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

local function spawnBioBolt(self, aimPos)
    local cfg = self.LODConfig
    local startPos = mawPosition(self)
    local direction = (aimPos - startPos):GetNormalized()

    local bolt = ents.Create("lod_bio_bolt")
    if not IsValid(bolt) then return false end
    bolt.LODOwner = self
    bolt.LODDirection = direction
    bolt.LODSpeed = cfg.projectileSpeed
    bolt.LODDamage = cfg.blastDamage
    bolt.LODLifetime = cfg.projectileLifetime
    bolt:SetPos(startPos)
    bolt:SetAngles(direction:Angle())
    bolt:Spawn()
    bolt:Activate()

    -- Share the Soldier's exact projectile-release cue. The Bio Blaster keeps
    -- its own organic charge/telegraph bank, but the release is the same short
    -- laser-like AR2 report instead of the former Physcannon/Antlion blast pair.
    self:EmitSound("Weapon_AR2.Single", 72, 100, 0.85, CHAN_WEAPON)
    return true
end

local function cancelBlast(self, cooldown)
    self.LODBioBlast = nil
    self.LODNextBioCharge = CurTime() + (cooldown or 0.45)
    bioIdle(self)
end

local function beginBlast(self, target)
    local cfg = self.LODConfig
    if self.LODBioBlast or not livingPlayer(target) then return false end
    if CurTime() < (self.LODNextBioCharge or 0) then return false end
    if self:GetPos():DistToSqr(target:GetPos()) > cfg.fireRange * cfg.fireRange then return false end
    if not bioHasLineOfSight(self, target) then return false end

    self.LODBioBlast = {
        target = target,
        fireAt = CurTime() + cfg.blastTelegraph,
        lastAimPos = target:WorldSpaceCenter()
    }
    holdAndFace(self, target)
    openChestPose(self)

    if not playRotating(self, "LODBioChargeOrdinal", BIO_CHARGE, 80, 88, 0.95, CHAN_VOICE)
        and CombatAudio and CombatAudio.PlayHostileAttack
    then
        CombatAudio:PlayHostileAttack(self)
    end
    self:EmitSound("buttons/button17.wav", 66, 76, 0.45, CHAN_ITEM)
    return true
end

local function processBlast(self)
    local burst = self.LODBioBlast
    if not burst then return false end
    local cfg = self.LODConfig
    local target = burst.target

    if not livingPlayer(target) then
        cancelBlast(self, 0.3)
        return false
    end

    holdAndFace(self, target)

    if CurTime() < burst.fireAt then
        if not bioHasLineOfSight(self, target) then
            cancelBlast(self, 0.35)
            return false
        end
        burst.lastAimPos = target:WorldSpaceCenter()
        return true
    end

    spawnBioBolt(self, burst.lastAimPos)
    self.LODBioBlast = nil
    -- Begin the next telegraph early enough that projectile releases remain
    -- approximately blastInterval seconds apart under uninterrupted combat.
    self.LODNextBioCharge = CurTime() + math.max(0.25, cfg.blastInterval - cfg.blastTelegraph)
    bioIdle(self)
    return false
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODBioBlasterPatched then return false end
    class.LODBioBlasterPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "bioblaster" or not self.LODConfig then return end

        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(72, 220, 92, 255))
        self.LODBioBlast = nil
        self.LODNextBioCharge = CurTime() + 0.75
        bioWalk(self)
    end

    -- Archetype dispatch is a named class method as well as a wrapper. Motion V2
    -- invokes it directly, so unordered OnEntityCreated hook execution cannot
    -- erase Bio combat by installing the generic motion tick afterward.
    function class:_RunBioBlasterTick()
        if self.LODArchetypeId ~= "bioblaster" then return false end

        -- A correctly ordered wrapper may reach this dispatcher before Motion V2
        -- does. Evaluate it only once per server frame, then let the second entry
        -- fall through to generic pursuit without duplicating target/LOS work.
        local frame = FrameNumber()
        if self.LODBioDispatchFrame == frame then return false end
        self.LODBioDispatchFrame = frame

        self.LODBioDebugTicks = (self.LODBioDebugTicks or 0) + 1
        if self.LODDead or not self.LODActivated then
            self.LODBioDebugGate = "inactive"
            return true
        end

        local state = LOD.RunManager and LOD.RunManager.State
        local graph = state and state.Graph
        if not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            self.LODBioDebugGate = "run-state"
            return true
        end

        if self.LODBioBlast then
            self.LODBioDebugGate = "charging"
            processBlast(self)
            return true
        end

        self:_RefreshTarget(graph)
        self:_RefreshRoute(graph)
        local target = self.LODTarget
        local targetLiving = livingPlayer(target)
        local hasLOS = targetLiving and bioHasLineOfSight(self, target) or false
        local distanceSq = targetLiving and self:GetPos():DistToSqr(target:GetPos()) or math.huge
        self.LODBioDebugTarget = target
        self.LODBioDebugLiving = targetLiving
        self.LODBioDebugLOS = hasLOS
        self.LODBioDebugDistanceSq = distanceSq

        if targetLiving and hasLOS then
            if distanceSq <= self.LODConfig.fireRange * self.LODConfig.fireRange
                and CurTime() >= (self.LODNextBioCharge or 0)
            then
                if beginBlast(self, target) then
                    self.LODBioDebugGate = "charge-started"
                    return true
                end
                self.LODBioDebugGate = "begin-rejected"
            end

            local preferred = self.LODConfig.preferredRange or 560
            if distanceSq <= preferred * preferred then
                self.LODBioDebugGate = "preferred-hold"
                holdAndFace(self, target)
                bioIdle(self)
                return true
            end
        end

        if not targetLiving then
            self.LODBioDebugGate = "no-live-target"
        elseif not hasLOS then
            self.LODBioDebugGate = "no-los"
        elseif distanceSq > self.LODConfig.fireRange * self.LODConfig.fireRange then
            self.LODBioDebugGate = "out-of-range"
        elseif CurTime() < (self.LODNextBioCharge or 0) then
            self.LODBioDebugGate = "cooldown-pursuit"
        else
            self.LODBioDebugGate = "generic-pursuit"
        end
        return false
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "bioblaster" and self:_RunBioBlasterTick() then return end
        return baseBehaviourTick(self)
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_BioBlasterInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

-- Add Bio Pressure as a discretionary mid/late-sector template. Avoid ambush
-- cells because the large projectile is meant to be read and dodged in space.
if EncounterDirector and not EncounterDirector.LODBioBlasterPlannerWrapped then
    EncounterDirector.LODBioBlasterPlannerWrapped = true

    local baseEligible = EncounterDirector._EligibleTemplates
    function EncounterDirector:_EligibleTemplates(sector, role)
        local base = baseEligible(self, sector, role)
        local out = {}
        for _, id in ipairs(base or {}) do out[#out + 1] = id end
        if sector >= 2 and role ~= "ambush" then out[#out + 1] = "bio_pressure" end
        return out
    end

    local baseSpawn = EncounterDirector._SpawnEncounter
    function EncounterDirector:_SpawnEncounter(encounter)
        if not encounter or not encounter.composition or not encounter.composition.bioblaster then
            return baseSpawn(self, encounter)
        end
        if encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition) do total = total + count end
        if self:GetActiveCount() + total > EC.ActiveHostileCeiling then return false end

        local center = LOD.MazeNavigator:CellCenter(encounter.cell) + Vector(0, 0, 10)
        local offsets = self:_SpawnOffsets(total)
        local ordinal = 1
        for _, archetypeId in ipairs({"shambler", "runner", "deadcrab", "bioblaster", "soldier"}) do
            local count = encounter.composition[archetypeId] or 0
            for _ = 1, count do
                local ent = ents.Create("lod_hostile")
                if IsValid(ent) then
                    ent.LODArchetypeId = archetypeId
                    ent.LODHomeCellKey = encounter.cellKey
                    ent.LODEncounterId = encounter.id
                    ent.LODEncounterOrdinal = ordinal
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

-- Extend the existing centralized audio API after Deadcrab has had a chance to
-- wrap it. Each wrapper delegates every non-Bio-Blaster case unchanged.
if CombatAudio and not CombatAudio.LODBioBlasterAudioWrapped then
    CombatAudio.LODBioBlasterAudioWrapped = true

    local basePain = CombatAudio.PlayHostilePain
    function CombatAudio:PlayHostilePain(hostile)
        if IsValid(hostile) and hostile.LODArchetypeId == "bioblaster" then
            local now = CurTime()
            if now < (hostile.LODNextPainAudio or 0) then return end
            hostile.LODNextPainAudio = now + 0.48
            playRotating(hostile, "LODBioPainOrdinal", BIO_PAIN, 76, 78, 0.90, CHAN_VOICE)
            return
        end
        return basePain(self, hostile)
    end

    local baseDeath = CombatAudio.PlayHostileDeath
    function CombatAudio:PlayHostileDeath(hostile)
        if IsValid(hostile) and hostile.LODArchetypeId == "bioblaster" then
            playRotating(hostile, "LODBioDeathOrdinal", BIO_DEATH, 82, 72, 1.0, CHAN_VOICE)
            return
        end
        return baseDeath(self, hostile)
    end

    local baseActivation = CombatAudio.PlayEncounterActivation
    function CombatAudio:PlayEncounterActivation(encounter, anchor)
        if IsValid(anchor) and anchor.LODArchetypeId == "bioblaster" then
            playRotating(anchor, "LODBioAlertOrdinal", BIO_ALERT, 80, 82, 0.90, CHAN_VOICE)
            return
        end
        return baseActivation(self, encounter, anchor)
    end
end

hook.Add("Think", "LOD_BioBlasterFootsteps", function()
    local now = CurTime()
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "bioblaster"
            and not hostile.LODDead and hostile.LODActivated ~= false
            and not hostile.LODBioBlast
            and hostile:GetVelocity():Length2D() > 18
            and now >= (hostile.LODBioNextFootstep or 0)
        then
            hostile.LODBioNextFootstep = now + 0.34
            playRotating(hostile, "LODBioFootOrdinal", BIO_FEET, 72, 76, 0.82, CHAN_BODY)
        end
    end
end)

concommand.Add("lod_m3_bioblaster_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local nearest, nearestDistanceSq
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODArchetypeId == "bioblaster" and not hostile.LODDead then
            local distanceSq = IsValid(ply) and hostile:GetPos():DistToSqr(ply:GetPos()) or 0
            if not nearest or distanceSq < nearestDistanceSq then
                nearest = hostile
                nearestDistanceSq = distanceSq
            end
        end
    end

    if not IsValid(nearest) then
        print("[LOD:BIO-STATUS] no live Bio Blaster")
        return
    end

    local target = nearest.LODBioDebugTarget
    local cfg = nearest.LODConfig or {}
    local sharedLOS = IsValid(target) and nearest._HasLineOfSight
        and nearest:_HasLineOfSight(target) or false
    local line = string.format(
        "#%d ticks=%d gate=%s target=%s living=%s distance=%.1f fireRange=%.1f bioLOS=%s sharedLOS=%s cooldown=%.2f charging=%s motion=%s",
        nearest:EntIndex(), nearest.LODBioDebugTicks or 0,
        tostring(nearest.LODBioDebugGate or "never-entered"),
        IsValid(target) and ("#" .. target:EntIndex()) or "none",
        tostring(nearest.LODBioDebugLiving == true),
        nearest.LODBioDebugDistanceSq and math.sqrt(nearest.LODBioDebugDistanceSq) or -1,
        cfg.fireRange or -1, tostring(nearest.LODBioDebugLOS == true), tostring(sharedLOS == true),
        math.max(0, (nearest.LODNextBioCharge or 0) - CurTime()),
        tostring(nearest.LODBioBlast ~= nil), tostring(nearest.LODMotionMode or "none")
    )
    print("[LOD:BIO-STATUS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_m3_bioblaster_audio_audit", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local function count(paths) return #usable(paths) end
    local lines = {
        "bioblaster model=" .. (util.IsValidModel(EC.Archetypes.bioblaster.model) and "OK" or "MISSING"),
        "feet=" .. count(BIO_FEET),
        "pain=" .. count(BIO_PAIN),
        "death=" .. count(BIO_DEATH),
        "alert=" .. count(BIO_ALERT),
        "charge=" .. count(BIO_CHARGE),
        "fire=Weapon_AR2.Single (shared with Soldier)",
        "impact=" .. (file.Exists("sound/physics/flesh/flesh_impact_bullet5.wav", "GAME") and "OK" or "MISSING")
    }
    for _, line in ipairs(lines) do
        print("[LOD:BIO] " .. line)
        if IsValid(ply) then ply:ChatPrint(line) end
    end
end)
