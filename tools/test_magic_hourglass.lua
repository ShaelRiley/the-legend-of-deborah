-- Production inventory, source binding, clock transaction, rewards and client
-- snapshot; native transport/entities and deterministic utility results are doubles.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,Rolls=LOD.Equipment,env.Run,LOD.CombatRolls
getmetatable(Vector()).__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
local now=200;CurTime=function() return now end;SysTime=CurTime;RealTime=CurTime
local noop=function() end
local commands={};concommand.Add=function(id,fn) commands[id]=fn end
local packet,packets,receivers={}, {}, {}
net.Start=function(id) packet={};packets[id]=packet end
local write=function(v) packet[#packet+1]=v end
for _,name in ipairs({'UInt','Bool','Float','Vector'}) do net['Write'..name]=write end
net.Broadcast=noop;net.Send=noop;net.Receive=function(id,fn) receivers[id]=fn end
local announcements={}
LOD.ProgressionDirector={Announce=function(_,s) announcements[#announcements+1]=s end}
local failures=0
R.FailCampaign=function(self,reason) self.State.Failed=true;self.State.FailureReason=reason;failures=failures+1 end
dofile(root..'sh_campaign_timeout.lua');dofile(root..'sv_campaign_timeout.lua')
dofile(root..'sv_equipment_moves.lua');dofile(root..'sv_magic_hourglass.lua')
local T=LOD.CampaignTimeout
T.Bounds=function() return Vector(),1200,0 end -- Native generated-geometry boundary, not clock logic.
local p=env.actor('hourglass')
local state
local function setup()
 now=now+2;p.hp=100;p.active=true;p.soldier=false;p.valid=true
 p.ps.lives=3;p.ps.eliminated=false;p.ps.deploymentComplete=true;p.ps.equipmentLifeSerial=1
 p.ps.equipment=nil;E:ClearTransient(p);E.NextUse[p]=nil
 R.State={CampaignEpoch=1,CampaignSeed=73,LevelSeed=7,Level=1,BuildReady=true,Graph={},
  CampaignClock={deadline=now+100}}
 state=E:Ensure(p.ps)
 assert(E:Grant(p,'magic_hourglass',3) and E:Equip(state,'magic_hourglass','throwable'))
 assert(E:Activate(p));p.ps.magic=31
end
local function count() local i=state.items.magic_hourglass;return i and i.count or 0 end
local rolls,rollValues,feed=0,{1,1},{}
Rolls._RNG=function(_,label)
 assert(label=='magic-hourglass');local index=0
 return {Int=function(_,lo,hi) assert(lo==1 and hi==4);index=index+1;rolls=rolls+1;assert(index<=2);return rollValues[index] end}
end
Rolls._Send=function(_,actor,kind,text,family,fields) feed[#feed+1]={text=text,fields=fields};assert(actor==p and kind==3) end
local function noSpend()
 local n,d,r=count(),T:Clock().deadline,rolls
 assert(not E:Use(p,'throw'));assert(count()==n and T:Clock().deadline==d and rolls==r)
end
for _,pair in ipairs({{1,1},{4,4},{2,3}}) do
 setup();rollValues=pair
 local before=T:Clock().deadline;local r=rolls
 assert(E:Use(p,'throw'))
 assert(count()==2 and rolls==r+2 and T:Clock().deadline==before+(pair[1]+pair[2])*60)
 assert(p.ps.magic==31 and E.NextUse[p]==now+.6)
 assert(feed[#feed].fields.first==pair[1] and feed[#feed].fields.second==pair[2])
 assert(packets[T.Message][3]==100+(pair[1]+pair[2])*60,'Party clock uses real broadcast transport')
 noSpend();now=now+1;assert(E:Use(p,'drink') and count()==1,'Both controls use one shared transaction')
 now=now+1;assert(E:Use(p,'drink') and count()==0 and not E:IsActive(p),'Depletion restores normal controls')
 assert(not state.slots.throwable and p.ps.magic==31)
end
setup();local consume=E.Consume;E.Consume=function() return false end
noSpend();assert(not E.NextUse[p]);E.Consume=consume
assert(not E:AddConsumable(state,'magic_hourglass',1),'Finite cap rejects overflow')
assert(E:Prompt(E.Definitions.magic_hourglass)=='LMB / RMB: USE HOURGLASS')
for _,blocked in ipairs({'dead','inactive','soldier','staging','eliminated','zero_lives','unheld','unequipped','wrong_owner',
 'failed','cleared','frozen','building','no_graph','paused','expired','scene'}) do
 setup()
 if blocked=='dead' then p.hp=0
 elseif blocked=='inactive' then p.active=false
 elseif blocked=='soldier' then p.soldier=true
 elseif blocked=='staging' then p.ps.deploymentComplete=false
 elseif blocked=='eliminated' then p.ps.eliminated=true
 elseif blocked=='zero_lives' then p.ps.lives=0
 elseif blocked=='unheld' then p.activeClass='weapon_lod_crowbar'
 elseif blocked=='unequipped' then E:Unequip(state,'throwable')
 elseif blocked=='wrong_owner' then p:GetActiveWeapon().owner=env.actor('other')
 elseif blocked=='failed' then R.State.Failed=true
 elseif blocked=='cleared' then R.State.LevelCleared=true
 elseif blocked=='frozen' then R.State.SimulationFrozen=true
 elseif blocked=='building' then R.State.BuildReady=false
 elseif blocked=='no_graph' then R.State.Graph=nil
 elseif blocked=='paused' then T:Clock().deadline=nil
 elseif blocked=='expired' then T:Clock().deadline=now
 elseif blocked=='scene' then T:Clock().scene={} end
 noSpend()
 if blocked=='expired' then assert(R.State.Failed and R.State.FailureReason=='TIME OVER' and failures==1) end
 p.weapons[E.WeaponClass].owner=p
end
-- Every stale clock binding is rejected before invoking its debit/roll callback.
for _,mutate in ipairs({
 function() R.State.CampaignClock={} end,function() R.State.Graph={} end,
 function() R.State.LevelSeed=8 end,function() T:Clock().deadline=T:Clock().deadline+1 end,
 function() local n={};for k,v in pairs(R.State) do n[k]=v end;R.State=n end
}) do
 setup();local binding=T:ExtensionBinding();mutate()
 assert(not T:TryExtend(binding,function() error('stale callback executed') end))
 assert(count()==3)
end
for _,mutate in ipairs({
 function() p.ps.identity='new identity' end,
 function() p.ps.equipmentLifeSerial=2 end,
 function() p.ps.equipment={items=state.items,slots=state.slots} end,
 function() local n={};for k,v in pairs(p.ps) do n[k]=v end;p.ps=n end,
 function() E:Unequip(state,'throwable') end,
 function() state.items.magic_hourglass={definitionId='magic_hourglass',count=3} end
}) do
 setup();local context={moveBinding=E:BindMoveSource(p,{family='magic_hourglass'}),weapon=p:GetActiveWeapon()}
 assert(E:HourglassSourceValid(p,context));mutate();assert(not E:HourglassSourceValid(p,context))
end
-- Two legitimate sources extend the same current deadline; old receipts cannot replay.
setup();rollValues={4,4};local old=T:ExtensionBinding();local initial=old.deadline
assert(E:Use(p,'throw'));now=now+1;assert(E:Use(p,'drink'))
assert(T:Clock().deadline==initial+960 and not T:TryExtend(old,function() error('replayed') end))
-- Crossing warnings again after added time is intentional; warnings still below us stay latched.
setup();rollValues={1,1};local c=T:Clock();c.deadline=now+5;c.warned={[600]=true,[300]=true,[60]=true,[30]=true,[10]=true}
assert(E:Use(p,'throw'));assert(c.warned[600] and c.warned[300] and not c.warned[60] and not c.warned[30] and not c.warned[10])
now=c.deadline-59;T:Step();assert(c.warned[60])
local n=count();T:ResetAfterRescue();assert(not T:Clock().deadline and T:Remaining(T:Clock(),now)==1800 and count()==n)
noSpend()
-- Real source models/item rewards and deterministic independent rare stream.
setup();local found=0
for i=1,512 do
 local key='hourglass-proof-'..i
 local seed=LOD.Seeds.Derive(R.State.CampaignSeed,E:RewardKey('hourglass',key))
 local card=LOD.RNG.New(LOD.Seeds.Derive(seed,'summon-card-v1')):Chance(1/8)
 local feather=LOD.RNG.New(LOD.Seeds.Derive(seed,'resurrection-feather-v1')):Chance(1/8)
 local hourglass=LOD.RNG.New(LOD.Seeds.Derive(seed,'magic-hourglass-v1')):Chance(1/16)
 local options={equipmentEligible=true,staticId=key}
 local kind,a=E:PrepareReward('hourglass','consumable',{itemId='healing_potion'},options)
 local _,b=E:PrepareReward('hourglass','consumable',{itemId='healing_potion'},options)
 assert(a.itemId==b.itemId and LOD.LootDirector:_PreparedRewardValid(kind,a))
 if card then assert(a.itemId=='summon_card')
 elseif feather then assert(a.itemId=='resurrection_feather')
 elseif hourglass then assert(a.itemId=='magic_hourglass');found=found+1
 else assert(a.itemId~='magic_hourglass') end
 local _,fixed=E:PrepareReward('hourglass','consumable',{itemId='healing_potion'},{staticId=key})
 assert(fixed.itemId=='healing_potion')
end
assert(found>0)
-- Actual clock receiver accepts the longer snapshot, including a fresh joining client.
setup();assert(E:Use(p,'throw'))
Material=function() return {} end;surface={CreateFont=noop};hook.GetTable=function() return {} end
dofile(root..'cl_campaign_timeout.lua')
local index=0;local read=function() index=index+1;return packets[T.Message][index] end
net.ReadUInt,net.ReadBool,net.ReadFloat=read,read,read
receivers[T.Message]();assert(T.Client.remaining==220 and T.Client.started and not T.Client.scene)
now=now+3;T:Sync(p);index=0;receivers[T.Message]()
assert(T.Client.remaining==217,'Late join uses current extended authoritative clock')
print('HOURGLASS_PASS: owned-source debit, exactly 2d4 utility minutes, cooldown/depletion, stale lifecycle/clock rejection, expiry wins, warnings/reset, deterministic rewards and client/party snapshots')
