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
dofile(root .. "sh_rpg_schema.lua")
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
assert(detailText ~= nil and detailText:find("%[rolls 10@10%+ > 10@10%+ > 1@10%+ = 21 rolled%]"), "DIE-LOGGER text visibly reports explosion continuation: " .. tostring(detailText))

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
local productionApplyDamage=forms._ApplyDamage
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

-- An exploded shot with no target still has exactly one arithmetic record.
local originalRoll = rolls.RollPlayerWeapon
local pending = {}
local originalTimer = timer.Simple
timer.Simple = function(_, fn) pending[#pending+1] = fn end
rolls.RollPlayerWeapon = function()
    return {formula="1d10!", values={10,10,7}, contributions={10,10,7}, chainStarts={1},
        baseDice=1,total=27,created=CurTime(),weaponClass="weapon_pistol",label="PISTOL"}
end
local bullet={}
sent={};netCalls={}
hooks.EntityFireBullets.LOD_DicePlayerFirearms(attacker,bullet)
assert(bullet.Damage==27 and #sent==1 and sent[1].name=="LOD_DiceExplosionFX")
for _,fn in ipairs(pending) do fn() end
local miss=sent[#sent]
assert(miss.name=="LOD_CombatRoll" and miss.args[2]:find("1d10! (0)",1,true)
    and miss.args[2]:find("10 > 10 > 7 = 27 rolled",1,true),"exploded miss records all dice, subtotal and zero damage")
local n=#sent
for _,fn in ipairs(pending) do fn() end
assert(#sent==n,"duplicate cleanup cannot duplicate exploded miss record")
rolls.RollPlayerWeapon=originalRoll;timer.Simple=originalTimer

-- Zero-damage Magic still reports the rolled arithmetic; no damage is applied.
local oldMagicRoll, oldResolve=forms._RollDamage,rolls.ResolveActorDamage
forms._RollDamage=function() return {formula="2d6!",values={6,2,3},contributions={6,2,3},
    chainStarts={1,3},baseDice=2,total=11} end
rolls.ResolveActorDamage=function() return 0 end
victim1.Health=function() return 50 end
sent={};netCalls={}
assert(not productionApplyDamage(forms,attacker,attacker,victim1,{id="beam",damageDice=2,damageSides=6},nil,{},Vector(1,0,0)))
assert(sent[#sent].name=="LOD_CombatRoll" and sent[#sent].args[2]:find("2d6! (0)",1,true)
    and sent[#sent].args[2]:find("6 > 2 + 3 = 11 rolled",1,true))
forms._RollDamage=oldMagicRoll;rolls.ResolveActorDamage=oldResolve

-- Production Magnum callback carries earlier chains and fresh bonus dice into
-- the actual damage authority rather than losing values at the piercing seam.
local oldWeapon,oldActorRoll,oldTrace=attacker.GetActiveWeapon,rolls.RollActorDamage,util.TraceLine
local pierceRNG=rolls._RNG
rolls._RNG=function() return {} end
local magnum={valid=true,GetClass=function() return "weapon_357" end}
attacker.GetActiveWeapon=function() return magnum end
victim2.Health=function() return 100 end
local magnumContract={weaponClass="weapon_357",formula="1d12!",created=CurTime(),baseDice=1,
    values={12,10,5},contributions={12,10,5},thresholds={8,7,6},chainStarts={1},total=27,targets={}}
attacker.LODActivePlayerRoll=magnumContract
rolls.RollActorDamage=function() return {values={12,4},contributions={12,4},thresholds={8,7},
    chainStarts={1},baseDice=1,total=16} end
local traces=0
util.TraceLine=function()
    traces=traces+1
    return traces==1 and {Hit=true,HitPos=Vector(200,0,64),Entity=victim2} or {Hit=false}
end
DMG_BULLET=2;DMG_ENERGYBEAM=1024
function DamageInfo()
    return {SetAttacker=function(self,v) self.attacker=v end,GetAttacker=function(self) return self.attacker end,
        SetInflictor=function(self,v) self.inflictor=v end,GetInflictor=function(self) return self.inflictor end,
        SetDamage=function(self,v) self.damage=v end,GetDamage=function(self) return self.damage end,
        SetDamageType=function(self,v) self.kind=v end,IsDamageType=function(self,v) return self.kind==v end,
        SetDamagePosition=function() end,SetDamageForce=function() end}
end
victim2.TakeDamageInfo=function(self,info)
    hooks.EntityTakeDamage.LOD_DiceDamageAuthority(self,info)
    rolls:ReportResolvedDamage(info) -- final-defense observer seam
end
dofile(root .. "sv_magnum_piercing.lua")
local piercingBullet={Src=attacker:GetShootPos(),Dir=Vector(1,0,0)}
hooks.EntityFireBullets.LOD_MagnumPiercing(attacker,piercingBullet)
local firstInfo=DamageInfo();firstInfo:SetDamage(27)
sent={};netCalls={}
piercingBullet.Callback(attacker,{Entity=victim1,HitPos=Vector(100,0,64)},firstInfo)
local pierced=sent[#sent]
assert(pierced.name=="LOD_CombatRoll" and pierced.args[2]:find("2d12! (43)",1,true))
assert(pierced.args[2]:find("12@8+ > 10@7+ > 5@6+ + 12@8+ > 4@7+ = 43 rolled",1,true),
    "piercing retains original and new rolls, actual thresholds, independent starts and total")
attacker.GetActiveWeapon=oldWeapon;rolls.RollActorDamage=oldActorRoll;util.TraceLine=oldTrace;rolls._RNG=pierceRNG
print("PASS: zero-damage Magic and production Magnum piercing retain complete arithmetic")

-- Deferred shotgun summaries keep each target's own resistance snapshot and
-- still report a killing hit if the engine has already removed that target.
local deadTarget={valid=false}
local shell={formula="1d6!",values={6,4},contributions={6,4},chainStarts={1},baseDice=1,total=10,
    pellets=6,hits={[victim1]=2,[deadTarget]=3},damageByTarget={[victim1]=3,[deadTarget]=4},
    feedResolution={total=99,resistance=3,reduced={3,1}},
    resolutionByTarget={[victim1]={total=8,resistance=1,reduced={5,3}},
        [deadTarget]={total=6,resistance=2,reduced={4,2}}},targetNames={[deadTarget]="Defeated Soldier"}}
sent={};netCalls={}
rolls:_FinishShotgunFeed(attacker,shell)
assert(#sent==2 and shell.feedReported,"removed shotgun target does not become a false miss")
local seenOne,seenTwo=false,false
for _,packet in ipairs(sent) do
    local text=packet.args[2]
    if text:find("(3)",1,true) then seenOne=text:find("CON -1/die: 5 + 3 = 8",1,true)~=nil end
    if text:find("(4)",1,true) then seenTwo=text:find("CON -2/die: 4 + 2 = 6",1,true)~=nil end
    assert(not text:find("resolved 99",1,true),"cannot inherit last target's resolution")
end
assert(seenOne and seenTwo,"target-specific shotgun resistance detail")

-- HUD surfaces cannot draw paper or opaque panels; fonts and colors differ
-- from menu ink without changing the underlying semantic spans.
local drawings={}
local oldPaper=LOD.UI.Paper
LOD.UI.Paper=function() error("opaque paper in gameplay HUD") end
local oldRounded=draw.RoundedBox
draw.RoundedBox=function() error("opaque panel in gameplay HUD") end
draw.SimpleTextOutlined=function(text,font,x,y,color)
    drawings[#drawings+1]={text=text,font=font,x=x,y=y,color=color}
end
attacker.GetNW2Int=function(_,_,default) return default end
attacker.GetNW2Float=function(_,_,default) return default end
attacker.GetNW2Bool=function(_,_,default) return default end
surface.DrawCircle=function() end
surface.DrawPoly=function() end
dofile(root .. "cl_combat_roll_feed_semantics.lua")
dofile(root .. "cl_magic_hud.lua")
dofile(root .. "cl_hud.lua")
LOD.ClientState.synchronized=true;LOD.ClientState.ranked=true
LOD.ClientState.objective="FIND THE RED KEYCARD"
local hudFeed=LOD.CombatRollFeed
hudFeed.diceExplosion=nil
local hudText="Player dealt 1d10! (27) [rolls 10 > 10 > 7 = 27 rolled] damage to Enemy, via pistol"
hudFeed.entries={{text=hudText,family="routine",created=CurTime()}}
for _,size in ipairs({{1280,800},{1920,1080},{1024,768}}) do
    ScrW=function() return size[1] end;ScrH=function() return size[2] end
    drawings={}
    hooks.HUDPaint.LOD_PersistentHUD()
    hooks.HUDPaint.LOD_MagicHUD()
    hooks.HUDPaint.LOD_CombatRollFeed()
    local number,objective,dieColor=false,false,false
    for _,item in ipairs(drawings) do
        assert(item.x>=0 and item.x<size[1] and item.y>=0 and item.y<size[2],"HUD text remains on screen")
        if item.font=="HudNumbers" then number=true end
        if item.text:find("KEYCARD",1,true) then objective=true end
        if item.color.r==LOD.UI.HUDRoles.dice.r and item.color.b==LOD.UI.HUDRoles.dice.b then dieColor=true end
    end
    assert(number and objective and dieColor,"stock Magic font, objective text and luminous dice spans")
end
LOD.UI.Paper=oldPaper;draw.RoundedBox=oldRounded
print("PASS: transparent HUD at Deck/desktop/4:3 sizes and exploded-miss production settlement")

-- Execute the bomb's real shared/server/client entry points with bounded render
-- seams. Cosmetic bomb rendering never creates a laser trail or dynamic light.
local entRoot="gamemodes/legend_of_deborah/entities/entities/lod_magic_projectile/"
local env=setmetatable({ENT={},AddCSLuaFile=function() end},{__index=_G})
env.include=function(name) assert(loadfile(entRoot..name,"t",env))() end
env.include("shared.lua")
local bomb=setmetatable({valid=true},{__index=env.ENT})
bomb.NetworkVar=function(self,kind,index,name)
    assert(kind=="String" and index==0 and name=="MagicForm")
    self.SetMagicForm=function(self,value) self.form=value end
    self.GetMagicForm=function(self) return self.form end
end
bomb:SetupDataTables()
local trailCount=0
local savedTrail=util.SpriteTrail
util.SpriteTrail=function() trailCount=trailCount+1 end
assert(loadfile(entRoot.."init.lua","t",env))()
local noop=function() end
for _,name in ipairs({"SetModel","SetMoveType","SetSolid","SetCollisionGroup","DrawShadow","SetRenderMode","SetColor"}) do bomb[name]=noop end
bomb.LODFormId="bomb";bomb.LODDirection=Vector(1,0,0)
bomb:Initialize()
assert(bomb:GetMagicForm()=="bomb" and trailCount==0,"bomb identity replicated and no missile trail")
assert(bomb.LODVelocity.x==900 and bomb.LODVelocity.z==240,"existing lob launch velocity preserved")
local spheres,fuses,lights=0,0,0
local oldRender=render
env.render={SetMaterial=noop,DrawSphere=function(_,radius) assert(radius==6);spheres=spheres+1 end,
    DrawBox=noop,DrawBeam=function() fuses=fuses+1 end,DrawSprite=noop}
env.DynamicLight=function() lights=lights+1 end
assert(loadfile(entRoot.."cl_init.lua","t",env))()
bomb.GetPos=function() return Vector() end
bomb.GetAngles=function() return {Up=function() return Vector(0,0,1) end,Right=function() return Vector(0,1,0) end} end
bomb.EntIndex=function() return 7 end
bomb.DrawModel=function() error("bomb must not draw its old missile-like model") end
bomb:Draw()
assert(spheres==1 and fuses==5 and lights==0,"sphere, bent fuse and three sparks, no dynamic lights")
util.SpriteTrail=savedTrail
print("PASS: replicated bomb identity, unchanged lob, round body/fuse render and bounded sparks")

print("AG-011R1_REPAIRS_PASS: All focused deterministic tests passed cleanly.")
