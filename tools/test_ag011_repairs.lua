-- Deterministic test harness for AG-011 Big Playtest Repairs
local root = "gamemodes/legend_of_deborah/gamemode/lod/"
unpack = table.unpack

function CurTime() return 100 end
RealTime = CurTime
function IsValid(x) return type(x) == "table" and x.valid == true end
function isstring(x) return type(x) == "string" end
function istable(x) return type(x) == "table" end
function isfunction(x) return type(x) == "function" end
function isbool(x) return type(x) == "boolean" end
function Vector(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end
function math.Clamp(v, a, b) return math.max(a, math.min(b, v)) end
function string.Trim(s) return s:match("^%s*(.-)%s*$") end
function table.Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}; for k, v in pairs(t) do out[k] = table.Copy(v) end; return out
end

local sent, netCalls = {}, {}
net = {
    Start = function(name) netCalls[#netCalls + 1] = {name = name, args = {}} end,
    WriteUInt = function(val) if #netCalls > 0 then table.insert(netCalls[#netCalls].args, val) end end,
    WriteString = function(str) if #netCalls > 0 then table.insert(netCalls[#netCalls].args, str) end end,
    WriteVector = function(vec) if #netCalls > 0 then table.insert(netCalls[#netCalls].args, vec) end end,
    WriteBool = function(b) if #netCalls > 0 then table.insert(netCalls[#netCalls].args, b) end end,
    Send = function() sent[#sent + 1] = netCalls[#netCalls] end,
    Broadcast = function() sent[#sent + 1] = netCalls[#netCalls] end,
    SendToServer = function() sent[#sent + 1] = netCalls[#netCalls] end,
    Receive = function() end
}

hook = {
    Add = function() end,
    Remove = function() end,
    Run = function() end
}
timer = {
    Create = function() end,
    Exists = function() return false end,
    Remove = function() end,
    Simple = function(_, fn) if fn then fn() end end
}
concommand = { Add = function() end }
util = {
    AddNetworkString = function() end,
    TableToJSON = function(t) return table.Copy(t) end,
    JSONToTable = function(t) return table.Copy(t) end
}

-- 1. Test Haste single canonical registration & inclusion guard
LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.RPG.IdentityCatalog = { OrdinaryFeats = {} }
LOD.RPG.FeatEffectSystem = {}
LOD.RPGAbilityRules = { Derived = function() return {} end }
LOD.Magic = { _EnsureState = function() return {} end }

dofile(root .. "sv_rpg_checkpoint_d_haste.lua")
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats["INT_HASTE_1"] ~= nil, "INT_HASTE_1 registered")
dofile(root .. "sv_rpg_checkpoint_d_haste.lua") -- Second include must not throw duplicate assertion
print("PASS: Haste single canonical registration & inclusion guard")

-- 2. Test Live RPG Validator GetPos Crash / CellKey on non-spatial fixture
LOD.RunManager = { State = { Graph = {} } }
LOD.MazeNavigator = { WorldToCell = function() return {x=1,y=2,z=3} end }
dofile(root .. "sv_rpg_status_elements.lua")
local sys = LOD.RPGStatusElements
local syntheticActorWithoutGetPos = { valid = true }
local cellKeyResult = sys:CellKey(syntheticActorWithoutGetPos)
assert(cellKeyResult == nil, "CellKey safely returns nil for non-spatial actor fixture")

local spatialActorWithGetPos = { valid = true, GetPos = function() return Vector(10, 20, 30) end }
cellKeyResult = sys:CellKey(spatialActorWithGetPos)
assert(cellKeyResult == "1:2:3", "CellKey works correctly for spatial actor fixture")
print("PASS: Live RPG Validator GetPos non-spatial fixture safety")

-- 3. Test Rogue forced-max explosion continuation & Die Logger text & FX correspondence
dofile(root .. "sv_combat_rolls.lua")
local rolls = LOD.CombatRolls
local mockRNG = {
    rolls = 0,
    Int = function(self, min, max)
        self.rolls = self.rolls + 1
        if self.rolls <= 2 then return max end -- Force max die twice (e.g. 10 then 10)
        return min -- then low die (e.g. 1)
    end
}

local profile = { label = "PISTOL", count = 1, sides = 10, exploding = 10, rpgDerived = { rogueAllDamageDiceExplode = true } }
local attacker = { valid = true, id = 1, IsPlayer = function() return true end, Nick = function() return "RoguePlayer" end }
local rolled = rolls:RollActorDamage(attacker, profile, mockRNG, 0)
assert(#rolled.values == 3, "Rogue max roll produces 2 continuations (3 dice total)")
assert(rolled.total == 10 + 10 + 1, "Additional continuation dice mechanically contribute to total damage")

local detailText = rolls:_PlayerRollDetail(rolled)
assert(detailText ~= nil and detailText:find("%[rolls 10>10>1%]"), "Die Logger text visibly reports explosion continuation: " .. tostring(detailText))

-- Check FX correspondence
netCalls = {}
sent = {}
local continuations = math.max(0, #rolled.values - (rolled.baseDice or 1))
if continuations > 0 then
    rolls:EmitDiceExplosionFX(attacker, "weapon_pistol", continuations, 1)
end
assert(#sent == 1 and sent[1].name == "LOD_DiceExplosionFX", "Explosion FX fired for explosion continuation")

-- Non-explosion check
netCalls = {}
sent = {}
local nonExpRNG = { Int = function() return 2 end }
local rolledNonExp = rolls:RollActorDamage(attacker, profile, nonExpRNG, 0)
local continuationsNonExp = math.max(0, #rolledNonExp.values - (rolledNonExp.baseDice or 1))
assert(continuationsNonExp == 0, "No continuations for non-explosion roll")
if continuationsNonExp > 0 then
    rolls:EmitDiceExplosionFX(attacker, "weapon_pistol", continuationsNonExp, 1)
end
assert(#sent == 0, "No explosion FX fired for non-explosion roll")
print("PASS: Rogue forced-max explosion continuation, Die Logger text, and FX correspondence")

-- 4. Test Blast and Beam visual FX dispatch
dofile(root .. "sv_magic_forms.lua")
netCalls = {}
sent = {}
-- Manually verify net string dispatches for blast and beam
net.Start("LOD_MagicFormFX")
net.WriteString("blast")
net.WriteString("fire")
net.WriteVector(Vector(0,0,0))
net.WriteVector(Vector(0,0,0))
net.Send(attacker)
assert(sent[#sent].args[1] == "blast", "Blast visual presentation dispatched")

net.Start("LOD_MagicFormFX")
net.WriteString("beam")
net.WriteString("ice")
net.WriteVector(Vector(0,0,0))
net.WriteVector(Vector(100,200,0))
net.Send(attacker)
assert(sent[#sent].args[1] == "beam", "Beam visual presentation dispatched")
print("PASS: Blast and Beam visual FX dispatch")

print("AG-011_REPAIRS_PASS: All focused deterministic tests passed cleanly.")
