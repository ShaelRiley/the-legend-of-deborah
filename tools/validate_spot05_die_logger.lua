-- SPOT-05 bounded production gate. Only Source/transport/storage boundaries are
-- faked; event formatting, recipients, dice, status, Magic, progression, observers
-- and client history below are the shipped modules, not duplicate implementations.
local root = 'gamemodes/legend_of_deborah/gamemode/'
local clock, dev, checks = 100, true, 0
local function check(ok, label)
    checks=checks+1; assert(ok, 'SPOT05 '..checks..': '..label); print('PASS '..checks..' '..label)
end
SERVER, CLIENT, GM, LOD = true, false, {}, {RPG={}}
unpack=table.unpack
function CurTime() return clock end
RealTime=CurTime
function IsValid(x) return type(x)=='table' and x.valid==true end
function isentity(x) return IsValid(x) end
function isfunction(x) return type(x)=='function' end
function istable(x) return type(x)=='table' end
function isstring(x) return type(x)=='string' end
function isnumber(x) return type(x)=='number' end
function isbool(x) return type(x)=='boolean' end
function math.Clamp(v,a,b) return math.max(a, math.min(b,v)) end
function math.Round(v) return math.floor(v+.5) end
function string.Trim(s) return s:match('^%s*(.-)%s*$') end
function table.Copy(t,seen)
    if type(t)~='table' then return t end
    seen=seen or {}; if seen[t] then return seen[t] end
    local result={};seen[t]=result;for k,v in pairs(t) do result[k]=table.Copy(v,seen) end;return result
end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function Vector(x,y,z)
    return {x=x or 0,y=y or 0,z=z or 0,DistToSqr=function(a,b)
        return (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2 end}
end
vector_origin=Vector()
local errors, hooks, timers, receivers, sent, logs = {}, {}, {}, {}, {}, {}
function ErrorNoHalt(text) errors[#errors+1]=text end
function AddCSLuaFile() end
function DeriveGamemode() end
function GetConVar() return {GetBool=function() return dev end,GetFloat=function() return 0 end} end
function include(path) return dofile(root..path:gsub('^legend_of_deborah/gamemode/','')) end
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
    Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end,
    GetTable=function() return hooks end,
    Run=function(event,...) for _,fn in pairs(hooks[event] or {}) do local v=fn(...);if v~=nil then return v end end end}
timer={Create=function(id,_,_,fn) timers[id]=fn end,Remove=function(id) timers[id]=nil end,
    Exists=function(id) return timers[id]~=nil end,Simple=function() end}
concommand={Add=function() end};team={SetUp=function() end}
resource={AddFile=function() end,AddWorkshop=function() end}
local disk, encodes = {}, 0
file={Exists=function(path) return disk[path]~=nil end,Read=function(path) return disk[path] end,
    Write=function(path,data) disk[path]=data end,CreateDir=function() end}
util={AddNetworkString=function() end,CRC=function(s) return tostring(s) end,
    TableToJSON=function(t) encodes=encodes+1;return table.Copy(t) end,JSONToTable=function(t) return table.Copy(t) end}
-- Typed packet model; not a claim about Source's native JSON/net codec.
local packet,reading,cursor
local function write(v,width) packet[#packet+1]={v,width} end
local function read(width) cursor=cursor+1;assert(reading[cursor][2]==width,'wire mismatch');return reading[cursor][1] end
net={Start=function(name) packet={name=name} end,WriteUInt=write,ReadUInt=read,
    WriteDouble=function(v) write(v,'double') end,WriteFloat=function(v) write(v,'float') end,
    WriteString=function(v) write(v,'string') end,ReadString=function() return read('string') end,
    WriteBool=function(v) write(v,'bool') end,ReadBool=function() return read('bool') end,
    WriteVector=function(v) write(v,'vector') end,ReadVector=function() return read('vector') end,
    Send=function(p) packet.ply=p;sent[#sent+1]=packet end,SendToServer=function() sent[#sent+1]=packet end,
    Receive=function(name,fn) receivers[name]=fn end}
local function deliver(p,recipient,handler) reading,cursor=p,0;(handler or receivers[p.name])(0,recipient) end
local humans, states = {}, {}
player={GetAll=function() return humans end,GetHumans=function() return humans end}
game={GetWorld=function() return {} end}
LOD.RunManager={State={RosterSeed=913,CampaignSeed=719,CampaignEpoch=1,Level=2,LevelSeed=11,Graph={}},
    IdentityOf=function(_,p) return p.id end,
    GetPlayerState=function(_,p) return states[type(p)=='string' and p or p.id] end,
    IsActivePlayer=function(_,p) return p.active~=false end,
    IsSoldierControl=function(_,p) return IsValid(p) and p.soldier==true end,
    _SyncPlayerVars=function() return nil,'sync',nil,4 end}
LOD.RPGTestLog={Write=function(_,name,fields) logs[#logs+1]={name=name,fields=fields} end}
dofile(root..'shared.lua')
dofile(root..'lod/sv_combat_rolls.lua')
dofile(root..'lod/sv_combat_feed_semantics.lua')
dofile(root..'lod/sv_magic.lua')
dofile(root..'lod/sv_rpg_block.lua')
dofile(root..'lod/sv_feedback_observers.lua')
local R,S,P,C,M,E = LOD.CombatRolls,LOD.RPGStatusElements,LOD.RPGPresentation,
    LOD.CharacterProgressionSystem,LOD.Magic,LOD.RPG.FeatEffectSystem
local Rules=LOD.RPGAbilityRules
local function actor(id,human,x,nick)
    local a={valid=true,id=tostring(id),hp=100,maxhp=100,nw={},position=Vector(x or 0,0,0),
        human=human,nick=nick or ('Player'..id)}
    function a:IsPlayer() return self.human end
    function a:Nick() return self.nick end
    function a:EntIndex() return tonumber(self.id) end
    function a:GetClass() return self.human and 'player' or 'lod_hostile' end
    function a:GetPos() return self.position end
    function a:WorldSpaceCenter() return self.position end
    function a:Alive() return self.hp>0 end
    function a:Health() return self.hp end
    function a:GetMaxHealth() return self.maxhp end
    function a:SetHealth(n) self.hp=n end
    function a:SetMaxHealth(n) self.maxhp=n end
    function a:SetNW2Float(k,v) self.nw[k]=v end
    a.SetNW2Int=a.SetNW2Float;a.SetNW2Bool=a.SetNW2Float;a.SetNW2String=a.SetNW2Float
    function a:EmitSound() end
    function a:ChatPrint() end
    function a:GetActiveWeapon() return nil end
    function a:GetWeapon() return nil end
    function a:GetVelocity() return vector_origin end
    function a:GetBaseVelocity() return vector_origin end
    function a:GetWalkSpeed() return 100 end
    function a:GetRunSpeed() return 200 end
    function a:TakeDamageInfo(info) self.hp=math.max(0,self.hp-info:GetDamage()) end
    local state=C:NewProgressionState(a.id,human and 'hero' or 'shambler',human and 'hero' or 'ai')
    state.baseAbilities=LOD.RPG.NewAbilityBlock(10);state.startingHP=100
    C:_RecomputeProgressionState(state);state.derivedStats.wisMod=1
    if human then
        humans[#humans+1]=a;states[a.id]={identity=a.id,lives=3,magic=100,progressionState=state}
    else a.LODProgressionState=state;a.LODHostile=true;a.LODArchetypeId='shambler' end
    return a,state
end
local a,as=actor(1,true,0,'Steam as 7');local b,bs=actor(2,true,800)
local near,ns=actor(3,true,400);local far,fs=actor(4,true,2000)
local dead=actor(5,true,0);dead.hp=0
local n1=actor(6,false,200);local n2=actor(7,false,300)
ns.derivedStats.wisMod=2
local function reset() sent={};logs={} end
local function packets(p)
    local rows={};for _,v in ipairs(sent) do if v.name=='LOD_CombatRoll' and (not p or v.ply==p) then rows[#rows+1]=v end end;return rows
end
local function text(p) local out={};for _,v in ipairs(packets(p)) do out[#out+1]=v[2][1] end;return table.concat(out,'\n') end
local function contains(s,p) return s:find(p,1,true)~=nil end
local function scripted(values)
    local rng={count=0};function rng:Int(lo,hi) self.count=self.count+1;local v=assert(values[self.count],'unexpected RNG draw');assert(v>=lo and v<=hi);return v end
    function rng:Float() self.count=self.count+1;return assert(values[self.count],'unexpected RNG draw') end
    return rng
end
reset();local encodedBefore=encodes
R:_Send({a,b},0,'paired outcome','damage')
check(#packets()==3 and #packets(a)==1 and #packets(b)==1 and #packets(near)==1,'one union delivery per participant/nearby observer')
local p1,p2,p3=table.unpack(packets())
check(p1[3][1]==p2[3][1] and p2[3][1]==p3[3][1] and p1[2][1]==p3[2][1],'one event serial and frozen wording for all recipients')
check(p1[5][1] and p2[5][1] and not p3[5][1],'only direct participants own feedback acknowledgments')
check(#packets(dead)==0 and #packets(far)==0 and encodes-encodedBefore==1,'dead/far observers excluded; shared spans encoded once')
reset();b.position=Vector(5000,0,0);R:_Send({a,b},0,'distant victim','damage')
check(#packets(b)==1,'direct victim receives its result beyond observer radius');b.position=Vector(800,0,0)
reset();R:_Send({n1,n2},0,'NPC resolution','roll')
check(#packets(a)==1 and #packets(near)==1 and #packets(b)==0,'NPC-only outcome routes by actual NPC positions and observer WIS')
reset();R:_Send(a,2,'private HP growth','progression');R:_Send(a,2,'private resource','resource')
check(#packets()==2 and #packets(a)==2,'explicit progression/resource families remain private')
reset();P:CombatEvent(a,b,'resist','same legitimate result');P:CombatEvent(a,b,'resist','same legitimate result')
check(#packets(a)==2 and packets(a)[1][3][1]~=packets(a)[2][3][1],'identical legitimate outcomes retain distinct serials')
reset();states[a.id].magic=99;M:_Sync(a,states[a.id]);states[a.id].magic=100;M:_Sync(a,states[a.id])
check(#packets()==0 and a.nw.LOD_Magic==100,'real Magic sync/full-cap crossing is silent, HUD state preserved')
reset();states[a.id].magic=99.9;timers.LOD_MagicRegen()
check(#packets()==0 and states[a.id].magic==100 and a.nw.LOD_Magic==100,'real passive regeneration reaches 100 without event noise')

reset();local rng=scripted({20});local applied,reason=S:Apply(b,'held',a,{dc=10,rng=rng})
check(not applied and reason=='saved' and rng.count==1,'saved status consumes its original one die')
check(contains(text(a),'1d20 [20] = 20') and contains(text(a),'DC 10 — SAVED') and contains(text(a),'HELD RESISTED'),'save natural/DC and outcome both represented')
reset();rng=scripted({1,3});applied,reason=S:Apply(b,'held',a,{dc=10,rng=rng})
check(applied and reason=='applied' and rng.count==2 and S.Active[b].held.expiresAt==clock+3,'failed save/duration preserve draws and deadline')
local records=packets(a)
check(#records==3 and contains(records[1][2][1],'FAILED') and contains(records[2][2][1],'DURATION') and contains(records[3][2][1],'APPLIED'),'save → duration → outcome share causal order')
reset();rng=scripted({1,2});S:Apply(b,'held',a,{dc=10,rng=rng})
check(rng.count==2 and contains(text(a),'[2] = 2'),'already-active status does not hide newly consumed duration dice')
reset();check(S:Clear(b,'held','test') and contains(text(a),'HELD ENDED'),'actual status clear reaches source and target')
reset();rng=scripted({1,8});as.featIds={'WIS_ATTUNEMENT'}
local amount,detail=S:ResolveElementDamage(100,a,b,{magic=true,element='fire',targetWeaknesses={fire=true}},rng)
check(math.abs(amount-188)<1e-9 and rng.count==2 and detail.index==8,'Attunement keeps identical selection and RNG consumption')
check(contains(text(a),'d8 [1, 8], selected 8'),'both elemental-table choice rolls are retained');as.featIds={}

reset();rng=scripted({1,1,1,1,1,1,1,1,1});S:Apply(b,'poisoned',a,{direct=true,dc=10,rng=rng})
check(rng.count==9 and S.Active[b].poisoned.nextRecoveryAt==clock+9 and contains(text(a),'POISON RECOVERY INTERVAL'),'initial poison recovery dice are visible without timing change')
local poison=S.Active[b].poisoned;local originalRNG=R._RNG
rng=scripted({1,1,1,1,1,1,1,1,1,1});R._RNG=function() return rng end
reset();S:_ProcessPoisoned(b,poison,clock+9)
check(rng.count==10 and poison.nextRecoveryAt==clock+18 and contains(text(a),'RECOVERY') and contains(text(a),'FAILED'),'failed poison recovery shows save and fresh interval')
rng=scripted({20});reset();S:_ProcessPoisoned(b,poison,clock+18)
check(rng.count==1 and not S:Has(b,'poisoned') and contains(text(a),'SAVED') and contains(text(a),'ENDED'),'successful poison recovery retains save and clear')
R._RNG=originalRNG
-- Real status-damage settlement with a native DamageInfo boundary object.
DMG_GENERIC,DMG_POISON,DMG_BURN,DMG_SLASH=0,1,2,4
function DamageInfo()
    local i={damage=0};function i:SetDamage(v) self.damage=v end;function i:GetDamage() return self.damage end
    function i:SetAttacker(v) self.attacker=v end;function i:GetAttacker() return self.attacker end
    function i:SetInflictor(v) self.inflictor=v end;function i:GetInflictor() return self.inflictor end
    function i:SetDamageType(v) self.kind=v end;function i:IsDamageType(v) return self.kind==v end
    function i:SetDamagePosition() end;function i:SetDamageForce(v) self.force=v end
    return i
end
dofile(root..'lod/sv_damage_info.lua')
reset();b.hp=100;S:_ApplyStatusDamage(b,{id='bleeding',source=a},3,DMG_SLASH,'Bleeding')
check(b.hp<=100 and contains(text(a),'Bleeding DAMAGE') and contains(text(a),'[3] = 3'),'actual status damage reports its consumed die and resolved result')
local dice={};for i=1,130 do dice[i]=i%6+1 end
reset();P:DiceEvent(a,b,'LONG CHAIN','dice',dice,455)
check(#packets(a)==3,'long dice array splits into finite 64-value records rather than truncating')
check(contains(text(a),'[part 1/3]') and contains(text(a),'[part 3/3]'),'ordered parts have explicit common labels in canonical stream')
local beforeSerial=R.Serial;local originalDice=P.DiceEvent;P.DiceEvent=function() error('intentional presentation failure') end
rng=scripted({20});applied,reason=S:Apply(b,'muted',a,{dc=10,rng=rng});P.DiceEvent=originalDice
check(not applied and reason=='saved' and rng.count==1 and #errors==1,'fallible dice presentation cannot change status result or draw count');errors={}

-- Actual evasion authorities consume the captured voluntary-motion sample.
DMG_FALL,DMG_CRUSH,DMG_BULLET,DMG_BUCKSHOT,DMG_CLUB=16,32,64,128,256
local function hit(event)
    local info=DamageInfo();info:SetDamage(10);info:SetAttacker(a);info:SetDamageType(DMG_BULLET)
    S:AttachDamageContext(info,{attackEvent=event});return info
end
Rules:Derived(b) -- establish the exact current life before feeding its motion sample
bs.derivedStats.dodgeChanceContribution=.33
Rules.DodgeMotion[b]={identity=bs,at=clock,speed=60,walk=100,sprint=200}
reset();rng=scripted({.8});R._RNG=function() return rng end
local event={};local info=hit(event)
check(not Rules:ApplyDodge(b,info) and info:GetDamage()==10 and rng.count==1,'failed Dodge preserves damage and one authoritative float')
check(contains(text(a),'DODGE FAILED') and #packets(a)==1 and #packets(b)==1,'failed Dodge is visible once to both participants')
Rules:ApplyDodge(b,hit(event));check(rng.count==1 and #packets(b)==1,'cached failed Dodge does not reroll or duplicate the record')
reset();rng=scripted({.1});info=hit({})
check(Rules:ApplyDodge(b,info) and info:GetDamage()==0 and info.force==vector_origin,'successful Dodge still commits zero damage')
check(contains(text(b),'DODGE SUCCESS') and contains(text(b),'0 HP DAMAGE'),'successful Dodge explicitly represents its zero result')
Rules.DodgeMotion[b].speed=0;reset();rng=scripted({})
check(not Rules:ApplyDodge(b,hit({})) and rng.count==0 and #packets()==0,'ineligible zero-chance Dodge produces neither RNG nor fake event')
bs.equipmentBlockChanceContribution=.33;reset();rng=scripted({.1});event={};info=hit(event)
check(Rules:ApplyBlock(b,info) and info:GetDamage()==0 and rng.count==1,'real Block authority retains chance and damage outcome')
Rules:ApplyBlock(b,hit(event));check(#packets(a)==1 and #packets(b)==1 and rng.count==1,'Block uses the same single-event participant union and cache')
bs.equipmentBlockChanceContribution=0;bs.derivedStats.dodgeChanceContribution=0;R._RNG=originalRNG
reset();rng=scripted({20,2,3,4});local ok,outcome,morale=S:AttemptMorale(a,n1,{forceMorale=true,rng=rng})
check(ok and outcome=='saved' and rng.count==4 and morale.cooldown==9.75,'NPC Morale save/cooldown retain exactly four draws and timing')
check(contains(text(a),'[20]') and contains(text(a),'30+3d20 [2+3+4] x0.25'),'Morale record retains previously omitted cooldown dice')
reset();R:ReportEnemyHealth(n1,{total=7,formula='2d4',values={3,4}},1,1,7)
local healthPackets=packets();local same=true;for _,p in ipairs(healthPackets) do same=same and p[3][1]==healthPackets[1][3][1] end
check(#healthPackets==#humans and same,'enemy HP generation has one serial, no all-player fan-out duplicates')
reset();local miss={values={3},contributions={3},total=3,formula='1d6',baseDice=1,label='pistol'}
R:_FinishExplodedMiss(a,miss);R:_FinishExplodedMiss(a,miss)
check(#packets(a)==1 and contains(text(a),'[rolls 3 = 3 rolled]') and contains(text(a),'(0) DAMAGE'),'ordinary non-exploding miss keeps its committed dice exactly once')
reset();as.featIds={'INT_FEEDBACK_LOOP'};local pool={magic=98}
local restored=E:ApplyFeedbackLoop(a,pool,2,0)
check(restored==2 and pool.magic==100 and contains(text(a),'FEEDBACK LOOP — +2 Magic'),'authored restoration to 100 remains meaningful despite passive-noise exception')
reset();E:ApplyFeedbackLoop(a,pool,2,0)
check(#packets()==0 and pool.magic==100,'zero actual proc restoration emits no fake resource gain');as.featIds={}

reset();local totalOnly=S.ConditionSave;S.ConditionSave=function() return 20 end
local saved,totalReason=S:Apply(b,'held',a,{dc=10});S.ConditionSave=totalOnly
check(not saved and totalReason=='saved' and not contains(text(a),'1d20') and #errors==0,
    'total-only legacy save remains authoritative without fabricated natural dice or report errors')

-- Exact state observations, not a second life/queue authority.
local run=LOD.RunManager
reset();run:_SyncPlayerVars(a);check(#packets()==0,'first local sync establishes baseline without invented revival')
states[a.id].lives=2;run:_SyncPlayerVars(a);check(contains(text(a),'LIFE LOST'),'real same-Hero life loss reported')
reset();states[a.id].lives=0;states[a.id].eliminated=true;run:_SyncPlayerVars(a)
check(contains(text(a),'ELIMINATED'),'elimination remains meaningful')
reset();states[a.id].lives=1;states[a.id].eliminated=false;run:_SyncPlayerVars(a)
check(contains(text(a),'REVIVED'),'same retained Hero resurrection reported')
reset();states[a.id]=table.Copy(states[a.id]);states[a.id].lives=3;run:_SyncPlayerVars(a)
check(#packets()==0,'replacement Hero is not reported as revived')
reset();run.State=table.Copy(run.State);states[a.id].lives=1;run:_SyncPlayerVars(a)
check(#packets()==0,'replacement run with same epoch establishes new baseline')
reset();run.State.CampaignEpoch=2;states[a.id].lives=3;run:_SyncPlayerVars(a)
check(#packets()==0,'new campaign epoch cannot inherit life comparison')
reset();local late=actor(8,true,0);states[late.id].lives=1;run:_SyncPlayerVars(late)
check(#packets()==0,'late-joining controller receives no synthetic life event')
reset();a.soldier=true;run:_SyncPlayerVars(a)
check(contains(text(a),'SOLDIER ACTIVE') and R:EntityDisplayName(a)=='Steam as 7 as Soldier','active Soldier identity uses actual role, not dormant Hero')
local spans=packets(a)[1][6][1];local hasNick,hasSoldier=false,false
for _,span in ipairs(spans) do
    hasNick=hasNick or span.role=='identity' and span.text=='Steam as 7'
    hasSoldier=hasSoldier or span.role=='character' and span.text=='Soldier'
end
check(hasNick and hasSoldier,'username containing as and Soldier have separate canonical semantic roles')
reset();a.soldier=false;run:_SyncPlayerVars(a);check(contains(text(a),'SOLDIER RETIRED'),'role retirement uses shared lifecycle stream')

-- Whole committed HP restoration remains an event; fractional accumulation and
-- unchanged synchronization do not manufacture heal notices.
as=states[a.id].progressionState;as.derivedStats={healthRegenEnabled=true,healthRegenCeilingFraction=.33,
    healthRegenBaseMaxHPPerSecond=.1,conRegenMultiplier=1,wisMod=1}
a.hp=10;a.LODRPGHealthRegenEligibleAt=0
reset();E:_TickActor(a,.01);check(#packets()==0 and a.hp==10,'fractional HP regeneration is not a committed outcome')
E:_TickActor(a,1);check(a.hp==20 and contains(text(a),'HEALTH REGENERATION +10 HP'),'actual whole HP regeneration is retained')
reset();a.hp=33;E:_TickActor(a,1);check(#packets()==0 and a.hp==33,'regeneration ceiling no-op is silent')

-- Actual deterministic progression authority on an identity string avoids native
-- model/weapon RPCs. Reporting resolves that identity to its connected recipient.
states[a.id].progressionState=nil;states[a.id].ordinal=1
local hero=C:InitializeHero(run,states[a.id],{id='male',presentationSex='male',name='Hero',model='models/Humans/Group01/male_01.mdl'})
check(hero~=nil and C:CommitClass(a.id,'fighter'),'real Hero initialization/class authority loads')
reset();check(C:AdvanceHeroToLevel(a.id,2),'actual Hero advancement succeeds')
local roll=hero.hitDieRollsByLevel[2]
check(roll and contains(text(a),'LEVEL 2 HP GROWTH') and contains(text(a),'= '..roll.total),'committed Hero HP die reaches canonical stream')
local copies=packets(a);check(#copies==1 and #packets()==1 and copies[1][4][1]=='progression','HP progression is private and delivered once')
reset();C:AdvanceHeroToLevel(a.id,2);check(#packets()==0,'cached/repeated level does not replay HP dice')

-- Disposable Soldier progression is a separate owner from the retained Hero.
reset();a.soldier=true;local soldier=LOD.SoldierProgression:Attach(a,991,40,3)
check(soldier and soldier~=hero and a.LODHumanSoldierProgressionState==soldier,'actual Soldier admission owns its separate progression')
local growthCount=0;for level=2,soldier.level do if soldier.hitDieRollsByLevel[level] then growthCount=growthCount+1 end end
check(growthCount>0 and #packets(a)==growthCount and #packets()==growthCount,'fresh Soldier HP dice are private and complete for committed levels')
reset();check(LOD.SoldierProgression:Attach(a,123,80,3)==soldier and #packets()==0,'repeated Soldier admission neither rerolls nor replays HP dice')
reset();local oldLevel=soldier.level;LOD.SoldierProgression:Award(soldier,100,false)
check(soldier.level>oldLevel and contains(text(a),'HP GROWTH') and contains(text(a),'SoldierXP'),'actual Soldier XP growth reports its new dice and outcome')
check(states[a.id].progressionState==hero and hero.level==2,'Soldier events cannot mutate or advance dormant Hero ownership')
reset();LOD.SoldierProgression:Retire(a);LOD.SoldierProgression:Award(soldier,100,false)
check(#packets()==0 and soldier.soldierIncarnation==false,'retired Soldier reference cannot emit a new growth event');a.soldier=false

-- Full real client receiver and retained history, using this server's packets.
local sounds={}
surface={CreateFont=function() end,SetFont=function() end,GetTextSize=function(s) return #s*7,16 end,
    PlaySound=function(s) sounds[#sounds+1]=s end,SetDrawColor=function() end,DrawOutlinedRect=function() end,DrawRect=function() end}
draw={RoundedBox=function() end,SimpleText=function() end,SimpleTextOutlined=function() end}
function ScrW() return 1280 end;function ScrH() return 800 end
local ackHandler=receivers.LOD_FeedbackAck
reset();P:CombatEvent(a,b,'damage','shared dice 1d6 [4] = 4');local sample=packets(a)[1]
dofile(root..'lod/cl_ui_theme.lua');dofile(root..'lod/cl_combat_roll_feed.lua')
dofile(root..'lod/cl_feedback_language.lua');dofile(root..'lod/cl_combat_roll_feed_semantics.lua')
local feed=LOD.CombatRollFeed;deliver(sample)
check(#feed.entries==1 and #feed.history==1 and feed.entries[1].text==feed.history[1].text,'real receiver retains exact live/history wording')
check(feed.entries[1].serial==feed.history[1].serial and LOD.DieLogger:ValidSegments(feed.history[1].segments,feed.entries[1].text),'live/history preserve event identity and semantic spans')
local ack=sent[#sent];local logCount=#logs;deliver(ack,far,ackHandler)
check(#logs==logCount,'unrelated client cannot acknowledge another player event')
deliver(ack,a,ackHandler);check(logs[#logs].fields.stage=='received','owner acknowledgment records transport receipt only')
deliver(sample);check(#feed.history==1,'repeat network serial does not duplicate history')
reset();P:CombatEvent(a,b,'damage','shared dice 1d6 [4] = 4');deliver(packets(a)[1])
check(#feed.history==2,'same text with a fresh authoritative serial is not suppressed')
for i=1,1010 do local p=table.Copy(sample);p[3][1]=100000+i;deliver(p) end
check(#feed.entries==10 and #feed.history==1000 and #feed.serialOrder<=1024,'live tail, history and replay memory remain bounded')
check(feed.history[1].serial<feed.history[#feed.history].serial,'retained chronological order survives rollover')
timers.LOD_DieLoggerSave();local saved=disk['legend_of_deborah/die_logger_history.json']
check(#saved==1000 and saved[#saved].serial==101010,'batched persistence retains serial/order')
for i=1,20 do saved[#saved+1]=table.Copy(saved[#saved]) end
LOD.CombatRollFeed={entries={}};dofile(root..'lod/cl_feedback_language.lua')
check(#LOD.CombatRollFeed.history==1000 and #LOD.CombatRollFeed.entries==0,'oversize persisted history is bounded and not replayed live')
check(#errors==0,'no unexpected presentation or engine-boundary errors: '..table.concat(errors,'\n'))
print('SPOT05_DIE_LOGGER_PASS '..checks..' bounded production assertions; native rendering/network acceptance pending')
