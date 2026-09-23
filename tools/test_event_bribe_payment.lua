-- Canonical equipment/value/removal and real event ownership/settlement. Only
-- native entities, LOS and packet delivery are Source boundary doubles.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run,realFloors=true})
local root,E,Run,D=F.root,LOD.Equipment,F.Run,F.D
SOLID_BBOX=2
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
dofile(root..'sv_debbie_junk.lua')
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_safe_teleport.lua')
dofile(root..'sv_progression_builder.lua')
local nativeCreate=ents.Create
ents.Create=function(class)
 local ent=nativeCreate(class)
 if class=='lod_gate' then
  for _,name in ipairs({'GateIndex','GateAxis','Opened','OpenedAt'}) do
   ent['Set'..name]=function(self,value) self[name]=value end
   ent['Get'..name]=function(self) return self[name] end
 end
  ent.solid,ent.NotSolid,ent.Opened=SOLID_BBOX,false,false
  ent.GetNotSolid=nil -- Source has IsSolid/GetSolid; reject invented getters.
  function ent:SetSolid(value) self.solid=value end
  function ent:GetSolid() return self.solid end
  function ent:IsSolid() return self:GetSolid()~=SOLID_NONE and not self.NotSolid end
  function ent:CollisionRulesChanged() end
 end
 return ent
end
dofile(root..'sv_event_bribe_blockade.lua')
dofile(root..'sv_event_bribe_payment.lua')
local B,p,q=LOD.EventBribeBlockade,F.a,F.b
assert(B.price==50)
local function copy(t) return table.Copy(t) end
local function same(a,b) return WalletJSONEncode(a)==WalletJSONEncode(b) end
local function near(actor,ent) actor.pos=ent:GetPos() end
-- Generation/topology proofs live in test_event_bribe_blockade.lua. This gate
-- starts from real graph/native event creation and varies only settlement state.
local graph,placement,cell=F.graph
for ek,edge in pairs(graph.Edges) do
 if edge.a.z==edge.b.z then
  cell=graph.Cells[F.key(edge.a)]
  for ck,candidate in pairs(graph.Cells) do
   if ck~=F.key(edge.a) and ck~=F.key(edge.b) then
    placement={cellKey=F.key(edge.a),edgeKey=ek,cacheCellKey=ck};break
   end
  end
  break
 end
end
local generation=0
local function build()
 generation=generation+1
 Run.State={RunId='bribe-payment:'..generation,CampaignSeed=41,CampaignEpoch=generation,Level=1,
  LevelSeed=graph.MasterLevelSeed,Graph=graph,BuildReady=true,Ranked=false}
 local instance={id='bribe-test:'..generation,archetype=B.id,contract='BLOCKADE',cell=cell,
  cellKey=placement.cellKey,placement=copy(placement),claims={},entities={}}
 assert(D:Activate(graph,{mode='preview',selectedCount=1,instances={instance}}))
 assert(instance.archetype==B.id and B.Owned(D,instance))
 for _,actor in ipairs({p,q}) do
  actor.id=actor==p and '76561198000000001' or '76561198000000002'
  actor.active,actor.dead,actor.soldier=true,false,false
  actor.ps={identity=actor.id,deploymentComplete=true,lives=3,equipmentLifeSerial=1,equipment={items={},slots={}}}
  near(actor,instance.entities[1])
 end
 return instance
end
local function review(instance,actor)
 actor=actor or p;near(actor,instance.entities[1])
 assert(D:Interact(instance.entities[1],actor))
 return assert(B.Reviews[actor]).id
end
local function recover(instance,actor)
 actor=actor or p;near(actor,instance.entities[2])
 assert(D:Interact(instance.entities[2],actor) and instance.recovered)
 near(actor,instance.entities[1])
end
local serial=0
local function item(actor,kind)
 serial=serial+1
 local gear
 if kind=='exact' then
  -- Legal legacy procedural values continue through the canonical validator.
  gear={id='bribe:legacy:'..serial,definitionId='gloves',count=1,dungeonLevel=51,budget=60,
   properties={{id='ability_str',amount=5}}}
 elseif kind=='low' then
  gear={id='bribe:legacy:'..serial,definitionId='gloves',count=1,dungeonLevel=81,budget=84,
   properties={{id='ability_str',amount=6},{id='ability_dex',amount=1},{id='ability_con',amount=-3}}}
 else gear=E:Generate(88000+serial,1,'ring','bribe-payment:'..serial) end
 assert(E:ValidateWearable(gear))
 assert(E:StoreWearable(E:Ensure(actor.ps),gear))
 return actor.ps.equipment.items[gear.id]
end
local instance=build()
local original=p.ps.equipment
local id=review(instance)
assert(not B.Confirm(p,id,'items',{}) and p.ps.equipment==original)
assert(not B.Confirm(p,id,'collateral') and p.ps.equipment==original and not instance.recovered)
assert(B.Cancel(p,id) and not B.Reviews[p] and p.ps.equipment==original)
assert(not B.Confirm(p,id,'collateral') and instance.state=='active')
local low=item(p,'low');id=review(instance)
assert(E:Value(low)==49 and not B.Confirm(p,id,'items',{low.id}) and original.items[low.id]==low)
local exact=item(p,'exact');id=review(instance)
assert(E:Value(exact)==50)
assert(not B.Confirm(p,id,'items',{exact.id,exact.id}),'Duplicate selected IDs cannot double their value')
assert(not B.Confirm(p,id,'items',{q.id}),'Another account is not an owned equipment ID')
local accepted,receipt=B.Confirm(p,id,'items',{exact.id})
assert(accepted and receipt.value==50 and instance.state=='resolved' and instance.barrier:GetOpened())
assert(p.ps.equipment~=original and not p.ps.equipment.items[exact.id] and p.ps.equipment.items[low.id])
assert(original.items[exact.id]==exact,'Detached settlement cannot mutate the prior inventory')
assert(not B.Confirm(p,id,'items',{low.id}) and not B.Reviews[p])
local snapshot=D:Snapshot(q)
assert(snapshot.events[1].state=='resolved' and snapshot.events[1].details.opened,'Late joins receive shared opening')

-- Each excluded item is evaluated through the existing exchange authority.
instance=build()
local gear=item(p)
local state=p.ps.equipment
assert(B.PaymentEligible(state,gear.id))
assert(E:Equip(state,gear.id,'left_hand'));assert(not B.PaymentEligible(state,gear.id));E:UnequipItem(state,gear.id)
for _,field in ipairs({'bound','economyExcluded','recreatedFrom'}) do
 gear[field]=true;assert(not B.PaymentEligible(state,gear.id),field);gear[field]=nil
end
local weapon=E:Generate(989898,1,'weapon_pistol','bribe-weapon')
assert(E:StoreWearable(state,weapon) and not B.PaymentEligible(state,weapon.id))
local generatedValue=E:Value(gear)
id=review(instance)
assert(B.Confirm(p,id,'items',{gear.id}) and instance.result.value==generatedValue and instance.result.price==50)
assert(not p.ps.equipment.items[gear.id],'Excess item value is wholly surrendered; no wallet credit')

-- Guaranteed collateral is shared, never ordinary spendable inventory, and
-- costs no bag space even at the canonical storage ceiling.
instance=build()
for n=1,E:StorageCapacity(p.ps.equipment) do item(p) end
original=p.ps.equipment
local before=copy(original)
recover(instance,q)
assert(not p.ps.equipment.items[instance.collateral.id] and not q.ps.equipment.items[instance.collateral.id])
id=review(instance)
assert(B.Cancel(p,id) and instance.recovered and not instance.collateralSpent and same(original,before))
id=review(instance)
assert(B.Confirm(p,id,'collateral') and instance.collateralSpent and same(p.ps.equipment,before))
assert(not p.ps.equipment.items[instance.collateral.id] and E:StoredEquipmentCount(p.ps.equipment)==E:StorageCapacity(p.ps.equipment))

-- Canonical staging failures leave exact live ownership untouched.
for _,method in ipairs({'StoreWearable','Discard'}) do
 for _,throws in ipairs({false,true}) do
  instance=build();recover(instance);id=review(instance);original=p.ps.equipment
  local saved=E[method]
  E[method]=function(_,staged)
   assert(staged~=original);staged.items.injected={}
   if throws then error('injected staging failure') end
   return false
  end
  assert(not B.Confirm(p,id,'collateral') and p.ps.equipment==original and not original.items.injected)
  assert(instance.state=='active' and not instance.collateralSpent and not instance.settling)
  E[method]=saved
  assert(B.Confirm(p,id,'collateral'),'Same unspent quote retries after temporary staging failure')
 end
end

-- The shared lock rejects other Heroes inside native opening callbacks; only
-- the winner's exact inventory is replaced, and both reviews are invalidated.
instance=build();recover(instance)
local qgear=item(q);local qoriginal=q.ps.equipment
local pid,qid=review(instance,p),review(instance,q)
local prepare=B.PrepareOpen
B.PrepareOpen=function(i)
 assert(not B.Confirm(q,qid,'items',{qgear.id}),'Concurrent Hero bypassed the instance lock')
 assert(not D:Interact(i.entities[2],q),'Reentrant cache interaction cannot mutate settlement')
 return prepare(i)
end
assert(B.Confirm(p,pid,'collateral'))
B.PrepareOpen=prepare
assert(q.ps.equipment==qoriginal and qoriginal.items[qgear.id]==qgear and not B.Reviews[q])

-- Native opening can fail or throw after partially opening; the owned gate is
-- restored and the original inventory/collateral remain available.
for _,throws in ipairs({false,true}) do
 instance=build();recover(instance);id=review(instance);original=p.ps.equipment
 B.PrepareOpen=function(i) prepare(i);if throws then error('partial open failure') end;return false end
 assert(not B.Confirm(p,id,'collateral') and p.ps.equipment==original and instance.state=='active')
 assert(not instance.barrier:GetOpened() and instance.barrier:IsSolid())
 B.PrepareOpen=prepare
 assert(B.Confirm(p,id,'collateral'))
end

-- Every exact reviewed owner can change after native work; reject before the
-- first live inventory mutation, including in-place metadata/slot replacement.
local mutations={
 {'life',function(a) a.ps.equipmentLifeSerial=a.ps.equipmentLifeSerial+1 end},
 {'inventory',function(a) a.ps.equipment=copy(a.ps.equipment) end},
 {'items table',function(a) a.ps.equipment.items=copy(a.ps.equipment.items) end},
 {'slots table',function(a) a.ps.equipment.slots=copy(a.ps.equipment.slots) end},
 {'Hero',function(a) local replacement={};for k,v in pairs(a.ps) do replacement[k]=v end;a.ps=replacement end},
 {'account',function(a) a.id='76561198000999999' end},
 {'Hero identity',function(a) a.ps.identity='replaced' end},
 {'dead',function(a) a.dead=true end},
 {'Soldier',function(a) a.soldier=true end},
 {'inactive',function(a) a.active=false end},
 {'staging',function(a) a.ps.inStaging=true end},
 {'deployment',function(a) a.ps.deploymentComplete=false end},
 {'lives',function(a) a.ps.lives=0 end},
 {'eliminated',function(a) a.ps.eliminated=true end},
 {'frozen',function() Run.State.SimulationFrozen=true end},
 {'timeout',function() Run.State.CampaignClock={deadline=F.now-1} end},
 {'range',function(a) a.pos=Vector(-999999,-999999,-999999) end},
 {'gate owner',function(_,i) i.barrier.LODEventInstance={} end},
 {'terminal owner',function(_,i) i.entities[1].LODEventInstance={} end},
 {'cache owner',function(_,i) i.entities[2].LODEventInstance={} end},
 {'native invalid',function(_,i) i.barrier.valid=false end},
 {'collateral record',function(_,i) i.collateral=copy(i.collateral) end},
 {'collateral data',function(_,i) i.collateral.bound=true end},
 {'collateral recovered',function(_,i) i.recovered=false end},
 {'generation',function() Run.State.CampaignEpoch=Run.State.CampaignEpoch+1 end},
 {'cleanup',function() D:Cleanup('injected stale settlement') end}
}
for _,test in ipairs(mutations) do
 Run.State.SimulationFrozen,Run.State.CampaignClock=false,nil
 instance=build();recover(instance);gear=item(p);id=review(instance)
 original=p.ps.equipment;before=copy(original)
 B.PrepareOpen=function(i) local result=prepare(i);test[2](p,i);return result end
 assert(not B.Confirm(p,id,'items',{gear.id}),test[1])
 assert(original.items[gear.id] and same(original,before),test[1]..' consumed from original inventory')
 assert(not instance.result and not instance.settling,test[1]..' sealed a rejected settlement')
 if test[1]=='terminal owner' or test[1]=='cache owner' then
  assert(not instance.barrier:GetOpened() and instance.barrier:IsSolid(),'Exact native gate must close when an interaction owner changes')
 end
 B.PrepareOpen=prepare
end
Run.State.SimulationFrozen,Run.State.CampaignClock=false,nil
-- Final LOS callbacks run after native preparation: movement and gate closure
-- cannot hide behind earlier ownership/native checks.
local trace=util.TraceLine
for _,kind in ipairs({'range','reclose'}) do
 instance=build();recover(instance);id=review(instance);original=p.ps.equipment
 util.TraceLine=function(...)
  if instance.barrier:GetOpened() then
   if kind=='range' then p.pos=Vector(-999999,0,0) else instance.barrier:SetOpened(false);instance.barrier:SetSolid(SOLID_BBOX);instance.barrier:SetNotSolid(false) end
  end
  return trace(...)
 end
 assert(not B.Confirm(p,id,'collateral') and p.ps.equipment==original and instance.state=='active',kind)
 assert(not instance.barrier:GetOpened() and instance.barrier:IsSolid())
 util.TraceLine=trace
end
-- Cache recovery has its own post-LOS exact-life/role/range guards.
for _,kind in ipairs({'life','account','dead','range','clock'}) do
 instance=build();near(p,instance.entities[2])
 util.TraceLine=function(...)
  if kind=='life' then p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1
  elseif kind=='account' then p.id='76561198000123456'
  elseif kind=='dead' then p.dead=true
  elseif kind=='range' then p.pos=Vector(-999999,0,0)
  else Run.State.CampaignClock={deadline=F.now-1} end
  return trace(...)
 end
 assert(not B.Review(D,instance,p,'76561198000000001',instance.entities[2]) and not instance.recovered,kind)
 util.TraceLine=trace;Run.State.CampaignClock=nil
end
instance=build();recover(instance);id=review(instance)
F.now=F.now+B.ReviewSeconds+1
assert(not B.Confirm(p,id,'collateral') and instance.state=='active' and not instance.collateralSpent)
id=review(instance)
D:Cleanup('test teardown')
assert(not B.Reviews[p] and not B.Confirm(p,id,'collateral'))
for _,entity in ipairs(instance.entities) do assert(not IsValid(entity)) end

-- The client review sends only server review IDs and selected item IDs. Prove
-- explicit confirm/cancel callbacks and usable button allocation at 480px.
local widgets={}
ScrW=function() return 480 end;ScrH=function() return 360 end
TOP,BOTTOM,LEFT,FILL=1,2,3,4
local widget={};widget.__index=widget
for _,method in ipairs({'Center','SetTitle','MakePopup','Dock','DockMargin','SetWrap','SetMultiSelect','SetFixedWidth'}) do widget[method]=F.noop end
function widget:SetSize(w,h) self.width,self.height=w,h end
function widget:GetWide() return self.width end
function widget:SetWide(w) self.width=w end
function widget:SetTall(h) self.height=h end
function widget:SetText(text) self.text=text end
function widget:SetEnabled(enabled) self.enabled=enabled end
function widget:AddColumn() return setmetatable({},widget) end
function widget:AddLine() local line={};self.lines[#self.lines+1]=line;return line end
function widget:GetSelected() return self.selected or {} end
function widget:Close() if self.OnClose then self:OnClose() end;self.valid=false end
vgui={Create=function(kind,parent)
 local w=setmetatable({kind=kind,parent=parent,valid=true,lines={}},widget);widgets[#widgets+1]=w;return w
end}
local sent
net.Start=function(name) sent={name=name,ints={},strings={}} end
net.WriteUInt=function(value) sent.ints[#sent.ints+1]=value end
net.WriteString=function(value) sent.strings[#sent.strings+1]=value end
net.SendToServer=F.noop
local quote={id=313,price=50,seconds=45,items={{id='owned:one',name='Exact Ring',value=50}},collateral={name='Recovered Ring',value=100}}
net.ReadTable=function() return quote end
dofile(root..'cl_event_bribe_payment.lua')
local function show()
 widgets={};F.receivers.LOD_BribeReview()
 local frame,list,confirm,cancel,collateral
 for _,w in ipairs(widgets) do
  if w.kind=='DFrame' then frame=w
  elseif w.kind=='DListView' then list=w
  elseif w.text=='CONFIRM SELECTED PAYMENT' then confirm=w
  elseif w.text=='CANCEL' then cancel=w
  elseif w.text and w.text:find('SURRENDER SHARED') then collateral=w end
 end
 assert(frame.width==440 and confirm.width<frame.width-100,'Cancel must remain usable on a narrow screen')
 return frame,list,confirm,cancel,collateral
end
local frame,list,confirm,cancel,collateral=show()
cancel:DoClick();assert(sent.ints[1]==313 and sent.ints[2]==0)
frame,list,confirm,cancel,collateral=show()
list.selected={list.lines[1]};list:Think();assert(confirm.enabled)
confirm:DoClick();assert(sent.name=='LOD_BribeDecision' and sent.ints[2]==2 and sent.ints[3]==1 and sent.strings[1]=='owned:one')
assert(#sent.ints==3 and #sent.strings==1,'Client must not send mutable prices or item records')
frame,list,confirm,cancel,collateral=show()
collateral:DoClick();assert(sent.ints[2]==1 and #sent.strings==0)
print('BRIBE_PAYMENT_PASS: real eligibility/value/staging; exact threshold/insufficient/duplicates/overpayment; cancel/retry/full-bag shared collateral; atomic concurrent payment; native rollback; exact inventory/Hero/life/account/resources/post-LOS ownership; expiry/cleanup/late joins')
