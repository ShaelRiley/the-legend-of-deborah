LOD = LOD or {}
LOD.SoldierShotContract = LOD.SoldierShotContract or {}

local Contract = LOD.SoldierShotContract

-- The Soldier warning is gameplay information, not a decorative approximation.
-- One immutable world-space line therefore owns the complete warning/burst:
--   origin + direction * t
-- Client rendering and physical bolts consume that exact line. Neither realm is
-- allowed to reconstruct it from live bones after beam-on.
--
-- This hardpoint is expressed in the Combine Soldier's native entity-local space
-- and transformed once at commitment. Unlike hand/weapon bones, it is invariant
-- across animation phase and across the client/server animation clocks. The size
-- transform mirrors the existing client-only hostile RenderMultiply convention.
local SHOT_SITE_LOCAL = Vector(30, -4, 48)

local function soldierFamily(hostile)
    if not IsValid(hostile) then return false end
    local archetype = hostile.LODArchetypeId or hostile:GetNW2String("LOD_Archetype", "")
    return archetype == "soldier" or archetype == "blitzer"
end

local function clearNetworkContract(hostile)
    if not IsValid(hostile) then return end

    hostile:SetNW2Bool("LOD_SoldierShotTelegraph", false)
    hostile:SetNW2Vector("LOD_SoldierShotOrigin", vector_origin)
    hostile:SetNW2Vector("LOD_SoldierShotDirection", vector_origin)
    hostile:SetNW2Vector("LOD_SoldierShotAimPoint", vector_origin)

    -- Keep the retired presentation path inert. In particular, the legacy bolt
    -- Initialize() rebase checks LOD_SoldierAim; leaving it at vector_origin makes
    -- the immutable LODDirection supplied below remain the sole flight authority.
    hostile:SetNW2Bool("LOD_SoldierTelegraph", false)
    hostile:SetNW2Entity("LOD_SoldierTelegraphTarget", NULL)
    hostile:SetNW2Vector("LOD_SoldierAim", vector_origin)
    hostile:SetNW2Vector("LOD_SoldierAimDirection", vector_origin)
end

function Contract:ShotOrigin(hostile)
    if not IsValid(hostile) then return vector_origin end

    local size = math.Clamp(hostile:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local mins = util.GetModelBounds and select(1, util.GetModelBounds(hostile:GetModel()))
        or Vector(-16, -16, 0)
    local motionV2 = hostile:GetNW2Bool("LOD_MotionV2", false)
    local verticalCompensation = motionV2 and -(mins.z * size) or mins.z * (1 - size)

    local localPos = Vector(
        SHOT_SITE_LOCAL.x * size,
        SHOT_SITE_LOCAL.y * size,
        SHOT_SITE_LOCAL.z * size + verticalCompensation
    )
    return hostile:LocalToWorld(localPos)
end

function Contract:HoldFacing(hostile, facingPos)
    if not IsValid(hostile) or not facingPos then return end

    local motion = LOD.HostileMotionV2
    if motion and motion.Stop and motion.FaceToward then
        motion:Stop(hostile)
        motion:FaceToward(hostile, facingPos)
        return
    end

    if hostile.loco then hostile.loco:SetDesiredSpeed(0) end
    local delta = Vector(
        facingPos.x - hostile:GetPos().x,
        facingPos.y - hostile:GetPos().y,
        0
    )
    if delta:LengthSqr() > 0.001 then
        hostile:SetAngles(Angle(0, delta:Angle().y, 0))
    end
end

local function installContract()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end
    if class.LODSoldierShotContractInstalled then return true end
    class.LODSoldierShotContractInstalled = true

    -- Save the final post-wrapper behavior authority. This module is intentionally
    -- loaded after Motion V2, variance, hit feedback, and pose systems so the
    -- active-burst branch below can bypass Motion V2's obsolete live-target facing
    -- without disturbing any non-burst behavior or hit-stun dispatch.
    local baseBehaviourTick = class._BehaviourTick
    local baseBeginDeath = class._BeginDeathPresentation
    local baseOnRemove = class.OnRemove

    function class:_SpawnSoldierBolt(committedDirection, shotIndex)
        local cfg = self.LODConfig
        local burst = self.LODSoldierBurst
        local startPos = burst and burst.shotOrigin or Contract:ShotOrigin(self)
        local direction = burst and burst.shotDirection or committedDirection or vector_origin
        direction = direction:GetNormalized()
        if direction == vector_origin then return false end

        local ang = direction:Angle()
        if self.LODArchetypeId == "blitzer" then
            local shot = burst and burst.pattern and burst.pattern[shotIndex]
            if shot and shot.veer then
                ang.y = ang.y + shot.yaw
                ang.p = ang.p + shot.pitch
            end
        end
        direction = ang:Forward()

        local bolt = ents.Create("lod_soldier_bolt")
        if not IsValid(bolt) then return false end
        bolt.LODOwner = self
        bolt.LODDirection = direction
        bolt.LODSpeed = cfg.projectileSpeed
        bolt.LODDamage = cfg.burstDamage
        bolt.LODLifetime = cfg.projectileLifetime
        bolt.LODContractOrigin = startPos
        bolt.LODContractDirection = direction
        bolt:SetPos(startPos)
        bolt:SetAngles(direction:Angle())
        bolt:Spawn()
        bolt:Activate()

        self.LODLastSoldierShotOrigin = startPos
        self.LODLastSoldierShotDirection = direction

        if self.LODArchetypeId == "blitzer" then
            self.LODBlitzerShotsFired = (self.LODBlitzerShotsFired or 0) + 1
            local shot = burst and burst.pattern and burst.pattern[shotIndex]
            if shot and shot.veer then
                self.LODBlitzerVeeringShots = (self.LODBlitzerVeeringShots or 0) + 1
            end
            self:EmitSound("Weapon_AR2.Single", 73, 116, 0.88)
        else
            self:EmitSound("Weapon_AR2.Single", 72, 100, 0.85)
        end
        return true
    end

    function class:_BeginSoldierBurst(target)
        local cfg = self.LODConfig
        if self.LODSoldierBurst or not IsValid(target) then return false end
        if CurTime() < (self.LODNextAttack or 0) then return false end
        if self:GetPos():DistToSqr(target:GetPos()) > cfg.fireRange * cfg.fireRange then return false end
        if not self:_HasLineOfSight(target) then return false end

        local shots = cfg.burstShots or 3
        local pattern
        local patternSeed
        if self.LODArchetypeId == "blitzer" then
            self.LODBlitzerAttackOrdinal = (self.LODBlitzerAttackOrdinal or 0) + 1
            local instanceSeed = self.LODInstanceSeed or self:GetNW2Int("LOD_InstanceSeed", 1)
            patternSeed = LOD.Seeds.Derive(instanceSeed, "blitzer-burst:" .. self.LODBlitzerAttackOrdinal)
            local rng = LOD.RNG.New(patternSeed)
            shots = rng:Int(cfg.burstShotsMin or 1, cfg.burstShotsMax or 6)
            pattern = {}
            for i = 1, shots do
                local veer = rng:Chance(cfg.veerChance or 0.50)
                local sign = rng:Chance(0.5) and -1 or 1
                pattern[i] = {
                    veer = veer,
                    yaw = sign * (cfg.veerDegrees or 2.4),
                    pitch = veer and rng:Float(-0.35, 0.35) or 0
                }
            end
            self.LODBlitzerBurstsStarted = (self.LODBlitzerBurstsStarted or 0) + 1
            self.LODBlitzerLastPatternSeed = patternSeed
            self.LODBlitzerLastPatternShots = shots
            self.LODBlitzerLastVeerRolls = #pattern
        end

        local targetAimPos = self:_SoldierTargetAimPos(target)
        local facingPos = Vector(targetAimPos.x, targetAimPos.y, self:GetPos().z)

        -- Facing is part of the commitment. Establish it before transforming the
        -- local weapon hardpoint, then never point the actor at the moving player
        -- again until this burst has completed or been cancelled.
        Contract:HoldFacing(self, facingPos)

        local shotOrigin = Contract:ShotOrigin(self)
        local shotDelta = targetAimPos - shotOrigin
        if shotDelta:LengthSqr() <= 0.001 then return false end
        local shotDirection = shotDelta:GetNormalized()

        self.LODSoldierTelegraphSerial = (self.LODSoldierTelegraphSerial or 0) + 1
        self.LODSoldierBurst = {
            target = target,
            facingPos = facingPos,
            windupEnd = CurTime() + cfg.burstTelegraph,
            nextShot = nil,
            shotsRemaining = shots,
            originalShots = shots,
            shotIndex = 0,
            shotOrigin = shotOrigin,
            shotDirection = shotDirection,
            aimPos = targetAimPos,
            pattern = pattern,
            patternSeed = patternSeed,
            firingActivityStarted = false
        }

        -- Disable every legacy trajectory input before publishing the new one.
        clearNetworkContract(self)
        self:SetNW2Int("LOD_SoldierShotSerial", self.LODSoldierTelegraphSerial)
        self:SetNW2Vector("LOD_SoldierShotOrigin", shotOrigin)
        self:SetNW2Vector("LOD_SoldierShotDirection", shotDirection)
        self:SetNW2Vector("LOD_SoldierShotAimPoint", targetAimPos)
        self:SetNW2Bool("LOD_SoldierShotTelegraph", true)

        -- The old implementation played the firing animation throughout the full
        -- one-second warning, moving its weapon bones while the warning was meant
        -- to be stable. Hold the aimed idle presentation during the tell; switch
        -- to the firing activity only when the actual burst begins.
        self:_SetActivity(self:_SoldierIdleActivity(), true)
        self:EmitSound("buttons/button17.wav", 64, self.LODArchetypeId == "blitzer" and 136 or 115, 0.72)
        return true
    end

    function class:_CancelSoldierBurst(shortCooldown)
        self.LODSoldierBurst = nil
        clearNetworkContract(self)
        self.LODNextAttack = CurTime() + (shortCooldown or 0.35)
        self:_SetActivity(self:_SoldierIdleActivity(), true)
    end

    function class:_ProcessSoldierBurst()
        local burst = self.LODSoldierBurst
        if not burst then return false end
        local cfg = self.LODConfig
        local target = burst.target

        if not IsValid(target) or not target:Alive() then
            self:_CancelSoldierBurst(0.2)
            return false
        end

        Contract:HoldFacing(self, burst.facingPos)

        if CurTime() < burst.windupEnd then
            -- Breaking line of sight during the tell still cancels the attack.
            -- Player motion never alters origin, direction, endpoint, or facing.
            if not self:_HasLineOfSight(target) then
                self:_CancelSoldierBurst(0.25)
                return false
            end
            return true
        end

        self:SetNW2Bool("LOD_SoldierShotTelegraph", false)
        if not burst.firingActivityStarted then
            burst.firingActivityStarted = true
            self:_SetActivity(self:_SoldierAttackActivity(), true)
        end
        if not burst.nextShot then burst.nextShot = CurTime() end

        if burst.shotsRemaining > 0 and CurTime() >= burst.nextShot then
            burst.shotIndex = burst.shotIndex + 1
            self:_SpawnSoldierBolt(burst.shotDirection, burst.shotIndex)
            burst.shotsRemaining = burst.shotsRemaining - 1
            burst.nextShot = CurTime() + cfg.burstShotInterval
        end

        if burst.shotsRemaining <= 0 then
            if self.LODArchetypeId == "blitzer" then
                self.LODBlitzerCompletedBursts = (self.LODBlitzerCompletedBursts or 0) + 1
                self.LODBlitzerLastCompletedShots = burst.originalShots or burst.shotIndex
                self.LODBlitzerLastCompletedVeerRolls = #(burst.pattern or {})
                self.LODBlitzerLastCompletedSeed = burst.patternSeed
            end
            self.LODSoldierBurst = nil
            clearNetworkContract(self)
            self.LODNextAttack = CurTime() + cfg.burstCooldown
            self:_SetActivity(self:_SoldierIdleActivity(), true)
            return false
        end

        return true
    end

    function class:_BehaviourTick()
        if soldierFamily(self) and self.LODSoldierBurst then
            -- Hit feedback normally cancels the burst synchronously. This guard
            -- makes the final authority robust to any same-frame wrapper ordering.
            if CurTime() < (self.LODHitStunUntil or 0) then
                self:_CancelSoldierBurst(0.4)
                return baseBehaviourTick(self)
            end

            local state = LOD.RunManager and LOD.RunManager.State
            if state and (state.Failed or state.LevelCleared) then
                self:_CancelSoldierBurst(0.2)
                return
            end

            Contract:HoldFacing(self, self.LODSoldierBurst.facingPos)
            self:_ProcessSoldierBurst()
            return
        end
        return baseBehaviourTick(self)
    end

    function class:_BeginDeathPresentation()
        clearNetworkContract(self)
        self.LODSoldierBurst = nil
        return baseBeginDeath(self)
    end

    function class:OnRemove()
        clearNetworkContract(self)
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

if not installContract() then
    hook.Add("OnEntityCreated", "LOD_InstallSoldierShotContract", function(ent)
        if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
        if installContract() then
            hook.Remove("OnEntityCreated", "LOD_InstallSoldierShotContract")
        end
    end)
end

-- Hit stun is an external cancellation path. It predates the shot contract and
-- only knows how to clear the legacy telegraph, so extend that one authority here.
if LOD.M3HitFeedback and not LOD.M3HitFeedback.LODSoldierShotContractWrapped then
    LOD.M3HitFeedback.LODSoldierShotContractWrapped = true
    local baseApplyHitStun = LOD.M3HitFeedback.ApplyHitStun
    function LOD.M3HitFeedback:ApplyHitStun(hostile)
        local applied = baseApplyHitStun(self, hostile)
        if applied and IsValid(hostile) and soldierFamily(hostile) then
            hostile.LODSoldierBurst = nil
            clearNetworkContract(hostile)
        end
        return applied
    end
end

-- Diagnostic: physical Soldier bolts should remain exactly on the immutable line.
-- Blitzer veer is deliberately excluded because its per-shot angular deviation is
-- an authored archetype mechanic rather than a trajectory-integrity failure.
concommand.Add("lod_soldier_contract_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active = 0
    local legacyActive = 0
    local bolts = 0
    local maxDeviation = 0

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODArchetypeId == "soldier" then
            if hostile.LODSoldierBurst then active = active + 1 end
            if hostile:GetNW2Bool("LOD_SoldierTelegraph", false) then legacyActive = legacyActive + 1 end
        end
    end

    for _, bolt in ipairs(ents.FindByClass("lod_soldier_bolt")) do
        local owner = bolt.LODOwner
        if IsValid(bolt) and IsValid(owner) and owner.LODArchetypeId == "soldier"
            and bolt.LODContractOrigin and bolt.LODContractDirection
        then
            bolts = bolts + 1
            local delta = bolt:GetPos() - bolt.LODContractOrigin
            local dir = bolt.LODContractDirection:GetNormalized()
            local deviation = delta:Cross(dir):Length()
            maxDeviation = math.max(maxDeviation, deviation)
        end
    end

    local passed = legacyActive == 0 and maxDeviation <= 0.05
    local line = string.format(
        "activeBursts=%d physicalBolts=%d legacyTelegraphs=%d maxLineDeviation=%.4f result=%s",
        active, bolts, legacyActive, maxDeviation, passed and "PASS" or "FAIL"
    )
    print("[LOD:SOLDIER-CONTRACT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
