local E, Run = assert(LOD.Equipment), assert(LOD.RunManager)

function E:RefreshDerived(ply, ps)
    local progression = ps and ps.progressionState
    local system = LOD.CharacterProgressionSystem
    if not progression or not system then return end
    local abilities, _, block = self:Contributions(ps.equipment)
    local changed = progression.equipmentBlockChanceContribution ~= block
    for _, ability in ipairs(self.Abilities) do
        if not progression.equipmentAbilityDelta or progression.equipmentAbilityDelta[ability] ~= abilities[ability] then changed=true end
    end
    if not changed then return end
    progression.equipmentAbilityDelta = abilities
    progression.equipmentBlockChanceContribution = block
    system:_RecomputeProgressionState(progression)
    system:_ApplyPlayerMaxHP(ply, progression)
    system:SyncPlayer(ply)
end

function E:PrepareReward(owner, kind, payload, options)
    if not options.equipmentEligible or kind ~= "weapon" and kind ~= "cache" then return kind,payload end
    local run = Run.State
    local seed = LOD.Seeds.Derive(run.LevelSeed or 1,
        "equipment-reward:"..tostring(owner)..":"..tostring(options.staticId or options.equipmentSeed))
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed,"conversion"))
    if not rng:Chance(0.25) then return kind,payload end
    return "wearable", {item=self:Generate(seed,run.Level or 1)}
end

function E:SyncPickup(ent)
    local item = ent.LODLootPayload and ent.LODLootPayload.item
    if not self:ValidateWearable(item) then return end
    -- Ownership transmission remains LootDirector's authority. This is display
    -- data only; no client description/value can enter the equip transaction.
    ent:SetNW2String("LOD_Wearable", util.TableToJSON(item))
end

function E:CollectWearable(ent, ply, accept)
    if not self:CanAct(ply) then return false end
    local item = ent.LODLootPayload and ent.LODLootPayload.item
    local state = self:Ensure(Run:GetPlayerState(ply))
    if not self:AcquireWearable(state, item, accept) then return false end
    self:Sync(ply)
    return true, self:ItemName(item).." equipped — "..self:Description(item)
end
