LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "WIS information feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "WIS information feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "WIS information feats require ability rules")

local definitions = {
    {
        id = "WIS_SPATIAL_AWARENESS", name = "Spatial Awareness", wis = 15,
        effectHandlerId = "rear_hostile_awareness",
        effectParams = {widthCells = 3, depthAbility = "wis", minimumDepthCells = 1, ordinaryLOS = true}
    },
    {
        id = "WIS_OMNISCIENCE", name = "Omniscience", wis = 17,
        effectHandlerId = "direct_look_hostile_information",
        effectParams = {fields = {"type", "level", "class", "hp"}}
    }
}
for _, item in ipairs(definitions) do
    assert(Feats[item.id] == nil, "duplicate canonical feat " .. item.id)
    Feats[item.id] = {
        featId = item.id, displayName = item.name, featFamilyId = item.id:lower(), rankIndex = 1,
        replacesLowerRank = false, repeatableFallback = false,
        governingAbilities = {"wis"}, abilityRequirements = {wis = item.wis},
        prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier"}, requiredSubsystemTags = {"navigation", "information"},
        synergyTags = {"wisdom", "navigation", "information"}, oneRank = true,
        effectHandlerId = item.effectHandlerId, effectParams = item.effectParams,
        directorBaseWeight = 1.0, eligibilityText = "WIS " .. item.wis,
        actorText = "Human Heroes and human Soldiers"
    }
end
Catalog.OrdinaryFeats = Feats

local NET_OMNISCIENCE = "LOD_RPGWisOmniscience"
util.AddNetworkString(NET_OMNISCIENCE)

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

local function humanEligible(actor, state)
    -- Human Heroes/Soldiers are player-controlled identities. AI actors can own
    -- many ordinary feats, but these two information feats are explicitly human-only.
    return IsValid(actor) and actor:IsPlayer() and actor:Alive() and state ~= nil
end

local function cardinalFromYaw(yaw)
    local normalized = math.NormalizeAngle(tonumber(yaw) or 0)
    local quarter = math.floor((normalized + 45) / 90)
    quarter = ((quarter % 4) + 4) % 4
    if quarter == 0 then return 1, 0 end
    if quarter == 1 then return 0, 1 end
    if quarter == 2 then return -1, 0 end
    return 0, -1
end

function RPG:CheckpointDWisRearOffsets(wisMod, yaw)
    local depth = math.max(1, math.floor(tonumber(wisMod) or 0))
    local fx, fy = cardinalFromYaw(yaw)
    local bx, by = -fx, -fy
    local rx, ry = -by, bx
    local offsets = {}
    for d = 1, depth do
        for lateral = -1, 1 do
            offsets[#offsets + 1] = {
                x = bx * d + rx * lateral,
                y = by * d + ry * lateral,
                depth = d,
                lateral = lateral
            }
        end
    end
    return offsets
end

local function cellForPosition(pos)
    local maze = assert(LOD.Config and LOD.Config.Maze, "WIS information requires maze config")
    local size = math.max(1, tonumber(maze.CellSize) or 384)
    local origin = maze.Origin or vector_origin
    local levelHeight = math.max(1, tonumber(maze.LevelHeight) or size)
    return math.floor((pos.x - origin.x) / size + 0.5),
        math.floor((pos.y - origin.y) / size + 0.5),
        math.floor((pos.z - origin.z) / levelHeight + 0.5)
end

local function rearCoordinatesFor(ply, wisMod)
    local px, py, pz = cellForPosition(ply:GetPos())
    local wanted = {}
    for _, offset in ipairs(RPG:CheckpointDWisRearOffsets(wisMod, ply:EyeAngles().y)) do
        wanted[(px + offset.x) .. ":" .. (py + offset.y) .. ":" .. pz] = offset
    end
    return wanted
end

local function ordinaryLOS(ply, hostile)
    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = hostile:WorldSpaceCenter(),
        filter = ply,
        mask = MASK_VISIBLE_AND_NPCS
    })
    return not trace.Hit or trace.Entity == hostile
end

function RPG:CheckpointDWisRearHostiles(ply, wisMod)
    if not IsValid(ply) then return {} end
    local wanted = rearCoordinatesFor(ply, wisMod)
    local found = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.LODHostile and not ent.LODDead then
            local x, y, z = cellForPosition(ent:GetPos())
            local offset = wanted[x .. ":" .. y .. ":" .. z]
            if offset and ordinaryLOS(ply, ent) then
                found[#found + 1] = {entity = ent, depth = offset.depth, lateral = offset.lateral}
            end
        end
    end
    table.sort(found, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        if a.lateral ~= b.lateral then return a.lateral < b.lateral end
        return a.entity:EntIndex() < b.entity:EntIndex()
    end)
    return found
end

local function privateFeed(ply, text)
    local rolls = LOD.CombatRolls
    if rolls and rolls._Send then rolls:_Send(ply, 3, text); return end
    if IsValid(ply) then ply:ChatPrint(text) end
end

local function hostileType(hostile)
    local config = hostile.LODConfig
    return tostring(config and config.name or hostile.LODArchetypeId or hostile:GetClass() or "Hostile")
end

local function hostileLevel(hostile)
    local state = hostile.LODProgressionState
    return math.Clamp(math.floor(tonumber(state and state.level or hostile.LODCharacterLevel) or 1), 1, 255)
end

local function hostileClass(hostile)
    local state = hostile.LODProgressionState or {}
    return tostring(state.className or state.classId or state.class or hostile.LODArchetypeId or hostile:GetClass() or "Hostile")
end

local function sendOmniscience(ply, hostile)
    net.Start(NET_OMNISCIENCE)
    net.WriteEntity(IsValid(hostile) and hostile or NULL)
    if IsValid(hostile) then
        net.WriteString(hostileType(hostile))
        net.WriteUInt(hostileLevel(hostile), 8)
        net.WriteString(hostileClass(hostile))
        net.WriteInt(math.Clamp(math.floor(hostile:Health()), -32768, 32767), 16)
        net.WriteUInt(math.Clamp(math.floor(hostile:GetMaxHealth()), 0, 65535), 16)
    end
    net.Send(ply)
end

RPG.CheckpointDWisInformationStats = RPG.CheckpointDWisInformationStats or {
    spatialAlerts = 0, omniscienceUpdates = 0
}

local function scanPlayer(ply)
    local state = Rules:ProgressionState(ply)
    if not humanEligible(ply, state) then return end

    if owns(state, "WIS_SPATIAL_AWARENESS") then
        local derived = Rules:Derived(ply) or {}
        local hostiles = RPG:CheckpointDWisRearHostiles(ply, derived.wisMod)
        local occupied = #hostiles > 0
        if occupied and not ply.LODWisSpatialOccupied then
            privateFeed(ply, "BEHIND YOU")
            RPG.CheckpointDWisInformationStats.spatialAlerts = RPG.CheckpointDWisInformationStats.spatialAlerts + 1
        end
        ply.LODWisSpatialOccupied = occupied
    else
        ply.LODWisSpatialOccupied = false
    end

    if owns(state, "WIS_OMNISCIENCE") then
        local trace = ply:GetEyeTrace()
        local target = trace and trace.Entity or nil
        if not (IsValid(target) and target.LODHostile and not target.LODDead) then target = nil end
        local changed = target ~= ply.LODWisOmniscienceTarget
        local hpChanged = IsValid(target) and target:Health() ~= ply.LODWisOmniscienceHP
        if changed or hpChanged or CurTime() >= (ply.LODWisOmniscienceNextSync or 0) then
            sendOmniscience(ply, target)
            ply.LODWisOmniscienceTarget = target
            ply.LODWisOmniscienceHP = IsValid(target) and target:Health() or nil
            ply.LODWisOmniscienceNextSync = CurTime() + 0.20
            RPG.CheckpointDWisInformationStats.omniscienceUpdates = RPG.CheckpointDWisInformationStats.omniscienceUpdates + 1
        end
    elseif ply.LODWisOmniscienceTarget ~= nil then
        sendOmniscience(ply, nil)
        ply.LODWisOmniscienceTarget = nil
        ply.LODWisOmniscienceHP = nil
    end
end

timer.Create("LOD_CheckpointDWisInformation", 0.20, 0, function()
    for _, ply in ipairs(player.GetHumans()) do scanPlayer(ply) end
end)

function RPG:ValidateCheckpointDWisInformationFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local spatial, omniscience = Feats.WIS_SPATIAL_AWARENESS, Feats.WIS_OMNISCIENCE
    expect(spatial and spatial.abilityRequirements.wis == 15, "Spatial Awareness definition")
    expect(omniscience and omniscience.abilityRequirements.wis == 17, "Omniscience definition")
    expect(spatial and #spatial.allowedActorTypes == 2 and spatial.allowedActorTypes[1] == "hero"
        and spatial.allowedActorTypes[2] == "human_soldier", "Spatial Awareness human-only actors")
    expect(omniscience and #omniscience.allowedActorTypes == 2 and omniscience.allowedActorTypes[1] == "hero"
        and omniscience.allowedActorTypes[2] == "human_soldier", "Omniscience human-only actors")
    local one = self:CheckpointDWisRearOffsets(-2, 0)
    expect(#one == 3, "rear depth clamps to one cell")
    expect(one[1].x == -1 and one[1].y == 1 and one[2].x == -1 and one[2].y == 0
        and one[3].x == -1 and one[3].y == -1, "yaw zero rear strip geometry")
    local two = self:CheckpointDWisRearOffsets(2, 90)
    expect(#two == 6, "WIS modifier controls rear depth")
    expect(two[1].x == -1 and two[1].y == -1 and two[4].x == -1 and two[4].y == -2,
        "cardinal rotation remains deterministic")
    expect(omniscience and table.concat(omniscience.effectParams.fields, ",") == "type,level,class,hp",
        "Omniscience exact information fields")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_wis_information", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDWisInformationFeats()
    print("[LOD:WIS-INFORMATION] " .. (ok and "PASS" or "FAIL")
        .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
