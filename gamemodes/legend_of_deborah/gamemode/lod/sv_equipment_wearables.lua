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

-- Item records exceed NW2String's 511-byte limit. Send the full immutable
-- record only to its nearby owner, on demand (also works after reconnect/PVS).
util.AddNetworkString("LOD_EquipmentInspect")
local inspectTimes = setmetatable({}, {__mode="k"})
function E:SyncPickup(ent)
    ent.LODItemViewReady = self:ValidateWearable(ent.LODLootPayload and ent.LODLootPayload.item)
end
function E:SendPickupView(ply, ent)
    if not self:CanAct(ply) or not IsValid(ent) or ent:GetClass()~="lod_loot_pickup"
        or not ent.LODItemViewReady or ent.LODCollected
        or ent.LODLootOwnerIdentity~=Run:IdentityOf(ply)
        or ent.LODLootLevelSeed~=Run.State.LevelSeed
        or ent.LODLootExpiresAt and ent.LODLootExpiresAt<=CurTime()
        or ply:GetPos():DistToSqr(ent:GetPos())>128*128 then return false end
    net.Start("LOD_EquipmentInspect")
    net.WriteEntity(ent)
    net.WriteTable(ent.LODLootPayload.item)
    net.Send(ply)
    return true
end
net.Receive("LOD_EquipmentInspect",function(bits,ply)
    if bits>16 or not IsValid(ply) then return end
    local now=CurTime()
    if now<(inspectTimes[ply] or 0) then return end
    inspectTimes[ply]=now+.25
    E:SendPickupView(ply,net.ReadEntity())
end)

function E:CollectWearable(ent, ply, accept)
    if not self:CanAct(ply) then return false end
    local item = ent.LODLootPayload and ent.LODLootPayload.item
    local state = self:Ensure(Run:GetPlayerState(ply))
    if not self:AcquireWearable(state, item, accept) then return false end
    self:Sync(ply)
    return true, self:ItemName(item).." equipped — "..self:Description(item)
end
