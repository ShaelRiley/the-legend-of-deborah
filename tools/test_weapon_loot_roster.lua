local f=dofile('tools/test_equipment_economy_runtime.lua')
local E,L,R=LOD.Equipment,LOD.LootDirector,f.Run
local p=f.actor('weapon-roster');R.State.PlayerState[p.id]=p.ps
p:Give('weapon_pistol');p:Give('weapon_lod_crowbar');p:SelectWeapon('weapon_pistol');E:Sync(p)
local function sample(level,owned)
 R.State.Level=level;local counts={};local generated={}
 for i=1,2400 do
  local seed=i*173
  local class=L:_MissingWeaponReward(p,LOD.RNG.New(seed))
  assert(class==L:_MissingWeaponReward(p,LOD.RNG.New(seed)),'Identical acquisition state/seed replays')
  counts[class]=(counts[class] or 0)+1
  local kind,payload=L:ResolveEnemyReward(p,'weapon',LOD.RNG.New(seed))
  assert(kind=='weapon')
  kind,payload=E:PrepareReward(p.id,kind,payload,{staticId='roster:'..level..':'..i,equipmentEligible=true})
  if payload.item and payload.item.definitionId==class then
   assert(E:ValidateWearable(payload.item) and #payload.item.properties>=4)
   generated[class]=(generated[class] or 0)+1
  end
 end
 for _,class in ipairs(L:_AllowedWeaponClasses(level)) do
  assert((counts[class] or 0)>120,'Ordinary pool frequency: '..class)
  assert((generated[class] or 0)>50,'Natural procedural conversion: '..class)
 end
 if level==1 then assert(not counts.weapon_357 and not counts.weapon_ar2,'Preserve advanced-family dungeon gates') end
 print('WEAPON_ROSTER_SAMPLE',level,owned,counts.weapon_pistol,counts.weapon_lod_crowbar)
end
sample(1,'starter families')
for _,class in ipairs(E.WeaponFamilies) do p:Give(class) end
sample(3,'all families')
-- Acquisition/equipping selects the rolled copy on the actual held entity.
for _,class in ipairs({'weapon_pistol','weapon_lod_crowbar'}) do
 R.State.Level=10
 local item=E:Generate(9876,10,class,'upgraded:'..class)
 assert(E:AcquireWorldItem(p,item,false,'pickup'))
 assert(E:InventoryWeapon(p,item.id,false))
 assert(p:GetActiveWeapon():GetClass()==class)
 assert(p:GetActiveWeapon().nw.LOD_WeaponAppearance==LOD.WeaponAppearance:Encode(item))
 assert(E:Equipped(p.ps.equipment,class).id==item.id)
end
print('WEAPON_LOOT_ROSTER_PASS: 4800 deterministic ordinary reward samples, early upgraded starter families, late duplicates, progression gates, real held-copy stamping')
