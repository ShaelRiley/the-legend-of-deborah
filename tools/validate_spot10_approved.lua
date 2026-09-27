-- Approved SPOT-10 contracts. Real catalog, defense, resource and drain methods;
-- native actors, clock, transport and profile bindings are boundary doubles.
local timers, hooks, now, checks = {}, {}, 10, 0
function CurTime() return now end
timer = {Create=function(id,_,_,fn) timers[id]=fn end, Simple=function() end,
 Remove=function(id) timers[id]=nil end, Exists=function(id) return timers[id]~=nil end}
hook = {Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
 GetTable=function() return hooks end}
dofile('tools/test_checkpoint_d_closure.lua')
local function expect(v,msg) checks=checks+1;assert(v,'SPOT10 '..checks..': '..msg) end
local function near(a,b,msg) expect(math.abs(a-b)<1e-8,msg..': '..a..' ~= '..b) end
local RPG,Rules,E,P=LOD.RPG,LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem,LOD.CharacterProgressionSystem
local C=RPG.IdentityCatalog.OrdinaryFeats
-- A remains rejected, including the cumulative effect of legitimately owned ranks.
expect(C.DEX_EXPLODE_D8.prerequisiteFeatIds[1]=='DEX_EXPLODE_D10','A: d8 prerequisite retained')
expect(C.DEX_EXPLODE_D4.prerequisiteFeatIds[1]=='DEX_EXPLODE_D8','A: d4 prerequisite retained')
local dice=E:ExplodingDiceProfile({featIds={'DEX_EXPLODE_D4'}}).enabledBySides
expect(dice[4] and dice[8] and dice[10],'A: cumulative existing ownership retained')
local bounds={{'INT_MANA_SPRING','int',13},{'WIS_FRUGAL_MAP','wis',15},{'WIS_MIND_OVER_MATTER','wis',17}}
for _,v in ipairs(bounds) do
 expect(C[v[1]].abilityRequirements[v[2]]==v[3],v[1]..' unchanged threshold')
 expect(C[v[1]].featId==v[1] and C[v[1]].rankIndex==1,v[1]..' stable ID/rank')
end
expect(C.WIS_MIND_OVER_MATTER.prerequisiteFeatIds[1]=='WIS_TRUE_FAITH','B prerequisite retained')
expect(C.INT_MANA_SPRING.requiredCapabilityTags[1]=='magic_pool','spring capability')
expect(C.WIS_FRUGAL_MAP.requiredCapabilityTags[1]=='minimap','map capability')
expect(C.WIS_MIND_OVER_MATTER.effectParams.cooldownSeconds==3 and C.WIS_MIND_OVER_MATTER.effectParams.cooldownDice==nil,'B fixed duration/no dice')
expect(C.WIS_FRUGAL_MAP.effectParams.mapDrainMultiplier==.75,'C registered rate')
expect(C.INT_MANA_SPRING.effectParams.description:find('22%%')~=nil,'spring card')
expect(C.WIS_FRUGAL_MAP.effectParams.description:find('Haste')~=nil,'C Haste disclosure')
expect(not C.WIS_MIND_OVER_MATTER.effectParams.description:find('3d4',1,true),'B card has no retired dice')
for _,pool in ipairs({0,1,50,99,100}) do
 for _,enabled in ipairs({false,true}) do
  for _,permitted in ipairs({false,true}) do
   local m,w,r,s,a=E:ResolveManaSpringTick(enabled,pool,true,3.75,permitted,100)
   local active=enabled and permitted and pool<100
   near(m,active and 1.22 or 1,'spring exact multiplier')
   expect(not w and r==0 and not s and a==active,'spring clears legacy state; no timer/trigger')
  end
 end
end
-- Map floor precedes Haste rank fraction, without a second feat discount.
for _,u in ipairs({.6,.85,1,1.4}) do
 local d={utilityMagicCostMultiplier=u,mapDrainFeatMultiplier=.75,minimumMapDrainPerSecond=3}
 near(Rules:MapDrainPerSecondFromDerived(100/15,d),math.max(3,100/15*u*.75),'C exact map rate')
end
near(Rules:MapDrainPerSecondFromDerived(2,{utilityMagicCostMultiplier=1,mapDrainFeatMultiplier=.75,minimumMapDrainPerSecond=3}),3,'C lower base retains floor')

-- Boundary actor profiles; native resource/defense methods remain production.
function IsValid(v) return type(v)=='table' and v.valid~=false end
local actors={}
local function actor(id,kind,owned)
 local a={id=id,kind=kind,valid=true,active=true,hp=100,nw={},ps={magic=50},state={actorType=kind,usesMagic=true,featIds=owned or {}}}
 a.state.derivedStats={magicRegenMultiplier=1,wizardCapstoneMagicRegenMultiplier=1,utilityMagicCostMultiplier=.6,wisMod=3}
 E:ApplyDerived(a.state,a.state.derivedStats)
 function a:IsPlayer() return self.kind~='ai' end
 function a:Alive() return self.hp>0 end
 function a:Health() return self.hp end
 function a:EntIndex() return self.id end
 function a:SetNW2Float(k,v) self.nw[k]=v end
 function a:SetNW2Int(k,v) self.nw[k]=v end
 function a:SetNW2Bool(k,v) self.nw[k]=v end
 return a
end
Rules.ProgressionState=function(_,a) return a and a.state end
Rules.Derived=function(_,a) return a and a.state and a.state.derivedStats end
LOD.RunManager={State={},LODMagicWrapped=true,
 GetPlayerState=function(_,a) return a.ps end,
 IsActivePlayer=function(_,a) return a.active and a.kind=='hero' end,
 IsSoldierControl=function(_,a) return a.active and a.kind=='human_soldier' end}
player.GetHumans=function() local out={};for _,a in ipairs(actors) do if a:IsPlayer() then out[#out+1]=a end end;return out end
player.GetAll=player.GetHumans
net.Start=function() end;net.WriteString=function() end;net.Send=function() end
local receivers, mapOpen = {}, false
net.Receive=function(name,fn) receivers[name]=fn end
net.ReadBool=function() return mapOpen end
LOD.MinimapServer={CanUse=function(_,a) return a.active end}
GetConVar=function(name) return {GetBool=function() return name~='lod_mapless' end} end
hook.Run=function(event,a,ps)
 if event=='LODMagicRegenerationSuppressed' then
  local haste=hooks[event] and hooks[event].LOD_RPG_CheckpointDHaste
  return a.suppressed or (haste and haste(a,ps)) or false
 end
end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_magic.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_minimap_magic.lua')
local M,Map=LOD.Magic,LOD.MinimapMagic
local function setMap(a,open)
 mapOpen=open;receivers.LOD_MapMagicState(1,a)
end
local tick=assert(timers.LOD_MagicRegen)
for _,kind in ipairs({'hero','human_soldier','ai'}) do
 local a=actor(1,kind,{'INT_MANA_SPRING'});actors={a}
 local ps=assert(M:_EnsureState(a));ps.magic=50;ps.manaSpringWaiting=true;ps.manaSpringRemainingSeconds=4
 tick();near(ps.magic,50+(100/240)*1.22,kind..' actual timer restores without empty trigger')
 expect(ps.manaSpringWaiting==false and ps.manaSpringRemainingSeconds==0,kind..' legacy resource state cleared')
 -- No four-second expiry. Capstone and ability contributions compose once.
 ps.magic=20;a.state.derivedStats.magicRegenMultiplier=2;a.state.derivedStats.wizardCapstoneMagicRegenMultiplier=1.5
 for i=1,20 do now=now+.25;tick() end
 near(ps.magic,20+20*(100/240)*2*1.5*1.22,kind..' sustained >4sec and existing modifiers')
 ps.magic=99.9;tick();near(ps.magic,100,kind..' hard capacity')
 ps.magic=50;a.suppressed=true;tick();near(ps.magic,50,kind..' sustained suppression')
 a.suppressed=false;setMap(a,true)
 expect(Map:IsOpen(a)==a:IsPlayer(),kind..' only a player owns an admitted map session')
 tick();near(ps.magic,a:IsPlayer() and 50 or 50+(100/240)*2*1.5*1.22,kind..' admitted map suppression')
 setMap(a,false)
 a.state.featIds={};E:ApplyDerived(a.state,a.state.derivedStats);ps.magic=50;tick()
 near(ps.magic,50+(100/240)*Rules:MagicRegenMultiplier(a),kind..' removal stops spring multiplier')
 a.state.featIds={'INT_MANA_SPRING'};E:ApplyDerived(a.state,a.state.derivedStats)
 a.hp=0;ps.magic=50;tick();near(ps.magic,50,kind..' death does not regenerate')
 M.ActivePools[a]=nil
end
-- Real Haste rate/activation and actual additive map + Haste drain callbacks.
local a=actor(2,'hero',{'INT_MANA_SPRING','WIS_FRUGAL_MAP','INT_HASTE_3'});actors={a};a.ps.magic=60
near(Rules:MapDrainPerSecond(a,100/15),3,'C native personal floor')
near(Rules:HasteDrainPerSecond(a),1,'C Haste rank applies after map floor')
expect(Rules:SetHasteActive(a,true),'Haste activation retained')
tick();near(a.ps.magic,60,'spring cannot restore under Haste')
setMap(a,true);Map.Active[a].lastTick=now-.1
E.HasteState[a].lastAt=now-.1
timers.LOD_RPG_CheckpointDHasteDrain();timers.LOD_MinimapMagicDrain()
near(a.ps.magic,59.6,'map plus Haste debit independently, no duplicate discount')
setMap(a,false);Rules:SetHasteActive(a,false)
a.ps.magic=100;tick();near(a.ps.magic,100,'full resource no overfill')
a.active=false;a.ps.magic=50;tick();near(a.ps.magic,50,'spectator resource untouched')
a.active=true
local old=a.ps;a.ps={magic=20};tick();near(old.magic,50,'replacement does not mutate old pool')
near(a.ps.magic,20+(100/240)*1.22,'replacement uses current owned profile')
LOD.RunManager.State.Failed=true;local before=a.ps.magic;tick();near(a.ps.magic,before,'failed campaign skips regeneration');LOD.RunManager.State.Failed=false
-- B actual defense function: after upstream classification, before diversion.
local S=LOD.RPGStatusElements
S.DamageContext=function(_,d) return d.context end
S.AttachDamageContext=function(_,d,c) d.context=c end
Rules.EnemyDefenseNotice=function() end
local function hit(target,amount,physical,magical)
 local d={damage=amount,context={physical=physical,magical=magical}}
 function d:GetDamage() return self.damage end
 function d:SetDamage(v) self.damage=v end
 Rules:ApplyWisDefense(target,d);return d.damage
end
local oldRNG=LOD.RNG.New;LOD.RNG.New=function() error('B must not roll timing dice') end
for _,kind in ipairs({'hero','human_soldier','ai'}) do
 local t=actor(3,kind,{'WIS_TRUE_FAITH','WIS_MIND_OVER_MATTER'});now=100
 near(hit(t,12,true,false),9,kind..' B first physical reduction');near(t.LODMindOverMatterReadyAt,103,'B exact deadline')
 now=102.999;near(hit(t,12,true,false),12,'B before deadline');near(t.LODMindOverMatterReadyAt,103,'B no refresh in recovery')
 now=103;near(hit(t,12,true,false),9,'B boundary ready')
 t.LODMindOverMatterReadyAt=nil;near(hit(t,12,false,true),9,'B magical-only True Faith')
 expect(t.LODMindOverMatterReadyAt==nil,'B magical-only no consume')
 near(hit(t,12,true,true),6,'B mixed event once per defense');near(hit(t,12,true,true),9,'B mixed during recovery')
 t.LODMindOverMatterReadyAt=nil;near(hit(t,2,true,false),0,'B damage never negative')
 t.LODMindOverMatterReadyAt=nil;t.state.derivedStats.wisMod=-1;near(hit(t,12,true,false),12,'B negative WIS no extra damage')
end
LOD.RNG.New=oldRNG
print('SPOT10_APPROVED_PASS '..checks..' focused assertions; actual Lua paths, native boundary doubles')
