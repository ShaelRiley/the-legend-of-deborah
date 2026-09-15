-- Count actual bullet callbacks, not the engine's merged damage notifications.
local env=dofile('tools/test_cross_feats_dodge.lua')
local Rolls,Rules,Status=env.Rolls,env.Rules,env.Status
local pending={};timer.Simple=function(_,fn) pending[#pending+1]=fn end
local function flush() local batch=pending;pending={};for _,fn in ipairs(batch) do fn() end end
local source=env.actor({},true)
source.state.derivedStats={physicalDamageBonus=0}
local weapon={valid=true,GetClass=function() return 'weapon_shotgun' end}
function source:GetActiveWeapon() return weapon end
function source:GetShootPos() return Vector(0,0,32) end
function source:GetPos() return Vector() end
local targets={}
local function victim()
 local v=env.actor()
 v.state.derivedStats={damageResistancePerDie=3}
 v.hits,v.amount=0,0
 function v:WorldSpaceCenter() return Vector(30,0,32) end
 function v:GetPos() return Vector(30,0,0) end
 function v:TakeDamageInfo(info)
  self.hits=self.hits+1;self.amount=self.amount+info:GetDamage()
  self.hp=self.hp-info:GetDamage()
  env.hooks.EntityTakeDamage.LOD_DiceDamageAuthority(self,info)
  Rolls:ReportResolvedDamage(info)
 end
 return v
end
LOD.M3HitFeedback=nil;LOD.Equipment=nil
Rolls._RNG=function() return {Int=function(_,lo) return lo end} end
LOD.GeneratedGeometryBallistics={SegmentBlocked=function(_,_,_,_,t) return t.blocked end}
local function fire(targets)
 local bullet={Src=source:GetShootPos(),Num=7}
 env.hooks.EntityFireBullets.LOD_DicePlayerFirearms(source,bullet)
 assert(GM:EntityFireBullets(source,bullet)==true,'Source must commit hook changes')
 assert(bullet.Num==9 and bullet.Callback,'utility count/collector missing')
 local contract=source.LODActiveShotgunRoll
 for _,t in ipairs(targets) do
  local info=DamageInfo();info:SetDamage(bullet.Damage)
  local result=bullet.Callback(source,{Entity=t,HitPos=t:WorldSpaceCenter()},info)
  assert(result.damage==false and info:GetDamage()==0,'native pellets must not enter mitigation')
 end
 return contract
end
local close=victim();local same={};for i=1,9 do same[i]=close end
local c=fire(same)
assert(c.hits[close]==9 and close.hits==0,'collect all nine before any native damage')
flush();assert(close.hits==1 and close.amount==9,'CON3 must not collapse a full shell to one pellet')
Rolls:SettleShotgun(source,c);assert(close.hits==1,'shell settlement is idempotent')
local armored=victim()
function armored:TakeDamageInfo(info) self.hp=self.hp-math.floor(info:GetDamage()/2) end
local armorShell=fire({armored,armored,armored,armored});flush()
assert(armorShell.damageByTarget[armored]==2,'feed must reflect native armor after mitigation')
local a,b=victim(),victim();fire({a,a,a,a,a,b,b,b,b});flush()
assert(a.hits==1 and a.amount==5 and b.hits==1 and b.amount==4,'split shell must aggregate per target')
local blocked=victim();blocked.blocked=true;fire({blocked});flush();assert(blocked.hits==0,'cover blocks shell')
local dead=victim();fire({dead});dead.valid=false;flush();assert(dead.hits==0,'removed target survives deferred callback')
local stale=victim();fire({stale});local old=source.state;source.state={};flush();source.state=old
assert(stale.hits==0,'role/progression transition invalidates pending attack')
local afterDeath=victim();fire({afterDeath});source.hp=0;flush();source.hp=100;assert(afterDeath.hits==0)
local respawn=victim();fire({respawn});env.hooks.PlayerDeath.LOD_CombatAttackLife(source)
env.hooks.PlayerSpawn.LOD_CombatAttackLife(source);flush();assert(respawn.hits==0,'same-frame respawn must cancel old shell')
local oldLevel=victim();fire({oldLevel});LOD.RunManager.State.LevelSeed=99;flush();assert(oldLevel.hits==0)
local x,y=victim(),victim();fire({x,x});fire({y,y,y});flush()
assert(x.amount==2 and y.amount==3,'same-frame shells must retain independent contracts')
local d={physicalDamageBonus=0}
for con=0,3 do
 for hit=1,36 do
  local n=Rules:ResolveDamageValues({contributions={3}},d,{damageResistancePerDie=con},
   {physical=true,shotgunHits=hit,shotgunShares=6})
  assert(n>=hit,'ordinary CON defeated pellet minimum')
 end
end
assert(Rules:ResolveDamageValues({contributions={3}},d,{},
 {physical=true,shotgunHits=9,shotgunShares=6,authoredScale=0})==0,'zero scale must remain zero')
-- Strong rolls retain authored scaling instead of gaining a new damage formula.
assert(Rules:ResolveDamageValues({contributions={6,4}},d,{damageResistancePerDie=3},
 {physical=true,shotgunHits=12,shotgunShares=6,authoredScale=2})==16)
print('SHOTGUN_NATIVE_PATH_PASS: actual pellets, Source commit, CON0..3, split targets, cover, lifecycle, idempotence, zero scale')
