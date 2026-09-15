-- A native stock weapon is not safe to interrogate or mutate synchronously from
-- WeaponEquip: the hook is published from inside Player:Give's construction
-- stack. Model that boundary by making every weapon access fail until Give has
-- returned, then prove the real SMG capacity hook settles on the next tick.
local handlers, queued = {}, {}
local function noop() end

hook = {Add = function(event, name, fn)
    if event == "WeaponEquip" then handlers[name] = fn end
end}
timer = {Simple = function(_, fn) queued[#queued + 1] = fn end}
weapons = {GetStored = function() return {Primary = {}} end}
concommand = {Add = noop}
function GetConVar() return nil end
function CurTime() return 0 end
function IsValid(value) return type(value) == "table" and value.valid ~= false end
math.Clamp = math.Clamp or function(value, low, high)
    return math.max(low, math.min(high, value))
end

LOD = {
    DiceAmmo = {
        Stats = {},
        ClampFamily = noop,
        _FamilyState = function() return {} end
    },
    LootDirector = {
        _GrantWeapon = function() return true, "granted" end
    }
}

dofile("gamemodes/legend_of_deborah/gamemode/lod/sv_smg_capacity_rebalance.lua")
local onEquip = assert(handlers.LOD_SMGCapacityEquip)

local player = {valid = true, weapons = {}, ammo = {SMG1 = 0}}
function player:GetWeapon(class) return self.weapons[class] end
function player:GetAmmoCount(kind) return self.ammo[kind] or 0 end
function player:SetAmmo(amount, kind) self.ammo[kind] = amount end

local weapon = setmetatable({
    valid = true,
    class = "weapon_smg1",
    clip = 45,
    settled = false
}, {
    __newindex = function(self, key, value)
        if key == "Primary" and not rawget(self, "settled") then
            error("WeaponEquip mutated an unsettled native weapon instance")
        end
        rawset(self, key, value)
    end
})
function weapon:GetClass()
    assert(self.settled, "WeaponEquip interrogated an unsettled native weapon instance")
    return self.class
end
function weapon:GetOwner() assert(self.settled);return self.owner end
function weapon:Clip1() return self.clip end
function weapon:SetClip1(value) self.clip = value end

-- This call models the synchronous hook invocation inside Player:Give.
onEquip(weapon, player)
assert(#queued == 1 and weapon.Primary == nil,
    "SMG WeaponEquip must only enqueue settlement")

-- Player:Give returns; ownership and the native entity are now settled.
weapon.settled = true
weapon.owner = player
player.weapons.weapon_smg1 = weapon
queued[1]()
assert(weapon.Primary and weapon.Primary.ClipSize == 25)
assert(weapon:Clip1() == 25 and player:GetAmmoCount("SMG1") == 20,
    "deferred SMG capacity settlement changed authored ammo accounting")

weapon.clip=40;weapon.owner={};onEquip(weapon,player);queued[#queued]()
assert(weapon.clip==40,'stale equip callback mutated a weapon belonging to another player')
print("WEAPON_EQUIP_SETTLEMENT_PASS: real SMG hook performs zero synchronous native access and preserves 25/75 accounting")
