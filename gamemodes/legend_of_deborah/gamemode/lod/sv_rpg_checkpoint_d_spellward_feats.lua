LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Spellward requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Spellward requires ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Spellward requires effects")
Feats.WIS_SPELLWARD = {
    featId="WIS_SPELLWARD", displayName="Spellward", featFamilyId="wis_spellward", rankIndex=1,
    replacesLowerRank=false, repeatableFallback=false, governingAbilities={"wis"}, abilityRequirements={wis=13},
    prerequisiteFeatIds={}, requiredCapabilityTags={}, incompatibleFeatIds={},
    allowedActorTypes={"hero","human_soldier","ai"}, requiredSubsystemTags={"status_saves"},
    synergyTags={"wisdom","magic_save","defense"}, oneRank=true, effectHandlerId="magic_save_advantage",
    effectParams={magicSaveAdvantage=true, description="Whenever an otherwise-legal Magic Save is made, roll two d20s and keep the higher natural result before adding the ordinary WIS and level modifiers. This creates no save against effects that normally allow none."},
    directorBaseWeight=1.0, eligibilityText="WIS 13", actorText="Heroes, human Soldiers, and AI"
}
Catalog.OrdinaryFeats = Feats
local function owns(state)
    for _, id in ipairs(state and state.featIds or {}) do if id=="WIS_SPELLWARD" then return true end end
    return false
end
if not Effects.LODCheckpointDSpellwardDerivedWrapped then
    Effects.LODCheckpointDSpellwardDerivedWrapped=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self,state,derived)
        derived.magicSaveAdvantage=owns(state)
    end
end
function RPG:ValidateCheckpointDSpellwardFeats()
    local d={}; Effects:ApplyDerived({featIds={"WIS_SPELLWARD"}},d)
    local plain={}; Effects:ApplyDerived({featIds={}},plain)
    local ok=Feats.WIS_SPELLWARD.abilityRequirements.wis==13 and d.magicSaveAdvantage==true
        and plain.magicSaveAdvantage==false and Feats.WIS_SPELLBREAKER==nil and Feats.WIS_SPELLBANE==nil
    return ok, ok and {} or {"Spellward advantage/single-rank definition"}
end
concommand.Add("lod_rpg_validate_spellward",function(ply)
    local cv=GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok,errors=RPG:ValidateCheckpointDSpellwardFeats()
    print("[LOD:SPELLWARD] "..(ok and "PASS" or "FAIL")..(#errors>0 and (" "..table.concat(errors,"; ")) or ""))
end)
