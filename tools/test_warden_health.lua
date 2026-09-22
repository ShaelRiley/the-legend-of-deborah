dofile('tools/test_actor_progression.lua')
local C=LOD.CharacterProgressionSystem
function IsValid(v) return type(v)=='table' end
local noop=function() end
for _,level in ipairs({1,5,20,100}) do
 for _,size in ipairs({0.33,1,1.33}) do
  local previous
  for party=1,4 do
   local e={LODHostile=true,LODArchetypeId='warden',LODWardenParty=party,LODVariance={size=size},hp=3333}
   e.SetNW2String=noop;e.SetNW2Int=noop
   function e:GetMaxHealth() return self.hp end
   function e:SetMaxHealth(n) self.maximum=n end
   function e:SetHealth(n) self.hp=n end
   local expected=assert(C:GenerateMonsterProgression('warden',1337,level,1000,'ai'))
   local state=assert(C:AttachMonsterProgression(e,1337,level))
   assert(state.level==level+math.floor(level/3)+2 and state.tierId=='champion')
   local rng=LOD.RNG.New(LOD.Seeds.Derive(1337,'rpg:warden-health-variation'))
   local hp=math.floor(expected.derivedStats.maxHP*size*rng:Float(0.94,1.06)*(1+0.2*(party-1))+0.5)
   assert(e.hp==hp and e.maximum==hp,'wrong RPG -> variation -> party health order '..e.hp..' vs '..hp..' scale='..state.wardenHPScale)
   assert(state.startingHP==1000 and state.progressionHitDieSides==20)
   if previous then assert(e.hp>previous.hp);assert(state.derivedStats.physicalDamageBonus==previous.state.derivedStats.physicalDamageBonus,'party changes damage') end
   previous={hp=e.hp,state=state}
   e.hp=1;assert(C:AttachMonsterProgression(e,1337,level)==state and e.hp==1,'repeat attach healed Warden')
  end
 end
end
print('WARDEN_HEALTH_PASS: production actor pipeline; D+floor(D/3)+2 Champion, 1000 reference+d20/CON, size/variance then 1/1.2/1.4/1.6 party HP; no damage multiplier or reattach healing')
