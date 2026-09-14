-- Deterministic test harness for AG-011R1 Big Playtest Repairs
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
function Color(r, g, b, a) return {r = r or 0, g = g or 0, b = b or 0, a = a or 255} end
DMG_BLAST = 64
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

local hooks = {}
hook = {
    Add = function(event, id, fn) hooks[event] = hooks[event] or {}; hooks[event][id] = fn end,
    Remove = function(event, id) if hooks[event] then hooks[event][id] = nil end end,
    Run = function(event, ...) for _, fn in pairs(hooks[event] or {}) do fn(...) end end
}
local timers = {}
timer = {
    Create = function(id, _, _, fn) timers[id] = fn end,
    Exists = function(id) return timers[id] ~= nil end,
    Remove = function(id) timers[id] = nil end,
    Simple = function(_, fn) if fn then fn() end end
}
concommand = { Add = function() end }
util = {
    AddNetworkString = function() end,
    TableToJSON = function(t) return table.Copy(t) end,
    JSONToTable = function(t) return table.Copy(t) end
}
file = {
    Exists = function() return false end,
    Read = function() return "" end,
    Write = function() end,
    CreateDir = function() end
}
function ScrW() return 1280 end
function ScrH() return 800 end
surface = {
    CreateFont = function() end,
    SetFont = function() end,
    GetTextSize = function(s) return #s * 7, 16 end,
    PlaySound = function() end,
    SetDrawColor = function() end,
    DrawOutlinedRect = function() end,
    DrawRect = function() end
}
draw = { RoundedBox = function() end, SimpleTextOutlined = function() end, SimpleText = function() end }

-- Mock VGUI system to test Feed:OpenHistory construction
local createdPanels = {}
vgui = {
    Create = function(class, parent)
        local panel = {
            valid = true,
            class = class,
            parent = parent,
            children = {},
            SetSize = function(self, w, h) self.w, self.h = w, h end,
            SetTall = function(self, h) self.h = h end,
            GetWide = function(self) return self.w or 100 end,
            GetTall = function(self) return self.h or 100 end,
            Center = function() end,
            SetTitle = function(self, t) self.title = t end,
            ShowCloseButton = function() end,
            SetDraggable = function() end,
            MakePopup = function() end,
            SetText = function(self, text) self.text = text end,
            SetFont = function() end,
            SetTextColor = function() end,
            SetPos = function(self, x, y) self.x, self.y = x, y end,
            Dock = function() end,
            DockMargin = function() end,
            SetWrap = function() end,
            SetAutoStretchVertical = function() end,
            InvalidateLayout = function() end,
            IsHovered = function() return false end,
            Remove = function(self) self.valid = false end,
            Clear = function(self) self.children = {} end,
            GetVBar = function() return {SetScroll=function() end} end,
            GetCanvas = function() return { Paint = function() end } end
        }
        if parent and parent.children then
            parent.children[#parent.children + 1] = panel
        end
        createdPanels[#createdPanels + 1] = panel
        return panel
    end
}

-- 1. Test Haste single canonical registration & inclusion guard
LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.RPG.IdentityCatalog = { OrdinaryFeats = {} }
LOD.RPG.FeatEffectSystem = {}
LOD.RPGAbilityRules = {
    Derived = function() return { rogueAllDamageDiceExplode = true } end,
    CopyDamageProfile = function(self, profile, ply)
        local copy = table.Copy(profile or {})
        copy.rpgDerived = self:Derived(ply)
        return copy
    end,
    ResolveDamageContract = function(self, contract) return contract.total or 10 end
}
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

-- 3. Test DIE-LOGGER OpenHistory VGUI Construction (Defect 1)
dofile(root .. "sh_die_logger.lua")
dofile(root .. "cl_ui_theme.lua")
dofile(root .. "cl_combat_roll_feed.lua")
dofile(root .. "cl_feedback_language.lua")
dofile(root .. "cl_combat_roll_feed_semantics.lua")
local feed = LOD.CombatRollFeed
feed.history = {
    { stamp = "09-13 12:00:00", text = "Test event 1" },
    { stamp = "09-13 12:00:05", text = "Test event 2 [rolls 10>10>5]" }
}
local frame = feed:OpenHistory()
assert(IsValid(frame), "Feed:OpenHistory returned valid DFrame")
assert(frame.w <= ScrW() - 40 and frame.h <= ScrH() - 40 and frame.w > 0 and frame.h > 0, "Frame size computed without variable scope error")

-- Search for title label text
local titleFound = false
for _, p in ipairs(createdPanels) do
    if p.text == "THE LEGEND OF DEBORAH / DIE-LOGGER" then
        titleFound = true
        break
    end
end
assert(titleFound, "DIE-LOGGER title correctly set to THE LEGEND OF DEBORAH / DIE-LOGGER")
print("PASS: Feed:OpenHistory VGUI construction and scope validity")

-- 4. Test Rogue forced-max explosion continuation & DIE-LOGGER text & FX correspondence
dofile(root .. "sv_combat_rolls.lua")
player = {GetAll = function() return {} end}
dofile(root .. "sv_combat_feed_semantics.lua")
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
local attacker = {
    valid = true, id = 1, IsPlayer = function() return true end, Nick = function() return "RoguePlayer" end,
    Alive = function() return true end, GetActiveWeapon = function() return { valid = true, GetClass = function() return "weapon_pistol" end } end
}
local rolled = rolls:RollActorDamage(attacker, profile, mockRNG, 0)
assert(#rolled.values == 3, "Rogue max roll produces 2 continuations (3 dice total)")
assert(rolled.total == 10 + 10 + 1, "Additional continuation dice mechanically contribute to total damage")

local detailText = rolls:_PlayerRollDetail(rolled)
assert(detailText ~= nil and detailText:find("%[rolls 10@10%+ > 10@10%+ > 1@10%+%]"), "DIE-LOGGER text visibly reports explosion continuation: " .. tostring(detailText))

-- Check single FX correspondence for pistol
netCalls = {}
sent = {}
local continuations = math.max(0, #rolled.values - (rolled.baseDice or 1))
if continuations > 0 then
    rolls:EmitDiceExplosionFX(attacker, "weapon_pistol", continuations, 1)
end
assert(#sent == 1 and sent[1].name == "LOD_DiceExplosionFX", "Explosion FX fired for explosion continuation")
print("PASS: Rogue forced-max explosion continuation & DIE-LOGGER text")

-- 5. Test Grenade Explosion-FX Multiplicity Gated to 1 Per Grenade Attack (Defect 2)
netCalls = {}
sent = {}
local grenadeRNG = {
    rolls = 0,
    Int = function(self, min, max)
        self.rolls = self.rolls + 1
        if self.rolls == 1 then return 20 end -- Exploding d20!
        return 5
    end
}
-- Override RNG for grenade roll test
local origRNG = rolls._RNG
rolls._RNG = function() return grenadeRNG end

local inflictorEntity = { valid = true, GetClass = function() return "npc_grenade_frag" end, LODAimMultiplier = 1 }
local victim1 = { valid = true, LODHostile = true, IsPlayer = function() return false end, EntIndex = function() return 10 end }
local victim2 = { valid = true, LODHostile = true, IsPlayer = function() return false end, EntIndex = function() return 11 end }
local fakeDmgInfo1 = {
    IsDamageType = function(_, t) return t == 64 end, -- DMG_BLAST
    GetAttacker = function() return attacker end,
    GetInflictor = function() return inflictorEntity end,
    GetDamage = function() return 100 end,
    SetDamage = function(self, d) self.dmg = d end
}
local fakeDmgInfo2 = {
    IsDamageType = function(_, t) return t == 64 end,
    GetAttacker = function() return attacker end,
    GetInflictor = function() return inflictorEntity end,
    GetDamage = function() return 80 end,
    SetDamage = function(self, d) self.dmg = d end
}

-- Simulate hit on victim 1
hooks["EntityTakeDamage"]["LOD_DiceDamageAuthority"](victim1, fakeDmgInfo1)
-- Simulate hit on victim 2 (same grenade inflictor)
hooks["EntityTakeDamage"]["LOD_DiceDamageAuthority"](victim2, fakeDmgInfo2)

local explosionFXCount = 0
for _, packet in ipairs(sent) do
    if packet.name == "LOD_DiceExplosionFX" then
        explosionFXCount = explosionFXCount + 1
    end
end
assert(explosionFXCount == 1, "Grenade explosion FX emitted EXACTLY ONCE for multi-target hit (got " .. tostring(explosionFXCount) .. ")")

-- Non-exploding grenade test
netCalls = {}
sent = {}
local nonExpGrenadeRNG = { Int = function() return 10 end }
rolls._RNG = function() return nonExpGrenadeRNG end

local nonExpInflictor = { valid = true, GetClass = function() return "npc_grenade_frag" end }
local nonExpDmgInfo = {
    IsDamageType = function(_, t) return t == 64 end,
    GetAttacker = function() return attacker end,
    GetInflictor = function() return nonExpInflictor end,
    GetDamage = function() return 100 end,
    SetDamage = function() end
}
hooks["EntityTakeDamage"]["LOD_DiceDamageAuthority"](victim1, nonExpDmgInfo)
hooks["EntityTakeDamage"]["LOD_DiceDamageAuthority"](victim2, nonExpDmgInfo)

local nonExpFXCount = 0
for _, packet in ipairs(sent) do
    if packet.name == "LOD_DiceExplosionFX" then nonExpFXCount = nonExpFXCount + 1 end
end
assert(nonExpFXCount == 0, "Non-exploding grenade emits ZERO explosion FX")
rolls._RNG = origRNG
print("PASS: Grenade explosion-FX multiplicity gated to exactly 1 per attack contract")

-- 6. Execute the production Blast/Beam paths and consume their actual FX packets.
local vec = {}; vec.__index=vec
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
function vec.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function vec.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function vec.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function vec:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function vec:GetNormalized() local n=math.sqrt(self:LengthSqr());return self*(1/math.max(n,0.001)) end
function vec:Distance(other) return math.sqrt((self-other):LengthSqr()) end
function vec:DistToSqr(other) return (self-other):LengthSqr() end
vector_origin=Vector()
NULL={}
LOD.CharacterProgressionSystem={}
LOD.MagicProgression={}
LOD.RPG.Constants={}
net.WriteEntity=function(ent) table.insert(netCalls[#netCalls].args,ent) end
attacker.GetShootPos=function() return Vector(0,0,64) end
attacker.GetAimVector=function() return Vector(1,0,0) end
attacker.EyePos=attacker.GetShootPos
LOD.Config={CellSize=192}
player.GetAll=function() return {attacker} end
dofile(root .. "sv_magic_forms.lua")
local forms=assert(LOD.MagicForms)
local hits={}
forms._BlastTargets=function() return {victim1,victim2} end
forms._ApplyDamage=function(_,_,_,target) hits[#hits+1]=target;return true end
assert(forms:_CastBlast(attacker,{id="blast"},{id="fire"},{spatialBonusCells=0}))
local blast=sent[#sent]
assert(#hits==2 and blast.name=="LOD_MagicFormFX" and blast.args[1]=="blast" and blast.args[5]==attacker)
local traceCalls=0
local wall=Vector(300,0,64)
util.TraceLine=function(spec)
    traceCalls=traceCalls+1
    if traceCalls==1 then return {Hit=true,HitPos=Vector(100,0,64),Entity=victim1} end
    if traceCalls==2 then
        assert(spec.filter[#spec.filter]==victim1,"pierced body is ignored")
        return {Hit=true,HitPos=Vector(200,0,64),Entity=victim2}
    end
    assert(spec.filter[#spec.filter]==victim2,"second body is ignored")
    return {Hit=true,HitPos=wall,Entity=NULL}
end
hits={}
assert(forms:_CastBeam(attacker,{id="beam"},{id="fire"},{spatialBonusCells=0}))
local beam=sent[#sent]
assert(#hits==2 and hits[1]==victim1 and hits[2]==victim2 and traceCalls==3)
assert(beam.args[1]=="beam" and beam.args[4]==wall and beam.args[5]==attacker,
    "Beam effect endpoint is the production blocking trace; caster is explicit")

-- Real FX receiver/renderer, including bounded bursts and depth/skybox exclusion.
local receives={}
net.Receive=function(name,fn) receives[name]=fn end
local reading,cursor
local function read() cursor=cursor+1;return reading[cursor] end
net.ReadString=read;net.ReadVector=read;net.ReadEntity=read
function Material(path) return path end
function LocalPlayer() return attacker end
local beams,sprites,material=0,0,nil
render={SetMaterial=function(m) material=m end,
    DrawBeam=function(_,_,_,_,_,color)
        beams=beams+1
        if material=="trails/laser" and color.r~=255 then assert(color.b==255 and color.g==185,"Beam cyan core survives FIRE Content") end
    end,
    DrawSprite=function() sprites=sprites+1 end}
surface.DrawLine=function() end
dofile(root .. "cl_magic_form_fx.lua")
local function deliver(packet) reading,cursor=packet.args,0;receives[packet.name]() end
deliver(blast);deliver(beam)
hooks.PostDrawTranslucentRenderables.LOD_MagicFormPresentation(true,false)
assert(beams==0,"no effects in depth prepass")
hooks.PostDrawTranslucentRenderables.LOD_MagicFormPresentation(false,true)
assert(beams==0,"no effects in skybox")
hooks.PostDrawTranslucentRenderables.LOD_MagicFormPresentation(false,false)
assert(beams>30 and sprites>0,"actual Blast arcs and Beam are rendered")
for i=1,200 do deliver(beam) end
beams=0
hooks.PostDrawTranslucentRenderables.LOD_MagicFormPresentation(false,false)
assert(beams==96,"at most 48 two-layer Beam effects retained under burst")
hooks.HUDPaint.LOD_MagicLocalCast()
print("PASS: production Blast/Beam hits, actual trace endpoint, caster-local cue, bounded client rendering")

-- Closing a pending Spellbook request cancels it; a late response only caches data.
gui={IsConsoleVisible=function() return false end};chat={IsTyping=function() return false end}
dofile(root .. "cl_spellbook.lua")
local book=LOD.Spellbook
book:Open();assert(book.PendingOpen)
book:Close();assert(not book.PendingOpen)
net.ReadTable=function() return {forms={},contents={}} end
receives.LOD_MagicSpellbookSnapshot()
assert(book.Snapshot and not IsValid(book.Frame) and not book.PendingOpen)
book.Snapshot=nil;book:Open();LOD.UI:SelectPage("sheet")
receives.LOD_MagicSpellbookSnapshot()
assert(LOD.UI.ActivePage=="sheet" and not IsValid(book.Frame),"late I response cannot replace selected P page")
print("PASS: dismissed and superseded Spellbook requests remain closed")

print("AG-011R1_REPAIRS_PASS: All focused deterministic tests passed cleanly.")
