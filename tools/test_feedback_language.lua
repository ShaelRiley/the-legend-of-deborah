-- Finite server/client transport + observer isolation + real Magic transaction gate.
local root = "gamemodes/legend_of_deborah/gamemode/lod/"
unpack = table.unpack
local clock, dev = 100, true
function CurTime() return clock end
RealTime = CurTime
function IsValid(x) return type(x) == "table" and x.valid == true end
function isstring(x) return type(x) == "string" end
function istable(x) return type(x) == "table" end
function math.Clamp(v, a, b) return math.max(a, math.min(b, v)) end
function string.Trim(s) return s:match("^%s*(.-)%s*$") end
function table.Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}; for k, v in pairs(t) do out[k] = table.Copy(v) end; return out
end
local errors = {}
function ErrorNoHalt(s) errors[#errors + 1] = s end
function GetConVar() return {GetBool = function() return dev end} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
local hooks, timers, receives, sent, logs = {}, {}, {}, {}, {}
hook = {Add = function(event, id, fn) hooks[event] = hooks[event] or {}; hooks[event][id] = fn end,
    Remove = function(event, id) if hooks[event] then hooks[event][id] = nil end end,
    Run = function(event, ...) for _, fn in pairs(hooks[event] or {}) do fn(...) end end}
timer = {Create = function(id, _, _, fn) timers[id] = fn end, Exists = function(id) return timers[id] ~= nil end,
    Remove = function(id) timers[id] = nil end, Simple = function() end}
concommand = {Add = function() end}
util = {AddNetworkString = function() end, TableToJSON = function(t) return table.Copy(t) end,
    JSONToTable = function(t) return table.Copy(t) end}
local packet, reading, cursor
local function write(value, width) packet[#packet + 1] = {value, width} end
local function read(width)
    cursor = cursor + 1; assert(reading[cursor][2] == width, "wire schema mismatch")
    return reading[cursor][1]
end
net = {Start = function(name) packet = {name = name} end,
    WriteUInt = write, WriteString = function(s) write(s, "string") end,
    WriteBool = function(b) write(b, "bool") end,
    WriteVector = function(v) write(v,"vector") end,
    ReadUInt = read, ReadString = function() return read("string") end,
    ReadBool = function() return read("bool") end,
    ReadVector = function() return read("vector") end,
    Send = function(ply) packet.ply = ply; sent[#sent+1] = packet end,
    SendToServer = function() sent[#sent+1] = packet end,
    Receive = function(name, fn) receives[name] = fn end}
local function deliver(p, ply, receiver)
    reading, cursor = p, 0; (receiver or receives[p.name])(0, ply)
end
local function actor(id, human)
    return {valid = true, id = id, IsPlayer = function() return human end,
        EntIndex = function() return id end, Nick = function() return "Player" .. id end,
        GetClass = function() return "enemy" end, Alive = function() return true end, EmitSound = function() end}
end
local a, b, enemy = actor(1,true), actor(2,true), actor(3,false)
player = {GetAll = function() return {a,b} end}
local states = {[a] = {lives = 3, progressionState = {xp = 0}}, [b] = {lives = 3, progressionState = {xp = 0}}}
LOD = {RPG = {}, RPGPresentation = {}, CombatRolls = {Stats = {}},
    RPGTestLog = {Write = function(_, name, fields) logs[#logs+1] = {name = name, fields = fields} end},
    RunManager = {State = {CampaignEpoch = 1, Level = 1},
        IdentityOf = function(_, ply) return tostring(ply.id) end,
        GetPlayerState = function(_, who) if who == "1" then who = a end; return states[who] end,
        _SyncPlayerVars = function() return nil, "sync", nil, 4 end,
        IsSoldierControl = function(_, ply) return ply.soldier == true end}}
dofile(root .. "sh_die_logger.lua")
dofile(root .. "sh_feedback_language.lua")
dofile(root .. "sv_feedback_language.lua")
dofile(root .. "sv_combat_feed_semantics.lua")
local P, rolls = LOD.RPGPresentation, LOD.CombatRolls
local ackReceiver = receives.LOD_FeedbackAck
P:Event(a, "status", "HELD APPLIED", {event = "test_apply"}, "held")
assert(#sent == 1 and logs[1].fields.event == "test_apply")
local first = sent[1]
P:Event(a, "status", "HELD APPLIED", nil, "held")
assert(#sent == 1 and logs[#logs].name == "FEEDBACK_SUPPRESSED")
P:Event(b, "status", "HELD APPLIED", nil, "held")
assert(#sent == 2, "recipient cooldown isolation")
rolls:_Send(a, 0, string.rep("x", 5000))
assert(#sent[#sent][2][1] == 4096, "bounded complete transport")
dev = false; rolls:_Send(a, 0, "quiet"); assert(sent[#sent][5][1] == false); dev = true

local baseCalls = 0
LOD.RPGStatusElements = {Active = {},
    Apply = function(_, target, id, source)
        baseCalls = baseCalls + 1
        return false, "saved", {save = 17, dc = 12}, nil, "sentinel"
    end}
LOD.CharacterProgressionSystem = {AwardHeroXP = function(_, who, xp)
    states[who].progressionState.xp = states[who].progressionState.xp + xp
    return nil, "preserved", nil, 7
end}
dofile(root .. "sv_feedback_observers.lua")
local result = table.pack(LOD.RPGStatusElements:Apply(enemy, "held", a))
assert(result.n == 5 and result[5] == "sentinel" and baseCalls == 1, "authority called once; all returns preserved")
assert(logs[#logs].fields.outcome == "saved" and logs[#logs].fields.save == 17)
result = table.pack(LOD.CharacterProgressionSystem:AwardHeroXP(a, 12))
assert(result.n == 4 and result[4] == 7 and states[a].progressionState.xp == 12)
local realEvent = P.Event; P.Event = function() error("deliberate observer failure") end
result = table.pack(LOD.CharacterProgressionSystem:AwardHeroXP(a, 2))
assert(result[4] == 7 and states[a].progressionState.xp == 14 and #errors == 1,
    "presentation failure cannot change authority outcome")
P.Event = realEvent; errors = {}
LOD.RunManager:_SyncPlayerVars(a)
states[a].lives = 2; LOD.RunManager:_SyncPlayerVars(a)
assert(logs[#logs].fields.event == "life_lost")
states[a].lives = 0; states[a].eliminated = true; LOD.RunManager:_SyncPlayerVars(a)
assert(logs[#logs].fields.text:find("ELIMINATED"))
states[a].lives = 1; states[a].eliminated = false; LOD.RunManager:_SyncPlayerVars(a)
assert(logs[#logs].fields.text:find("REVIVED"))
local n = #sent; LOD.RunManager:_SyncPlayerVars(a); assert(#sent == n, "unchanged sync is silent")

-- Exercise real CastSelected with bounded spatial seams, preserving cost/refund/cooldown.
local ps, form, content = {magic = 50}, {id = "blast", magicCost = 20}, {id = "fire", surcharge = 5}
LOD.Magic = {NextCast = {}, Stats = {casts = 0}, _EnsureState = function() return ps end, _Sync = function() end}
LOD.MagicProgression = {}
local spentEvents=0
LOD.RPG.PrepareCheckpointDAuraBurst=function() return {prepared=true} end
hook.Add("LODDiscreteMagicSpent","test_spend_observer",function(_,cost,context)
    assert(cost>0 and context.auraBurst.prepared)
    spentEvents=spentEvents+1
end)
LOD.RPGAbilityRules = {OffensiveMagicCost = function(_, _, cost) return cost end,
    CommitAttack=function(_,actor) actor.LODRPGNextAceReadyAt=clock+3;return true end}
LOD.RPGStatusElements.CanInitiateMagic = function() return true end
dofile(root .. "sv_magic_forms.lua")
local forms = LOD.MagicForms
forms.SelectedCastState = function() return {}, form, content end
forms._NewContext = function() return {} end
forms._CanCastPreSpend = function() return true end
forms._CastBlast = function() return true end
assert(forms:CastSelected(a) == true and ps.magic == 25)
assert(spentEvents==1,"one successful discrete activation event")
assert(logs[#logs].fields.spent == 25 and logs[#logs].fields.outcome == "committed")
clock = clock + 2; ps.magic = 10
local ok, reason = forms:CastSelected(a)
assert(not ok and reason == "magic" and ps.magic == 10)
assert(logs[#logs].fields.spent == 0 and logs[#logs].fields.text:find("insufficient Magic"))
clock = clock + 2; ps.magic = 50; local cooldown = LOD.Magic.NextCast[a]
local previousAce=a.LODRPGNextAceReadyAt
forms._CastBlast = function() return false end
ok, reason = forms:CastSelected(a)
assert(not ok and reason == "cast" and ps.magic == 50 and LOD.Magic.NextCast[a] == cooldown)
assert(logs[#logs].fields.outcome == "cast" and logs[#logs].fields.spent == 0)
assert(spentEvents==1 and a.LODRPGNextAceReadyAt==previousAce,"failed casts neither emit spend nor consume priming")

-- Execute actual client receiver/renderer and round-trip its acknowledgments.
local disk, sounds = {}, {}
file = {Exists = function(path) return disk[path] ~= nil end, Read = function(path) return disk[path] end,
    Write = function(path, data) disk[path] = data end, CreateDir = function() end}
surface = {CreateFont = function() end, SetFont = function() end, GetTextSize = function(s) return #s * 7, 16 end,
    PlaySound = function(s) sounds[#sounds + 1] = s end, SetDrawColor = function() end,
    DrawOutlinedRect = function() end, DrawRect = function() end}
draw = {RoundedBox = function() end, SimpleTextOutlined = function() end, SimpleText = function() end}
function ScrW() return 1280 end
function ScrH() return 800 end
dofile(root .. "cl_ui_theme.lua")
dofile(root .. "cl_combat_roll_feed.lua")
dofile(root .. "cl_feedback_language.lua")
dofile(root .. "cl_combat_roll_feed_semantics.lua")
local feed = LOD.CombatRollFeed
clock = 101 -- first packet still inside ACK validity window
deliver(first)
assert(#feed.entries == 1 and #feed.history == 1 and #sounds == 1)
local receivedAck = sent[#sent]
deliver(receivedAck, b, ackReceiver) -- guessed serial from another player must fail
assert(logs[#logs].name ~= "FEEDBACK_CLIENT_ACK")
deliver(receivedAck, a, ackReceiver)
assert(logs[#logs].fields.stage == "received" and logs[#logs].fields.history_retained)
hooks.HUDPaint.LOD_CombatRollFeed()
local drawnAck = sent[#sent]; deliver(drawnAck, a, ackReceiver)
assert(logs[#logs].fields.stage == "drawn")
n = #sent; hooks.HUDPaint.LOD_CombatRollFeed(); assert(#sent == n, "no per-frame ACK traffic")
-- Hidden by congestion != lost history. Sound cap applies even with rapid entries.
deliver(first)
assert(#feed.history == 1, "duplicate packet cannot replay history or sound")
for i = 1, 1010 do
    local distinct = table.Copy(first); distinct[3][1] = 10000+i
    deliver(distinct)
end
assert(#feed.entries == 10 and #feed.history == 1000 and #sounds == 1)
local saveFn = timers.LOD_DieLoggerSave or hooks.ShutDown.LOD_DieLoggerSave
saveFn()
assert(disk["legend_of_deborah/die_logger_history.json"] ~= nil, "die_logger_history.json written")
LOD.CombatRollFeed = {entries = {}}
dofile(root .. "cl_feedback_language.lua")
assert(#LOD.CombatRollFeed.history == 1000, "history survives reload from die_logger_history.json")

-- Test fallback migration from legacy dialogger_history.json
disk["legend_of_deborah/die_logger_history.json"] = nil
disk["legend_of_deborah/dialogger_history.json"] = util.TableToJSON({{text = "legacy history test", stamp = "01-01 00:00:00"}})
LOD.CombatRollFeed = {entries = {}}
dofile(root .. "cl_feedback_language.lua")
assert(#LOD.CombatRollFeed.history == 1 and LOD.CombatRollFeed.history[1].text == "legacy history test",
    "fallback migration loads legacy history")

feed = LOD.CombatRollFeed
dofile(root .. "cl_combat_roll_feed_semantics.lua")
feed:RetainFeedback({text = "PROGRESS", family = "progress"})
hooks.HUDPaint.LOD_FeedbackNotice()
assert(feed.notice.entry.text == "PROGRESS")
feed:RetainFeedback({text = "LIFE LOST", family = "danger"})
hooks.HUDPaint.LOD_FeedbackNotice()
assert(feed.notice.entry.text == "LIFE LOST", "danger preempts ordinary progression")
for i = 1, 20 do feed:RetainFeedback({text = "NEW FORM", family = "progress"}) end
assert(#feed.notices <= 8, "bounded critical queue")

-- The canonical summary exposes client stages instead of conflating dispatch and display.
function isbool(x) return type(x) == "boolean" end
function isfunction(x) return type(x) == "function" end
game = {GetMap = function() return "gm_flatgrass" end}
engine = {ActiveGamemode = function() return "legend_of_deborah" end}
file.Append = function() end
dofile("lua/autorun/server/lod_rpg_test_session_summary.lua")
local summary = LOD.RPGTestSessionSummary
summary:BeginSession("feedback harness")
summary:Record(1, clock, "FEEDBACK_DISPATCH", {serial = 1})
summary:Record(2, clock, "FEEDBACK_CLIENT_ACK", {serial = 1, stage = "received", sound_requested = true})
summary:Record(3, clock, "FEEDBACK_CLIENT_ACK", {serial = 1, stage = "drawn"})
assert(summary.Feedback.dispatched == 1 and summary.Feedback.received == 1 and summary.Feedback.drawn == 1)
assert(summary.Feedback.sound_requested == 1)
dofile(root .. "cl_rpg_major_fx.lua")
local fx = LOD.RPGMajorFX
local reactions = 0
LOD.WizardFX = {Trigger = function() reactions = reactions + 1; return true end}
fx:Trigger(2, "LEVEL UP", "", 1)
assert(fx:Trigger(1, "FEEDBACK", "", 2) == true and fx.active.kind == 2 and reactions == 1)
clock = clock + 2
assert(fx:Trigger(1, "FEEDBACK", "", 3) == true and reactions == 2)
assert(#errors == 0, table.concat(errors, "\n"))
-- Span identity is independent of sentence role and survives names with ' as '.
local logger=LOD.DieLogger
local name="Steam as 7 as Deborah Riley"
local sentence=name.." dealt 1d10! (27) [rolls 10 > 10 > 7] damage to "..name..", via Magic"
local segments=logger:Segments(sentence,"routine",{{text=name,characterStart=15}})
assert(logger:ValidSegments(segments,sentence))
local identities,characters=0,0
for _,span in ipairs(segments) do
    if span.role=="identity" and span.text=="Steam as 7" then identities=identities+1 end
    if span.role=="character" and span.text=="Deborah Riley" then characters=characters+1 end
end
assert(identities==2 and characters==2,"actor/target identity uses exact Steam and character spans")
local chain={values={10,10,7,3},chainStarts={1,4},baseDice=2,contributions={10,10,7,4}}
assert(logger:RollDetail(chain)=="10 > 10 > 7 + 3=>4","base dice, continuations, contribution adjustments stay distinct")
local chainText=string.rep("10 > ",127).."7"
local longText=rolls:_DamageEventText(a,"4d10!",1277,b,"[rolls "..chainText.."]")
assert(longText:find(chainText,1,true),"128-die detail is never dropped")
rolls:_Send(a,0,longText)
local record=sent[#sent]
assert(record[2][1]==longText and logger:ValidSegments(record[6][1],longText))
local entry={text=longText,segments=record[6][1],family="routine"}
feed:RetainFeedback(entry)
assert(feed.history[#feed.history].segments==entry.segments,"history retains identical server spans")
local unbroken={text=string.rep("名",180),family="routine"}
local lines,widths=feed:Layout(unbroken,160)
local rebuilt={}
for i,line in ipairs(lines) do
    assert(widths[i]<=160,"long UTF-8 identity never leaves column")
    for _,span in ipairs(line) do rebuilt[#rebuilt+1]=span.text end
end
assert(table.concat(rebuilt)==unbroken.text,"wrapping loses no UTF-8 text")
clock=clock+20
hooks.HUDPaint.LOD_FeedbackNotice()
assert(not feed.notice and #feed.notices==0,"old lifecycle notices expire rather than replay later")
assert(#errors==0,table.concat(errors,"\n"))
local resolvedChain={values={10,10,7},contributions={10,10,7},chainStarts={1},baseDice=1,bonus=2,
    feedResolution={total=19.5,resistance=1,reduced={9,9,6}}}
local breakdown=logger:RollBreakdown(resolvedChain)
assert(breakdown=="10 > 10 > 7 + 2 bonus = 29 rolled; CON -1/die: 9 + 9 + 6 + 2 bonus = 26; resolved 19.5")
resolvedChain.bonus=-2
resolvedChain.feedResolution.total=22
assert(logger:RollBreakdown(resolvedChain):find("CON -1/die: 9 + 9 + 6 - 2 bonus = 22",1,true),
    "negative flat modifiers remain explicit in the resisted subtotal")
resolvedChain.bonus=0
resolvedChain.feedResolution.total=24
assert(logger:RollBreakdown(resolvedChain):find("CON -1/die: 9 + 9 + 6 = 24",1,true),
    "zero modifiers do not add noise")
local text=rolls:_DamageEventText(a,"1d10!+2",19.5,b,"[rolls "..breakdown.."]")
rolls:_Send(a,0,text)
assert(sent[#sent][2][1]:find("(19.5) DAMAGE",1,true)==1 and sent[#sent][2][1]:find("1d10!+2",1,true),
    "damage total leads in parentheses, followed by the formula and complete rolls")
local wire=sent[#sent]
assert(logger:ValidSegments(wire[6][1],text),"expanded arithmetic keeps exact semantic transport")
-- A nickname-only observer event must still retain its identity color.
rolls:_Send(a,3,"[STATUS] Player1: HELD APPLIED","status")
local nickname=false
for _,span in ipairs(sent[#sent][6][1]) do
    if span.text=="Player1" and span.role=="identity" then nickname=true end
end
assert(nickname,"nickname-only event uses identity role")
-- Font-sensitive caches cannot reuse menu line breaks on the transparent HUD.
local sample={text="same record, different metrics",family="routine"}
feed:Layout(sample,150,false);assert(sample.layoutFont=="LOD_CombatRoll")
feed:Layout(sample,150,true);assert(sample.layoutFont=="ChatFont")
print("FEEDBACK_LANGUAGE_PASS: isolation, typed transport, ACK ownership/dedup, Magic cost/refund, lifecycle, history and draw boundaries")

-- Success metadata takes the same path as text/history; replay cannot replay a cue.
dofile(root .. "cl_combat_roll_feed.lua")
local accentCalls=0
LOD.AdventurePresentation={OnFeedback=function(_,row)
    if row.cue==1 then accentCalls=accentCalls+1;assert(row.cueVariant==2);return true end
    return false
end}
P:Event(a,'objective','GREEN KEYCARD ACQUIRED',{event='keycard_acquired',cardIndex=2})
local treasurePacket=sent[#sent]
deliver(treasurePacket)
assert(accentCalls==1 and feed.entries[#feed.entries].cue==1 and feed.history[#feed.history].cue==1)
deliver(treasurePacket)
assert(accentCalls==1,'duplicate transport cannot replay discovery sound')
P:Event(a,'blocked','KEYCARD REQUIRED',{event='objective_denied'})
deliver(sent[#sent])
assert(accentCalls==1,'denial text cannot masquerade as success')
print('PASS: discovery cue, logger/history parity and duplicate/denial isolation')

local awarenessCalls=0
local position={x=384,y=-768,z=64}
LOD.RPGWisInformation={OnFeedback=function(_,row)
    if row.family=='awareness' then
        awarenessCalls=awarenessCalls+1
        assert(row.position.x==384 and row.position.y==-768)
    end
end}
feed.nextFeedbackSound=clock+10;feed.lastFeedbackPriority=3
local beforeSounds=#sounds
rolls:_Send(a,3,'[AWARENESS] LEFT: SHAMBLER','awareness',{event='spatial_awareness',position=position})
local awarenessPacket=sent[#sent]
deliver(awarenessPacket)
assert(awarenessCalls==1 and #sounds==beforeSounds+1,'awareness light and audible alert share logger delivery')
assert(feed.history[#feed.history].text=='[AWARENESS] LEFT: SHAMBLER','awareness retained in history')
deliver(awarenessPacket)
assert(awarenessCalls==1 and #sounds==beforeSounds+1,'duplicate cannot replay light or sound')
feed.lastFeedbackPriority=0
rolls:_Send(a,3,'[AWARENESS] RIGHT: RUNNER','awareness',{event='spatial_awareness',position=position})
deliver(sent[#sent])
assert(#sounds==beforeSounds+1,'ordinary priority changes cannot bypass awareness sound spacing')
clock=clock+1
rolls:_Send(a,3,'[AWARENESS] BEHIND YOU: SOLDIER','awareness',{event='spatial_awareness',position=position})
deliver(sent[#sent])
assert(#sounds==beforeSounds+2,'awareness rearms its distinct sound after spacing')
print('PASS: spatial awareness event position, history, priority sound and replay isolation')
