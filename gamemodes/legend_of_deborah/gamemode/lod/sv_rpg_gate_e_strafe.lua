local RPG = LOD.RPG
local Effects, Rules = RPG.FeatEffectSystem, LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Feats = RPG.IdentityCatalog.OrdinaryFeats
local IDS = {'DEX_STRAFER_1'}
local NAMES = {'Strafer'}
local RANKS = {}
for rank, id in ipairs(IDS) do
    RANKS[id] = rank
    Feats[id] = {
        featId=id, displayName=NAMES[rank], featFamilyId='dex_strafe', rankIndex=rank,
        replacesLowerRank=rank>1, governingAbilities={'dex'}, abilityRequirements={dex=11+2*rank},
        prerequisiteFeatIds=rank>1 and {IDS[rank-1]} or {}, requiredCapabilityTags={},
        incompatibleFeatIds={}, allowedActorTypes={'hero','human_soldier'}, requiredSubsystemTags={},
        synergyTags={'movement'}, oneRank=true, repeatableFallback=false, directorBaseWeight=1,
        effectHandlerId='lateral_strafe', effectParams={multiplier=(rank>0 and 1.75 or 1), description=string.format(
            'Ordinary lateral strafe movement is %d%% faster. Only the sideways component changes on diagonals. Ladders, scripted and forced movement are unchanged.',75)}
    }
end
function Effects:StrafeProfile(state)
    local rank=0
    for _,id in ipairs(state and state.featIds or {}) do rank=math.max(rank,RANKS[id] or 0) end
    return rank,(rank>0 and 1.75 or 1)
end
if not Effects.LODStrafeDerivedWrapped then
    Effects.LODStrafeDerivedWrapped=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state,derived)
        base(self,state,derived)
        derived.strafeRank,derived.strafeSpeedMultiplier=self:StrafeProfile(state)
    end
end

-- Resolve the ordinary capped input first, then change only the lateral axis.
-- Merely multiplying raw sidemove would let Source's circular speed clamp also
-- reduce forward motion on diagonals. Raising the cap alone would boost both axes.
-- Loaded by shared.lua; standalone diagnostics may include this module directly.
if not LOD.FeatMovement then include("sh_feat_movement.lua") end
function Effects:ResolveStrafeInput(...) return LOD.FeatMovement.ResolveStrafeInput(...) end

Effects.StrafeStats=Effects.StrafeStats or setmetatable({}, {__mode='k'})
if not Rules.LODStrafeMovementWrapped then
    Rules.LODStrafeMovementWrapped=true
    local base=Rules.ApplyVoluntaryMovementFeats
    function Rules:ApplyVoluntaryMovementFeats(actor,move)
        if base then base(self,actor,move) end
        local derived=self:Derived(actor)
        local multiplier=derived and derived.strafeSpeedMultiplier or 1
        local eligible=IsValid(actor) and actor:IsPlayer() and actor:Alive()
            and actor:GetMoveType()==MOVETYPE_WALK
            and actor:WaterLevel()<2
            and not (actor.InVehicle and actor:InVehicle())
            and not (actor.IsFrozen and actor:IsFrozen())
            and (not LOD.RPGStatusElements or LOD.RPGStatusElements:CanMoveVoluntarily(actor))
        local forward,side=move:GetForwardSpeed(),move:GetSideSpeed()
        local stats=Effects.StrafeStats[actor]
        if eligible and multiplier>1 and side~=0 then
            local speed,client=move:GetMaxSpeed(),move:GetMaxClientSpeed()
            local f,s,m,c=Effects:ResolveStrafeInput(forward,side,speed,client,multiplier)
            move:SetForwardSpeed(f); move:SetSideSpeed(s)
            move:SetMaxSpeed(m); move:SetMaxClientSpeed(c)
            if stats then
                stats.samples=stats.samples+1
                if forward~=0 then stats.diagonal=stats.diagonal+1 end
                stats.peak=math.max(stats.peak,multiplier)
                stats.last=multiplier
            end
        elseif stats then
            stats.last=1
            if forward~=0 and side==0 then stats.forwardOnly=stats.forwardOnly+1 end
        end
    end
end
function Effects:ValidateStrafe()
    local errors={}
    for rank,id in ipairs(IDS) do
        local owned={}
        for i=1,rank do owned[i]=IDS[i] end
        local r,m=self:StrafeProfile({featIds=owned})
        local d=Feats[id]
        if r~=rank or math.abs(m-((rank>0 and 1.75 or 1)))>.000001 or d.abilityRequirements.dex~=11+2*rank
            or (rank>1 and d.prerequisiteFeatIds[1]~=IDS[rank-1]) then errors[#errors+1]=id end
        local f,s=self:ResolveStrafeInput(10000,10000,200,200,m)
        if math.abs(f-200/math.sqrt(2))>.000001 or math.abs(s-f*m)>.000001 then
            errors[#errors+1]='diagonal component mismatch'
        end
    end
    return #errors==0,errors
end
local validation=LOD.RPGValidation
if validation and not validation.LODStrafeWrapped then
    validation.LODStrafeWrapped=true
    local base=validation.Run
    function validation:Run(printResult)
        local ok,errors=base(self,printResult)
        local valid,ownErrors=Effects:ValidateStrafe()
        errors=errors or {}
        for _,err in ipairs(ownErrors) do errors[#errors+1]=err end
        return ok and valid,errors
    end
end
local function allowed(ply)
    local cv=GetConVar('lod_developer_mode')
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin()
end
concommand.Add('lod_rpg_strafe_testkit',function(ply,_,args)
    if not allowed(ply) or not ply:Alive() then return end
    local state=Rules:ProgressionState(ply)
    if not state then return end
    local rank=math.Clamp(math.floor(tonumber(args[1]) or 1),0,1)
    local kept={}
    for _,id in ipairs(state.featIds or {}) do if not RANKS[id] then kept[#kept+1]=id end end
    state.featIds=kept; state.featStackCounts=state.featStackCounts or {}
    for _,id in ipairs(IDS) do state.featStackCounts[id]=nil end
    for i=1,rank do state.featIds[#state.featIds+1]=IDS[i]; state.featStackCounts[IDS[i]]=1 end
    Progression:_RecomputeProgressionState(state); Progression:SyncPlayer(ply)
    if LOD.RunManager.MarkUnranked then LOD.RunManager:MarkUnranked('Strafe feat test') end
    Effects.StrafeStats[ply]={samples=0,diagonal=0,forwardOnly=0,peak=1,last=1}
    ply:ChatPrint('Strafe rank '..rank..': walk A, D, W+A, S+D, then W; run lod_rpg_strafe_status.')
end)
concommand.Add('lod_rpg_strafe_status',function(ply)
    if not allowed(ply) then return end
    local stats=Effects.StrafeStats[ply] or {}
    local rank=Effects:StrafeProfile(Rules:ProgressionState(ply))
    local ok,errors=Effects:ValidateStrafe()
    local line=string.format('[LOD:STRAFE] definition=%s rank=%d samples=%d diagonal=%d forwardOnly=%d peak=%.2f last=%.2f %s',
        ok and 'PASS' or 'FAIL',rank,stats.samples or 0,stats.diagonal or 0,stats.forwardOnly or 0,
        stats.peak or 1,stats.last or 1,table.concat(errors,'; '))
    print(line); ply:ChatPrint(line)
end)
return Effects
