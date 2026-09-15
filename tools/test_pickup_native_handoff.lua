local env=dofile('tools/test_equipment_economy_runtime.lua')
local Loot,E=LOD.LootDirector,LOD.Equipment
local hero=env.actor('pickup-owner');env.Run.State.PlayerState={['pickup-owner']=hero.ps}
player.GetAll=function() return {hero} end
local pending,stages={},{}
timer.Simple=function(_,fn) pending[#pending+1]=fn end
local function flush() local work=pending;pending={};for _,fn in ipairs(work) do fn() end end
LOD.RPGTestLog={Write=function(_,event,fields) assert(event=='LOOT_NATIVE_STAGE');stages[#stages+1]=fields.stage end}
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
 function ent:SetModelScale(v) self.scale=v end
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
Loot.Collect=function(_,ent,p) assert(ent.LODLootReady and ent.LODLootRegistered);assert(p==hero);grants=grants+1;ent.LODCollected=true;return true end
for _,family in ipairs({'boots','helmet','ring','weapon_357'}) do
 -- Use available canonical definitions for each model family.
 if E.Definitions[family] then
  local item=E:NewItem(hero,family,'native-'..family)
  local ent=assert(Loot:SpawnPickup('pickup-owner',Vector(), 'wearable',{item=item}))
  assert(ent.LODLootRegistered and not ent.LODLootReady and not ent.LODCollected)
  flush();assert(ent.LODLootReady)
  local n=grants;ent.inTouch=true;ent:Touch(hero);ent:Touch(hero);ent:Use(hero);ent.inTouch=false
  assert(ent.valid and grants==n+1,'one grant, no removal inside touch')
  flush();assert(not ent.valid)
 end
end
local ent=assert(Loot:SpawnPickup('pickup-owner',Vector(),'life',{}))
assert(ent.scale==1.35);ent:Remove();flush();assert(not ent.LODLootReady,'removed before arming')
assert(stages[#stages]=='registered')
Loot.Collect=oldCollect
print('PICKUP_NATIVE_HANDOFF_PASS: real initialization and director registration, no scaled activation, overlap guard, deferred removal and duplicate touch isolation')
