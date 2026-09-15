LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "WIS information feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "WIS information feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "WIS information feats require ability rules")

local definitions = {
    {
        id = "WIS_SPATIAL_AWARENESS", name = "Spatial Awareness", wis = 15,
        effectHandlerId = "rear_hostile_awareness",
        effectParams = {description = "Warns about visible hostile monsters behind you and directly to either side. RearRangeCells = max(1, WIS_MOD), without Astral Reach. Quantize horizontal facing to the nearest cardinal maze direction. The rear footprint remains three cells wide for depths 1 through RearRangeCells: directly behind, plus one cell on either side of each rear cell. Add a single-cell-wide ray directly left and directly right from the player's current cell, each extending SideRangeCells = ceil(RearRangeCells / 2). No forward cells or other floors qualify. Closed walls, closed gates and ordinary blocking geometry still block detection. Retain the selected monster while it qualifies; otherwise choose by shortest footprint depth, then smallest absolute lateral offset, then stable actor identity. On acquisition or replacement after the prior selection ceases to qualify, name the monster in a private BEHIND YOU, LEFT or RIGHT notice in the live die-readout and Die Log, play a clearly audible alert, and briefly show a violet directional light toward its position at detection. The light is a transient directional notification, not an enemy outline, minimap marker or persistent tracker. Do not repeat the alert while the same selected monster remains qualified. No target lock, aim assist, combat bonus, through-wall detection or AI behavior change.", widthCells = 3, depthAbility = "wis", minimumDepthCells = 1, ordinaryLOS = true}
    },
    {
        id = "WIS_OMNISCIENCE", name = "Omniscience", wis = 17,
        effectHandlerId = "direct_look_hostile_information",
        effectParams = {description = "While controlled by a human, whenever this actor looks at or within six degrees of a visible monster through the shared near-look identification authority, render an Omniscience readout above that monster at the same presentation anchor used for player identity text. For an ordinary AI monster, the readout shows the monster's canonical type/archetype name, current Combat Level, current class, and current Hit Points as CurrentHP/MaxHP. Example structure: Soldier • Level 21 • Fighter • HP 84/117. The values update live while the target remains valid. Omniscience is informational only: it grants no extra targeting range, no through-wall or off-screen awareness, no outline or tracking after look-away, and no combat/stat bonus. A human-controlled Soldier is still a monster for Omniscience purposes, but its existing HumanSoldierText remains the primary identity line; Omniscience appends the same Type/Level/Class/HP readout rather than replacing or hiding the controlling player's identity. Non-monster world entities and cooperative Heroes do not receive this monster-stat readout.", fields = {"type", "level", "class", "hp"}}
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
                lateral = lateral,
                direction = "BEHIND YOU"
            }
        end
    end
    for d=1,math.ceil(depth/2) do
        offsets[#offsets+1]={x=-fy*d,y=fx*d,depth=d,lateral=d,direction="LEFT"}
        offsets[#offsets+1]={x=fy*d,y=-fx*d,depth=d,lateral=d,direction="RIGHT"}
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
    local registry=LOD.HostileRegistry
    local candidates=registry and registry.List and registry:List() or ents.FindByClass("lod_hostile")
    for _, ent in ipairs(candidates) do
        if IsValid(ent) and ent.LODHostile and not ent.LODDead and ent:Health()>0 then
            local x, y, z = cellForPosition(ent:GetPos())
            local offset = wanted[x .. ":" .. y .. ":" .. z]
            if offset and ordinaryLOS(ply, ent) then
                found[#found + 1] = {entity = ent, depth = offset.depth,
                    lateral = math.abs(offset.lateral),direction=offset.direction}
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

local function privateFeed(ply, text, position)
    local rolls = LOD.CombatRolls
    if rolls and rolls._Send then
        rolls:_Send(ply,3,"[AWARENESS] "..text,"awareness",{event="spatial_awareness",position=position})
        return
    end
    if IsValid(ply) then ply:ChatPrint(text) end
end

local function hostileType(hostile)
    local config = hostile.LODConfig
    return tostring(config and config.name or hostile.LODArchetypeId or hostile:GetClass() or "Hostile")
end

local function hostileLevel(hostile)
    local state = Rules:ProgressionState(hostile)
    return math.Clamp(math.floor(tonumber(state and state.level or hostile.LODCharacterLevel) or 1), 1, 255)
end

local function hostileClass(hostile)
    local state = Rules:ProgressionState(hostile) or {}
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

local spatialState=setmetatable({}, {__mode="k"})
local function scanPlayer(ply)
    local state = Rules:ProgressionState(ply)
    if not humanEligible(ply, state) then spatialState[ply]=nil; return end

    if owns(state, "WIS_SPATIAL_AWARENESS") then
        local derived = Rules:Derived(ply) or {}
        local hostiles = RPG:CheckpointDWisRearHostiles(ply, derived.wisMod)
        local seed=LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed
        local previous=spatialState[ply]
        local selected
        if previous and previous.state==state and previous.seed==seed then
            for _,entry in ipairs(hostiles) do
                if entry.entity==previous.entity then selected=entry; break end
            end
        end
        local retained=selected~=nil
        selected=selected or hostiles[1]
        if selected and not retained then
            privateFeed(ply, selected.direction..": "..string.upper(hostileType(selected.entity)),
                selected.entity:WorldSpaceCenter())
            RPG.CheckpointDWisInformationStats.spatialAlerts = RPG.CheckpointDWisInformationStats.spatialAlerts + 1
        end
        spatialState[ply]=selected and {entity=selected.entity,state=state,seed=seed} or nil
    else
        spatialState[ply]=nil
    end

    if owns(state, "WIS_OMNISCIENCE") then
        local target = LOD.NearLook:Find(ply,4096,function(ent)
            return (ent.LODHostile or ent:IsPlayer() and ent:GetNW2Bool("LOD_IsSoldier",false))
                and not ent.LODDead and ent:Health()>0
        end)
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

hook.Add("PlayerDisconnected","LOD_SpatialAwarenessDisconnect",function(ply) spatialState[ply]=nil end)
hook.Add("PlayerDeath","LOD_SpatialAwarenessDeath",function(ply) spatialState[ply]=nil end)
hook.Add("PreCleanupMap","LOD_SpatialAwarenessCleanup",function() spatialState=setmetatable({}, {__mode="k"}) end)

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
    expect(#one == 5, "rear depth clamps to one cell plus two side cells")
    expect(one[1].x == -1 and one[1].y == 1 and one[2].x == -1 and one[2].y == 0
        and one[3].x == -1 and one[3].y == -1, "yaw zero rear strip geometry")
    local two = self:CheckpointDWisRearOffsets(2, 90)
    expect(#two == 8, "WIS modifier controls rear depth and ceil half side range")
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

