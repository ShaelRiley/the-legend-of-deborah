-- Real canonical actor generation/attachment; native combat acceptance is separate.
dofile('tools/test_actor_progression.lua')
local C=LOD.CharacterProgressionSystem
function IsValid(v) return type(v)=='table' end
local noop=function() end
for _,seed in ipairs({42,1337,424242}) do
 local previous
 for party=1,4 do
  local e={LODHostile=true,LODHector=true,LODArchetypeId='hector',LODHectorParty=party,
   LODVariance={size=1},hp=99999}
  e.SetNW2String,e.SetNW2Int=noop,noop
  function e:GetMaxHealth() return self.hp end
  function e:SetMaxHealth(n) self.maximum=n end
  function e:SetHealth(n) self.hp=n end
  local expected=assert(C:GenerateMonsterProgression('hector',seed,20,420,'ai'))
  local s=assert(C:AttachMonsterProgression(e,seed,20))
  assert(s.level==28 and s.tierId=='champion','Level20 canonical champion growth')
  assert(s.startingHP==420 and s.progressionHitDieSides==20,'reference pool and hit die')
  assert(s.derivedStats.healthRegenEnabled==false,'Hector must not regenerate')
  assert(e.hp==math.floor(expected.derivedStats.maxHP*(1+.2*(party-1))+.5),'party scale applied once after growth')
  assert(e.maximum==e.hp and e.hp==s.derivedStats.maxHP,'one health authority')
  assert(LOD.RPG.ArchetypeProgressionTemplates.hector.baseXp==500,'canonical XP template')
  if previous then
   assert(e.hp>previous.hp,'party health monotonic')
   for _,field in ipairs({'physicalDamageBonus','magicDamageBonus','physicalDamageReduction','magicDefenseReduction'}) do
    assert(s.derivedStats[field]==previous.s.derivedStats[field],'party must not inflate damage/defenses '..field)
   end
  end
  previous={hp=e.hp,s=s}
  e.hp=7;e.LODHectorParty=4
  assert(C:AttachMonsterProgression(e,seed,20)==s and e.hp==7,'late joins/revival never reattach/heal/rescale')
 end
end
-- Real variance entrypoint must preserve a fixed core and finite stationary
-- speed metadata while still attaching canonical progression exactly once.
LOD.Config=LOD.Config or {};LOD.Config.Encounter=LOD.Config.Encounter or {}
LOD.Config.Encounter.InstanceVariance={}
LOD.RunManager={State={Level=20,LevelSeed=44}}
scripted_ents={GetStored=function() return nil end}
-- Hector has no independent health-dice profile; its authored reference is420.
LOD.CombatRolls.RollEnemyHealth=function() return nil end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_variance.lua')
local e={LODHostile=true,LODHector=true,LODArchetypeId='hector',LODHectorParty=2,
 LODInstanceSeed=1337,LODConfig={baseHP=420,speed=0,meleeDamage=8},hp=420}
e.SetNW2String,e.SetNW2Int,e.SetNW2Float,e.SetModelScale=noop,noop,noop,noop
function e:GetPos() return {} end
function e:GetMaxHealth() return self.hp end
function e:SetMaxHealth(n) self.maximum=n end
function e:SetHealth(n) self.hp=n end
LOD.EnemyVariance:Apply(e)
assert(e.LODVariance.size==1 and e.LODVariance.speedScale==1 and e.LODConfig.speed==0,'fixed finite stationary core')
assert(e.LODProgressionState.startingHP==420 and e.LODProgressionState.level==28,'variance delegates actor growth')
e.hp=9;LOD.EnemyVariance:Apply(e);assert(e.hp==9,'variance reentry must not heal')
print('HECTOR_HEALTH_PASS: canonical champion28, 420 reference+d20/CON/feats, frozen 1/1.2/1.4/1.6 HP, standard XP, no regeneration or reattach healing')
