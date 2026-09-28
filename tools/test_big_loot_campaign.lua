-- Finite natural-offer sample: 32 real 20-level campaigns, two isolated owners,
-- all static nodes plus 48 enemy opportunities per owner/level. Native pickup
-- bodies are doubled; production graph, plans, category/conversion/generation,
-- receipt and item-validation authorities run unchanged. Bags are kept empty
-- to measure offered vocabulary; capacity behavior has its own focused gate.
local env=dofile('tools/big_loot_test_fixture.lua')(true)
local H,E,L,Run=env.H,LOD.Equipment,LOD.LootDirector,env.Run
local X=L.Ecology
local campaigns=tonumber(arg and arg[1]) or 32
assert(campaigns>=1 and campaigns<=32)
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function add(t,k,n) if k~=nil then t[k]=(t[k] or 0)+(n or 1) end end
local function hash(h,text)
    for i=1,#text do h=(h*131+text:byte(i))%2147483647 end
    return h
end
local function mechanical(item)
    if item.archetypeId then return item.archetypeId end
    local ids={}
    for _,r in ipairs(item.properties or {}) do ids[#ids+1]=r.id..(r.amount<0 and '-' or '+') end
    table.sort(ids)
    return item.definitionId..':'..table.concat(ids,',')
end
local function stats()
    return {items=0,catalog={},families={},slots={},rarities={},values={},levels={},
        consecutive=0,pairs=0,previous={},jaccard=0,jaccardPairs=0,previousLevel={},coverage={}}
end
local actual,control=stats(),stats()
local report={campaigns=campaigns,levels=0,static=0,rewards=0,enemyOpportunities=0,
    drops=0,noDrops=0,motifs={},phrases={},resources={},rewardKinds={},divergent=0,
    comparisons=0,supportNodes=0,supportPreserved=0,progressionChecks=0,hashes={},
    legacy={},consumables={},topology={deadEnd=0,vertical=0,distanceTotal=0,riskTotal=0},
    rewardEquipment={count=0,valueTotal=0,rarities={}}}
local recording=true
local ownerSets,ownerLevelSets,campaignHash={}, {},1
local function observe(s,item,owner,level)
    assert(E:ValidateWearable(item),'invalid naturally generated equipment')
    local a=item.archetypeId and E.Archetypes[item.archetypeId]
    assert(not item.archetypeId or a,'undefined naturally generated archetype')
    assert(not a or level>=a.minLevel,'archetype appeared before its introduction: '..tostring(item.archetypeId))
    local value=E:Value(item)
    assert(value==value and value>0 and value<=E:Budget(level,item.definitionId)*2,'invalid/out-of-bounds item value')
    if not recording then return end
    s.items=s.items+1;add(s.catalog,item.archetypeId);add(s.families,a and a.family or 'legacy')
    add(s.slots,E:Definition(item).slots[1]);add(s.rarities,item.rarity)
    s.values[#s.values+1]=value
    local key=mechanical(item)
    if s.previous[owner] then
        s.pairs=s.pairs+1;if s.previous[owner]==key then s.consecutive=s.consecutive+1 end
    end
    s.previous[owner]=key
    s.levels[owner]=s.levels[owner] or {};s.levels[owner][key]=true
    if s==actual then
        report.progressionChecks=report.progressionChecks+1
        ownerSets[owner]=ownerSets[owner] or {};ownerLevelSets[owner]=ownerLevelSets[owner] or {}
        if item.archetypeId then ownerSets[owner][item.archetypeId]=true;ownerLevelSets[owner][item.archetypeId]=true end
    end
end
local sourceControl={}
local generate=X.Generate
function X:Generate(owner,seed,level,base,key,context)
    local ctx=self:PlayerContext(Run:GetPlayerState(owner),context)
    local id
    if not (base and E.Definitions[base] and E.Definitions[base].moves) then
        id=self:Select(seed,level,base,self:NewMemory(),ctx)
    end
    sourceControl[key]=id and E:GenerateArchetype(seed,level,id,key) or E:Generate(seed,level,base,key)
    return generate(self,owner,seed,level,base,key,context)
end
local originalDecorate=X.DecoratePlan
function X:DecoratePlan(graph,plan)
    local retained={}
    for _,node in ipairs(plan.nodes) do
        if node.role~='reward' then retained[node.staticId]=H.serial(node) end
    end
    local result=originalDecorate(self,graph,plan)
    local kept=0
    for _,node in ipairs(plan.nodes) do
        if retained[node.staticId] then
            local prior=node.lootMotif;node.lootMotif=nil
            assert(H.serial(node)==retained[node.staticId],'ecology changed a mandatory sustain node')
            node.lootMotif=prior;kept=kept+1
        end
    end
    assert(kept==count(retained),'ecology removed a mandatory sustain node')
    if recording then report.supportNodes=report.supportNodes+count(retained);report.supportPreserved=report.supportPreserved+kept end
    return result
end
local entitySerial,lastEntity=0,nil
ents.Create=function(class)
    assert(class=='lod_loot_pickup');entitySerial=entitySerial+1
    local ent={valid=true,id=entitySerial,nw={}}
    function ent:EntIndex() return self.id end
    function ent:SetPos(pos) self.pos=pos end
    function ent:GetPos() return self.pos end
    function ent:SetAngles() end
    function ent:Spawn() end
    function ent:SetNW2String(k,v) self.nw[k]=v end
    ent.SetNW2Int=ent.SetNW2String
    function ent:SetPreventTransmit() end
    function ent:Remove() self.valid=false end
    lastEntity=ent
    return ent
end
util.IsValidModel=function() return true end
player.GetAll=function() return {} end
Run.IsDungeonPlayer=Run.IsActivePlayer
local function result(ent,owner,level,source,reward)
    assert(ent and ent.LODLootRegistered and ent.LODLootOwnerIdentity==owner,'native admission lost ownership')
    local kind,payload=ent.LODLootKind,ent.LODLootPayload
    campaignHash=hash(campaignHash,source..':'..kind..':'..H.serial(payload))
    if recording then
        add(report.resources,kind)
        if reward then add(report.rewardKinds,kind) end
    end
    if kind=='wearable' then
        observe(actual,payload.item,owner,level)
        observe(control,sourceControl[E:RewardKey(owner,source)] or payload.item,owner,level)
        if recording and not payload.item.archetypeId then add(report.legacy,payload.item.definitionId) end
        if recording and reward then
            local r=report.rewardEquipment;r.count=r.count+1;r.valueTotal=r.valueTotal+E:Value(payload.item)
            add(r.rarities,payload.item.rarity)
        end
    elseif kind=='consumable' then
        assert(E.Definitions[payload.itemId],'undefined consumable')
        if recording then add(report.consumables,payload.itemId) end
    end
    ent:Remove()
    L:_PruneEntities()
    return mechanical(payload.item or {definitionId=kind,properties={}})
end
local function finishLevel(s,owner)
    local current=s.levels[owner] or {};local prior=s.previousLevel[owner]
    if prior then
        local intersection,union=0,0
        for id in pairs(current) do union=union+1;if prior[id] then intersection=intersection+1 end end
        for id in pairs(prior) do if not current[id] then union=union+1 end end
        s.jaccard=s.jaccard+(union>0 and intersection/union or 0);s.jaccardPairs=s.jaccardPairs+1
    end
    s.previousLevel[owner]=current;s.levels[owner]={}
end
local function runCampaign(campaign)
    local seed=campaign*7919
    local campaignPhrases={}
    env:setRun({RunId='big-loot-sample:'..campaign,CampaignEpoch=1,CampaignSeed=seed,Level=1,PlayerState={}})
    local heroes={env:player('sample-a','fighter'),env:player('sample-b','wizard')}
    ownerSets,ownerLevelSets,sourceControl={},{},{}
    campaignHash=1
    for _,s in ipairs({actual,control}) do s.previous={};s.previousLevel={};s.levels={} end
    for _,hero in ipairs(heroes) do
        hero.hp=70;hero.position=Vector()
        function hero:GetPos() return self.position end
        hero:Give('weapon_pistol');hero:Give('weapon_lod_crowbar')
    end
    for level=1,20 do
        H.setParty(2)
        local graph=H.prepare(seed,level)
        Run.State=H.Run.State
        Run.State.GatesOpen={false,false,false,false}
        local gateState=H.serial(Run.State.GatesOpen)
        local encounters=H.build(graph);H.bounds(encounters)
        assert(#graph.Progression.Gates==4 and graph.Progression.Warden,'not production four-gate progression')
        local ok,plan=L:BuildStaticPlan(graph);assert(ok,plan)
        assert(H.serial(Run.State.GatesOpen)==gateState,'loot planning opened progression gates')
        assert(plan.ecology and #plan.ecology.motifs==4 and #plan.nodes<=80,'missing motifs or unbounded static plan')
        campaignHash=hash(campaignHash,H.serial(plan))
        if recording then report.levels=report.levels+1 end
        for _,motif in ipairs(plan.ecology.motifs) do
            campaignPhrases[motif.phrase]=true
            if recording then add(report.motifs,motif.id);add(report.phrases,motif.phrase) end
        end
        local occupied={}
        for _,encounter in ipairs(encounters.encounters) do occupied[encounter.cellKey]=true end
        local staticIds,rewardCells={},{}
        for _,node in ipairs(plan.nodes) do
            local key=LOD.MazeGenerator.CellKey(node.cell.x,node.cell.y,node.cell.z)
            local cell,tag=graph.Cells[key],graph.CellTags[key]
            assert(cell and tag and not staticIds[node.staticId],'invalid cell or duplicate static identity')
            staticIds[node.staticId]=true
            assert(node.lootMotif==plan.ecology.bySource[node.staticId].motif,'pickup lost its contextual motif')
            if node.role=='reward' then
                assert(not tag.objective and tag.role~='boss' and not occupied[key],'treasure occupied a protected objective or encounter')
                assert(not rewardCells[key],string.format('two treasure rewards share one placement cell: campaign=%d level=%d seed=%s source=%s cell=%s sector=%s candidates=%d',
                    campaign,level,tostring(Run.State.LevelSeed),node.staticId,key,tostring(node.sector),#L:_RewardCells(graph,node.sector)))
                rewardCells[key]=true
                if recording then
                    report.rewards=report.rewards+1
                    local c=plan.ecology.bySource[node.staticId];local t=report.topology
                    t.deadEnd=t.deadEnd+(c.deadEnd and 1 or 0);t.vertical=t.vertical+(c.vertical and 1 or 0)
                    t.distanceTotal=t.distanceTotal+c.distance;t.riskTotal=t.riskTotal+c.risk
                end
            end
            if recording then report.static=report.static+1 end
            for _,hero in ipairs(heroes) do
                local ent=assert(L:SpawnPickup(hero.id,LOD.MazeNavigator:CellCenter(cell)+node.offset,node.kind,node.payload,
                    {staticId=node.staticId,equipmentEligible=node.role=='reward'}))
                result(ent,hero.id,level,node.staticId,node.role=='reward')
            end
        end
        for _,hero in ipairs(heroes) do
            local lootState=L:_PlayerLootState(hero)
            for serial=1,48 do
                local encounter=encounters.encounters[(serial-1)%#encounters.encounters+1]
                local cell=graph.Cells[encounter.cellKey]
                local instance=LOD.Seeds.Derive(Run.State.LevelSeed,'sample-hostile:'..serial)
                local hostile={valid=true,LODInstanceSeed=instance,pos=LOD.MazeNavigator:CellCenter(cell)}
                function hostile:GetPos() return self.pos end
                function hostile:EntIndex() return self.LODInstanceSeed end
                hero.position=hostile.pos
                local rng=LOD.RNG.New(LOD.Seeds.Derive(Run.State.LevelSeed,'sample-drop:'..hero.id..':'..serial))
                local category=L:_DropCategory(hero,lootState,rng,false)
                local dropped=category and L:_SpawnEnemyResult(hero,hostile,category,rng)
                if recording then report.enemyOpportunities=report.enemyOpportunities+1 end
                if dropped then
                    lootState.dryKills=0
                    result(lastEntity,hero.id,level,instance,false)
                    if recording then report.drops=report.drops+1 end
                else
                    lootState.dryKills=(lootState.dryKills or 0)+1
                    if recording then report.noDrops=report.noDrops+1 end
                end
            end
            if recording then finishLevel(actual,hero.id);finishLevel(control,hero.id) end
            assert(#X:Memory(hero.id).recent<=X.historyLimit,'unbounded campaign memory')
        end
        if recording then
            report.comparisons=report.comparisons+1
            if H.serial(ownerLevelSets['sample-a'])~=H.serial(ownerLevelSets['sample-b']) then report.divergent=report.divergent+1 end
        end
        ownerLevelSets={}
        assert(H.D:CommitEcologyPlan(graph),'encounter history commit failed')
        L:CleanupLevel()
    end
    if recording then
        for _,hero in ipairs(heroes) do actual.coverage[#actual.coverage+1]=count(ownerSets[hero.id] or {}) end
        if campaigns==32 then assert(count(campaignPhrases)==3,'campaign had no lean/cache/scavenge rhythm: '..campaign) end
    end
    return campaignHash
end
for campaign=1,campaigns do
    local h=runCampaign(campaign)
    assert(not report.hashes[h],'different seeds reproduced the entire loot ecology')
    report.hashes[h]=true
    print(string.format('BIG_LOOT_CAMPAIGN campaign=%d hash=%d coverage=%d/%d',campaign,h,
        actual.coverage[#actual.coverage-1],actual.coverage[#actual.coverage]))
    if campaign==1 then
        recording=false;assert(runCampaign(campaign)==h,'same campaign/owners/state did not exactly replay');recording=true
    end
end
local function summary(s)
    table.sort(s.values)
    local min,total=math.huge,0
    for _,n in ipairs(s.coverage) do min=math.min(min,n);total=total+n end
    return {items=s.items,catalog=count(s.catalog),minCoverage=#s.coverage>0 and min or nil,meanCoverage=#s.coverage>0 and total/#s.coverage or nil,
        consecutiveRate=s.pairs>0 and s.consecutive/s.pairs or 0,
        consecutiveLevelJaccard=s.jaccardPairs>0 and s.jaccard/s.jaccardPairs or 0,
        valueP10=s.values[math.max(1,math.ceil(#s.values*.10))],valueP50=s.values[math.ceil(#s.values*.50)],
        valueP90=s.values[math.ceil(#s.values*.90)],valueMax=s.values[#s.values],
        families=s.families,slots=s.slots,rarities=s.rarities}
end
local full,flat=summary(actual),summary(control)
print('BIG_LOOT_SAMPLE '..H.serial(report))
print('BIG_LOOT_MEMORY '..H.serial(full))
print('BIG_LOOT_CONTROL '..H.serial(flat))
print('BIG_LOOT_EXPOSURE '..H.serial(actual.catalog))
if campaigns==32 then
    assert(full.catalog==#E.ArchetypeOrder,'expanded catalog did not appear through natural acquisition: '..full.catalog..'/'..#E.ArchetypeOrder)
    assert(full.minCoverage>=50 and full.meanCoverage>=65,'campaign exposure below the finite diversity floor')
    assert(count(report.motifs)==#X.Motifs and count(report.phrases)==3,'unreachable motif or economic phrase')
    assert(report.divergent/report.comparisons>.90,'individualized offers did not materially diverge')
    assert(full.consecutiveRate<flat.consecutiveRate*.75,'history did not reduce immediate mechanical repeats by 25%')
    assert(full.consecutiveLevelJaccard<flat.consecutiveLevelJaccard,'history did not reduce adjacent-level overlap')
    for family,n in pairs(actual.families) do assert(n/actual.items<.35,'one family dominated campaigns: '..family) end
    assert((actual.rarities[4] or 0)>0 and (actual.rarities[4] or 0)/actual.items<.05,'broken highest-rarity band')
    assert(report.supportNodes==report.supportPreserved,'support was lost during topology annotation')
    assert(report.topology.deadEnd>0 and report.topology.vertical>0,'natural treasure never used detour/vertical topology')
    assert(report.noDrops/report.enemyOpportunities>.15 and report.noDrops/report.enemyOpportunities<.40,'unbounded loot rain/scarcity')
end
print('BIG_LOOT_CAMPAIGN_PASS: actual graph and four-gate progression; final loot/conversion/generation; exact whole-campaign replay; seed/owner divergence; protected topology; unchanged support; quantitative catalog/repetition/rarity/value exposure')
