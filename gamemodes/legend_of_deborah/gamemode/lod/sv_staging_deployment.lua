LOD = LOD or {}
LOD.StagingDeployment = LOD.StagingDeployment or {}

local Staging = LOD.StagingDeployment
local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local CC = LOD.Config
if not RunManager or not CC then return end

Staging.ArchitectureVersion = "canonical-native-room-v1"
Staging.HutEntities = Staging.HutEntities or {}
Staging.StarterEntities = Staging.StarterEntities or {}
Staging.TorchEntities = Staging.TorchEntities or {}
Staging.Stats = Staging.Stats or {
    staged = 0,
    starterClaims = 0,
    deployments = 0,
    portalDenied = 0,
    duplicateStarterPrevented = 0
}

local STARTER_SPECS = {
    weapon_shotgun = {label = "Shotgun", clip = 7, ammo = "Buckshot", model = "models/weapons/w_shotgun.mdl"},
    weapon_smg1 = {label = "SMG", clip = 25, ammo = "SMG1", model = "models/weapons/w_smg1.mdl"},
    weapon_357 = {label = ".357 Magnum", clip = 6, ammo = "357", model = "models/weapons/w_357.mdl"},
    weapon_ar2 = {label = "AR2", clip = 20, ammo = "AR2", model = "models/weapons/w_irifle.mdl"}
}
local STARTER_CLASSES = {"weapon_shotgun", "weapon_smg1", "weapon_357", "weapon_ar2"}
local TORCH_MODEL = "models/props_c17/light_cagelight02_on.mdl"

-- Native gm_flatgrass room discovery. This is the only hut-location authority.
local WORLD_MASK = MASK_PLAYERSOLID_BRUSHONLY or MASK_SOLID_BRUSHONLY or MASK_SOLID
local PLAYER_MINS = Vector(-16, -16, 0)
local PLAYER_MAXS = Vector(16, 16, 72)
local CARDINALS = {
    Vector(1, 0, 0), Vector(-1, 0, 0),
    Vector(0, 1, 0), Vector(0, -1, 0)
}
local SEARCH_XY = 320
local SEARCH_XY_STEP = 64
local SEARCH_DEPTH = 640
local SEARCH_Z_STEP = 16
local WALL_PROBE = 448
local MIN_ROOM_HEIGHT = 82
local SPAWN_CLASSES = {
    "info_player_start",
    "info_player_deathmatch",
    "info_player_rebel",
    "info_player_combine"
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

local function localOffset(center, angles, forward, right, up)
    local yaw = Angle(0, angles.y, 0)
    return center
        + yaw:Forward() * (forward or 0)
        + yaw:Right() * (right or 0)
        + Vector(0, 0, up or 0)
end

local function isWorldSolid(pos)
    return bit.band(util.PointContents(pos), CONTENTS_SOLID) ~= 0
end

local function hullClear(pos)
    local tr = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = PLAYER_MINS,
        maxs = PLAYER_MAXS,
        mask = WORLD_MASK
    })
    return not tr.StartSolid and not tr.AllSolid
end

local function traceWall(origin, dir)
    local tr = util.TraceLine({
        start = origin,
        endpos = origin + dir * WALL_PROBE,
        mask = WORLD_MASK
    })
    if tr.Hit and tr.HitWorld then return origin:Distance(tr.HitPos), tr end
    return nil, tr
end

local function candidateRoomAt(sample)
    if isWorldSolid(sample) then return nil end

    local floor = util.TraceLine({
        start = sample + Vector(0, 0, 8),
        endpos = sample - Vector(0, 0, 224),
        mask = WORLD_MASK
    })
    if not floor.Hit or not floor.HitWorld then return nil end

    local foot = floor.HitPos + Vector(0, 0, 2)
    if not hullClear(foot) then return nil end

    local ceiling = util.TraceLine({
        start = foot + Vector(0, 0, 72),
        endpos = foot + Vector(0, 0, 208),
        mask = WORLD_MASK
    })
    if not ceiling.Hit or not ceiling.HitWorld then return nil end
    if ceiling.HitPos.z - floor.HitPos.z < MIN_ROOM_HEIGHT then return nil end

    local chest = foot + Vector(0, 0, 42)
    local distances = {}
    for index, dir in ipairs(CARDINALS) do distances[index] = traceWall(chest, dir) end

    local plusX, minusX = distances[1], distances[2]
    local plusY, minusY = distances[3], distances[4]
    if not plusX or not minusX or not plusY or not minusY then return nil end

    local centerProbe = foot + Vector((plusX - minusX) * 0.5, (plusY - minusY) * 0.5, 0)
    local centerFloor = util.TraceLine({
        start = centerProbe + Vector(0, 0, 36),
        endpos = centerProbe - Vector(0, 0, 72),
        mask = WORLD_MASK
    })
    if not centerFloor.Hit or not centerFloor.HitWorld then return nil end

    local center = centerFloor.HitPos + Vector(0, 0, 2)
    if not hullClear(center) then return nil end

    local centerChest = center + Vector(0, 0, 42)
    local px = traceWall(centerChest, Vector(1, 0, 0))
    local nx = traceWall(centerChest, Vector(-1, 0, 0))
    local py = traceWall(centerChest, Vector(0, 1, 0))
    local ny = traceWall(centerChest, Vector(0, -1, 0))
    if not px or not nx or not py or not ny then return nil end

    local spanX, spanY = px + nx, py + ny
    if math.min(spanX, spanY) < 110 then return nil end

    local yaw = spanX >= spanY and 0 or 90
    return {
        center = center,
        angles = Angle(0, yaw, 0),
        halfForward = (spanX >= spanY and spanX or spanY) * 0.5,
        halfRight = (spanX >= spanY and spanY or spanX) * 0.5,
        score = center.z * 1000 + math.min(spanX, spanY)
    }
end

local function sortedNativeSpawns()
    local list = {}
    for classIndex, className in ipairs(SPAWN_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if IsValid(ent) then list[#list + 1] = {ent = ent, classIndex = classIndex} end
        end
    end
    table.sort(list, function(a, b)
        if a.classIndex ~= b.classIndex then return a.classIndex < b.classIndex end
        return a.ent:EntIndex() < b.ent:EntIndex()
    end)
    return list
end

local function findNativeEnclosedRoom()
    local best
    for _, item in ipairs(sortedNativeSpawns()) do
        local spawnPos = item.ent:GetPos()
        for ox = -SEARCH_XY, SEARCH_XY, SEARCH_XY_STEP do
            for oy = -SEARCH_XY, SEARCH_XY, SEARCH_XY_STEP do
                local previousSolid = false
                for dz = SEARCH_Z_STEP, SEARCH_DEPTH, SEARCH_Z_STEP do
                    local sample = Vector(spawnPos.x + ox, spawnPos.y + oy, spawnPos.z - dz)
                    local solid = isWorldSolid(sample)
                    if solid then
                        previousSolid = true
                    elseif previousSolid then
                        previousSolid = false
                        local room = candidateRoomAt(sample)
                        if room and (not best or room.score > best.score) then
                            best = room
                            best.anchorClass = item.ent:GetClass()
                        end
                    end
                end
            end
        end
    end
    return best
end

function Staging:_RegisterHutEntity(ent)
    if IsValid(ent) then self.HutEntities[#self.HutEntities + 1] = ent end
    return ent
end

function Staging:_ClearHutPresentation()
    for _, ent in ipairs(self.HutEntities or {}) do removeEntity(ent) end
    self.HutEntities = {}
    self.GuideEntity = nil
    self.PortalEntity = nil
    self.SignEntity = nil
    self.ManualEntity = nil
    self.MirrorEntity = nil
    self.StarterPedestalEntity = nil
    self.TorchEntities = {}
end

function Staging:_HutValid()
    return self.HutCenter ~= nil
        and self.HutAnchorSource == "native-enclosed-room"
        and IsValid(self.GuideEntity)
        and IsValid(self.PortalEntity)
end

local function findDeborahDoll(staging)
    local center = staging.HutCenter
    if not center then return nil end
    local radius = math.max(tonumber(staging.HutHalfForward) or 448,
        tonumber(staging.HutHalfRight) or 288) + 32

    local best
    for _, ent in ipairs(ents.FindInBox(
        center + Vector(-radius, -radius, -36),
        center + Vector(radius, radius, 170)
    )) do
        if IsValid(ent)
            and ent:GetClass() ~= "lod_staging_prop"
            and ent:GetClass() ~= "lod_field_manual"
            and ent:GetClass() ~= "lod_staging_mirror"
        then
            local model = string.lower(ent:GetModel() or "")
            if model ~= "" and string.find(model, "doll", 1, true) then
                local distance = ent:GetPos():DistToSqr(center)
                if not best or distance < best.distance then
                    best = {entity = ent, distance = distance, model = model}
                end
            end
        end
    end
    return best
end

local function featureWallLayout(staging)
    local center = staging.HutCenter
    local yaw = Angle(0, staging.HutAngles.y, 0)
    local fwd, right = yaw:Forward(), yaw:Right()
    local halfF = math.max(120, tonumber(staging.HutHalfForward) or 448)
    local halfR = math.max(90, tonumber(staging.HutHalfRight) or 288)
    local inset = 46

    local doll = findDeborahDoll(staging)
    local manualPos, manualInward, mirrorPos, mirrorInward

    if doll and IsValid(doll.entity) then
        local rel = doll.entity:GetPos() - center
        local localF, localR = rel:Dot(fwd), rel:Dot(right)
        local nearF, nearR = halfF - math.abs(localF), halfR - math.abs(localR)

        if nearR <= nearF then
            local side = localR >= 0 and 1 or -1
            local tangent = math.Clamp(localF + (localF >= 0 and -82 or 82), -halfF + 90, halfF - 90)
            manualPos = center + right * (side * (halfR - inset)) + fwd * tangent
            manualInward = right * -side
            mirrorPos = center + right * (-side * (halfR - 14))
            mirrorInward = right * side
        else
            local side = localF >= 0 and 1 or -1
            local tangent = math.Clamp(localR + (localR >= 0 and -82 or 82), -halfR + 90, halfR - 90)
            manualPos = center + fwd * (side * (halfF - inset)) + right * tangent
            manualInward = fwd * -side
            mirrorPos = center + fwd * (-side * (halfF - 14))
            mirrorInward = fwd * side
        end
        staging.FeatureDollModel = doll.model
    else
        manualPos = center - right * (halfR - inset) + fwd * 42
        manualInward = right
        mirrorPos = center + right * (halfR - 14)
        mirrorInward = -right
        staging.FeatureDollModel = "not-found"
    end

    manualPos.z, mirrorPos.z = center.z + 2, center.z + 2
    local manualAng, mirrorAng = manualInward:Angle(), mirrorInward:Angle()
    manualAng.p, manualAng.r = 0, 0
    mirrorAng.p, mirrorAng.r = 0, 0
    return manualPos, manualAng, mirrorPos, mirrorAng
end

function Staging:EnsureRoomDecor()
    if not self:_HutValid() then return false end

    local validTorches = 0
    for _, torch in ipairs(self.TorchEntities or {}) do
        if IsValid(torch) then validTorches = validTorches + 1 end
    end
    if IsValid(self.SignEntity)
        and validTorches >= 2
        and IsValid(self.ManualEntity)
        and IsValid(self.MirrorEntity)
        and IsValid(self.StarterPedestalEntity)
    then
        return true
    end

    for _, ent in ipairs({self.SignEntity, self.ManualEntity, self.MirrorEntity, self.StarterPedestalEntity}) do
        removeEntity(ent)
    end
    for _, torch in ipairs(self.TorchEntities or {}) do removeEntity(torch) end
    self.SignEntity, self.ManualEntity, self.MirrorEntity, self.StarterPedestalEntity = nil, nil, nil, nil
    self.TorchEntities = {}

    local center, angles = self.HutCenter, self.HutAngles
    local halfForward = math.max(120, tonumber(self.HutHalfForward) or 180)
    local halfRight = math.max(90, tonumber(self.HutHalfRight) or 130)
    local guideDistance = tonumber(self.HutGuideDistance) or 72

    local sign = ents.Create("lod_staging_prop")
    if IsValid(sign) then
        sign:SetStageKind(sign.KIND_SIGN or 4)
        sign:SetStageLabel("IT'S DANGEROUS TO GO\nALONE! TAKE THIS.")
        sign:SetPos(localOffset(center, angles, halfForward - 48, 0, 96))
        sign:SetAngles(Angle(0, angles.y + 180, 0))
        sign:Spawn()
        sign:Activate()
        self.SignEntity = self:_RegisterHutEntity(sign)
    end

    local torchForward = math.min(halfForward - 42, guideDistance + 48)
    local torchRight = math.min(halfRight - 34, math.max(74, halfRight * 0.32))
    for _, side in ipairs({-1, 1}) do
        local torch = ents.Create("lod_staging_prop")
        if IsValid(torch) then
            torch:SetStageKind(torch.KIND_TORCH or 5)
            torch:SetStageLabel("")
            torch.LODStageModel = TORCH_MODEL
            torch:SetPos(localOffset(center, angles, torchForward, torchRight * side, 34))
            torch:SetAngles(Angle(0, angles.y + 180, 0))
            torch:Spawn()
            torch:Activate()
            self.TorchEntities[#self.TorchEntities + 1] = self:_RegisterHutEntity(torch)
        end
    end

    local pedestal = ents.Create("lod_staging_prop")
    if IsValid(pedestal) then
        pedestal:SetStageKind(pedestal.KIND_PEDESTAL or 6)
        pedestal:SetStageLabel("")
        local starterPos = self:_StarterPosition()
        pedestal:SetPos(Vector(starterPos.x, starterPos.y, center.z + 2))
        pedestal:SetAngles(angles)
        pedestal:Spawn()
        pedestal:Activate()
        self.StarterPedestalEntity = self:_RegisterHutEntity(pedestal)
    end

    local manualPos, manualAng, mirrorPos, mirrorAng = featureWallLayout(self)
    local manual = ents.Create("lod_field_manual")
    if IsValid(manual) then
        manual:SetPos(manualPos)
        manual:SetAngles(manualAng)
        manual:Spawn()
        manual:Activate()
        self.ManualEntity = self:_RegisterHutEntity(manual)
    end

    local mirror = ents.Create("lod_staging_mirror")
    if IsValid(mirror) then
        mirror:SetPos(mirrorPos)
        mirror:SetAngles(mirrorAng)
        mirror:Spawn()
        mirror:Activate()
        self.MirrorEntity = self:_RegisterHutEntity(mirror)
    end

    return IsValid(self.SignEntity)
        and IsValid(self.ManualEntity)
        and IsValid(self.MirrorEntity)
        and IsValid(self.StarterPedestalEntity)
        and #self.TorchEntities >= 2
end

function Staging:EnsureHut()
    if self:_HutValid() then
        self:EnsureRoomDecor()
        return true
    end

    local room = findNativeEnclosedRoom()
    if not room then
        self.HutAnchorSource = "native-room-not-found"
        ErrorNoHalt("[LOD:STAGING] Could not locate the enclosed native gm_flatgrass room; staging was not released.\n")
        return false
    end

    self:_ClearHutPresentation()
    self.HutCenter = room.center
    self.HutAngles = room.angles
    self.HutAnchorSource = "native-enclosed-room"
    self.HutNativeSpawnClass = room.anchorClass
    self.HutHalfForward = room.halfForward
    self.HutHalfRight = room.halfRight

    local placement = math.Clamp(room.halfForward * 0.38, 44, 82)
    self.HutGuideDistance = placement
    self.HutPortalDistance = placement
    self.HutStarterDistance = math.Clamp(room.halfForward * 0.12, 16, 30)
    self.HutSpawnBack = math.Clamp(room.halfForward * 0.045, 8, 14)

    local guide = ents.Create("lod_staging_prop")
    if IsValid(guide) then
        guide:SetStageKind(guide.KIND_GUIDE or 1)
        guide:SetStageLabel("DUNGEON HERMIT")
        guide:SetPos(localOffset(room.center, room.angles, self.HutGuideDistance, 0, 0))
        guide:SetAngles(Angle(0, room.angles.y + 180, 0))
        guide:Spawn()
        guide:Activate()
        self.GuideEntity = self:_RegisterHutEntity(guide)
    end

    local portal = ents.Create("lod_staging_prop")
    if IsValid(portal) then
        portal:SetStageKind(portal.KIND_PORTAL or 2)
        portal:SetStageLabel("ENTER THE DUNGEON")
        portal:SetPos(localOffset(room.center, room.angles, -self.HutPortalDistance, 0, 0))
        portal:SetAngles(room.angles)
        portal:Spawn()
        portal:Activate()
        self.PortalEntity = self:_RegisterHutEntity(portal)
    end

    if not self:_HutValid() then return false end
    self:EnsureRoomDecor()

    print(string.format(
        "[LOD:STAGING] canonical native room pos=(%.1f %.1f %.1f) yaw=%.1f spanForward=%.1f spanRight=%.1f sourceSpawn=%s",
        room.center.x, room.center.y, room.center.z, room.angles.y,
        room.halfForward * 2, room.halfRight * 2, tostring(room.anchorClass)))
    return true
end

function Staging:_StarterPosition()
    return localOffset(self.HutCenter, self.HutAngles, self.HutStarterDistance or 24, 0, 20)
end

function Staging:_SpawnPosition()
    return localOffset(self.HutCenter, self.HutAngles, -(self.HutSpawnBack or 12), 0, 2)
end

function Staging:_FacingAngles()
    return Angle(0, self.HutAngles and self.HutAngles.y or 0, 0)
end

function Staging:IsDeployed(ply)
    if not IsValid(ply) or not slotActive(ply) then return false end
    local ps = RunManager:GetPlayerState(ply)
    return ps and ps.deploymentComplete == true or false
end

function RunManager:IsDungeonPlayer(ply)
    return Staging:IsDeployed(ply)
end

-- RunManager owns campaign slots; staging only refines the gameplay-active view.
if not RunManager.LODStagingActiveSemanticsInstalled then
    RunManager.LODStagingActiveSemanticsInstalled = true
    RunManager.IsSlotActivePlayer = RunManager.IsSlotActivePlayer or RunManager.IsActivePlayer
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
            if other and starterSpec(other.starterWeaponClass) then
                reserved[other.starterWeaponClass] = true
            end
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

local function initializeStagingState(ps)
    if not ps then return end
    Staging:_AssignStarter(ps)
    if ps.deploymentComplete == nil then ps.deploymentComplete = false end
    -- Compatibility cleanup for identities saved before staging became authoritative.
    ps.catchupLevel = nil
    ps.catchupGrantedLevel = nil
end

if not RunManager.LODStagingAdmissionWrapped then
    RunManager.LODStagingAdmissionWrapped = true
    local baseAdmitIdentity = RunManager._AdmitIdentity
    function RunManager:_AdmitIdentity(ply)
        local ps = baseAdmitIdentity(self, ply)
        initializeStagingState(ps)
        return ps
    end

    local baseTryActivatePlayer = RunManager.TryActivatePlayer
    function RunManager:TryActivatePlayer(ply)
        local active = baseTryActivatePlayer(self, ply)
        if active then initializeStagingState(self:GetPlayerState(ply)) end
        return active
    end
end

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
    if not self:EnsureHut() then return false end

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
    ent:SetStageLabel("TAKE THIS — " .. spec.label)
    ent.LODStageModel = spec.model
    ent.LODStagingOwnerIdentity = identity
    ent.LODStagingWeaponClass = weaponClass
    ent:SetPos(self:_StarterPosition())
    ent:SetAngles(Angle(0, self.HutAngles.y + 90, 0))
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

    initializeStagingState(ps)
    ply:SetPos(self:_SpawnPosition())
    ply:SetEyeAngles(self:_FacingAngles())
    ply:SetLocalVelocity(vector_origin)
    ply:SetNW2Bool("LOD_Staged", true)
    ply:SetNW2Bool("LOD_Deployed", false)
    self:EnsureStarterPickup(ply)

    if announce ~= false and not ps.stagingIntroShown then
        ps.stagingIntroShown = true
        ply:ChatPrint("DUNGEON HERMIT: It's dangerous to go alone. Take this.")
        ply:ChatPrint("Press P to choose your Class and Level-1 Feat, take your weapon, then use the blue portal.")
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

    local progression = LOD.CharacterProgressionSystem
    if not progression or not progression:IsDeploymentEligible(ps) then
        self.Stats.portalDenied = (self.Stats.portalDenied or 0) + 1
        ply:EmitSound("buttons/button10.wav", 58, 92, 0.7, CHAN_ITEM)
        ply:ChatPrint("THE PORTAL REMAINS CLOSED - PRESS P AND COMMIT YOUR CLASS + LEVEL-1 FEAT")
        if progression and progression.SyncPlayer then progression:SyncPlayer(ply) end
        return false
    end

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
    ps.deployedDungeonLevel = state.Level
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

-- Staging replaces the two historical guaranteed Level-1 firearm nodes. Keep this
-- narrow compatibility adapter until the broader LootDirector consolidation removes
-- those old nodes at their original source.
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
    function RunManager:NewCampaign(...)
        clearStarterEntities()
        Staging:_ClearHutPresentation()
        Staging.HutCenter = nil
        Staging.HutAnchorSource = nil
        return baseNewCampaign(self, ...)
    end
end

if not RunManager.LODStagingBuildWrapped then
    RunManager.LODStagingBuildWrapped = true
    local baseBuildCurrentLevel = RunManager.BuildCurrentLevel
    function RunManager:BuildCurrentLevel(...)
        local ok, result = baseBuildCurrentLevel(self, ...)
        if not ok then return ok, result end

        Staging:EnsureHut()
        timer.Simple(0, function()
            if not self.State or not self.State.BuildReady then return end
            for _, ply in ipairs(player.GetAll()) do
                local ps = self:GetPlayerState(ply)
                if IsValid(ply) and ps and self:IsSlotActivePlayer(ply)
                    and ps.deploymentComplete ~= true and ply:Alive()
                then
                    Staging:PlacePlayerInHut(ply, true)
                end
            end
        end)
        return ok, result
    end
end

hook.Add("PlayerInitialSpawn", "LOD_StagingStarterTransmission", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        for identity, ent in pairs(Staging.StarterEntities or {}) do
            if IsValid(ent) then ent:SetPreventTransmit(ply, identityOf(ply) ~= identity) end
        end
    end)
end)

hook.Add("PlayerDisconnected", "LOD_StagingStarterCleanup", function(ply)
    local identity = identityOf(ply)
    local ent = identity and Staging.StarterEntities[identity]
    removeEntity(ent)
    if identity then Staging.StarterEntities[identity] = nil end
end)

hook.Add("ShutDown", "LOD_StagingCleanup", function()
    clearStarterEntities()
    Staging:_ClearHutPresentation()
end)

concommand.Add("lod_staging_anchor_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local center = Staging.HutCenter
    local line = string.format(
        "source=%s hut=%s center=%s halfForward=%.1f halfRight=%.1f",
        tostring(Staging.HutAnchorSource or "none"), tostring(Staging:_HutValid()),
        center and string.format("%.1f,%.1f,%.1f", center.x, center.y, center.z) or "none",
        tonumber(Staging.HutHalfForward) or 0, tonumber(Staging.HutHalfRight) or 0)
    print("[LOD:STAGING-ANCHOR] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_staging_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local slotCount, stagedCount, deployedCount, claimedCount, pickupCount = 0, 0, 0, 0, 0
    local starterSeen, conflicts = {}, 0

    for _, candidate in ipairs(player.GetAll()) do
        local ps = RunManager:GetPlayerState(candidate)
        if ps and RunManager:IsSlotActivePlayer(candidate) then
            slotCount = slotCount + 1
            if ps.deploymentComplete then deployedCount = deployedCount + 1 else stagedCount = stagedCount + 1 end
            if ps.starterClaimed then claimedCount = claimedCount + 1 end
            if ps.starterWeaponClass then
                if starterSeen[ps.starterWeaponClass] then conflicts = conflicts + 1 end
                starterSeen[ps.starterWeaponClass] = true
            end
        end
    end
    for _, ent in pairs(Staging.StarterEntities or {}) do if IsValid(ent) then pickupCount = pickupCount + 1 end end

    local pass = Staging:_HutValid() and conflicts == 0
    local line = string.format(
        "slotActive=%d staged=%d deployed=%d claimed=%d pickups=%d hut=%s anchor=%s uniqueStarterConflicts=%d deployments=%d denied=%d result=%s",
        slotCount, stagedCount, deployedCount, claimedCount, pickupCount,
        tostring(Staging:_HutValid()), tostring(Staging.HutAnchorSource or "none"),
        conflicts, Staging.Stats.deployments or 0, Staging.Stats.portalDenied or 0,
        pass and "PASS" or "FAIL")
    print("[LOD:STAGING] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_staging_audit_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local torches, barrierBoxes = 0, 0
    for _, ent in ipairs(Staging.TorchEntities or {}) do if IsValid(ent) then torches = torches + 1 end end
    for _, ent in ipairs(Staging.HutEntities or {}) do
        if IsValid(ent) and ent:GetClass() == "lod_static_box" then barrierBoxes = barrierBoxes + 1 end
    end

    local portalShared = IsValid(Staging.PortalEntity)
        and Staging.PortalEntity.PortalAimFraction ~= nil
        and Staging.PortalEntity.IsPortalAimHit ~= nil
    local decor = IsValid(Staging.SignEntity)
        and IsValid(Staging.ManualEntity)
        and IsValid(Staging.MirrorEntity)
        and IsValid(Staging.StarterPedestalEntity)
        and torches >= 2
    local pass = Staging.ArchitectureVersion == "canonical-native-room-v1"
        and Staging:_HutValid()
        and Staging.HutAnchorSource == "native-enclosed-room"
        and barrierBoxes == 0 and decor and portalShared

    local line = string.format(
        "architecture=%s nativeRoom=%s barriers=%d decor=%s torches=%d portalShared=%s manual=%s mirror=%s result=%s",
        tostring(Staging.ArchitectureVersion), tostring(Staging.HutAnchorSource == "native-enclosed-room"),
        barrierBoxes, tostring(decor), torches, tostring(portalShared),
        tostring(IsValid(Staging.ManualEntity)), tostring(IsValid(Staging.MirrorEntity)),
        pass and "PASS" or "FAIL")
    print("[LOD:STAGING-AUDIT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
