LOD = LOD or {}
LOD.StagingDeployment = LOD.StagingDeployment or {}

local Staging = LOD.StagingDeployment
local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local MC = LOD.Config and LOD.Config.Maze
local CC = LOD.Config

if not RunManager or not MC or not CC then return end

local STARTER_SPECS = {
    weapon_shotgun = {label = "Shotgun", clip = 7, ammo = "Buckshot", model = "models/weapons/w_shotgun.mdl"},
    weapon_smg1 = {label = "SMG", clip = 25, ammo = "SMG1", model = "models/weapons/w_smg1.mdl"},
    weapon_357 = {label = ".357 Magnum", clip = 6, ammo = "357", model = "models/weapons/w_357.mdl"},
    weapon_ar2 = {label = "AR2", clip = 20, ammo = "AR2", model = "models/weapons/w_irifle.mdl"}
}
local STARTER_CLASSES = {"weapon_shotgun", "weapon_smg1", "weapon_357", "weapon_ar2"}
local HUT_KIND = 6
local HUT_HALF_X = 320
local HUT_HALF_Y = 240
local HUT_HEIGHT = 224
local WALL = 24
local FLOOR_THICKNESS = 32
local HUT_OFFSET = Vector(-5400, -5400, 0)

Staging.HutEntities = Staging.HutEntities or {}
Staging.StarterEntities = Staging.StarterEntities or {}
Staging.HutCenter = Staging.HutCenter or nil
Staging.Stats = Staging.Stats or {
    staged = 0,
    starterClaims = 0,
    deployments = 0,
    portalDenied = 0,
    duplicateStarterPrevented = 0
}

local function identityOf(ply)
    return IsValid(ply) and RunManager:IdentityOf(ply) or nil
end

local function slotActive(ply)
    local id = identityOf(ply)
    return id and RunManager.State and RunManager.State.ActiveIdentity
        and RunManager.State.ActiveIdentity[id] == true or false
end

local function starterSpec(weaponClass)
    return weaponClass and STARTER_SPECS[weaponClass] or nil
end

local function removeEntity(ent)
    if IsValid(ent) then ent:Remove() end
end

local function spawnStaticBox(pos, mins, maxs)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end
    ent:SetPos(pos)
    ent:SetAngles(angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(HUT_KIND)
    ent:Spawn()
    ent:Activate()
    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

function Staging:IsDeployed(ply)
    if not IsValid(ply) or not slotActive(ply) then return false end
    local ps = RunManager:GetPlayerState(ply)
    return ps and ps.deploymentComplete == true or false
end

function RunManager:IsDungeonPlayer(ply)
    return Staging:IsDeployed(ply)
end

-- From this point forward IsActivePlayer means an identity that both owns one of
-- the four campaign slots and has actually crossed the staging portal. Keep the
-- raw slot predicate separately for admission/reconnect internals.
if not RunManager.LODStagingActiveSemanticsInstalled then
    RunManager.LODStagingActiveSemanticsInstalled = true
    local baseIsActivePlayer = RunManager.IsActivePlayer
    RunManager.IsSlotActivePlayer = RunManager.IsSlotActivePlayer or baseIsActivePlayer
    function RunManager:IsActivePlayer(ply)
        if self.LODStagingBypassActive and self.LODStagingBypassActive[ply] then
            return self:IsSlotActivePlayer(ply)
        end
        return self:IsSlotActivePlayer(ply) and Staging:IsDeployed(ply)
    end
end

local function buildStarterOrder(seed, identity, ordinal)
    local pool = table.Copy(STARTER_CLASSES)
    local salt = string.format("staging-starter:%s:%d", tostring(identity), tonumber(ordinal) or 0)
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed or 1, salt))
    rng:Shuffle(pool)
    return pool
end

function Staging:_AssignStarter(ps)
    if not ps then return nil end
    if starterSpec(ps.starterWeaponClass) then return ps.starterWeaponClass end

    local state = RunManager.State or {}
    local reserved = {}
    for identity, enabled in pairs(state.ActiveIdentity or {}) do
        if enabled and identity ~= ps.identity then
            local other = state.PlayerState and state.PlayerState[identity]
            if other and starterSpec(other.starterWeaponClass) then reserved[other.starterWeaponClass] = true end
        end
    end

    local order = buildStarterOrder(state.CampaignSeed or 1, ps.identity, ps.ordinal)
    local chosen
    for _, weaponClass in ipairs(order) do
        if not reserved[weaponClass] then chosen = weaponClass break end
    end
    chosen = chosen or order[((math.max(1, tonumber(ps.ordinal) or 1) - 1) % #order) + 1]
    ps.starterWeaponClass = chosen
    ps.starterEntryLevel = math.max(1, tonumber(state.Level) or 1)
    return chosen
end

function Staging:_ClearLegacyCatchup(ps)
    if not ps then return end
    ps.catchupLevel = nil
    ps.catchupGrantedLevel = nil
end

if not RunManager.LODStagingAdmissionWrapped then
    RunManager.LODStagingAdmissionWrapped = true
    local baseAdmitIdentity = RunManager._AdmitIdentity
    function RunManager:_AdmitIdentity(ply)
        local ps = baseAdmitIdentity(self, ply)
        if ps then
            Staging:_AssignStarter(ps)
            Staging:_ClearLegacyCatchup(ps)
            if ps.deploymentComplete == nil then ps.deploymentComplete = false end
        end
        return ps
    end

    local baseTryActivatePlayer = RunManager.TryActivatePlayer
    function RunManager:TryActivatePlayer(ply)
        local active = baseTryActivatePlayer(self, ply)
        local ps = self:GetPlayerState(ply)
        if active and ps then
            Staging:_AssignStarter(ps)
            Staging:_ClearLegacyCatchup(ps)
            if ps.deploymentComplete == nil then ps.deploymentComplete = false end
        end
        return active
    end
end

-- Supersede the old Level-1/2/3 catch-up loadout. Every newly admitted identity
-- starts with only the universal Pistol + Crowbar baseline; the individualized
-- advanced firearm is a physical staging-room pickup. Later-campaign catch-up can
-- be tuned independently after multiplayer lifecycle validation.
local function giveLoaded(ply, className, clip)
    local weapon = ply:Give(className, true)
    if IsValid(weapon) and clip and clip >= 0 then weapon:SetClip1(clip) end
    return weapon
end

function GM:PlayerLoadout(ply)
    local ps = RunManager:GetPlayerState(ply)
    if not ps or ps.inventory or ps.initialLoadoutGranted then return end

    ply:StripWeapons()
    ply:RemoveAllAmmo()
    local pistol = giveLoaded(ply, "weapon_pistol", 18)
    ply:Give("weapon_lod_crowbar", true)
    ply:SetAmmo(0, "Pistol")
    ply:SetAmmo(0, "Grenade")
    ply:SetAmmo(0, "AR2AltFire")
    ps.initialLoadoutGranted = true
    if IsValid(pistol) then ply:SelectWeapon("weapon_pistol") end
end

function Staging:_BaseZ()
    local report = RunManager.State and RunManager.State.BuildReport
    if report and report.startPos then return report.startPos.z - 12 end
    return MC.Origin.z
end

function Staging:_DesiredHutCenter()
    local base = MC.Origin + HUT_OFFSET
    base.z = self:_BaseZ()
    return base
end

function Staging:_HutValid()
    if not self.HutCenter then return false end
    local valid = 0
    for _, ent in ipairs(self.HutEntities or {}) do if IsValid(ent) then valid = valid + 1 end end
    return valid >= 7 and IsValid(self.GuideEntity) and IsValid(self.PortalEntity)
end

function Staging:_RegisterHut(ent)
    if IsValid(ent) then self.HutEntities[#self.HutEntities + 1] = ent end
    return ent
end

function Staging:EnsureHut()
    local desired = self:_DesiredHutCenter()
    if self:_HutValid() and self.HutCenter:DistToSqr(desired) < 4 then return true end

    for _, ent in ipairs(self.HutEntities or {}) do removeEntity(ent) end
    self.HutEntities = {}
    self.GuideEntity = nil
    self.PortalEntity = nil
    self.HutCenter = desired

    local c = desired
    local floorCenter = c + Vector(0, 0, -FLOOR_THICKNESS * 0.5)
    local ceilingCenter = c + Vector(0, 0, HUT_HEIGHT + FLOOR_THICKNESS * 0.5)
    self:_RegisterHut(spawnStaticBox(floorCenter,
        Vector(-HUT_HALF_X, -HUT_HALF_Y, -FLOOR_THICKNESS * 0.5),
        Vector(HUT_HALF_X, HUT_HALF_Y, FLOOR_THICKNESS * 0.5)))
    self:_RegisterHut(spawnStaticBox(ceilingCenter,
        Vector(-HUT_HALF_X, -HUT_HALF_Y, -FLOOR_THICKNESS * 0.5),
        Vector(HUT_HALF_X, HUT_HALF_Y, FLOOR_THICKNESS * 0.5)))

    self:_RegisterHut(spawnStaticBox(c + Vector(HUT_HALF_X + WALL * 0.5, 0, HUT_HEIGHT * 0.5),
        Vector(-WALL * 0.5, -HUT_HALF_Y, -HUT_HEIGHT * 0.5),
        Vector(WALL * 0.5, HUT_HALF_Y, HUT_HEIGHT * 0.5)))
    self:_RegisterHut(spawnStaticBox(c + Vector(0, HUT_HALF_Y + WALL * 0.5, HUT_HEIGHT * 0.5),
        Vector(-HUT_HALF_X, -WALL * 0.5, -HUT_HEIGHT * 0.5),
        Vector(HUT_HALF_X, WALL * 0.5, HUT_HEIGHT * 0.5)))
    self:_RegisterHut(spawnStaticBox(c + Vector(0, -HUT_HALF_Y - WALL * 0.5, HUT_HEIGHT * 0.5),
        Vector(-HUT_HALF_X, -WALL * 0.5, -HUT_HEIGHT * 0.5),
        Vector(HUT_HALF_X, WALL * 0.5, HUT_HEIGHT * 0.5)))

    -- The portal is the only exit. The front wall is physically continuous, so
    -- walking past the portal cannot leak a staged player into Flatgrass.
    self:_RegisterHut(spawnStaticBox(c + Vector(-HUT_HALF_X - WALL * 0.5, 0, HUT_HEIGHT * 0.5),
        Vector(-WALL * 0.5, -HUT_HALF_Y, -HUT_HEIGHT * 0.5),
        Vector(WALL * 0.5, HUT_HALF_Y, HUT_HEIGHT * 0.5)))

    local guide = ents.Create("lod_staging_prop")
    if IsValid(guide) then
        guide:SetStageKind(guide.KIND_GUIDE or 1)
        guide:SetStageLabel("DUNGEON HERMIT")
        guide:SetPos(c + Vector(190, 0, 0))
        guide:SetAngles(Angle(0, 180, 0))
        guide:Spawn()
        guide:Activate()
        self.GuideEntity = self:_RegisterHut(guide)
    end

    local portal = ents.Create("lod_staging_prop")
    if IsValid(portal) then
        portal:SetStageKind(portal.KIND_PORTAL or 2)
        portal:SetStageLabel("ENTER THE DUNGEON")
        portal:SetPos(c + Vector(-250, 0, 0))
        portal:SetAngles(angle_zero)
        portal:Spawn()
        portal:Activate()
        self.PortalEntity = self:_RegisterHut(portal)
    end

    return self:_HutValid()
end

function Staging:_StarterPosition()
    local c = self.HutCenter or self:_DesiredHutCenter()
    return c + Vector(40, 0, 20)
end

function Staging:_SpawnPosition()
    local c = self.HutCenter or self:_DesiredHutCenter()
    return c + Vector(-120, 0, 12)
end

function Staging:_ApplyStarterTransmission(ent, ownerIdentity)
    if not IsValid(ent) then return end
    for _, ply in ipairs(player.GetAll()) do
        ent:SetPreventTransmit(ply, identityOf(ply) ~= ownerIdentity)
    end
end

function Staging:EnsureStarterPickup(ply)
    if not IsValid(ply) then return false end
    local identity = identityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    if not identity or not ps or ps.deploymentComplete or ps.starterClaimed then return false end

    local weaponClass = self:_AssignStarter(ps)
    local spec = starterSpec(weaponClass)
    if not spec then return false end

    local existing = self.StarterEntities[identity]
    if IsValid(existing) then
        self:_ApplyStarterTransmission(existing, identity)
        return true
    end

    local ent = ents.Create("lod_staging_prop")
    if not IsValid(ent) then return false end
    ent:SetStageKind(ent.KIND_WEAPON or 3)
    ent:SetStageLabel(spec.label)
    ent.LODStageModel = spec.model
    ent.LODStagingOwnerIdentity = identity
    ent.LODStagingWeaponClass = weaponClass
    ent:SetPos(self:_StarterPosition())
    ent:SetAngles(Angle(0, 90, 0))
    ent:Spawn()
    ent:Activate()
    self.StarterEntities[identity] = ent
    self:_ApplyStarterTransmission(ent, identity)
    return true
end

function Staging:PlacePlayerInHut(ply, announce)
    if not IsValid(ply) or not ply:Alive() or not slotActive(ply) then return false end
    local ps = RunManager:GetPlayerState(ply)
    if not ps or ps.deploymentComplete then return false end
    if not self:EnsureHut() then return false end

    self:_AssignStarter(ps)
    self:_ClearLegacyCatchup(ps)
    ply:SetPos(self:_SpawnPosition())
    ply:SetEyeAngles(Angle(0, 0, 0))
    ply:SetLocalVelocity(vector_origin)
    ply:SetNW2Bool("LOD_Staged", true)
    ply:SetNW2Bool("LOD_Deployed", false)
    self:EnsureStarterPickup(ply)

    if announce ~= false and not ps.stagingIntroShown then
        ps.stagingIntroShown = true
        ply:ChatPrint("DUNGEON HERMIT: It's dangerous to go alone. Take this.")
        ply:ChatPrint("Take your weapon, then turn around and press E on the blue portal when you're ready.")
    end

    self.Stats.staged = (self.Stats.staged or 0) + 1
    return true
end

function Staging:ClaimStarter(ply, ent)
    if not IsValid(ply) or not ply:Alive() or not slotActive(ply) then return false end
    local identity = identityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    if not identity or not ps or ps.deploymentComplete or ps.starterClaimed then return false end
    if IsValid(ent) and ent.LODStagingOwnerIdentity ~= identity then return false end

    local weaponClass = self:_AssignStarter(ps)
    local spec = starterSpec(weaponClass)
    if not spec then return false end

    if IsValid(ply:GetWeapon(weaponClass)) then
        self.Stats.duplicateStarterPrevented = (self.Stats.duplicateStarterPrevented or 0) + 1
    else
        local weapon = ply:Give(weaponClass, true)
        if not IsValid(weapon) then return false end
        weapon:SetClip1(spec.clip)
    end
    ply:SetAmmo(0, spec.ammo)
    if weaponClass == "weapon_ar2" then ply:SetAmmo(0, "AR2AltFire") end

    ps.starterClaimed = true
    ps.starterClaimedLevel = RunManager.State and RunManager.State.Level or 1
    self.StarterEntities[identity] = nil
    self.Stats.starterClaims = (self.Stats.starterClaims or 0) + 1
    ply:EmitSound("items/ammo_pickup.wav", 65, 104, 0.8, CHAN_ITEM)
    ply:ChatPrint("STARTER ACQUIRED — " .. string.upper(spec.label))
    return true
end

function Staging:DeployPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or not slotActive(ply) then return false end
    local identity = identityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    if not ps or ps.deploymentComplete then return false end

    if not ps.starterClaimed then
        self.Stats.portalDenied = (self.Stats.portalDenied or 0) + 1
        ply:EmitSound("buttons/button10.wav", 58, 92, 0.7, CHAN_ITEM)
        ply:ChatPrint("THE PORTAL REMAINS CLOSED — TAKE THE WEAPON FIRST")
        self:EnsureStarterPickup(ply)
        return false
    end

    local state = RunManager.State
    if not state or not state.BuildReady or state.Failed or state.LevelCleared then return false end
    local destination = state.CheckpointPos or (state.BuildReport and state.BuildReport.startPos)
    if not destination then return false end

    ps.deploymentComplete = true
    ps.deployedAtLevel = state.Level
    ps.deployedAtLevelSeed = state.LevelSeed
    ply:SetNW2Bool("LOD_Staged", false)
    ply:SetNW2Bool("LOD_Deployed", true)
    ply:SetPos(destination)
    ply:SetEyeAngles(Angle(0, 0, 0))
    ply:SetLocalVelocity(vector_origin)
    RunManager:_SyncPlayerVars(ply)
    if Loot and Loot.EnsureStaticForPlayer then Loot:EnsureStaticForPlayer(ply) end

    ply:EmitSound("ambient/machines/teleport3.wav", 72, 104, 0.75, CHAN_ITEM)
    ply:ChatPrint("DEPLOYED — ENTER THE DUNGEON")
    self.Stats.deployments = (self.Stats.deployments or 0) + 1
    return true
end

if not RunManager.LODStagingApplyWrapped then
    RunManager.LODStagingApplyWrapped = true
    local baseApplyPlayerState = RunManager.ApplyPlayerState
    function RunManager:ApplyPlayerState(ply)
        local ps = self:GetPlayerState(ply)
        if ps and self:IsSlotActivePlayer(ply) and ps.deploymentComplete ~= true then
            self.LODStagingBypassActive = self.LODStagingBypassActive or setmetatable({}, {__mode = "k"})
            self.LODStagingBypassActive[ply] = true
            baseApplyPlayerState(self, ply)
            self.LODStagingBypassActive[ply] = nil
            timer.Simple(0, function()
                if IsValid(ply) then Staging:PlacePlayerInHut(ply, true) end
            end)
            return
        end

        baseApplyPlayerState(self, ply)
        if IsValid(ply) and ps and ps.deploymentComplete then
            ply:SetNW2Bool("LOD_Staged", false)
            ply:SetNW2Bool("LOD_Deployed", true)
        end
    end
end

-- The starter room replaces the former two guaranteed Level-1 firearm nodes.
-- Weapon discoveries beyond the individualized starter return to the ordinary
-- per-player rare/reward economy.
if Loot and not Loot.LODStagingStarterPlanInstalled then
    Loot.LODStagingStarterPlanInstalled = true
    local baseBuildStaticPlan = Loot.BuildStaticPlan
    function Loot:BuildStaticPlan(graph)
        local ok, plan = baseBuildStaticPlan(self, graph)
        if not ok or not plan then return ok, plan end
        if math.max(1, tonumber(plan.level) or 1) == 1 then
            local kept = {}
            for _, node in ipairs(plan.nodes or {}) do
                if node.role ~= "weapon" then kept[#kept + 1] = node end
            end
            plan.nodes = kept
            graph.LootPlan = plan
            self.StaticPlan = plan
        end
        return true, plan
    end
end

local function clearStarterEntities()
    for identity, ent in pairs(Staging.StarterEntities or {}) do
        removeEntity(ent)
        Staging.StarterEntities[identity] = nil
    end
end

if not RunManager.LODStagingCampaignWrapped then
    RunManager.LODStagingCampaignWrapped = true
    local baseNewCampaign = RunManager.NewCampaign
    function RunManager:NewCampaign()
        clearStarterEntities()
        return baseNewCampaign(self)
    end

    local baseBuildCurrentLevel = RunManager.BuildCurrentLevel
    function RunManager:BuildCurrentLevel(levelSeedOverride)
        local ok, result = baseBuildCurrentLevel(self, levelSeedOverride)
        if ok then
            Staging:EnsureHut()
            timer.Simple(0, function()
                for _, ply in ipairs(player.GetAll()) do
                    local ps = RunManager:GetPlayerState(ply)
                    if IsValid(ply) and ply:Alive() and ps and RunManager:IsSlotActivePlayer(ply)
                        and ps.deploymentComplete ~= true
                    then
                        Staging:PlacePlayerInHut(ply, false)
                    end
                end
            end)
        end
        return ok, result
    end
end

hook.Add("PlayerInitialSpawn", "LOD_StagingStarterTransmissionMask", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        local identity = identityOf(ply)
        for ownerIdentity, ent in pairs(Staging.StarterEntities or {}) do
            if IsValid(ent) then ent:SetPreventTransmit(ply, ownerIdentity ~= identity) end
        end
    end)
end)

hook.Add("PlayerDisconnected", "LOD_StagingDisconnectedStarterCleanup", function(ply)
    local identity = identityOf(ply)
    local ent = identity and Staging.StarterEntities[identity]
    if IsValid(ent) then ent:Remove() end
    if identity then Staging.StarterEntities[identity] = nil end
end)

hook.Add("ShutDown", "LOD_StagingCleanup", function()
    clearStarterEntities()
    for _, ent in ipairs(Staging.HutEntities or {}) do removeEntity(ent) end
    Staging.HutEntities = {}
end)

concommand.Add("lod_staging_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = RunManager.State or {}
    local staged, deployed, claims, pickups = 0, 0, 0, 0
    local starterSeen = {}
    local duplicateActiveStarter = 0

    for identity, active in pairs(state.ActiveIdentity or {}) do
        if active then
            local ps = state.PlayerState and state.PlayerState[identity]
            if ps then
                if ps.deploymentComplete then deployed = deployed + 1 else staged = staged + 1 end
                if ps.starterClaimed then claims = claims + 1 end
                if ps.starterWeaponClass then
                    if starterSeen[ps.starterWeaponClass] then duplicateActiveStarter = duplicateActiveStarter + 1 end
                    starterSeen[ps.starterWeaponClass] = true
                end
            end
        end
    end
    for _, ent in pairs(Staging.StarterEntities or {}) do if IsValid(ent) then pickups = pickups + 1 end end

    local hutReady = Staging:_HutValid()
    local result = hutReady and duplicateActiveStarter == 0 and "PASS" or "FAIL"
    local line = string.format(
        "slotActive=%d staged=%d deployed=%d claimed=%d pickups=%d hut=%s uniqueStarterConflicts=%d deployments=%d denied=%d result=%s",
        RunManager._ActiveCount and RunManager:_ActiveCount() or 0, staged, deployed, claims, pickups,
        tostring(hutReady), duplicateActiveStarter, Staging.Stats.deployments or 0,
        Staging.Stats.portalDenied or 0, result)
    print("[LOD:STAGING] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end

    for _, candidate in ipairs(RunManager:_SortedConnectedPlayers()) do
        if IsValid(candidate) then
            local ps = RunManager:GetPlayerState(candidate)
            if ps then
                local spec = starterSpec(ps.starterWeaponClass)
                local detail = string.format(
                    "%s ord=%s starter=%s claimed=%s staged=%s deployed=%s entryLevel=%s",
                    candidate:Nick(), tostring(ps.ordinal or "-"), spec and spec.label or "none",
                    tostring(ps.starterClaimed == true), tostring(ps.deploymentComplete ~= true),
                    tostring(ps.deploymentComplete == true), tostring(ps.starterEntryLevel or "-"))
                print("[LOD:STAGING] " .. detail)
                if IsValid(ply) then ply:ChatPrint(detail) end
            end
        end
    end
end)
