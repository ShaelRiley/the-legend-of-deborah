-- The saved native magazine is an adapter, never an entitlement to mint gear.
local env=dofile('tools/test_dungeon_transition.lua')
local Run,ply,E=env.Run,env.hero,LOD.Equipment
ply.throwGive=false
ply.StripWeapon=function(self,class)
    if self.weapons[class] then self.weapons[class].valid=false end
    self.weapons[class]=nil
end
ply:SelectWeapon('weapon_lod_empty_hands');E:Sync(ply)
local state=ply.ps.equipment
local retired=assert(E:Equipped(state,'weapon_357'))
assert(E:DiscardOwned(ply,retired.id))
assert(not state.items[retired.id] and not ply:HasWeapon('weapon_357'))
-- Death/spawn/reconnect may apply a previously captured native snapshot.
-- Neither that snapshot nor its deferred WeaponEquip hook can resurrect trash.
Run:RestoreInventory(ply,ply.ps);E:Sync(ply)
for _,callback in ipairs(env.fixture.timers) do callback() end
assert(not ply:HasWeapon('weapon_357') and not state.items[retired.id],
    'Stale native snapshot recreated discarded equipment')

-- Another owned copy preserves its family's original magazine and reserve.
local replacement=E:Generate(41005,8,'weapon_357','big-loot-retained-copy')
state.items[replacement.id]=replacement
Run:RestoreInventory(ply,ply.ps);E:Sync(ply)
assert(ply:HasWeapon('weapon_357') and E:Equipped(state,'weapon_357')==replacement)
assert(ply:GetWeapon('weapon_357'):Clip1()==3 and ply:GetAmmoCount('357')==19)
assert(not state.items[retired.id],'Restoration rerolled a missing selected copy')

-- Unversioned saved inventories retain the established one-time legacy path.
local legacy=env.fixture.actor('big-loot-legacy')
legacy.StripWeapons=ply.StripWeapons;legacy.RemoveAllAmmo=ply.RemoveAllAmmo
legacy.ps.inventory={weapons={{class='weapon_357',clip1=2,clip2=-1}},ammo={['357']=7}}
Run:RestoreInventory(legacy,legacy.ps);E:Sync(legacy)
assert(legacy:HasWeapon('weapon_357') and E:Equipped(legacy.ps.equipment,'weapon_357'))
assert(legacy:GetWeapon('weapon_357'):Clip1()==2 and legacy:GetAmmoCount('357')==7)
print('BIG_LOOT_INVENTORY_PASS: trash cannot reappear through native restore/deferred hooks; retained-copy magazines; legacy migration')
