LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["loot"] = "collapse-recovery-20260916-01"
LOD.LootDirector = LOD.LootDirector or {}

local Loot = LOD.LootDirector
local RunManager = LOD.RunManager
local MazeBuilder = LOD.MazeBuilder

local CLEANUP_TIMER = "LOD_LootDirectorCleanup"
local ENEMY_DROP_LIFETIME = 60
local ENEMY_DROP_CAP_PER_IDENTITY = 24
local MAX_ARMOR = 100

local AMMO = {
    weapon_pistol = {label = "Pistol", ammo = "Pistol", load = 18, cap = 54, small = 6, scarcity = 1.00},
    weapon_shotgun = {label = "Shotgun", ammo = "Buckshot", load = 6, cap = 18, small = 2, scarcity = 0.90},
    weapon_smg1 = {label = "SMG", ammo = "SMG1", load = 45, cap = 135, small = 15, scarcity = 0.80},
    weapon_ar2 = {label = "AR2", ammo = "AR2", load = 30, cap = 90, small = 10, scarcity = 0.55},
    weapon_357 = {label = ".357 Magnum", ammo = "357", load = 6, cap = 18, small = 2, scarcity = 0.45}
}

local WEAPONS = {
    weapon_pistol = {label = "Pistol", load = 18, model = "models/weapons/w_pistol.mdl"},
    weapon_lod_crowbar = {label = "Crowbar", load = -1, model = "models/weapons/w_crowbar.mdl"},
    weapon_shotgun = {label = "Shotgun", load = 6, model = "models/weapons/w_shotgun.mdl"},
    weapon_smg1 = {label = "SMG", load = 45, model = "models/weapons/w_smg1.mdl"},
    weapon_357 = {label = ".357 Magnum", load = 6, model = "models/weapons/w_357.mdl"},
    weapon_ar2 = {label = "AR2", load = 30, model = "models/weapons/w_irifle.mdl"}
}

local KIND_MODEL = {
    wearable = "models/props_junk/cardboard_box004a.mdl",
    consumable = "models/props_junk/garbage_glassbottle003a.mdl",
    ammo = "models/items/boxsrounds.mdl",
    health = "models/items/healthkit.mdl",
    armor = "models/items/battery.mdl",
    cache = "models/items/boxsrounds.mdl",
    life = "models/items/healthvial.mdl"
}

local KIND_COLOR = {
    wearable = Color(155, 195, 255, 245),
    consumable = Color(130, 235, 160, 245),
    ammo = Color(255, 196, 64, 240),
    health = Color(170, 255, 170, 245),
    armor = Color(110, 185, 255, 245),
    weapon = Color(255, 232, 145, 245),
    cache = Color(255, 145, 70, 245),
    life = Color(255, 110, 225, 250)
}

local EXPECTED_HP = {
    deadcrab = 6,
    runner = 10.5,
    shambler = 15,
    soldier = 15,
    blitzer = 15,
    bioblaster = 18.5
}

Loot.Entities = Loot.Entities or {}
Loot.StaticPlan = Loot.StaticPlan or nil
Loot.StaticByIdentity = Loot.StaticByIdentity or {}
Loot.Stats = Loot.Stats or {
    staticSpawned = 0,
    enemyRolls = 0,
    enemyDrops = 0,
    pityDrops = 0,
    collected = 0,
    extraLives = 0
}

local function identityOf(ply)
    return RunManager and RunManager.IdentityOf and RunManager:IdentityOf(ply) or nil
end

local function safeModel(path)
    if path and util.IsValidModel(path) then return path end
    return "models/items/boxsrounds.mdl"
end

local function sortedKeys(tbl)
    local out = {}
    for key in pairs(tbl or {}) do out[#out + 1] = key end
    table.sort(out)
    return out
end

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do
        total = total + math.max(0, entry.weight or 0)
    end
    if total <= 0 then return nil end

    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries) do
        cursor = cursor + math.max(0, entry.weight or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

local function clampInt(value, minimum, maximum)
    return math.Clamp(math.floor((tonumber(value) or 0) + 0.5), minimum, maximum)
end

function Loot:_PlayerLootState(ply)
    local ps = RunManager and RunManager:GetPlayerState(ply)
    if not ps then return nil end
    ps.loot = ps.loot or {dryKills = 0, killSerial = 0, levelSeed = nil, consumedStatic = {}}

    local levelSeed = RunManager.State and RunManager.State.LevelSeed
    if ps.loot.levelSeed ~= levelSeed then
        ps.loot.levelSeed = levelSeed
        ps.loot.killSerial = 0
        ps.loot.consumedStatic = {}
    end
    return ps.loot, ps
end

function Loot:_FamilyTotal(ply, weaponClass, profile)
    if not IsValid(ply) then return 0, 0, nil end
    local weapon = ply:GetWeapon(weaponClass)
    if not IsValid(weapon) then return 0, 0, nil end
    local clip = math.max(0, weapon:Clip1())
    local reserve = math.max(0, ply:GetAmmoCount(profile.ammo))
    return clip + reserve, clip, weapon
end

function Loot:_AmmoNeed(ply)
    local need = 0
    for weaponClass, profile in pairs(AMMO) do
        local total, _, weapon = self:_FamilyTotal(ply, weaponClass, profile)
        if weapon and total < profile.cap then
            local ratio = total / math.max(1, profile.cap)
            need = math.max(need, 1 - ratio)
        end
    end
    return need
end

function Loot:_ChooseAmmoFamily(ply, rng, preferredClass)
    if preferredClass and AMMO[preferredClass] then
        local total, _, weapon = self:_FamilyTotal(ply, preferredClass, AMMO[preferredClass])
        if weapon and total < AMMO[preferredClass].cap then return preferredClass end
    end

    local candidates = {}
    for weaponClass, profile in pairs(AMMO) do
        if not (weaponClass == "weapon_pistol" and ply.LODM3InfiniteTestPistol == true) then
            local total, _, weapon = self:_FamilyTotal(ply, weaponClass, profile)
            if weapon and total < profile.cap then
                local ratio = total / math.max(1, profile.cap)
                local weight = profile.scarcity * (0.35 + (1 - ratio) * 1.65)
                if ratio < 0.50 then weight = weight * 2.25 end
                candidates[#candidates + 1] = {value = weaponClass, weight = weight}
            end
        end
    end
    return weightedPick(rng, candidates)
end

function Loot:_GrantAmmo(ply, rng, tier, preferredClass)
    local weaponClass = self:_ChooseAmmoFamily(ply, rng, preferredClass)
    local profile = weaponClass and AMMO[weaponClass]
    if not profile then return false end

    local total = self:_FamilyTotal(ply, weaponClass, profile)
    local headroom = math.max(0, profile.cap - total)
    if headroom <= 0 then return false end

    local multiplier = tier == "large" and 3 or (tier == "medium" and 2 or 1)
    local amount = math.min(headroom, math.max(1, profile.small * multiplier))
    if amount <= 0 then return false end

    ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + amount, profile.ammo)
    if LOD.DiceAmmo and LOD.DiceAmmo.ClampFamily then
        LOD.DiceAmmo:ClampFamily(ply, weaponClass, profile)
    end
    return true, string.format("+%d %s ammo", amount, profile.label), amount, weaponClass
end

function Loot:_GrantHealth(ply, amount)
    local maximum = math.max(1, ply:GetMaxHealth())
    local current = ply:Health()
    if current >= maximum then return false end
    local granted = math.min(math.max(1, amount or 25), maximum - current)
    ply:SetHealth(current + granted)
    return true, string.format("+%d health", granted)
end

function Loot:_GrantArmor(ply, amount)
    local current = math.max(0, ply:Armor())
    if current >= MAX_ARMOR then return false end
    local granted = math.min(math.max(1, amount or 20), MAX_ARMOR - current)
    ply:SetArmor(current + granted)
    local ps = RunManager:GetPlayerState(ply)
    if ps then ps.armor = ply:Armor() end
    return true, string.format("+%d armor", granted)
end

function Loot:_AllowedWeaponClasses(level)
    local out = {"weapon_shotgun", "weapon_smg1"}
    if (level or 1) >= 2 then out[#out + 1] = "weapon_357" end
    if (level or 1) >= 3 then out[#out + 1] = "weapon_ar2" end
    return out
end

function Loot:_MissingWeaponReward(ply, rng)
    local missing = {}
    for _, weaponClass in ipairs(self:_AllowedWeaponClasses(RunManager.State.Level or 1)) do
        if not IsValid(ply:GetWeapon(weaponClass)) then missing[#missing + 1] = weaponClass end
    end
    if #missing == 0 then return nil end
    table.sort(missing)
    return missing[rng:Int(1, #missing)]
end

function Loot:_GrantWeapon(ply, weaponClass, rng)
    local spec = WEAPONS[weaponClass]
    if not spec then return false end

    if IsValid(ply:GetWeapon(weaponClass)) then
        return self:_GrantAmmo(ply, rng, "medium", weaponClass)
    end

    local weapon = ply:Give(weaponClass, true)
    if not IsValid(weapon) then return false end
    weapon:SetClip1(spec.load or 0)
    local profile = AMMO[weaponClass]
    if profile and LOD.DiceAmmo and LOD.DiceAmmo.ClampFamily then
        LOD.DiceAmmo:ClampFamily(ply, weaponClass, profile)
    end
    return true, spec.label .. " acquired"
end

function Loot:_OldestEliminatedTeammate(excludeIdentity)
    local chosenId
    local chosenState
    for id, ps in pairs(RunManager.State and RunManager.State.PlayerState or {}) do
        if id ~= excludeIdentity then
            local isEligible = RunManager and RunManager.IsHeroRevivalQueueEligible and RunManager:IsHeroRevivalQueueEligible(id)
            if isEligible then
                if not chosenState or (ps.eliminatedSince or math.huge) < (chosenState.eliminatedSince or math.huge) then
                    chosenId = id
                    chosenState = ps
                elseif (ps.eliminatedSince or math.huge) == (chosenState.eliminatedSince or math.huge) then
                    local ordCandidate = ps.ordinal or 100000
                    local ordChosen = chosenState.ordinal or 100000
                    if ordCandidate < ordChosen then
                        chosenId = id
                        chosenState = ps
                    end
                end
            end
        end
    end
    return chosenId, chosenState
end

function Loot:_CanUseExtraLife(ply)
    local ps = RunManager:GetPlayerState(ply)
    if not ps then return false end
    if (ps.lives or 0) < (LOD.Config.Lives.MaxLives or 4) then return true end
    local id = identityOf(ply)
    return self:_OldestEliminatedTeammate(id) ~= nil
end

function Loot:_GrantExtraLife(ply)
    local ps = RunManager:GetPlayerState(ply)
    if not ps then return false end
    local cap = LOD.Config.Lives.MaxLives or 4

    if (ps.lives or 0) < cap then
        ps.lives = ps.lives + 1
        RunManager:_SyncPlayerVars(ply)
        self.Stats.extraLives = (self.Stats.extraLives or 0) + 1
        return true, "EXTRA LIFE"
    end

    local ownerId = identityOf(ply)
    local revivedId = self:_OldestEliminatedTeammate(ownerId)
    if not revivedId then return false end

    if RunManager and RunManager.ReviveIdentity then
        local revived, disposition = RunManager:ReviveIdentity(revivedId)
        if not revived then return false end
        self.Stats.extraLives = (self.Stats.extraLives or 0) + 1
        if disposition == "active" then
            return true, "EXTRA LIFE REVIVED A TEAMMATE"
        end
        return true, "EXTRA LIFE REVIVED A TEAMMATE — WAITING FOR AN ACTIVE SLOT"
    end

    return false
end

function Loot:_GrantLargeCache(ply, rng)
    local messages = {}
    local gained = false

    for _ = 1, 2 do
        local ok, message = self:_GrantAmmo(ply, rng, "large")
        if ok then gained = true messages[#messages + 1] = message end
    end

    if ply:Health() < ply:GetMaxHealth() then
        local ok, message = self:_GrantHealth(ply, 25)
        if ok then gained = true messages[#messages + 1] = message end
    elseif ply:Armor() < MAX_ARMOR then
        local ok, message = self:_GrantArmor(ply, 20)
        if ok then gained = true messages[#messages + 1] = message end
    end

    return gained, gained and ("LARGE CACHE: " .. table.concat(messages, ", ")) or nil
end

function Loot:IsPickupOwner(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return false end
    local ownerIdentity = ent.LODLootOwnerIdentity
    return ownerIdentity ~= nil and ownerIdentity == identityOf(ply)
end

function Loot:_MarkConsumed(ent, ply)
    if not ent.LODLootStaticId then return end
    local state = self:_PlayerLootState(ply)
    if state then state.consumedStatic[ent.LODLootStaticId] = true end
end

function Loot:Collect(ent, ply, acceptEquipment)
    -- The grant authority owns admission and idempotence. Touch/Use are observers,
    -- and must not be the only protection against repeated or reentrant grants.
    if not IsValid(ent) or ent.LODCollected or ent.LODCollecting
        or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()
        or not self:IsPickupOwner(ent, ply) then return false end
    local staging = LOD.StagingDeployment
    local stagedGift = staging and staging.CanCollectGift and staging:CanCollectGift(ply, ent)
    if not RunManager:IsActivePlayer(ply) and not stagedGift then return false end
    local state = RunManager.State
    if not state or state.Failed or state.LevelCleared then return false end
    if ent.LODLootLevelSeed ~= state.LevelSeed then return false end
    local lootState = self:_PlayerLootState(ply)
    if ent.LODLootStaticId and lootState and lootState.consumedStatic[ent.LODLootStaticId] then return false end
    ent.LODCollecting = true

    local payload = ent.LODLootPayload or {}
    local seed = LOD.Seeds.Derive(state.LevelSeed or 1,
        string.format("loot-collect:%s:%s", tostring(ent.LODLootOwnerIdentity), tostring(ent.LODLootStaticId or ent:EntIndex())))
    local rng = LOD.RNG.New(seed)

    local ok, message
    if ent.LODLootKind == "ammo" then
        ok, message = self:_GrantAmmo(ply, rng, payload.tier or "small", payload.weaponClass)
    elseif ent.LODLootKind == "wearable" then
        if LOD.Equipment then ok, message = LOD.Equipment:CollectWearable(ent, ply, acceptEquipment == true) end
    elseif ent.LODLootKind == "dft" then
        if LOD.CryptoDirector then ok, message = LOD.CryptoDirector:CollectToken(ply, payload.token) end
    elseif ent.LODLootKind == "consumable" then
        if LOD.Equipment then ok, message = LOD.Equipment:Grant(ply, payload.itemId, 1, ent) end
    elseif ent.LODLootKind == "health" then
        ok, message = self:_GrantHealth(ply, payload.amount or 25)
    elseif ent.LODLootKind == "armor" then
        ok, message = self:_GrantArmor(ply, payload.amount or 20)
    elseif ent.LODLootKind == "weapon" then
        ok, message = self:_GrantWeapon(ply, payload.weaponClass, rng)
    elseif ent.LODLootKind == "cache" then
        ok, message = self:_GrantLargeCache(ply, rng)
    elseif ent.LODLootKind == "life" then
        ok, message = self:_GrantExtraLife(ply)
    end

    ent.LODCollecting = nil
    if not ok then return false end

    ent.LODCollected = true
    self:_MarkConsumed(ent, ply)
    self.Stats.collected = (self.Stats.collected or 0) + 1
    ply:EmitSound(ent.LODLootKind == "life" and "items/suitchargeok1.wav" or "items/itempickup.wav",
        64, ent.LODLootKind == "life" and 125 or 100, 0.78, CHAN_ITEM)
    if message then ply:ChatPrint(message) end
    if message and LOD.RPGPresentation and LOD.RPGPresentation.Event then
        LOD.RPGPresentation:Event(ply, "resource", message, {event = "loot_collected", kind = ent.LODLootKind})
    end
    return true
end

function Loot:_ApplyTransmission(ent)
    if not IsValid(ent) then return end
    local ownerIdentity = ent.LODLootOwnerIdentity
    for _, ply in ipairs(player.GetAll()) do
        ent:SetPreventTransmit(ply, identityOf(ply) ~= ownerIdentity)
    end
end

function Loot:_PruneEntities()
    local now = CurTime()
    local currentSeed = RunManager.State and RunManager.State.LevelSeed
    local kept = {}
    for _, ent in ipairs(self.Entities or {}) do
        if IsValid(ent) then
            local expired = ent.LODLootExpiresAt and ent.LODLootExpiresAt <= now
            local wrongLevel = currentSeed and ent.LODLootLevelSeed ~= currentSeed
            if expired or wrongLevel then
                ent:Remove()
            else
                kept[#kept + 1] = ent
            end
        end
    end
    self.Entities = kept
end

function Loot:_EnforceTransientCap(ownerIdentity)
    local transient = {}
    for _, ent in ipairs(self.Entities or {}) do
        if IsValid(ent) and not ent.LODLootStaticId and ent.LODLootOwnerIdentity == ownerIdentity then
            transient[#transient + 1] = ent
        end
    end
    table.sort(transient, function(a, b)
        return (a.LODLootSpawnedAt or 0) < (b.LODLootSpawnedAt or 0)
    end)
    while #transient > ENEMY_DROP_CAP_PER_IDENTITY do
        local ent = table.remove(transient, 1)
        if IsValid(ent) then ent:Remove() end
    end
end

-- Finite native-stage breadcrumbs identify the last completed operation if the
-- engine closes without a Lua traceback. Never serialize full item records.
function Loot:TraceStage(stage, ent, kind, model, detail)
    local fields = {stage=stage, entity=IsValid(ent) and ent:EntIndex() or -1,
        kind=kind, model=model}
    -- Plain bounded reproduction inputs only; never serialize entities/items.
    for key, value in pairs(detail or {}) do
        fields[key] = type(value) == "string" and string.sub(value, 1, 240) or value
    end
    local log = LOD.RPGTestLog
    if log and log.Write then log:Write("LOOT_NATIVE_STAGE", fields) end
    if LOD.RuntimeAudit and LOD.RuntimeAudit.Record then
        local parts = {}
        for key, value in pairs(fields) do parts[#parts + 1] = key .. "=" .. tostring(value) end
        table.sort(parts)
        LOD.RuntimeAudit:Record("LOOT_NATIVE_STAGE", table.concat(parts, " "))
    end
end

function Loot:_PreparedRewardValid(kind, payload)
    if type(kind) ~= "string" or type(payload) ~= "table" then return false end
    if kind == "wearable" then
        local equipment = LOD.Equipment
        local item = payload.item
        return equipment and equipment.ValidateWearable and equipment:ValidateWearable(item)
            and equipment:Definition(item) ~= nil
    end
    if kind == "consumable" then
        local equipment = LOD.Equipment
        local def = equipment and equipment.Definitions and equipment.Definitions[payload.itemId]
        return def ~= nil and def.throwable == true
    end
    if kind == "weapon" then return WEAPONS[payload.weaponClass] ~= nil end
    if kind == "dft" then return payload.token ~= nil end
    return KIND_MODEL[kind] ~= nil
end

function Loot:_PickupName(kind, payload)
    if kind == "wearable" and LOD.Equipment then
        return LOD.Equipment:ItemName(payload.item)
    end
    if kind == "consumable" and LOD.Equipment then
        local def = LOD.Equipment.Definitions[payload.itemId]
        return def and def.name or "Consumable"
    end
    if kind == "weapon" then
        local def = WEAPONS[payload.weaponClass]
        return def and def.label or "Weapon"
    end
    return ({ammo="Ammunition",health="Health",armor="Armor",life="Extra Life",
        cache="Supply Cache",dft="Debbie Fund Token"})[kind] or kind
end

function Loot:SpawnPickup(ownerIdentity, pos, kind, payload, options)
    if not ownerIdentity or not pos then return nil end
    options = options or {}
    self:TraceStage("reward_prepare", nil, kind)
    if LOD.Equipment and LOD.Equipment.PrepareReward then
        local prepared, preparedKind, preparedPayload = pcall(
            LOD.Equipment.PrepareReward, LOD.Equipment, ownerIdentity, kind, payload, options)
        if not prepared then
            self:TraceStage("reward_prepare_error", nil, kind, "rejected")
            print("[LOD:LOOT] rejected reward after equipment preparation error: " .. tostring(preparedKind))
            return nil
        end
        kind, payload = preparedKind, preparedPayload
    end
    self:TraceStage("reward_prepared", nil, kind)
    if not self:_PreparedRewardValid(kind, payload) then
        self:TraceStage("reward_invalid", nil, kind, "rejected")
        print("[LOD:LOOT] rejected invalid prepared reward kind=" .. tostring(kind))
        return nil
    end

    self:TraceStage("entity_create", nil, kind)
    local ent = ents.Create("lod_loot_pickup")
    if not IsValid(ent) then return nil end

    local model = kind == "dft" and "models/props_lab/huladoll.mdl" or KIND_MODEL[kind]
    if kind == "weapon" and payload and WEAPONS[payload.weaponClass] then
        model = WEAPONS[payload.weaponClass].model
    end
    if kind=="wearable" and payload and LOD.Equipment then
        local def=LOD.Equipment:Definition(payload.item)
        if def then model=def.model end
    end

    ent.LODLootOwnerIdentity = ownerIdentity
    ent.LODLootKind = kind
    ent.LODLootPayload = table.Copy(payload or {})
    ent.LODLootStaticId = options.staticId
    ent.LODLootLevelSeed = RunManager.State and RunManager.State.LevelSeed
    ent.LODLootSpawnedAt = CurTime()
    ent.LODLootExpiresAt = options.staticId and nil or (CurTime() + ENEMY_DROP_LIFETIME)
    self:TraceStage("model_validate", ent, kind, model)
    ent.LODLootModel = safeModel(model)
    ent.LODLootColor = KIND_COLOR[kind] or KIND_COLOR.ammo
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, options.yaw or 0, 0))
    self:TraceStage("spawn_enter", ent, kind, ent.LODLootModel)
    ent:Spawn()
    if not IsValid(ent) then return nil end
    self:TraceStage("spawn_complete", ent, kind, ent.LODLootModel)
    ent:SetNW2String("LOD_LootName", string.sub(self:_PickupName(kind, payload), 1, 256))
    -- The pickup uses a fixed bounding box at native model scale. Avoid both
    -- collision rebuilds and cosmetic appearance work for ordinary wearables.
    local itemDef = kind == "wearable" and LOD.Equipment and LOD.Equipment:Definition(payload.item)
    if itemDef and itemDef.weapon and LOD.WeaponAppearance then
        LOD.WeaponAppearance:Stamp(ent, payload.item)
    end
    if kind == "wearable" and LOD.Equipment then LOD.Equipment:SyncPickup(ent) end

    self.Entities[#self.Entities + 1] = ent
    self:_ApplyTransmission(ent)
    ent.LODLootRegistered = true
    self:TraceStage("registered", ent, kind, ent.LODLootModel)
    if not options.staticId then self:_EnforceTransientCap(ownerIdentity) end
    return ent
end

function Loot:CleanupLevel()
    for _, ent in ipairs(self.Entities or {}) do
        if IsValid(ent) then ent:Remove() end
    end
    self.Entities = {}
    self.StaticPlan = nil
    self.StaticByIdentity = {}
end

local function encounterByCell(graph)
    local occupied = {}
    local plan = graph.EncounterPlan
    for _, encounter in ipairs(plan and plan.encounters or {}) do
        if encounter.cellKey then occupied[encounter.cellKey] = true end
    end
    return occupied
end

function Loot:_RewardCells(graph, sector)
    local occupied = encounterByCell(graph)
    local reward = {}
    local fallback = {}
    for _, key in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[key]
        local tag = graph.CellTags and graph.CellTags[key]
        if cell and tag and tag.sector == sector and not tag.objective and tag.role ~= "boss"
            and not occupied[key]
        then
            if tag.role == "reward" then reward[#reward + 1] = cell end
            if tag.role == "reward" or tag.role == "resupply" or tag.safe or tag.role == "travel" then
                fallback[#fallback + 1] = cell
            end
        end
    end
    return #reward > 0 and reward or fallback
end

function Loot:_SectorCandidates(graph, sector)
    local occupied = encounterByCell(graph)
    local preferred = {}
    local fallback = {}
    for _, key in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[key]
        local tag = graph.CellTags and graph.CellTags[key]
        if cell and tag and tag.sector == sector and not tag.objective and tag.role ~= "boss"
            and not occupied[key]
        then
            if tag.safe or tag.role == "resupply" or tag.role == "reward" then
                preferred[#preferred + 1] = cell
            else
                fallback[#fallback + 1] = cell
            end
        end
    end
    for _, cell in ipairs(fallback) do preferred[#preferred + 1] = cell end
    return preferred
end

function Loot:_AddStaticNode(plan, cell, kind, payload, sector, role, offset)
    if not cell then return nil end
    local id = #plan.nodes + 1
    local node = {
        id = id,
        staticId = string.format("%d:%d", plan.levelSeed, id),
        cell = {x = cell.x, y = cell.y, z = cell.z},
        kind = kind,
        payload = table.Copy(payload or {}),
        sector = sector,
        role = role or "sustain",
        offset = offset or Vector(0, 0, 30)
    }
    plan.nodes[#plan.nodes + 1] = node
    return node
end

function Loot:_SectorThreat(graph)
    local threat = {0, 0, 0, 0}
    for _, encounter in ipairs(graph.EncounterPlan and graph.EncounterPlan.encounters or {}) do
        local sector = math.Clamp(encounter.sector or 1, 1, 4)
        threat[sector] = threat[sector] + (encounter.threat or 0)
    end
    return threat
end

function Loot:_ExpectedAuthoredHP(graph)
    local hp = {0, 0, 0, 0}
    for _, encounter in ipairs(graph.EncounterPlan and graph.EncounterPlan.encounters or {}) do
        local sector = math.Clamp(encounter.sector or 1, 1, 4)
        for archetype, count in pairs(encounter.composition or {}) do
            local expected = EXPECTED_HP[archetype]
            if not expected then
                local cfg = LOD.Config.Encounter.Archetypes[archetype]
                expected = cfg and math.max(1, (cfg.baseHP or 10) * 0.55) or 10
            end
            hp[sector] = hp[sector] + expected * count
        end
    end
    return hp
end

function Loot:BuildStaticPlan(graph)
    if not graph or not graph.Progression or not graph.CellTags then return false, "loot plan requires encounter-tagged progression graph" end

    local levelSeed = RunManager.State and RunManager.State.LevelSeed or graph.MasterLevelSeed or 1
    local level = RunManager.State and RunManager.State.Level or 1
    local rng = LOD.RNG.New(LOD.Seeds.Derive(levelSeed, "loot-static"))
    local plan = {
        seed = LOD.Seeds.Derive(levelSeed, "loot-static"),
        levelSeed = levelSeed,
        level = level,
        nodes = {},
        sectorThreat = self:_SectorThreat(graph),
        expectedAuthoredHP = self:_ExpectedAuthoredHP(graph),
        ammoNodes = {0, 0, 0, 0}
    }

    -- Early baseline sustain without silently changing the starting inventory.
    self:_AddStaticNode(plan, graph.Start, "ammo", {tier = "small"}, 1, "baseline", Vector(72, 0, 28))
    self:_AddStaticNode(plan, graph.Start, "armor", {amount = 15}, 1, "baseline", Vector(-72, 0, 28))

    -- Level-1 weapon access is individualized but remains in the same objective
    -- pockets that proved readable during the Gate-C scaffold.
    local cards = graph.Progression.Keycards or {}
    if level == 1 then
        if cards[1] then self:_AddStaticNode(plan, cards[1].cell, "weapon", {weaponClass = "weapon_shotgun"}, 1, "weapon", Vector(78, 0, 28)) end
        if cards[2] then self:_AddStaticNode(plan, cards[2].cell, "weapon", {weaponClass = "weapon_smg1"}, 2, "weapon", Vector(-78, 0, 28)) end
    end

    -- Checkpoint recovery is deliberately visible immediately beyond each gate.
    for index, gate in ipairs(graph.Progression.Gates or {}) do
        local sector = math.min(4, index + 1)
        self:_AddStaticNode(plan, gate.afterCell, "health",
            {amount = index == 3 and 45 or (20 + index * 5)}, sector, "checkpoint", Vector(68, 0, 28))
        self:_AddStaticNode(plan, gate.afterCell, "ammo",
            {tier = index == 3 and "large" or "medium"}, sector, "checkpoint", Vector(-68, 0, 28))
        if index == 3 then
            self:_AddStaticNode(plan, gate.afterCell, "armor", {amount = 35}, sector, "pre-core", Vector(0, 68, 28))
        end
    end

    -- Encounter-derived baseline ammunition. More dangerous sectors earn more
    -- caches, with a hard bound to preserve sparse authored-feeling placement.
    local usedCell = {}
    for sector = 1, 4 do
        local count = math.Clamp(math.ceil((plan.sectorThreat[sector] + sector * 0.75) / 2.5), 2, 5)
        local candidates = self:_SectorCandidates(graph, sector)
        rng:Derive("sector-candidates:" .. sector):Shuffle(candidates)
        local placed = 0
        for _, cell in ipairs(candidates) do
            local key = LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z)
            if not usedCell[key] then
                usedCell[key] = true
                local tier = sector == 1 and "small" or "medium"
                self:_AddStaticNode(plan, cell, "ammo", {tier = tier}, sector, "sustain", Vector(0, 0, 28))
                plan.ammoNodes[sector] = plan.ammoNodes[sector] + 1
                placed = placed + 1
                if placed >= count then break end
            end
        end
    end

    -- Optional reward branches carry the campaign weapon bands and above-baseline caches.
    local reward2 = self:_RewardCells(graph, 2)
    local reward3 = self:_RewardCells(graph, 3)
    local reward4 = self:_RewardCells(graph, 4)
    local function pickReward(list, label)
        if not list or #list == 0 then return nil end
        local copy = table.Copy(list)
        rng:Derive(label):Shuffle(copy)
        return copy[1]
    end

    self:_AddStaticNode(plan, pickReward(reward3, "throwable"), "consumable", {itemId = "healing_potion"}, 3, "reward", Vector(0, 0, 30))
    self:_AddStaticNode(plan, pickReward(reward4, "large-cache"), "cache", {}, 4, "reward", Vector(0, 0, 30))
    if level >= 2 then
        self:_AddStaticNode(plan, pickReward(reward2, "magnum"), "weapon", {weaponClass = "weapon_357"}, 2, "reward", Vector(0, 0, 30))
    end
    if level >= 3 then
        self:_AddStaticNode(plan, pickReward(reward3, "ar2"), "weapon", {weaponClass = "weapon_ar2"}, 3, "reward", Vector(0, 0, 30))
    end

    graph.LootPlan = plan
    self.StaticPlan = plan
    return true, plan
end

function Loot:EnsureStaticForPlayer(ply)
    if not IsValid(ply) or not RunManager:IsActivePlayer(ply) then return false end
    local plan = self.StaticPlan
    if not plan or plan.levelSeed ~= RunManager.State.LevelSeed then return false end

    local ownerIdentity = identityOf(ply)
    if not ownerIdentity then return false end
    local lootState = self:_PlayerLootState(ply)
    if not lootState then return false end

    self.StaticByIdentity[ownerIdentity] = self.StaticByIdentity[ownerIdentity] or {}
    local byId = self.StaticByIdentity[ownerIdentity]

    for _, node in ipairs(plan.nodes) do
        if not lootState.consumedStatic[node.staticId] then
            local existing = byId[node.staticId]
            if IsValid(existing) then
                existing:SetPreventTransmit(ply, false)
            else
                local cell = RunManager.State.Graph and RunManager.State.Graph.Cells[
                    LOD.MazeGenerator.CellKey(node.cell.x, node.cell.y, node.cell.z)]
                if cell then
                    local pos = LOD.MazeNavigator:CellCenter(cell) + node.offset
                    local ent = self:SpawnPickup(ownerIdentity, pos, node.kind, node.payload,
                        {staticId = node.staticId, yaw = (node.id * 53) % 360, equipmentEligible=node.role == "reward"})
                    if IsValid(ent) then
                        byId[node.staticId] = ent
                        self.Stats.staticSpawned = (self.Stats.staticSpawned or 0) + 1
                    end
                end
            end
        end
    end
    return true
end

function Loot:_ObjectiveClearDrop(hostile)
    local encounterId = hostile.LODEncounterId
    local plan = LOD.EncounterDirector and LOD.EncounterDirector.Plan
    local encounter = encounterId and plan and plan.encounters and plan.encounters[encounterId]
    if not encounter or not encounter.objective then return false end

    for _, ent in ipairs(encounter.entities or {}) do
        if IsValid(ent) and ent ~= hostile and not ent.LODDead then return false end
    end
    return true
end

function Loot:_DropCategory(ply, lootState, rng, guaranteedUseful)
    local usefulChance = guaranteedUseful and 1.0 or (lootState.dryKills >= 5 and 0.90 or 0.75)
    if not rng:Chance(usefulChance) then return nil, false end

    local hpRatio = ply:Health() / math.max(1, ply:GetMaxHealth())
    local armorRatio = ply:Armor() / MAX_ARMOR
    local ammoNeed = self:_AmmoNeed(ply)
    local weaponMissing = self:_MissingWeaponReward(ply, rng) ~= nil

    local entries = {
        {value = "ammo", weight = 35 * (0.55 + ammoNeed * 1.85)},
        {value = "health", weight = 12 * (hpRatio < 0.25 and 3.0 or (hpRatio < 0.55 and 2.0 or 0.55))},
        {value = "armor", weight = 5 * (armorRatio < 0.25 and 2.2 or (armorRatio < 0.60 and 1.4 or 0.45))},
        {value = "weapon", weight = 12 * (weaponMissing and 1.8 or 0.75)},
        {value = "wearable", weight = 24},
        {value = "consumable", weight = 12},
        {value = "life", weight = self:_CanUseExtraLife(ply) and 1.5 or 0}
    }

    return weightedPick(rng, entries), lootState.dryKills >= 5 and not guaranteedUseful
end

function Loot:ResolveEnemyReward(ply, category, rng)
    local kind = category
    local payload = {}
    if category == "ammo" then
        local family = self:_ChooseAmmoFamily(ply, rng)
        if not family then return false end
        payload.tier = "small"
        payload.weaponClass = family
    elseif category == "health" then
        payload.amount = ply:Health() <= ply:GetMaxHealth() * 0.30 and 35 or 25
    elseif category == "armor" then
        payload.amount = 20
    elseif category == "weapon" then
        local weaponClass = self:_MissingWeaponReward(ply, rng)
        if weaponClass then
            kind = "weapon"
            payload.weaponClass = weaponClass
        elseif rng:Chance(0.35) then
            kind = "consumable"
            payload.itemId = "healing_potion"
        else
            kind = "cache"
        end
    elseif category == "consumable" then
        payload.itemId = "healing_potion"
    elseif category == "life" then
        if not self:_CanUseExtraLife(ply) then return false end
        kind = "life"
    end

    return kind, payload
end

function Loot:_SpawnEnemyResult(ply, hostile, category, rng)
    local ownerIdentity = identityOf(ply)
    if not ownerIdentity then return false end
    local kind, payload = self:ResolveEnemyReward(ply, category, rng)
    if not kind then return false end
    local basePos = hostile:GetPos() + Vector(0, 0, 12)
    local angle = rng:Float(0, math.pi * 2)
    local radius = rng:Float(8, 18)
    local pos = basePos + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
    local ent = self:SpawnPickup(ownerIdentity, pos, kind, payload,
        {yaw = rng:Int(0, 359), equipmentEligible=true, equipmentSeed=hostile.LODInstanceSeed or hostile:EntIndex()})
    if IsValid(ent) then
        self.Stats.enemyDrops = (self.Stats.enemyDrops or 0) + 1
        return true
    end
    return false
end

function Loot:OnHostileLootHandoff(hostile)
    if not IsValid(hostile) or hostile.LODLootHandoffCompleted then return end
    local state = RunManager.State
    if not state or state.Failed or state.LevelCleared or hostile.LODDeathLevelSeed ~= state.LevelSeed then return end
    hostile.LODLootHandoffCompleted = true

    self:TraceStage("handoff_begin", hostile)
    local guaranteedUseful = self:_ObjectiveClearDrop(hostile)
    local instanceSeed = hostile.LODInstanceSeed or hostile:GetNW2Int("LOD_InstanceSeed", hostile:EntIndex())

    for _, ply in ipairs(player.GetAll()) do
        if RunManager:IsActivePlayer(ply) then
            local lootState = self:_PlayerLootState(ply)
            if lootState then
                lootState.killSerial = (lootState.killSerial or 0) + 1
                self.Stats.enemyRolls = (self.Stats.enemyRolls or 0) + 1

                local ownerIdentity = identityOf(ply) or "unknown"
                local seed = LOD.Seeds.Derive(state.LevelSeed,
                    string.format("loot-drop:%s:%d:%s", ownerIdentity, lootState.killSerial, tostring(instanceSeed)))
                local rng = LOD.RNG.New(seed)
                local category, pity = self:_DropCategory(ply, lootState, rng, guaranteedUseful)

                self:TraceStage("category_resolved", hostile, category or "none")
                if category and self:_SpawnEnemyResult(ply, hostile, category, rng) then
                    lootState.dryKills = 0
                    if pity then self.Stats.pityDrops = (self.Stats.pityDrops or 0) + 1 end
                else
                    lootState.dryKills = (lootState.dryKills or 0) + 1
                end
            end
        end
    end
end

-- The former shared Level-1 weapon entities are replaced by individualized
-- LootDirector copies. The progression wrapper calls this method dynamically.
function MazeBuilder:_BuildLevelOneWeaponAccess()
    return 0
end

local baseMazeBuild = MazeBuilder.Build
function MazeBuilder:Build(graph)
    Loot:CleanupLevel()
    local ok, report = baseMazeBuild(self, graph)
    if not ok then return ok, report end

    local planned, planOrErr = Loot:BuildStaticPlan(graph)
    if not planned then
        self:Cleanup()
        Loot:CleanupLevel()
        return false, "loot planning failed: " .. tostring(planOrErr)
    end

    report.lootNodes = #(planOrErr.nodes or {})
    report.lootSeed = planOrErr.seed
    report.progression = report.progression or {}
    report.progression.guaranteedWeapons = 0
    return true, report
end

local baseTryActivate = RunManager.TryActivatePlayer
function RunManager:TryActivatePlayer(ply)
    local active = baseTryActivate(self, ply)
    if active and self.State.BuildReady and Loot.StaticPlan then Loot:EnsureStaticForPlayer(ply) end
    return active
end

hook.Add("PlayerInitialSpawn", "LOD_LootTransmissionForJoiningPlayer", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        for _, ent in ipairs(Loot.Entities or {}) do
            if IsValid(ent) then ent:SetPreventTransmit(ply, identityOf(ply) ~= ent.LODLootOwnerIdentity) end
        end
        if RunManager:IsActivePlayer(ply) then Loot:EnsureStaticForPlayer(ply) end
    end)
end)

-- lod_hostile resolves LootDirector directly; no class-table mutation.
timer.Create(CLEANUP_TIMER, 1, 0, function()
    Loot:_PruneEntities()
end)

hook.Add("ShutDown", "LOD_LootDirectorShutdown", function()
    Loot:CleanupLevel()
end)

concommand.Add("lod_loot_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    Loot:_PruneEntities()
    local static = 0
    local transient = 0
    for _, ent in ipairs(Loot.Entities or {}) do
        if IsValid(ent) then
            if ent.LODLootStaticId then static = static + 1 else transient = transient + 1 end
        end
    end

    local plan = Loot.StaticPlan
    local line = string.format(
        "planNodes=%d static=%d transient=%d enemyRolls=%d enemyDrops=%d pity=%d collected=%d extraLives=%d result=%s",
        plan and #plan.nodes or 0, static, transient, Loot.Stats.enemyRolls or 0,
        Loot.Stats.enemyDrops or 0, Loot.Stats.pityDrops or 0, Loot.Stats.collected or 0,
        Loot.Stats.extraLives or 0, plan and "PASS" or "FAIL")
    print("[LOD:LOOT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
