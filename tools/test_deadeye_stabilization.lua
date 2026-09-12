-- Sol stabilization regression for Deadeye universal Aim.
-- Pure/static checks only: runtime GMod acceptance is exercised separately.

local root = arg and arg[1] or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local text = f:read("*a")
    f:close()
    return text
end

local failures = {}
local function expect(ok, label)
    print(string.format("[%s] %s", ok and "PASS" or "FAIL", label))
    if not ok then failures[#failures + 1] = label end
end

local singletons = read("gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_singletons.lua")
local aim = read("gamemodes/legend_of_deborah/gamemode/lod/sv_magnum_aim_state.lua")
local client = read("gamemodes/legend_of_deborah/gamemode/lod/cl_magnum_aim_state.lua")
local crowbar = read("gamemodes/legend_of_deborah/entities/weapons/weapon_lod_crowbar/shared.lua")
local validator = read("gamemodes/legend_of_deborah/gamemode/lod/sv_deadeye_validation.lua")
local combat = read("gamemodes/legend_of_deborah/gamemode/lod/sv_combat_rolls.lua")

expect(singletons:find('"DEX_MAGNUM_DEADEYE", "Deadeye", "dex", 15, nil', 1, true) ~= nil,
    "Deadeye is DEX 15 with no capability prerequisite")
expect(singletons:find("aimHoldSeconds = 0.50", 1, true) ~= nil,
    "generic Aim compatibility hold is 0.50")
expect(singletons:find("magnumAimHoldSeconds = 0.50", 1, true) ~= nil,
    "Magnum Aim compatibility hold is 0.50")

expect(aim:find("LOD.UniversalAim = LOD.UniversalAim or {}", 1, true) ~= nil,
    "one universal Aim authority exists")
expect(aim:find("function Aim:CommitPrimaryAttack", 1, true) ~= nil,
    "primary attack transaction API exists")
expect(aim:find("if not state.armed and attackDown then", 1, true) ~= nil,
    "pre-lock held attack interrupts Aim")
expect(aim:find('Aim:CommitPrimaryAttack(ply, "weapon_ar2")', 1, true) ~= nil,
    "AR2 snapshots Aim at BeginAR2Burst")
expect(aim:find("contract.total = math.max", 1, true) == nil,
    "Aim does not double-multiply contract.total")
expect(aim:find('weapon:GetClass() ~= "weapon_357"', 1, true) ~= nil,
    "Magnum burst wrapper is Magnum-only")
expect(aim:find('ent:GetClass() ~= "npc_grenade_frag"', 1, true) ~= nil,
    "frag snapshot hook is real frag-only")
expect(aim:find('grenade_ar2', 1, true) == nil and aim:find('prop_combine_ball', 1, true) == nil,
    "AR2 secondary explosives are excluded from Aim snapshot")

local commitPos = assert(crowbar:find("aim:CommitPrimaryAttack", 1, true))
local tracePos = assert(crowbar:find("util.TraceHull", 1, true))
expect(commitPos < tracePos, "Crowbar consumes Aim before hit/miss trace")
expect(client:find('LOD_UniversalAimMultiplier', 1, true) ~= nil,
    "client HUD consumes server multiplier")
expect(client:find("ProgressionState", 1, true) == nil,
    "client HUD does not re-derive feat ownership")

expect(validator:find("RPG.IdentityCatalog", 1, true) ~= nil,
    "Deadeye validator uses canonical catalog")
expect(validator:find("GrantFeat", 1, true) == nil,
    "Deadeye testkit avoids nonexistent GrantFeat API")
expect(validator:find("_RecomputeProgressionState", 1, true) ~= nil,
    "Deadeye testkit recomputes canonical progression")
expect(validator:find("Deadeye legal without .357 access", 1, true) ~= nil,
    "singleton validator accepts Deadeye without Magnum")

expect(combat:find("local grenadeRolls = setmetatable", 1, true) ~= nil,
    "existing per-grenade combat cache remains intact")

if #failures > 0 then
    io.stderr:write("Deadeye stabilization static validation FAILED: " .. table.concat(failures, ", ") .. "\n")
    os.exit(1)
end

print("Deadeye stabilization static validation PASS")
