-- Execute production completion -> advancement -> build -> deferred Hero spawn,
-- with native Spawn/weapon admission emulated and the real equipment capacity gate.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local R,E=env.Run,LOD.Equipment
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local getState,isSoldier=R.GetPlayerState,R.IsSoldierControl
GM={};OBS_MODE_FIXED=1;OBS_MODE_CHASE=2;NULL={}
CreateConVar=function() return {GetInt=function() return 0 end} end
SysTime=CurTime;ErrorNoHalt=error
local vmeta=getmetatable(Vector())
vmeta.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
Angle=function() return {} end
util.IsValidModel=function() return true end
game={};player={}
game.GetMap=function() return 'gm_flatgrass' end
game.GetAmmoName=function(id) return tostring(id) end
dofile(root..'sv_run_manager.lua')
R.GetPlayerState=getState;R.IsSoldierControl=isSoldier
local hero,soldier=env.actor('transition-hero'),env.actor('transition-soldier')
local people={hero,soldier}
player.GetAll=function() return people end
R.State={CampaignSeed=73,LevelSeed=7,Level=1,BuildReady=true,PlayerState={},ActiveIdentity={}}
R._SyncPlayerVars=noop;R.PromoteWaitingSpectators=noop
R.IsActivePlayer=function(_,p) return not p.soldier end
R.IsSlotActivePlayer=R.IsActivePlayer
R.TryActivatePlayer=function() return true end
R._SortedConnectedPlayers=function() return people end
R.RetireSoldier=function(_,p) p.soldier=false end
R._GenerateProgressionLevel=function() return {Validation={cellCount=1,criticalVerticalTransitions=0},Attempt=1} end
LOD.MazeBuilder.Build=function() return true,{entityCount=1} end
LOD.ProgressionDirector={ResetLevelState=noop,CommitBuiltLevel=noop,SyncAll=noop,Announce=noop}
LOD.StagingDeployment={PlacePlayerInHut=function(_,p) p.inHut=true;return true end}
LOD.CharacterProgressionSystem.ProcessBankedHeroXP=noop
for _,p in ipairs(people) do
    R.State.PlayerState[p.id]=p.ps;p.ps.lives=3;p.ps.deploymentComplete=true
    p.ps.deployedDungeonLevel=1;p.ps.armor=27
    p.Nick=function() return p.id end;p.SteamID64=p.Nick
    p.Armor=function() return 27 end;p.SetArmor=noop
    p.UnSpectate=noop;p.SetTeam=noop;p.SetNoCollideWithTeammates=noop;p.CollisionRulesChanged=noop
    p.Spectate=noop;p.SpectateEntity=noop;p.SetPos=noop;p.SetModel=noop
    p.GetAmmo=function() return p.ammo end
    p.GetWeapons=function() local list={} for _,w in pairs(p.weapons) do list[#list+1]=w end return list end
    p.StripWeapons=function() for _,w in pairs(p.weapons) do w.valid=false end;p.weapons={} end;p.RemoveAllAmmo=function() p.ammo={} end
    local give=p.Give
    p.Give=function(self,class,...)
        if self.throwGive then error('native grant failed') end
        local candidate={valid=true,GetClass=function() return class end}
        if env.hooks.LOD_EquipmentInventoryCapacity(self,candidate)==false then return nil end
        local w=give(self,class,...);w.Clip2=function() return -1 end;w.SetClip2=noop
        return w
    end
    p.Spawn=function(self)
        self:StripWeapons();self:RemoveAllAmmo()
        env.hooks.LOD_PlayerSpawn(self)
    end
    p:Give('weapon_357'):SetClip1(3);p:SelectWeapon('weapon_357');p:SetAmmo(19,'357')
    E:Sync(p)
    local bag=E:Ensure(p.ps)
    -- Real, valid bag records at the authored maximum; restoration must not
    -- need a spare slot or replace the roll/selected slot with a new record.
    for i=2,E.MaximumStoredEquipment do
        local item=E:NewItem(p,'boots','transition:'..i);bag.items[item.id]=item
    end
    E:AddConsumable(bag,'healing_potion',4)
    assert(not E:CanStore(bag,{definitionId='weapon_357',count=1}))
    R:CaptureInventory(p,p.ps)
    p.beforeBag=table.Copy(bag);p.bag=bag
end
soldier.soldier=true;soldier:StripWeapons();soldier:Give('weapon_smg1')
local dormant=soldier.ps.inventory
assert(R:CompleteLevel(hero))
assert(soldier.ps.inventory==dormant,'rescue captured Soldier equipment over Hero loadout')
assert(R:AdvanceLevel() and R.State.Level==2)
assert(soldier.ps.inventory==dormant,'retirement/build captured Soldier equipment over Hero loadout')
-- A second build before the zero-delay spawn restore must not capture the
-- engine's empty body. The stale first-spawn callback must also be harmless.
assert(R:BuildCurrentLevel())
for _,p in ipairs(people) do
    assert(not p:HasWeapon('weapon_357') and #p.ps.inventory.weapons==1)
    R:CaptureInventory(p,p.ps)
    assert(#p.ps.inventory.weapons==1,'pending spawn erased saved native inventory')
end
local callbacks=env.timers
for _,fn in ipairs(callbacks) do fn() end
for _,p in ipairs(people) do
    assert(p.inHut and p.LODRunInventoryReady and not p.ps.deploymentComplete)
    assert(p:HasWeapon('weapon_357') and p:GetWeapon('weapon_357'):Clip1()==3 and p:GetAmmoCount('357')==19)
    assert(p.activeClass=='weapon_357' and p.ps.equipment==p.bag)
    E:Sync(p)
    local function equal(a,b)
        if type(a)~='table' then return a==b end
        if type(b)~='table' then return false end
        for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    assert(equal(p.ps.equipment,p.beforeBag),'items, stacks, rolls or equipped slots changed')
    assert(not p.LODInventoryNativeRestore,'restore admission bypass leaked')
end
hero.throwGive=true
assert(not pcall(R.RestoreInventory,R,hero,hero.ps) and not hero.LODInventoryNativeRestore,'failed native grant leaked admission bypass')
print('DUNGEON_TRANSITION_PASS: actual rescue/build/respawn, full-bag native restore, exact weapons/ammo/active selection, stacks/slots/rolls, Soldier isolation, stale spawn guard, failed-Give cleanup')
