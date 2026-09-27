-- Real faction, status, GM and multiplayer gates; native transport is a boundary.
local root='gamemodes/legend_of_deborah/gamemode/'
local noop=function() end
local clock=100
SERVER=true;CLIENT=false;GM={};unpack=table.unpack
function CurTime() return clock end
function IsValid(v) return type(v)=='table' and v.valid==true end
function ErrorNoHalt(s) error(s) end
function math.Clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function table.Copy(v) if type(v)~='table' then return v end;local c={};for k,x in pairs(v) do c[k]=table.Copy(x) end;return c end
DeriveGamemode=noop;AddCSLuaFile=noop;include=noop;Color=function(...) return {...} end
Vector=function(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end;vector_origin=Vector()
timer={Create=noop,Remove=noop,Simple=noop};concommand={Add=noop};GetConVar=function() return nil end
local hooks={}
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
 GetTable=function() return hooks end,Run=noop}
local humans,monsters={},{}
player={GetAll=function() return humans end}
LOD={Config={},RunManager={State={Graph={},LevelSeed=1,CampaignEpoch=1,BuildReady=true}},RPGAbilityRules={}}
local R=LOD.RunManager
function R:IsActivePlayer(p) return p.active==true and not self:IsSoldierControl(p) end
function R:IsSoldierControl(p) return p.soldier==true end
function R:GetPlayerState(p) return p.LODProgressionState end
LOD.HostileRegistry={List=function() return monsters end}
function LOD.RPGAbilityRules:ProgressionState(p) return p and p.LODProgressionState end
-- shared.lua is executed, not text-extracted; child includes are independent test units.
dofile(root..'shared.lua')
dofile(root..'lod/sh_rng.lua');dofile(root..'lod/sh_rpg_schema.lua')
dofile(root..'lod/sv_faction_manager.lua')
dofile(root..'lod/sv_multiplayer_contracts.lua')
dofile(root..'lod/sv_rpg_status_elements.lua')
local F,S=LOD.FactionManager,LOD.RPGStatusElements
local serial=0
local function actor(kind)
 serial=serial+1
 local p={valid=true,hp=100,index=serial,active=kind=='hero',soldier=kind=='soldier',LODHostile=kind=='enemy',
  LODSummonedSeeker=kind=='summon',LODProgressionState={level=1,abilities={},derivedStats={}}}
 function p:IsPlayer() return kind=='hero' or kind=='soldier' or kind=='spectator' end
 function p:Alive() return self.hp>0 end
 function p:Health() return self.hp end
 function p:EntIndex() return self.index end
 function p:GetOwner() return self.owner end
 function p:SetNW2Bool() end;function p:SetNW2Float() end
 return p
end
local h,h2,s,s2,m,m2,summon,watcher=actor('hero'),actor('hero'),actor('soldier'),actor('soldier'),actor('enemy'),actor('enemy'),actor('summon'),actor('spectator')
humans={h,h2,s,s2,watcher};monsters={m,m2};LOD.MagicForms={ActiveSummons={[h]={summon}}}
local tests,failures=0,{}
local function check(ok,label) tests=tests+1;if not ok then failures[#failures+1]=label end end
local function damage(a,v,inflictor,reverse)
 local info={amount=10}
 function info:GetAttacker() return a end;function info:GetInflictor() return inflictor or a end
 function info:SetDamage(n) self.amount=n end;function info:ScaleDamage(n) self.amount=self.amount*n end
 function info:GetDamage() return self.amount end
 local ids={'LOD_MultiplayerFriendlyFire'}
 local allowed
 for _,id in ipairs(ids) do local fn=hooks.PlayerShouldTakeDamage[id];local result=fn(v,a);if result~=nil then allowed=result;break end end
 if allowed==nil then allowed=GM:PlayerShouldTakeDamage(v,a) end
 if v:IsPlayer() and allowed==false then return 0 end
 ids={'LOD_HostileFactionDamage','LOD_MultiplayerFriendlyFireOwnedEntities'}
 if reverse then ids={ids[2],ids[1]} end
 for _,id in ipairs(ids) do local result=hooks.EntityTakeDamage[id](v,info);if result~=nil then break end end
 return info.amount
end
local function reckless(p,duration)
 assert(S:Apply(p,'reckless',m,{direct=true,duration=duration or 10}))
end
for _,reverse in ipairs({false,true}) do
 for _,pair in ipairs({{h,s},{s,h},{h,m},{m,h}}) do check(damage(pair[1],pair[2],nil,reverse)==10,'opposition reaches HP regardless controller or hook order') end
 for _,pair in ipairs({{h,h2},{s,s2},{s,m},{m,s},{m,m2},{h,summon},{summon,h}}) do
  local a,v=pair[1],pair[2]
  check(damage(a,v,nil,reverse)==0,'ordinary same-faction protection')
  reckless(v);check(damage(a,v,nil,reverse)==0,'victim-only Reckless never licenses the attacker');S:Clear(v,'reckless')
  reckless(a);check(damage(a,v,nil,reverse)==10,'Reckless source bypasses all same-faction gates');S:Clear(a,'reckless')
  check(damage(a,v,nil,reverse)==0,'cure restores protection')
 end
end
-- Ownership cannot mistake two opposing controllers for teammates, nor bypass protection.
local weapon={valid=true,IsPlayer=function() return false end,GetOwner=function() return h end}
local projectile={valid=true,IsPlayer=function() return false end,GetOwner=function() return weapon end}
local world={valid=true,IsPlayer=function() return false end,GetOwner=function() return nil end}
check(damage(projectile,s)==10,'owned projectile can damage enemy Soldier')
check(damage(projectile,h2)==0,'owned projectile cannot bypass teammate protection')
reckless(h);check(damage(projectile,h2)==10,'owned projectile resolves Reckless attacker')
check(damage(world,h2,projectile)==10,'inflictor fallback resolves attributed Reckless damage');S:Clear(h,'reckless')
check(damage(world,h2,projectile)==0,'inflictor fallback retains ordinary protection')
check(damage(h,h)==10,'Hero self damage unchanged')
check(damage(world,h)==10,'unowned environmental damage unchanged')
reckless(h,1);clock=clock+1
check(damage(h,h2)==0,'exact status expiry restores protection')
reckless(h);S:ResetActorLife(h);check(damage(h,h2)==0,'life reset revokes old Reckless')
reckless(h);h.LODProgressionState=table.Copy(h.LODProgressionState)
check(damage(h,h2)==0,'progression incarnation replacement revokes Reckless')
reckless(h);R.State.Graph={};check(damage(h,h2)==0,'same-seed graph replacement revokes Reckless')
local beforeOpponent=F:IsOpponent(h,h2)
reckless(h)
check(F:IsOpponent(h,h2)==beforeOpponent and not beforeOpponent,'Reckless never changes natural opposition')
if F.CanDamage and F.DamageTargets then
 check(F:CanDamage(h,h2),'actual damage selector includes Reckless teammate')
 check(not F:CanDamage(h,watcher),'damage selector excludes spectators')
 check(not F:CanDamage(h,h),'damage selector does not invent self hits')
 local seen={};for _,p in ipairs(F:DamageTargets(h)) do seen[p]=true end
 check(seen[h2] and seen[s] and seen[m] and seen[summon] and not seen[h] and not seen[watcher],'area damage candidates respect factions, status and lifecycle')
 S:Clear(h,'reckless');check(not F:CanDamage(h,h2),'ordinary damage selector excludes teammate')
else check(false,'shared geometry-facing damage selector exists');S:Clear(h,'reckless') end
-- Existing packet-scoped B15 exception remains independent of Reckless.
LOD.EnemyRoster={AllowsCrossfire=function(_,info,a,v) return a==m and v==m2 and info:GetDamage()==10 end}
check(damage(m,m2)==10,'authored crossfire packet exception preserved')
check(damage(m,s)==0,'crossfire does not grant human Soldier immunity bypass')
-- Sealed projectile permissions survive expiry only for the exact accepted
-- attack, source life and world; they never become a permanent PvP switch.
local function packet(a)
 return {GetAttacker=function() return a end,GetInflictor=function() return a end}
end
if F.CaptureAttackPermission and F.DealDamage then
 local event={};reckless(h,1);F:CaptureAttackPermission(h,event);clock=clock+1
 check(not S:Has(h,'reckless') and F:CanDamage(h,h2,event),'committed projectile survives status expiry')
 check(not F:CanDamage(h,h2,{}),'new attack has no expired permission')
 local received
 h2.TakeDamageInfo=function(_,info) received=damage(info:GetAttacker(),h2) end
 F:DealDamage(h2,packet(h),event,h)
 check(received==10 and F.DamagePackets[h2]==nil,'sealed native packet passes both player gates and cleans scope')
 check(damage(h,h2)==0,'packet permission cannot leak to subsequent damage')
 local previous={attacker=h,source=h,event=event};F.DamagePackets[h2]=previous
 h2.TakeDamageInfo=function() error('native-error-boundary') end
 check(not pcall(F.DealDamage,F,h2,packet(h),event,h) and F.DamagePackets[h2]==previous,'native error restores enclosing scope')
 F.DamagePackets[h2]=nil;h2.TakeDamageInfo=nil
 h.soldier=true;check(not F:AllowsFriendlyFire(h,event),'role transition revokes committed ally permission');h.soldier=false
 S:ResetActorLife(h);check(not F:AllowsFriendlyFire(h,event),'death/spawn lifecycle revokes accepted projectile')
 reckless(h);event={};F:CaptureAttackPermission(h,event);S:Clear(h,'reckless');R.State.Graph={}
 check(not F:AllowsFriendlyFire(h,event),'world replacement revokes accepted projectile')
 reckless(h);h.LODDead=true;check(not F:AllowsFriendlyFire(h),'dead AI/player cannot retain unprocessed status permission');h.LODDead=nil;S:ResetActorLife(h)
 local cycle={valid=true,IsPlayer=function() return false end};cycle.GetOwner=function() return cycle end
 check(F:DamageSource(cycle)==nil,'bounded ownership cycle')
 check(F:CanDamage(projectile,s),'geometry-facing proxy allegiance resolves to Hero')
end
-- Allowing faction damage must not prematurely approve the entire native hook
-- chain: an unrelated invulnerability/sanctuary hook may still reject the hit.
check(hooks.PlayerShouldTakeDamage.LOD_MultiplayerFriendlyFire(h,s)==nil,'opposition yields nil from hook, not forced allow')
reckless(h)
check(hooks.PlayerShouldTakeDamage.LOD_MultiplayerFriendlyFire(h2,h)==nil,'Reckless yields nil from hook, not forced allow')
S:Clear(h,'reckless')
print('FACTION_DAMAGE_CHECKS '..tests..' failures='..#failures)
for _,label in ipairs(failures) do print('FAIL '..label) end
assert(#failures==0,'faction damage regressions: '..#failures)
return {F=F,S=S,heroes={h,h2},soldiers={s,s2},enemies={m,m2},hooks=hooks,actor=actor,damage=damage,
 check=check,reckless=reckless,clock=function(v) clock=v or clock;return clock end}
