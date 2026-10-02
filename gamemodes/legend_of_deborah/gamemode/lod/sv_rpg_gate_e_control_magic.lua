LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Validation = LOD.RPGValidation
if not Feats or not Effects or not Rules or not Progression then return end

local function owns(state,id)
    for _,value in ipairs(state and state.featIds or {}) do if value==id then return true end end
    return false
end
local function singleton(id, name, ability, requirement, capability, family, handler,
    actorText, description)
    return {
        featId = id,
        displayName = name,
        featFamilyId = family,
        rankIndex = 1,
        replacesLowerRank = false,
        repeatableFallback = false,
        governingAbilities = {ability},
        abilityRequirements = {[ability] = requirement},
        prerequisiteFeatIds = {},
        requiredCapabilityTags = capability and {capability} or {},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {family},
        oneRank = true,
        effectHandlerId = handler,
        effectParams = {description = description},
        directorBaseWeight = 1.0,
        eligibilityText = string.format("%s %d%s", string.upper(ability), requirement,
            capability and (" / " .. capability) or ""),
        actorText = actorText
    }
end

Feats.INT_MANA_SPRING = singleton(
    "INT_MANA_SPRING", "Mana Spring", "int", 13, "magic_pool",
    "int_mana_spring", "mana_spring_regeneration",
    "Heroes, human Soldiers, and Magic-using AI",
    "Magic regenerates 22% faster whenever ordinary regeneration is permitted. Multiply the otherwise resolved passive regeneration rate by 1.22 once; no zero-Magic trigger, duration or cooldown. Existing suppression and the 100-Magic capacity remain; direct refunds, costs and drains are unchanged.")


Catalog.OrdinaryFeats=Feats
Effects.ControlMagicConfig={manaSpringMultiplier=1.22}
Effects.ControlMagicStats={manaSpringActiveTicks=0,manaSpringPausedTicks=0,lastManaSpringMultiplier=1}
function Effects:ControlMagicProfile(state)
    local spring=owns(state,"INT_MANA_SPRING")
    return {manaSpring=spring,manaSpringRegenMultiplier=spring and 1.22 or 1}
end
function Effects:ResolveManaSpringTick(enabled,currentMagic,regenerationPermitted)
    local active=enabled==true and regenerationPermitted==true and (tonumber(currentMagic) or 0)<100
    return active and 1.22 or 1,active
end
-- Shared Magic Push remains available to ordinary forms/items/capstones. No
-- retired feat can author an outgoing amplifier or incoming resistance here.
function Effects:ResolvePushDistance(authoredDistance,attackerDerived,defenderDerived,opts)
    opts=opts or {}
    local authored=math.max(0,tonumber(authoredDistance) or 0)
    local outgoing=math.max(0,tonumber(attackerDerived and attackerDerived.fighterCapstoneOutgoingPushMultiplier) or 1)
    local magic=opts.magicPush==true and math.max(0,tonumber(attackerDerived and attackerDerived.magicPushMultiplier) or 1) or 1
    local incoming=opts.ignoreResistance==true and 1 or math.max(0,tonumber(defenderDerived and defenderDerived.fighterCapstoneIncomingPushMultiplier) or 1)
    return authored*outgoing*magic*incoming,{authored=authored,outgoingMultiplier=outgoing,
        magicPushMultiplier=magic,incomingMultiplier=incoming}
end
if not Effects.LODGateEControlMagicApplyDerivedWrapped then
    Effects.LODGateEControlMagicApplyDerivedWrapped=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state,derived)
        base(self,state,derived)
        local profile=self:ControlMagicProfile(state)
        derived.manaSpringEnabled=profile.manaSpring
        derived.manaSpringRegenMultiplier=profile.manaSpringRegenMultiplier
    end
end
for _,field in ipairs({"manaSpringEnabled","manaSpringRegenMultiplier"}) do
    local fields=RPG.Schema and RPG.Schema.DerivedStats
    if fields then
        local found=false
        for _,existing in ipairs(fields) do if existing==field then found=true end end
        if not found then fields[#fields+1]=field end
    end
end
function Effects:ValidateControlMagicFamilies()
    local errors={}
    local function expect(ok,message) if not ok then errors[#errors+1]=message end end
    local def=Feats.INT_MANA_SPRING
    expect(def and def.abilityRequirements.int==13,"Mana Spring INT 13")
    for _,value in ipairs({0,1,50,99}) do
        expect(self:ResolveManaSpringTick(true,value,true)==1.22,"passive x1.22 at "..value)
        expect(self:ResolveManaSpringTick(true,value,false)==1,"suppression respected")
        expect(self:ResolveManaSpringTick(false,value,true)==1,"ownership required")
    end
    expect(self:ResolveManaSpringTick(true,100,true)==1,"full pool cannot regenerate")
    expect(self:ResolvePushDistance(336,{}, {},{magicPush=true})==336,"ordinary Magic Push preserved")
    return #errors==0,errors
end
if Validation and not Validation.LODGateEControlMagicWrapped then
    Validation.LODGateEControlMagicWrapped=true
    local base=Validation.Run
    function Validation:Run(printResult)
        local ok,errors=base(self,false);errors=errors or {}
        local pass,more=Effects:ValidateControlMagicFamilies()
        for _,message in ipairs(more) do errors[#errors+1]="Mana Spring: "..message end
        if printResult~=false then print("[LOD:RPG] Mana Spring validation "..(ok and pass and "PASS" or "FAIL")) end
        return ok and pass,errors
    end
end
local function allowed(ply)
    local cv=GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end
concommand.Add("lod_rpg_gate_e_control_magic_validate",function(ply)
    if not allowed(ply) then return end
    local ok,errors=Effects:ValidateControlMagicFamilies()
    print("[LOD:RPG-E] Mana Spring passive x1.22 "..(ok and "PASS" or table.concat(errors,"; ")))
end)
concommand.Add("lod_rpg_gate_e_control_magic_status",function(ply)
    if not allowed(ply) or not IsValid(ply) then return end
    local profile=Effects:ControlMagicProfile(Rules:ProgressionState(ply))
    print(string.format("[LOD:RPG-E] Mana Spring=%s passive multiplier=%.2f; no trigger/window/cooldown",
        tostring(profile.manaSpring),profile.manaSpringRegenMultiplier))
end)
return Effects
