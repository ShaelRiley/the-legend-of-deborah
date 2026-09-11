local serverPath = arg[1] or "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_gps_feat.lua"
local clientPath = arg[2] or "gamemodes/legend_of_deborah/gamemode/lod/cl_rpg_gps.lua"

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source
end

local server = readAll(serverPath)
local client = readAll(clientPath)
local function expect(ok, message) if not ok then error(message, 0) end end

expect(server:find('featId = GPS_ID', 1, true), "missing canonical GPS feat")
expect(server:find('abilityRequirements = {wis = 17}', 1, true), "GPS must be WIS 17")
expect(server:find('allowedActorTypes = {"hero"}', 1, true), "GPS must be Hero-only")
expect(server:find('idleBaseSeconds = 3, idleDieSides = 6, defaultKey = "G"', 1, true),
    "GPS must use sealed 3+1d6 idle delay and default G key")
expect(server:find('magicCost = 0, maxBarksPerStationaryEpisode = 1', 1, true),
    "GPS must cost no Magic and bark once per stationary episode")
expect(server:find('util.SharedRandom("LOD_WIS_GPS:"', 1, true), "GPS idle die must be sealed utility randomness")
expect(server:find('return 3 + math.Clamp(roll, 1, 6)', 1, true), "GPS idle delay must be 3+1d6")
expect(server:find('director:GetObjectiveGraphTarget()', 1, true), "GPS must consume canonical progression objective")
expect(server:find('navigator:FindPath(graph, cell, objective.a)', 1, true),
    "GPS must consume canonical MazeNavigator route")
expect(not server:find('ents.GetAll', 1, true), "GPS may not world-scan")
expect(server:find('if r.barked or CurTime() < r.idleStarted + r.delay then return end', 1, true),
    "GPS must emit at most one bark per stationary episode")
expect(server:find('ply:GetVelocity():Length2DSqr() >= MOVE_SPEED_SQR', 1, true),
    "GPS must re-arm on meaningful locomotion")
expect(server:find('if ply:GetObserverMode() ~= OBS_MODE_NONE then return true end', 1, true),
    "GPS must suspend while spectating")
expect(server:find('if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) then return true end', 1, true),
    "GPS must suspend during active combat input")

expect(client:find('concommand.Add("lod_gps_toggle", requestToggle)', 1, true),
    "GPS must expose a rebindable toggle action")
expect(client:find('input.LookupBinding("lod_gps_toggle", true)', 1, true),
    "GPS default-key fallback must defer to a user binding")
expect(client:find('input.IsKeyDown(KEY_G)', 1, true), "GPS unbound default must be G")
expect(client:find('GPS ENABLED — If it gets annoying, press G to turn it off. Press G again to turn it back on.', 1, true),
    "GPS acquisition notice mismatch")
expect(client:find('notice(enabled and "GPS ON" or "GPS OFF")', 1, true), "GPS toggle notice mismatch")
expect(client:find('switchChime()', 1, true), "GPS toggle must play a switch/chime")
expect(client:find('sound.PlayFile(BANK, "mono noblock noplay"', 1, true),
    "GPS must use private synthetic/concatenative voice playback")

local supported = {
    "TURN LEFT", "TURN RIGHT", "TURN AROUND", "CONTINUE FORWARD",
    "TAKE THE STAIRS UP", "TAKE THE STAIRS DOWN", "YOU HAVE ARRIVED AT YOUR DESTINATION"
}
for _, phrase in ipairs(supported) do
    expect(server:find(phrase, 1, true) or client:find(phrase, 1, true), "missing GPS phrase family: " .. phrase)
end
expect(server:find('"IN %d %s TURN', 1, true) or server:find('"IN %d %s %s"', 1, true),
    "missing distance-to-turn guidance family")
expect(server:find('"IN %d %s TAKE THE STAIRS %s"', 1, true),
    "missing distance-to-stairs guidance family")

print("GPS_HARNESS_PASS")
