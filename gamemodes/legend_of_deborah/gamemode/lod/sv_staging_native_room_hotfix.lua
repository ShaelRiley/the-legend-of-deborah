LOD = LOD or {}

local Staging = LOD.StagingDeployment
local RunManager = LOD.RunManager
if not Staging or not RunManager then return end

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
    if tr.Hit and tr.HitWorld then
        return origin:Distance(tr.HitPos), tr
    end
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
    local wallHits = 0
    for index, dir in ipairs(CARDINALS) do
        local distance = traceWall(chest, dir)
        distances[index] = distance
        if distance then wallHits = wallHits + 1 end
    end
    if wallHits < 4 then return nil end

    local plusX, minusX = distances[1], distances[2]
    local plusY, minusY = distances[3], distances[4]
    if not plusX or not minusX or not plusY or not minusY then return nil end

    local shiftX = (plusX - minusX) * 0.5
    local shiftY = (plusY - minusY) * 0.5
    local centerProbe = foot + Vector(shiftX, shiftY, 0)

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

    local spanX = px + nx
    local spanY = py + ny
    if math.min(spanX, spanY) < 110 then return nil end

    local yaw = spanX >= spanY and 0 or 90
    local halfForward = (spanX >= spanY and spanX or spanY) * 0.5
    local halfRight = (spanX >= spanY and spanY or spanX) * 0.5

    -- Prefer the highest fully enclosed cavity beneath the normal spawn roof.
    -- The stock Flatgrass room is inside the central structure; the 3D skybox is
    -- much farther below and therefore loses this score decisively.
    local score = center.z * 1000 + math.min(spanX, spanY)
    return {
        center = center,
        angles = Angle(0, yaw, 0),
        halfForward = halfForward,
        halfRight = halfRight,
        score = score
    }
end

local function sortedNativeSpawns()
    local list = {}
    for classIndex, className in ipairs(SPAWN_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if IsValid(ent) then
                list[#list + 1] = {ent = ent, classIndex = classIndex}
            end
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
                        -- Evaluate only a solid->empty transition. This keeps the
                        -- one-time native-room discovery bounded instead of tracing
                        -- every empty Z sample below the spawn platform.
                        previousSolid = false
                        local room = candidateRoomAt(sample)
                        if room and (not best or room.score > best.score) then
                            best = room
                            best.anchorClass = item.ent:GetClass()
                            best.spawnPos = spawnPos
                        end
                    end
                end
            end
        end
    end
    return best
end

local function removeEntity(ent)
    if IsValid(ent) then ent:Remove() end
end

local function clearHutPresentation()
    for _, ent in ipairs(Staging.HutEntities or {}) do removeEntity(ent) end
    Staging.HutEntities = {}
    Staging.GuideEntity = nil
    Staging.PortalEntity = nil
end

local function localOffset(center, angles, forward, right, up)
    local yaw = Angle(0, angles.y, 0)
    return center
        + yaw:Forward() * (forward or 0)
        + yaw:Right() * (right or 0)
        + Vector(0, 0, up or 0)
end

function Staging:_HutValid()
    return self.HutCenter ~= nil
        and self.HutAnchorSource == "native-enclosed-room"
        and IsValid(self.GuideEntity)
        and IsValid(self.PortalEntity)
end

function Staging:EnsureHut()
    if self:_HutValid() then return true end

    local room = findNativeEnclosedRoom()
    if not room then
        self.HutAnchorSource = "native-room-not-found"
        ErrorNoHalt("[LOD:STAGING] Could not locate the enclosed native gm_flatgrass room; staging was not released.\n")
        return false
    end

    clearHutPresentation()
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
    self.HutSpawnBack = math.Clamp(room.halfForward * 0.18, 22, 40)

    local guide = ents.Create("lod_staging_prop")
    if IsValid(guide) then
        guide:SetStageKind(1)
        guide:SetStageLabel("DUNGEON HERMIT")
        guide:SetPos(localOffset(room.center, room.angles, self.HutGuideDistance, 0, 0))
        guide:SetAngles(Angle(0, room.angles.y + 180, 0))
        guide:Spawn()
        guide:Activate()
        self.HutEntities[#self.HutEntities + 1] = guide
        self.GuideEntity = guide
    end

    local portal = ents.Create("lod_staging_prop")
    if IsValid(portal) then
        portal:SetStageKind(2)
        portal:SetStageLabel("PRESS E — ENTER THE DUNGEON")
        portal:SetPos(localOffset(room.center, room.angles, -self.HutPortalDistance, 0, 0))
        portal:SetAngles(room.angles)
        portal:Spawn()
        portal:Activate()
        self.HutEntities[#self.HutEntities + 1] = portal
        self.PortalEntity = portal
    end

    print(string.format(
        "[LOD:STAGING] native enclosed room pos=(%.1f %.1f %.1f) yaw=%.1f spanForward=%.1f spanRight=%.1f sourceSpawn=%s",
        room.center.x, room.center.y, room.center.z, room.angles.y,
        room.halfForward * 2, room.halfRight * 2, tostring(room.anchorClass)))

    return self:_HutValid()
end

function Staging:_StarterPosition()
    return localOffset(self.HutCenter, self.HutAngles, self.HutStarterDistance or 24, 0, 20)
end

function Staging:_SpawnPosition()
    return localOffset(self.HutCenter, self.HutAngles, -(self.HutSpawnBack or 32), 0, 2)
end

function Staging:_FacingAngles()
    return Angle(0, self.HutAngles and self.HutAngles.y or 0, 0)
end

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
