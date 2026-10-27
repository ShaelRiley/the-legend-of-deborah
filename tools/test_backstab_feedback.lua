-- Real Backstab resolution + canonical presentation/name formatting; only Source
-- actor/transport boundaries are doubled. No native or multiplayer claim.
local env=...
if type(env)~='table' or type(env.actor)~='function' then
    env=dofile('tools/test_equipment_economy_runtime.lua')
end
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local V=getmetatable(Vector())
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:GetNormalized() local n=math.sqrt(self:LengthSqr());return n>0 and self*(1/n) or Vector() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
isstring=function(v) return type(v)=='string' end
net.Receive=function() end
util.AddNetworkString=function() end
ErrorNoHalt=function(err) error(err) end
function string.Trim(s) return s:match('^%s*(.-)%s*$') end
Color=Color or function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
player={GetAll=function() return {} end}
dofile(root..'sh_die_logger.lua')
dofile(root..'sh_feedback_language.lua')
dofile(root..'sv_feedback_language.lua')
dofile(root..'sv_combat_feed_semantics.lua')
if arg and arg[1] then dofile(arg[1]) end -- Exact old authority for negative control.
local sent={}
function LOD.CombatRolls:_Send(recipient,category,text,family,fields)
    sent[#sent+1]={recipient=recipient,text=text,family=family,event=fields.event}
end
local R,C,P=LOD.RPGAbilityRules,LOD.CharacterProgressionSystem,LOD.RPGPresentation
local function actor(id,enemy)
    local who=env.actor(id,enemy)
    who.LODConfig={name=id}
    who.GetClass=function() return 'lod_hostile' end
    -- Lua-table Source doubles take PlayerCharacterText's state branch.
    who.lastPlayerName=id
    who.Nick=function() return id end
    who.pos=Vector()
    who.GetPos=function(self) return self.pos end
    who.facing=Vector(1,0,0)
    who.GetForward=function(self) return self.facing end
    who.EyeAngles=function(self) return {Forward=function() return self.facing end} end
    return who
end
local ai,hero,other=actor('Soldier',true),actor('Henry'),actor('Victoria')
hero.lastPlayerName='Steam One';hero.characterName='Henry Cold Coffee Perry'
other.lastPlayerName='Steam Two';other.characterName='Victoria'
assert(P:FeedbackName(hero)=='Steam One as Henry Cold Coffee Perry',
    'Player names must travel through the canonical Steam/Hero display formatter')
ai.pos=Vector(-100,0,0);other.pos=Vector(-100,0,0)
local function setClass(who,class)
    who.LODProgressionState.classId=class
    C:_RecomputeProgressionState(who.LODProgressionState)
end
local function resolve(source,target,tags,contract)
    sent={};tags=tags or {physical=true}
    local amount=R:ResolveDamageContract(contract or {contributions={4},attackEvent={}},source,target,tags)
    return amount,tags
end
local function notice(source,target,viewer)
    assert(#sent==1 and sent[1].event=='backstab' and sent[1].family=='damage')
    assert(sent[1].recipient==viewer,'Backstab notice must preserve its existing player recipient')
    local expected=P:FeedbackName(source)..': BACKSTAB — bonus damage multiple; Constitution bypassed'
    assert(sent[1].text==expected,'Backstab notice must name actual attacker without attributing the ability to its recipient: '..sent[1].text)
    print('BACKSTAB_NOTICE '..sent[1].text)
end
local function near(a,b) assert(math.abs(a-b)<.000001,tostring(a)..' ~= '..b) end
for _,fields in ipairs({{event='default'},{event='empty',subjectName=''},
    {event='invalid',subjectName=17}}) do
    sent={};P:Event(hero,'damage','DEFAULT SUBJECT',fields)
    assert(#sent==1 and sent[1].recipient==hero
        and sent[1].text==P:FeedbackName(hero)..': DEFAULT SUBJECT',
        'Unspecified/invalid subject keeps the existing audience prefix')
end
setClass(ai,'fighter');setClass(hero,'rogue')
local amount,tags=resolve(ai,hero)
near(amount,4);assert(not tags.backstab and #sent==0,'Target Rogue alone must not enable enemy Backstab')
setClass(ai,'rogue');setClass(hero,'fighter')
for mult=1,3 do
    hero.LODProgressionState.derivedStats.damageResistancePerDie=3
    amount,tags=resolve(ai,hero,{physical=true,authoredScale=mult,attackMultiplier=mult})
    near(amount,4*(mult+1));assert(tags.backstab);notice(ai,hero,hero)
end
setClass(hero,'rogue')
amount,tags=resolve(ai,hero,{magic=true})
near(amount,8);assert(tags.backstab);notice(ai,hero,hero)
-- Player→enemy and player→player use the actual attacker identity, preserving
-- existing recipient selection. The presentation does not change combat math.
hero.pos=Vector(-100,0,0);ai.pos=Vector()
amount,tags=resolve(hero,ai);near(amount,8);notice(hero,ai,hero)
amount,tags=resolve(other,ai);near(amount,4);assert(not tags.backstab and #sent==0)
setClass(other,'rogue');hero.pos=Vector()
amount,tags=resolve(other,hero);near(amount,8);notice(other,hero,other)
-- A cached target/event reports once even if the defender turns; distinct
-- attacks remain distinct notices and excluded/forward damage emits none.
ai.pos=Vector(-100,0,0)
local event={contributions={4},attackEvent={}}
amount,tags=resolve(ai,hero,nil,event);near(amount,8);notice(ai,hero,hero)
hero.facing=Vector(-1,0,0)
amount,tags=resolve(ai,hero,nil,event);near(amount,8);assert(#sent==0)
amount,tags=resolve(ai,hero);near(amount,4);assert(not tags.backstab and #sent==0)
hero.facing=Vector(1,0,0)
for _,key in ipairs({'statusDamage','passiveDamage','reactiveDamage','auraBurst','environmental','wallCrush'}) do
    amount,tags=resolve(ai,hero,{physical=true,[key]=true})
    near(amount,4);assert(not tags.backstab and #sent==0,key..' must not backstab or emit a notice')
end
for i=1,2 do amount,tags=resolve(ai,hero);near(amount,8);notice(ai,hero,hero) end
local npc=actor('Shambler',true)
amount,tags=resolve(ai,npc);near(amount,8);assert(tags.backstab and #sent==0,'Preserve existing NPC-only notice policy')
print('BACKSTAB_FEEDBACK_PASS: actual attacker identity separate from existing audience; default Event compatibility; defender-class isolation, x2/x3/x4 and CON bypass, cached/repeated events and excluded damage')
