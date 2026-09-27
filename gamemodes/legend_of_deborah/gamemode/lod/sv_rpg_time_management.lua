-- SPOT-14: registered ordinary feat; the existing clock owns presence/accounting.
local RPG = assert(LOD.RPG)
local Catalog = assert(RPG.IdentityCatalog)
local Feats = assert(Catalog.OrdinaryFeats)
local Effects = assert(RPG.FeatEffectSystem)
local ID = "INT_TIME_MANAGEMENT"
assert(not Feats[ID], "duplicate canonical feat " .. ID)
Feats[ID] = {
    featId=ID, displayName="Time Management", featFamilyId="int_time_management", rankIndex=1,
    replacesLowerRank=false, repeatableFallback=false, oneRank=true,
    governingAbilities={"int"}, abilityRequirements={int=17}, prerequisiteFeatIds={},
    requiredCapabilityTags={}, incompatibleFeatIds={}, allowedActorTypes={"hero"},
    requiredSubsystemTags={}, synergyTags={"intelligence", "utility"},
    effectHandlerId="time_management", directorBaseWeight=1.0,
    eligibilityText="INT 17", actorText="Cooperative Heroes only",
    effectParams={secondsPerIntBonus=60, description="While alive and deployed, add your positive effective INT modifier in minutes to the shared dungeon clock. Different Heroes stack. Death, leaving or Soldier play removes your allowance; losing it can cause TIME OVER. Returning restores only that allowance, never elapsed time or an expired clock. No Magic cost."}
}

-- Consume canonical recomputed effective INT. Qualification remains FeatDirector's
-- job (including Winning Personality); temporary gear never rewrites ownership.
function Effects:TimeManagementSeconds(state)
    if not state or state.actorType ~= "hero" then return 0 end
    local owned = false
    for _, id in ipairs(state and state.featIds or {}) do
        if id == ID then owned = true; break end
    end
    if not owned then return 0 end
    local modifier = tonumber(state.derivedStats and state.derivedStats.intMod) or 0
    if modifier ~= modifier or modifier == math.huge or modifier == -math.huge then return 0 end
    return math.Clamp(math.floor(modifier), 0, 10) * Feats[ID].effectParams.secondsPerIntBonus
end
