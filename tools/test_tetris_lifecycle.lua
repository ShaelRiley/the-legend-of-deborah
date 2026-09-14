-- Production death-session/input authority with deterministic engine boundaries.
SERVER = true
local clock, action = 100, 0
local callbacks, receivers, hooks = {}, {}, {}
local function noop() end
CurTime = function() return clock end
IsValid = function(v) return type(v) == "table" and v.valid == true end
isstring = function(v) return type(v) == "string" end
math.Clamp = function(v, low, high) return math.max(low, math.min(high, v)) end
util = {AddNetworkString = noop}
net = {Receive = function(name, fn)
    assert(not receivers[name], "duplicate receiver: " .. name)
    receivers[name] = fn
end, ReadUInt = function() return action end, Start = noop, Send = noop,
    WriteUInt = noop, WriteInt = noop, WriteBool = noop}
timer = {Simple = function(_, fn) callbacks[#callbacks+1] = fn end}
hook = {Add = function(event, name, fn)
    hooks[event] = hooks[event] or {}; hooks[event][name] = fn
end}
local ply = {valid = true, alive = false, nw = {}, spawns = 0, LODRunSpawnSerial = 1}
function ply:Alive() return self.alive end
function ply:SetNW2Bool(k, v) self.nw[k] = v end
ply.SetNW2Float = ply.SetNW2Bool
ply.SetNW2Int = ply.SetNW2Bool
ply.UnSpectate = noop
function ply:Spawn() self.spawns = self.spawns + 1; self.alive = true end
player = {GetAll = function() return {ply} end}
local ps = {lives = 3, respawnAt = 120, nextLifeHPBonus = 0}
local active = true
LOD = {Config = {Lives = {RespawnDelay = 20}}, RunManager = {State = {LevelSeed = 123}}}
local run = LOD.RunManager
function run:IdentityOf(p) return p == ply and "hero" or nil end
function run:GetPlayerState(p) return (p == ply or p == "hero") and ps or nil end
function run:IsActivePlayer(p) return active and p == ply end
local base = "gamemodes/legend_of_deborah/gamemode/lod/"
dofile(base .. "sh_rng.lua")
dofile(base .. "sh_tetris.lua")
dofile(base .. "sv_death_tetris.lua")
local death = LOD.DeathTetris
local state = assert(death:StartDeath(ply, 120))
clock = 105
assert(death:StartDeath(ply, 125) == state and state.mandatoryEndsAt == 120
    and state.hardCapAt == 160, "duplicate death must preserve both deadlines")
local session = assert(death:StartSession(ply, "death"))
-- Set up a real two-line clear, then invoke the actual network action and board.
for y = 19, 20 do
    for x = 1, 10 do session.game.board[y][x] = x <= 2 and 0 or 1 end
end
session.game.current = {id = 2, rotation = 1, x = 0, y = 1}
action = 5
receivers.LOD_TetrisInput(0, ply)
assert(ps.nextLifeHPBonus == 30 and session.lastClearLines == 2,
    "real two-line clear grants canonical overfill")
assert(death:GetMandatoryRemaining(ply) == 15 and ply.nw.LOD_RespawnRemaining == 15,
    "line clears must not shorten the mandatory wait or its HUD readout")
action = 2
receivers.LOD_DeathTetrisAction(0, ply)
assert(ply.spawns == 0, "respawn before twenty seconds is rejected")
clock = 120; active = false
receivers.LOD_DeathTetrisAction(0, ply)
assert(ply.spawns == 0, "inactive slot cannot authorize respawn")
active = true
receivers.LOD_DeathTetrisAction(0, ply)
assert(ply.spawns == 1 and not death.Deaths.hero and not death.Sessions.hero,
    "exactly twenty seconds permits respawn and retires the session")
assert(ps.nextLifeHPBonus == 30, "overfill survives until the Hero spawn authority consumes it")

-- A delayed death observer cannot author a session for a new body or campaign.
ply.alive = false; ps.respawnAt = 140
hooks.PlayerDeath.LOD_DeathTetrisPrepare(ply)
ply.LODRunSpawnSerial = 2
callbacks[#callbacks]()
assert(not death.Deaths.hero, "old-body death callback ignored")
hooks.PlayerDeath.LOD_DeathTetrisPrepare(ply)
run.State = {LevelSeed = 123}
callbacks[#callbacks]()
assert(not death.Deaths.hero, "old-campaign death callback ignored")
hooks.PlayerDeath.LOD_DeathTetrisPrepare(ply)
callbacks[#callbacks]()
assert(death.Deaths.hero, "current dead body receives its session")
hooks.PlayerSpawn.LOD_DeathTetrisEndOnSpawn(ply)
assert(not death.Deaths.hero, "spawn synchronously retires the old session")
print("TETRIS_LIFECYCLE_PASS: immutable deadline, real line clear, ownership, stale callbacks")
