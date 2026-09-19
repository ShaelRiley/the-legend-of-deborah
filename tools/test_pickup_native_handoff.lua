local env=dofile('tools/test_equipment_economy_runtime.lua')
LOD.RunManager.IsDungeonPlayer=LOD.RunManager.IsActivePlayer
local Loot,E=LOD.LootDirector,LOD.Equipment
local hero=env.actor('pickup-owner');env.Run.State.PlayerState={['pickup-owner']=hero.ps}
player.GetAll=function() return {hero} end
local pending,stages,records={},{},{}
timer.Simple=function(_,fn) pending[#pending+1]=fn end
local function flush() local work=pending;pending={};for _,fn in ipairs(work) do fn() end end
LOD.RPGTestLog={Write=function(_,event,fields) assert(event=='LOOT_NATIVE_STAGE');stages[#stages+1]=fields.stage;records[#records+1]=fields end}
local oldInclude=include;include=function() end;ENT={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_loot_pickup/init.lua');include=oldInclude
local serial=2000
ents={}
ents.Create=function(class)
 assert(class=='lod_loot_pickup');serial=serial+1
 local ent=setmetatable({valid=true,id=serial,nw={}}, {__index=ENT})
 function ent:EntIndex() return self.id end
 function ent:SetModel(m) self.model=m end
 function ent:SetPos(v) self.pos=v end
 function ent:SetAngles() end
 function ent:SetMoveType() end
 function ent:SetSolid() end
 function ent:SetCollisionBounds() end
 function ent:SetTrigger() self:StartTouch(hero) end -- simulate overlap during spawn
 function ent:SetUseType() end
 function ent:SetCollisionGroup() end
 function ent:SetRenderMode() end
 function ent:SetColor() end
 function ent:SetModelScale() error('loot pickups must retain native model scale') end
 function ent:DrawShadow() end
 function ent:Spawn() self.spawning=true;self:Initialize();self.spawning=false end
 function ent:Activate() error('scaled pickup must not reactivate native model collision') end
 function ent:SetNW2String(k,v) self.nw[k]=v end
 function ent:SetNW2Int(k,v) self.nw[k]=v end
 function ent:SetPreventTransmit() assert(self.valid) end
 function ent:Remove() assert(not self.inTouch and not self.spawning);self.valid=false end
 return ent
end
util.IsValidModel=function() return true end
Angle=function() return {} end
local oldCollect=Loot.Collect
local grants=0
Loot.Collect=function(_,ent,p) assert(ent.LODLootReady and ent.LODLootRegistered and not ent.inTouch);assert(p==hero);grants=grants+1;ent.LODCollected=true;return true end
for _,family in ipairs({'boots','helmet','ring','weapon_357'}) do
 -- Use available canonical definitions for each model family.
 if E.Definitions[family] then
  local item=E:NewItem(hero,family,'native-'..family)
  local ent=assert(Loot:SpawnPickup('pickup-owner',Vector(), 'wearable',{item=item}))
  assert(ent.LODLootRegistered and not ent.LODLootReady and not ent.LODCollected)
  flush();assert(ent.LODLootReady)
  local n=grants;ent.inTouch=true;ent:Touch(hero);ent:Touch(hero);ent:Use(hero);ent.inTouch=false
  assert(ent.valid and grants==n,'no native grant or removal inside touch')
  flush();assert(not ent.valid and grants==n+1,'one deferred grant')
 end
end
local ent=assert(Loot:SpawnPickup('pickup-owner',Vector(),'life',{}))
assert(ent.scale==nil);ent:Remove();flush();assert(not ent.LODLootReady,'removed before arming')
assert(stages[#stages]=='registered')
-- Retain exact generator inputs before entering procedural preparation; replay
-- must reproduce the very same immutable item, not a vaguely similar reward.
records={}
local generated=assert(Loot:SpawnPickup('pickup-owner',Vector(),'weapon',
 {weaponClass='weapon_357'},{equipmentSeed=731,equipmentEligible=true}))
local begin,complete,prepared
for i,row in ipairs(records) do
 if row.stage=='equipment_generate_begin' then begin=row;assert(not complete) end
 if row.stage=='equipment_generate_complete' then complete=row;assert(begin) end
 if row.stage=='reward_prepared' then prepared=i;assert(complete) end
 if row.stage=='entity_create' then assert(prepared,'native creation preceded preparation evidence') end
end
assert(begin and complete and complete.key==begin.key and complete.seed==begin.seed)
local replay=E:Generate(begin.seed,begin.level,begin.family~='random' and begin.family or nil,begin.key)
assert(replay.id==generated.LODLootPayload.item.id and replay.name==generated.LODLootPayload.item.name)
-- Replay the actual final preparation, not just a direct generator call. The
-- campaign seed is reconstructed from the reversible hash and cross-checked
-- against all fourteen recorded seed/key pairs (not claimed as a logged field).
local oldRun=env.Run.State
env.Run.State={RunId='campaign:26',CampaignSeed=664744883,LevelSeed=1504071172,Level=1}
local corpus=dofile('tools/fixtures/equipment_crash_20260916.lua')
for _,row in ipairs(corpus) do
 assert(LOD.Seeds.Derive(env.Run.State.CampaignSeed,row.key)==row.seed)
end
records={}
local final=corpus[#corpus]
local native=assert(Loot:SpawnPickup('76561198025505071',Vector(),'wearable',{},
 {equipmentSeed=660600545,equipmentEligible=true}))
local expected=E:Generate(final.seed,final.level,nil,final.key)
assert(native.LODLootPayload.item.id==expected.id and native.LODLootPayload.item.name==expected.name)
assert(E:Description(native.LODLootPayload.item)==E:Description(expected))
local finalBegin,finalComplete
for _,row in ipairs(records) do
 if row.stage=='equipment_generate_begin' then finalBegin=row end
 if row.stage=='equipment_generate_complete' then finalComplete=row end
end
assert(finalBegin.seed==996257890 and finalBegin.key==final.key and finalComplete.family=='gloves')
env.Run.State=oldRun
local generate=E.Generate;E.Generate=function() error('injected preparation failure') end
local before=serial;stages={}
assert(not Loot:SpawnPickup('pickup-owner',Vector(),'weapon',{weaponClass='weapon_357'},{}))
assert(serial==before and stages[#stages]=='reward_prepare_error','failed preparation reached native creation')
E.Generate=generate
Loot.Collect=oldCollect
print('PICKUP_NATIVE_HANDOFF_PASS: real initialization and director registration, native model scale, overlap guard, deferred removal and duplicate touch isolation')
