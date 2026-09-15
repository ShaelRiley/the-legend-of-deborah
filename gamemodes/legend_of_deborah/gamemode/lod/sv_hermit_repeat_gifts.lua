-- One stored ordinary-drop gift after the identity's one-time starter issuance.
local S, Run, Loot, E = LOD.StagingDeployment, LOD.RunManager, LOD.LootDirector, LOD.Equipment
function S:CanCollectGift(ply, ent)
    local state = Run.State
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or not state
        or state.Failed or state.LevelCleared or state.SimulationFrozen then return false end
    local ps = Run:GetPlayerState(ply)
    return IsValid(ent) and ps and not ps.deploymentComplete and ps.hermitGift
        and not ps.hermitGift.claimed and ps.hermitGift.level == Run.State.Level
        and ent.LODHermitGiftId == ps.hermitGift.id and self.StarterEntities[ps.identity] == ent
        and Run:IsSlotActivePlayer(ply) and not Run:IsSoldierControl(ply) and self:IsPlayerInHut(ply)
end
local originalEnsure = S.EnsureStarterPickup
function S:EnsureStarterPickup(ply)
    local ps = Run:GetPlayerState(ply)
    if not ps or not ps.starterClaimed then return originalEnsure(self, ply) end
    local level = Run.State.Level
    if ps.deploymentComplete or level <= (ps.starterClaimedLevel or ps.starterEntryLevel or 1) then return false end
    if not self:EnsureHut() then return false end
    local gift = ps.hermitGift
    if not gift or gift.level ~= level then
        local id = "hermit:" .. tostring(level) .. ":" .. tostring(ps.identity)
        local rng = LOD.RNG.New(LOD.Seeds.Derive(Run.State.CampaignSeed or 1, id))
        -- The Hermit guarantees one item, using the standard context-weighted
        -- non-elite category table. An existing starter never becomes eligible
        -- again; the author's no-second-firearm rule uses ordinary ammo instead.
        local category = Loot:_DropCategory(ply, {dryKills=0}, rng, true)
        if category == "weapon" then category = "ammo" end
        local kind, payload = Loot:ResolveEnemyReward(ply, category, rng)
        -- Full ammo must not turn a promised gift into a rerollable empty result.
        if not kind then kind, payload = "consumable", {itemId="healing_potion"} end
        kind, payload = E:PrepareReward(ps.identity, kind, payload, {staticId=id,equipmentEligible=true})
        gift = {level=level,id=id,kind=kind,payload=table.Copy(payload),claimed=false}
        ps.hermitGift = gift
    end
    if gift.claimed then return false end
    local existing = self.StarterEntities[ps.identity]
    if IsValid(existing) then return true end
    local ent = Loot:SpawnPickup(ps.identity, self:_StarterPosition(), gift.kind, gift.payload,
        {staticId=gift.id,equipmentEligible=false})
    if not IsValid(ent) then return false end
    ent.LODHermitGiftId = gift.id
    self.StarterEntities[ps.identity] = ent
    return true
end
local collect = Loot.Collect
function Loot:Collect(ent, ply, ...)
    local giftId = IsValid(ent) and ent.LODHermitGiftId
    local ok, message = collect(self, ent, ply, ...)
    if ok and giftId then
        local ps = Run:GetPlayerState(ply)
        if ps and ps.hermitGift and ps.hermitGift.id == giftId then
            ps.hermitGift.claimed = true
            S.StarterEntities[ps.identity] = nil
        end
    end
    return ok, message
end
-- Later visits should describe the actual gift rather than claiming another gun.
local place = S.PlacePlayerInHut
function S:PlacePlayerInHut(ply, announce)
    local ps = Run:GetPlayerState(ply)
    local repeatVisit = ps and ps.starterClaimed and Run.State.Level > (ps.starterClaimedLevel or ps.starterEntryLevel or 1)
    local shouldAnnounce = repeatVisit and announce ~= false and not ps.stagingIntroShown
    if repeatVisit then ps.stagingIntroShown = true end
    local ok = place(self, ply, repeatVisit and false or announce)
    if ok and shouldAnnounce then
        ply:ChatPrint("DUNGEON HERMIT: Welcome back. Your next gift is on the pedestal. Use the portal when you are ready.")
    end
    return ok
end
