-- Execute shared records and production server transactions with bounded GMod doubles.
SERVER, CLIENT = true, false
local root = "gamemodes/legend_of_deborah/gamemode/lod/"
local now = 10
function CurTime() return now end
function IsValid(v) return type(v)=="table" and v.valid~=false end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
local hooks, receivers = {}, {}
hook = {Add=function(name,id,fn) hooks[name..":"..id]=fn end}
timer = {Simple=function(_,fn) fn() end}
util = {AddNetworkString=function() end}
concommand = {Add=function() end}
net = {Start=function() end, WriteTable=function() end, Send=function() end,
    Receive=function(name,fn) receivers[name]=fn end}
local players = {}
LOD = {RunManager={State={LevelSeed=71,PlayerState={}},
    GetPlayerState=function(self,p) return self.State.PlayerState[p.id] end,
    IsActivePlayer=function(_,p) return p.active~=false end,
    IsSoldierControl=function(_,p) return p.soldier==true end,
    ApplyPlayerState=function() end},
    LootDirector={_GrantHealth=function(_,p,amount)
        if p.hp>=p.max then return false end
        local value=math.min(amount,p.max-p.hp);p.hp=p.hp+value
        return true,"+"..value.." health"
    end},RPGPresentation={Event=function() end}}
local R = LOD.RunManager
local function weapon(class)
    return {class=class,GetClass=function(self) return self.class end,Remove=function(self) self.valid=false end}
end
local function player(id)
    local p = {id=id,hp=50,max=100,alive=true,inventory={},nw={}}
    p.inventory.weapon_lod_crowbar=weapon("weapon_lod_crowbar")
    p.inventory.weapon_pistol=weapon("weapon_pistol");p.selected="weapon_pistol"
    function p:IsPlayer() return true end
    function p:Alive() return self.alive end
    function p:Health() return self.hp end
    function p:GetMaxHealth() return self.max end
    function p:GetActiveWeapon() return self.inventory[self.selected] end
    function p:HasWeapon(c) return self.inventory[c]~=nil end
    function p:Give(c) self.inventory[c]=weapon(c);return self.inventory[c] end
    function p:SelectWeapon(c) self.selected=c end
    function p:StripWeapon(c) self.inventory[c]=nil end
    function p:SetAmmo() end
    function p:SetNW2String(k,v) self.nw[k]=v end
    function p:SetNW2Int(k,v) self.nw[k]=v end
    function p:EmitSound() end
    function p:GetShootPos() return {} end
    function p:EyeAngles() return {} end
    R.State.PlayerState[id]={magic=63}
    players[id]=p
    return p
end
local spawnFail, created = false, nil
ents = {Create=function()
    if spawnFail then return nil end
    created={SetOwner=function() end,SetPos=function() end,SetAngles=function() end,
        Spawn=function() end,Activate=function() end,Remove=function(self) self.valid=false end}
    return created
end}
dofile(root.."sh_equipment.lua")
dofile(root.."sv_equipment.lua")
local E=LOD.Equipment
local p,q=player("hero"),player("ally")
assert(not E:IsActive(p))
assert(not E:Activate(p))
assert(E:Grant(p,"healing_potion",3))
local ps=R:GetPlayerState(p)
local state=ps.equipment
assert(state.items.healing_potion.count==3 and state.slots.throwable=="healing_potion")
assert(not E:Grant(p,"healing_potion",1))
assert(not E:Grant(p,"unknown",1))
assert(not E:Equip(state,"forged","throwable"))
assert(not E:Equip(state,"healing_potion","head"))
assert(not E:Use(p,"drink"),"Stored potion must not capture combat input")
assert(E:Activate(p) and E:IsActive(p))
assert(E:Use(p,"drink") and p.hp==75 and state.items.healing_potion.count==2)
assert(ps.magic==63,"Potion must not spend or overwrite Magic")
assert(not E:Use(p,"drink"),"Replay/cadence protection")
now=now+1
spawnFail=true
assert(not E:Use(p,"throw") and state.items.healing_potion.count==2,"Spawn failure must not consume")
spawnFail=false
assert(E:Use(p,"throw") and state.items.healing_potion.count==1)
assert(created.LODPotionState==state and created.LODPotionRun==R.State)
now=now+1
assert(not E:Use(p,"throw"),"One live projectile per actor")
created:Remove()
assert(E:Use(p,"drink") and p.hp==100)
assert(state.items.healing_potion==nil and state.slots.throwable==nil)
assert(not E:IsActive(p) and p.selected=="weapon_pistol","Last unit restores prior weapon/Magic")
now=now+1
assert(E:Grant(p,"healing_potion",2));E:Activate(p)
assert(not E:Use(p,"drink"),"Full health does not waste a drink")
p.selected="weapon_pistol"
assert(not E:IsActive(p) and not E:Use(p,"throw"),"Weapon switch releases suppression")
E:Activate(p)
p.alive=false
hooks["PlayerDeath:LOD_EquipmentDeath"](p)
assert(not E:IsActive(p) and state.items.healing_potion.count==2)
p.alive=true
R:ApplyPlayerState(p)
assert(ps.equipment==state and state.items.healing_potion.count==2 and not E:IsActive(p))
R.State.LevelSeed=72
R:ApplyPlayerState(p)
assert(ps.equipment==state and state.items.healing_potion.count==2)
E:Activate(p);p.soldier=true
assert(not E:IsActive(p) and not E:Use(p,"throw") and not E:Grant(p,"healing_potion",1))
E:Sync(p)
assert(p.nw.LOD_ThrowableCount==0 and state.items.healing_potion.count==2,"Soldier must not access Hero gear")
p.soldier=false
hooks["PlayerDisconnected:LOD_EquipmentDisconnect"](p)
local reconnected=player("hero")
R.State.PlayerState.hero=ps
R:ApplyPlayerState(reconnected)
assert(ps.equipment==state and state.items.healing_potion.count==2 and not E:IsActive(reconnected))
assert(E:Heal(reconnected,q,25) and q.hp==75)
q.soldier=true
assert(not E:Heal(reconnected,q,25) and q.hp==75)
q.soldier=false;q.alive=false
assert(not E:Heal(reconnected,q,25))
assert(E:Prompt(E.Definitions.healing_potion)=="LMB: THROW   RMB: DRINK")
-- A test-only throw-capable healing definition verifies capability routing;
-- this does not invent a production Stink Bomb effect or item.
E.Definitions.test_throw_only={name="Test",slots={"throwable"},throwable=true,drinkable=false,effect="heal",amount=25,maxStack=3}
assert(E:Prompt(E.Definitions.test_throw_only)=="LMB: THROW")
assert(E:Grant(reconnected,"test_throw_only",1))
assert(E:Equip(state,"test_throw_only","throwable"));E:Sync(reconnected);E:Activate(reconnected)
now=now+1
reconnected.hp=20
assert(not E:Use(reconnected,"drink") and state.items.test_throw_only.count==1)
assert(E:Use(reconnected,"throw") and state.items.test_throw_only==nil)
E.Definitions.test_throw_only=nil
-- Data-driven wearable occupancy: two rings, paired gloves and independent arm.
E.Definitions.test_ring={slots={"left_hand","right_hand"}}
E.Definitions.test_gloves={slots={"left_hand","right_hand"},occupancy={"left_hand","right_hand"}}
E.Definitions.test_shield={slots={"left_arm"}}
for _,id in ipairs({"ring1","ring2"}) do state.items[id]={definitionId="test_ring",count=1} end
state.items.gloves={definitionId="test_gloves",count=1}
state.items.shield={definitionId="test_shield",count=1}
assert(E:Equip(state,"ring1","left_hand") and E:Equip(state,"ring2","right_hand"))
assert(E:Equip(state,"shield","left_arm") and E:Equip(state,"gloves","left_hand"))
assert(state.slots.left_hand=="gloves" and state.slots.right_hand=="gloves" and state.slots.left_arm=="shield")
assert(E:Equip(state,"ring1","left_hand"))
assert(state.slots.right_hand==nil and state.items.gloves and state.slots.left_arm=="shield")
assert(hooks["PlayerCanPickupWeapon:LOD_NoOrdinaryGrenades"](p,weapon("weapon_frag"))==false)
assert(hooks["PlayerCanPickupItem:LOD_NoGrenadeAmmo"](p,weapon("item_ammo_grenade"))==false)
R.State={LevelSeed=73,PlayerState={hero={magic=100}}}
R:ApplyPlayerState(reconnected)
assert(not next(R:GetPlayerState(reconnected).equipment.items),"New campaign must not inherit gear")
print("EQUIPMENT_PASS: ownership, occupancy, consumption, Magic isolation, replay, lifecycle, faction and pickup guards")
