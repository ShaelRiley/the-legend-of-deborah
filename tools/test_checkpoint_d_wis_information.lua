local function fail(message) io.stderr:write("WIS_INFORMATION_HARNESS_FAIL: " .. message .. "\n"); os.exit(1) end
local function expect(ok, message) if not ok then fail(message) end end

local function cardinalFromYaw(yaw)
    local normalized = ((yaw + 180) % 360) - 180
    local quarter = math.floor((normalized + 45) / 90)
    quarter = ((quarter % 4) + 4) % 4
    if quarter == 0 then return 1, 0 end
    if quarter == 1 then return 0, 1 end
    if quarter == 2 then return -1, 0 end
    return 0, -1
end

local function rearOffsets(wisMod, yaw)
    local depth = math.max(1, math.floor(tonumber(wisMod) or 0))
    local fx, fy = cardinalFromYaw(yaw)
    local bx, by = -fx, -fy
    local rx, ry = -by, bx
    local offsets = {}
    for d = 1, depth do
        for lateral = -1, 1 do
            offsets[#offsets + 1] = {x = bx * d + rx * lateral, y = by * d + ry * lateral, depth = d, lateral = lateral}
        end
    end
    return offsets
end

local one = rearOffsets(-3, 0)
expect(#one == 3, "minimum rear depth must be one three-wide row")
expect(one[1].x == -1 and one[1].y == 1, "yaw 0 lateral -1 rear cell")
expect(one[2].x == -1 and one[2].y == 0, "yaw 0 center-rear cell")
expect(one[3].x == -1 and one[3].y == -1, "yaw 0 lateral +1 rear cell")

local three = rearOffsets(3, 90)
expect(#three == 9, "WIS_MOD 3 must produce three rows / nine cells")
expect(three[1].x == -1 and three[1].y == -1, "yaw 90 first row")
expect(three[7].x == -1 and three[7].y == -3, "yaw 90 third row")

local source = assert(io.open("gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_wis_information_feats.lua", "rb")):read("*a")
expect(source:find('id = "WIS_SPATIAL_AWARENESS"', 1, true), "Spatial Awareness registration")
expect(source:find('wis = 15', 1, true), "Spatial Awareness WIS 15")
expect(source:find('id = "WIS_OMNISCIENCE"', 1, true), "Omniscience registration")
expect(source:find('wis = 17', 1, true), "Omniscience WIS 17")
expect(source:find('allowedActorTypes = {"hero", "human_soldier"}', 1, true), "human-only actor restriction")
expect(source:find('ordinaryLOS = true', 1, true), "ordinary LOS contract")
expect(source:find('privateFeed(ply, "BEHIND YOU")', 1, true), "single private rear warning")
expect(source:find('{"type", "level", "class", "hp"}', 1, true), "Omniscience exact field contract")
expect(source:find('target.LODHostile', 1, true), "Omniscience hostile-only direct look")

local client = assert(io.open("gamemodes/legend_of_deborah/gamemode/lod/cl_rpg_wis_information.lua", "rb")):read("*a")
expect(client:find('trace.Entity ~= data.target', 1, true), "client direct-look guard")
expect(client:find('LEVEL %d / CLASS %s', 1, true), "level/class readout")
expect(client:find('HP %d/%d', 1, true), "HP readout")

print("WIS_INFORMATION_HARNESS_PASS")
