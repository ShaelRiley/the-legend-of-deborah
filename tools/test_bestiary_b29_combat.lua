-- Real final GM damage method, shared condition entry, and Pushback early gate.
-- Spatial unit fixture supplements (does not replace) full-build B29 coverage.
local env=dofile('tools/test_cross_feats_dodge.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local R=LOD.RunManager
LOD.Config.Maze={Origin=Vector(),CellSize=256,LevelHeight=256,Width=1,Height=1}
LOD.MazeGenerator={CellKey=function(x,y,z)return x..':'..y..':'..z end}
LOD.MazeNavigator={CellCenter=function()return Vector()end}
R.IdentityOf=function(_,p)return p.id end
R.State.Graph={Cells={},EntrySafety={cells={['1:1:0']=true},centers={Vector()},depth={}}}
LOD.FactionManager={IsEnemyCombatant=function(_,e)return e.LODHostile end,LivingTargets=function()return {} end}
dofile(root..'sv_entry_safety.lua')
local S=LOD.EntrySafety
local hero,enemy=env.actor({},true),env.actor()
hero.cell=Vector(0,0,12);enemy.cell=Vector(1000,0,12)
local protectedMagic=hero.resource.magic
local info=DamageInfo();info:SetAttacker(enemy);info:SetInflictor(enemy);info:SetDamage(12)
assert(GM:EntityTakeDamage(hero,info)==true and info:GetDamage()==0,'GM final native damage not refused')
assert(hero.resource.magic==protectedMagic,'sanctuary damage spent defense resource')
info:SetAttacker(hero);info:SetDamage(12)
assert(GM:EntityTakeDamage(enemy,info)==true and info:GetDamage()==0,'GM outgoing fire not refused')
local proxy={valid=true,IsPlayer=function()return false end,GetOwner=function()return hero end}
info:SetAttacker(proxy);info:SetDamage(12)
assert(GM:EntityTakeDamage(enemy,info)==true and info:GetDamage()==0,'GM proxy fire not refused')
local draws=0;local rng={Int=function()draws=draws+1;return 20 end}
local ok,why=env.Status:Apply(hero,'poisoned',enemy,{rng=rng})
assert(not ok and why=='entry_sanctuary_or_pressure' and draws==0,'incoming condition rolled/applied')
ok,why=env.Status:Apply(enemy,'poisoned',hero,{rng=rng})
assert(not ok and why=='entry_sanctuary_or_pressure' and draws==0,'outgoing condition rolled/applied')
assert(not env.Status:CanInitiateAttack(hero),'safe Hero started ordinary attack')
dofile(root..'sv_pushback.lua')
assert(LOD.Pushback:Apply(hero,{attacker=enemy,distance=168})==nil,'incoming displacement reached push RNG')
assert(LOD.Pushback:Apply(enemy,{attacker=hero,distance=168})==nil,'outgoing displacement reached push RNG')
hero.cell=Vector(1000,0,12)
assert(S:CombatAllowed(hero,enemy) and env.Status:CanInitiateAttack(hero),'ordinary combat remained suppressed outside')
print('B29_COMBAT_PASS real GM bilateral native/proxy damage; no defense resource spend; real incoming/outgoing condition pre-RNG gate; attack initiation; push pre-RNG; outside admission restored')
