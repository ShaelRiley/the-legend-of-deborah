LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG=LOD.RPG
local Catalog=assert(RPG.IdentityCatalog,"Haste requires catalog")
local Feats=assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats,"Haste requires ordinary feats")
local Effects=assert(RPG.FeatEffectSystem,"Haste requires effects")
local Rules=assert(LOD.RPGAbilityRules,"Haste requires movement authority")
Feats.INT_HASTE_1={
    featId="INT_HASTE_1",displayName="Haste",featFamilyId="int_haste",rankIndex=1,
    replacesLowerRank=false,repeatableFallback=false,governingAbilities={"int"},abilityRequirements={int=13},
    prerequisiteFeatIds={},requiredCapabilityTags={},incompatibleFeatIds={},
    allowedActorTypes={"hero","human_soldier"},requiredSubsystemTags={"movement"},
    synergyTags={"movement","passive"},oneRank=true,effectHandlerId="haste_passive_movement",
    effectParams={movementMultiplier=1.33,description="Passively increases ordinary voluntary walk, run and sprint speed by 33%. No toggle, Magic cost, drain or regeneration suppression. Does not amplify airborne acceleration, jump velocity, Wall Jump, Cloud Step, Float On, knockback or scripted movement."},
    directorBaseWeight=1,eligibilityText="INT 13",actorText="Player-controlled Heroes and human Soldiers"
}
Catalog.OrdinaryFeats=Feats
function Effects:HasteProfile(state)
    for _,id in ipairs(state and state.featIds or {}) do if id=="INT_HASTE_1" then return 1,1.33 end end
    return 0,1
end
-- Retire the old loaded toggle on AutoRefresh. Its captured MovementMultiplier
-- wrapper can survive until map restart; this inert compatibility predicate is
-- installed only for that historical closure, never used by the new movement path.
local legacyLoaded=Effects.LODCheckpointDHasteDerivedWrapped and not Effects.LODPassiveHaste20261002
if legacyLoaded then
    if timer and timer.Remove then timer.Remove("LOD_RPG_CheckpointDHasteDrain") end
    if hook.Remove then
        hook.Remove("LODMagicRegenerationSuppressed","LOD_RPG_CheckpointDHaste")
        hook.Remove("PlayerDeath","LOD_RPG_CheckpointDHasteDeath")
        hook.Remove("PlayerDisconnected","LOD_RPG_CheckpointDHasteDisconnect")
    end
    if net.Receivers then net.Receivers[string.lower("LOD_HasteToggle")]=nil end
    for ply in pairs(Effects.HasteState or {}) do
        if IsValid(ply) then ply:SetNW2Bool("LOD_HasteActive",false);ply.LODNextHasteToggle=nil end
    end
    Rules.IsHasteActive=function() return false end
    Rules.SetHasteActive=nil;Rules.HasteDrainPerSecond=nil;Effects.HasteState=nil
end
Feats.INT_HASTE_2=nil;Feats.INT_HASTE_3=nil
if not Effects.LODPassiveHaste20261002 then
    Effects.LODPassiveHaste20261002=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state,derived)
        base(self,state,derived)
        local owned,multiplier=self:HasteProfile(state)
        derived.hasteEnabled,derived.hasteMovementMultiplier=owned==1,multiplier
        derived.hasteRank,derived.hasteDrainMultiplier=nil,nil
    end
end

-- Modify voluntary wish movement, never velocity, BaseVelocity or authored kicks.
-- The ordinary walk/run/sprint, DEX, Rogue, equipment and status rates have already
-- resolved at the single Gate D SetupMove seam. Strafe changes only its own axis.
function Rules:VoluntaryFeatMovementMultiplier(actor,derived,move)
    if not IsValid(actor) or not actor:IsPlayer() or not actor:Alive()
        or actor:GetMoveType()~=MOVETYPE_WALK or actor:WaterLevel()>=2
        or (actor.InVehicle and actor:InVehicle()) or (actor.IsFrozen and actor:IsFrozen()) then return 1 end
    local status=LOD.RPGStatusElements
    if status and not status:CanMoveVoluntarily(actor) then return 1 end
    derived=derived or self:Derived(actor) or {}
    if actor:OnGround() then
        -- SetupMove precedes Source's jump/air-move decision. A jump command
        -- must not carry the grounded Haste wish-speed bonus into AirMove.
        -- Existing horizontal momentum and the jump impulse remain untouched.
        if move and move:KeyDown(IN_JUMP) then return 1 end
        return tonumber(derived.hasteMovementMultiplier) or 1
    end
    return tonumber(derived.springHeelAirMovementMultiplier) or 1
end
if not Rules.LODPassiveHasteMovement20261002 then
    Rules.LODPassiveHasteMovement20261002=true
    local base=Rules.ApplyVoluntaryMovementFeats
    function Rules:ApplyVoluntaryMovementFeats(actor,move)
        if base then base(self,actor,move) end
        local multiplier=self:VoluntaryFeatMovementMultiplier(actor,nil,move)
        if multiplier==1 then return end
        move:SetForwardSpeed(move:GetForwardSpeed()*multiplier)
        move:SetSideSpeed(move:GetSideSpeed()*multiplier)
        move:SetMaxSpeed(move:GetMaxSpeed()*multiplier)
        move:SetMaxClientSpeed(move:GetMaxClientSpeed()*multiplier)
    end
end
function Rules:ValidateCheckpointDHaste()
    local enabled,multiplier=Effects:HasteProfile({featIds={"INT_HASTE_1"}})
    local plain,ordinary=Effects:HasteProfile({featIds={}})
    local ok=enabled==1 and multiplier==1.33 and plain==0 and ordinary==1
        and Feats.INT_HASTE_1.abilityRequirements.int==13 and Feats.INT_HASTE_2==nil and Feats.INT_HASTE_3==nil
    return ok,ok and {} or {"Haste passive single-rank movement"}
end
concommand.Add("lod_rpg_validate_haste",function(ply)
    local cv=GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok,errors=Rules:ValidateCheckpointDHaste()
    print("[LOD:HASTE] "..(ok and "PASS" or "FAIL")..(#errors>0 and (" "..table.concat(errors,"; ")) or ""))
end)
