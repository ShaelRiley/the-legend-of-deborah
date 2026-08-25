LOD = LOD or {}
LOD.TempAmmoDrops = LOD.TempAmmoDrops or {}

local TempAmmoDrops = LOD.TempAmmoDrops
local FALLBACK_LIFETIME = 20
local AMMO_DROP_CHANCE = 0.35

local function shouldSpawnAmmoDrop(hostile)
    local baseSeed = hostile.LODInstanceSeed or hostile.LODDeathLevelSeed or 1
    local identity = hostile.LODEncounterOrdinal or hostile:EntIndex()
    local seed = LOD.Seeds.Derive(baseSeed, "temp-ammo-drop:" .. tostring(identity))
    local rng = LOD.RNG.New(seed)
    return rng:Float(0, 1) < AMMO_DROP_CHANCE
end

function TempAmmoDrops:InstallHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end
    if class.LODTemporaryAmmoDropPatched then return true end

    class.LODTemporaryAmmoDropPatched = true

    function class:_SpawnPlaceholderLoot()
        local state = LOD.RunManager and LOD.RunManager.State
        if not state or state.LevelSeed ~= self.LODDeathLevelSeed
            or state.Failed or state.LevelCleared
        then
            return
        end

        -- Approximate the finished LootDirector's useful-ammo band rather than
        -- turning every hostile into guaranteed ammunition. Other final drop
        -- categories remain intentionally absent from this temporary scaffold.
        if not shouldSpawnAmmoDrop(self) then return end

        local loot = ents.Create("lod_temp_ammo_drop")
        if not IsValid(loot) then return end

        loot:SetPos(self:GetPos() + Vector(0, 0, 8))
        loot:SetAngles(Angle(0, self:GetAngles().y, 0))
        loot.LODTemporaryAmmoLevelSeed = self.LODDeathLevelSeed
        loot.LODPlaceholderLoot = true
        loot:Spawn()
        loot:Activate()

        -- Reuse the already-proven bounded placeholder registry: at most 24
        -- live drops, 20-second lifetime, and automatic cleanup on level-seed
        -- changes. The final LootDirector will replace this temporary scaffold.
        local placeholder = LOD.PlaceholderLoot
        if placeholder and placeholder.Register then
            placeholder:Register(loot, self.LODDeathLevelSeed)
        else
            SafeRemoveEntityDelayed(loot, FALLBACK_LIFETIME)
        end
    end

    return true
end

if not TempAmmoDrops:InstallHostilePatch() then
    hook.Add("InitPostEntity", "LOD_TemporaryAmmoDropsInstall", function()
        TempAmmoDrops:InstallHostilePatch()
    end)

    hook.Add("OnEntityCreated", "LOD_TemporaryAmmoDropsHostileClassReady", function(ent)
        if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
        TempAmmoDrops:InstallHostilePatch()
    end)
end
