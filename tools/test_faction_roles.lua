-- Restore the actual GM/faction gates around the real Soldier incarnation and
-- staging/RunManager authorities used by SPOT-15, not a role predicate double.
local f=dofile('tools/test_spot15_soldier_queue.lua')
local root='gamemodes/legend_of_deborah/gamemode/'
local R=f.Run
local noop=function() end
DeriveGamemode=noop;AddCSLuaFile=noop
local previousInclude=include;include=noop
dofile(root..'shared.lua');include=previousInclude
local installed={}
local previousAdd=hook.Add
hook.Add=function(event,id,fn) installed[id]=fn;previousAdd(event,id,fn) end
-- Restore production methods potentially doubled by earlier fixture subtests.
dofile(root..'lod/sv_faction_manager.lua')
dofile(root..'lod/sv_multiplayer_contracts.lua')
local F,S=LOD.FactionManager,LOD.RPGStatusElements
local checks=0
local function check(ok,label) checks=checks+1;assert(ok,'FACTION_ROLES: '..label) end
local soldier,hero,saved,inc=f.soldier();f.flush()
hero.SetLocalVelocity=noop
LOD.StagingDeployment:_ExecuteDeploymentTransition(hero,hero.ps,Vector(1,2,3),R.State)
check(R:IsSoldierControl(soldier) and not R:IsActivePlayer(soldier),'real Soldier role is enemy, not active Hero')
check(R:IsActivePlayer(hero) and not R:IsSoldierControl(hero),'real surviving Hero remains active')
for _,pair in ipairs({{hero,soldier},{soldier,hero}}) do
 local a,v=pair[1],pair[2]
 check(GM:PlayerShouldTakeDamage(v,a),'actual GM permits opposed controllers')
 check(installed.LOD_MultiplayerFriendlyFire(v,a)==nil,'multiplayer gate does not override opposition')
 local info={damage=10,GetAttacker=function() return a end,GetInflictor=function() return a end,
  SetDamage=function(self,n) self.damage=n end,ScaleDamage=function(self,n) self.damage=self.damage*n end}
 installed.LOD_HostileFactionDamage(v,info);installed.LOD_MultiplayerFriendlyFireOwnedEntities(v,info)
 check(info.damage==10,'both actual EntityTakeDamage gates preserve opposed damage')
end
check(F:IsOpponent(hero,soldier) and F:IsOpponent(soldier,hero),'natural hostility follows actual incarnation')
local roleBefore=R:GetPlayerState(soldier)
check(S:Apply(soldier,'reckless',hero,{direct=true,duration=10}),'actual human Soldier accepts Reckless')
check(R:GetPlayerState(soldier)==roleBefore and R:IsSoldierControl(soldier),'status never changes role or saved Hero state')
local event={};F:CaptureAttackPermission(soldier,event);S:Clear(soldier,'reckless')
check(F:AllowsFriendlyFire(soldier,event),'real Soldier commitment retains temporary permission')
f.preserved(soldier,saved)
R:ReturnToHeroQueue(soldier)
check(not F:AllowsFriendlyFire(soldier,event),'return to queue invalidates Soldier-life permission')
check(not F:CanDamage(hero,soldier),'queued Hero is not a Magic/combat target')
print('FACTION_ROLES_PASS '..checks..' actual-production assertions')
