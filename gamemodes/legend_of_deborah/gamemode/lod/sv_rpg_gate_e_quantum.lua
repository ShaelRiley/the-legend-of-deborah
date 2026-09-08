local RPG = LOD.RPG
local Effects, Rules = RPG.FeatEffectSystem, LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Feats = RPG.IdentityCatalog.OrdinaryFeats
local IDS = {'INT_QUANTUM_MATHEMATICS_1','INT_QUANTUM_MECHANICS_2','INT_QUANTUM_MASTERY_3'}
local NAMES = {'Quantum Mathematics','Quantum Mechanics','Quantum Mastery'}
local MULTIPLIERS = {0.89,0.78,0.67}
local RANKS = {}
for rank,id in ipairs(IDS) do
    RANKS[id]=rank
    Feats[id]={featId=id,displayName=NAMES[rank],featFamilyId='int_quantum_cost',rankIndex=rank,
        replacesLowerRank=rank>1,governingAbilities={'int'},abilityRequirements={int=11+2*rank},
        prerequisiteFeatIds=rank>1 and {IDS[rank-1]} or {},requiredCapabilityTags={'offensive_magic_activation'},
        incompatibleFeatIds={},allowedActorTypes={'hero','human_soldier','ai'},requiredSubsystemTags={},
        synergyTags={'offensive_magic'},oneRank=true,repeatableFallback=false,directorBaseWeight=1,
        effectHandlerId='quantum_offensive_cost',effectParams={multiplier=MULTIPLIERS[rank],description=string.format(
            'Offensive active Magic costs %d%% less, rounded up with a minimum cost of 1. Highest rank replaces lower ranks. Utility costs, map drain, regeneration, damage and shield diversion are unchanged.',rank*11)}}
end
function Effects:QuantumProfile(state)
    local rank=0
    for _,id in ipairs(state and state.featIds or {}) do rank=math.max(rank,RANKS[id] or 0) end
    return rank,MULTIPLIERS[rank] or 1
end
function Effects:QuantumCost(baseCost,multiplier)
    if multiplier==1 then return baseCost end
    return math.max(1,math.ceil(baseCost*multiplier))
end
if not Effects.LODQuantumDerivedWrapped then
    Effects.LODQuantumDerivedWrapped=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state,derived)
        base(self,state,derived)
        derived.quantumRank,derived.quantumCostMultiplier=self:QuantumProfile(state)
    end
end
-- Call only at an eligible offensive activation's affordability/deduction seam.
-- Future Form/Content casting must use this after constructing its ordinary cost.
function Rules:OffensiveMagicCost(actor,baseCost)
    local derived=self:Derived(actor)
    return Effects:QuantumCost(baseCost,derived and derived.quantumCostMultiplier or 1)
end
Effects.QuantumStats=Effects.QuantumStats or setmetatable({}, {__mode='k'})
function Effects:RecordQuantumSpend(actor,baseCost,cost)
    local stats=self.QuantumStats[actor]
    if not stats then return end
    stats.casts=stats.casts+1; stats.base=baseCost; stats.cost=cost
    stats.spent=stats.spent+cost
end
function Effects:ValidateQuantum()
    local errors={}
    local expected={27,24,21}
    for rank,id in ipairs(IDS) do
        local owned={}
        for i=1,rank do owned[i]=IDS[i] end
        local r,m=self:QuantumProfile({featIds=owned})
        local def=Feats[id]
        if r~=rank or m~=MULTIPLIERS[rank] or self:QuantumCost(30,m)~=expected[rank]
            or self:QuantumCost(0.1,m)~=1 or def.abilityRequirements.int~=11+2*rank
            or (rank>1 and def.prerequisiteFeatIds[1]~=IDS[rank-1]) then errors[#errors+1]=id end
    end
    if self:QuantumCost(30,1)~=30 then errors[#errors+1]='baseline cost' end
    return #errors==0,errors
end
local validation=LOD.RPGValidation
if validation and not validation.LODQuantumWrapped then
    validation.LODQuantumWrapped=true
    local base=validation.Run
    function validation:Run(printResult)
        local ok,errors=base(self,printResult)
        local valid,ownErrors=Effects:ValidateQuantum()
        errors=errors or {}
        for _,err in ipairs(ownErrors) do errors[#errors+1]=err end
        return ok and valid,errors
    end
end
local function allowed(ply)
    local cv=GetConVar('lod_developer_mode')
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin()
end
concommand.Add('lod_rpg_quantum_testkit',function(ply,_,args)
    if not allowed(ply) or not ply:Alive() then return end
    local state=Rules:ProgressionState(ply)
    if not state then return end
    local rank=math.Clamp(math.floor(tonumber(args[1]) or 3),0,3)
    local kept={}
    for _,id in ipairs(state.featIds or {}) do if not RANKS[id] then kept[#kept+1]=id end end
    state.featIds=kept; state.featStackCounts=state.featStackCounts or {}
    for _,id in ipairs(IDS) do state.featStackCounts[id]=nil end
    for i=1,rank do state.featIds[#state.featIds+1]=IDS[i]; state.featStackCounts[IDS[i]]=1 end
    Progression:_RecomputeProgressionState(state); Progression:SyncPlayer(ply)
    local magic=LOD.Magic
    local ps=magic and magic:_EnsureState(ply)
    if ps then ps.magic=100; magic:_Sync(ply,ps) end
    if LOD.RunManager.MarkUnranked then LOD.RunManager:MarkUnranked('Quantum feat test') end
    Effects.QuantumStats[ply]={casts=0,base=0,cost=0,spent=0}
    ply:ChatPrint('Quantum rank '..rank..': cast once with RMB, then run lod_rpg_quantum_status.')
end)
concommand.Add('lod_rpg_quantum_status',function(ply)
    if not allowed(ply) then return end
    local stats=Effects.QuantumStats[ply] or {}
    local rank,m=Effects:QuantumProfile(Rules:ProgressionState(ply))
    local ok,errors=Effects:ValidateQuantum()
    local line=string.format('[LOD:QUANTUM] definition=%s rank=%d multiplier=%.2f casts=%d base=%g cost=%g spent=%g %s',
        ok and 'PASS' or 'FAIL',rank,m,stats.casts or 0,stats.base or 0,stats.cost or 0,stats.spent or 0,table.concat(errors,'; '))
    print(line); ply:ChatPrint(line)
end)
return Effects
