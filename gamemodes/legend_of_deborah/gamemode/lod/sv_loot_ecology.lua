-- Campaign memory belongs to the existing player state. Selection is pure;
-- only the reward admission seam records a new decision. Nothing ticks here.
local E, Loot, Run = assert(LOD.Equipment), assert(LOD.LootDirector), assert(LOD.RunManager)
local Ecology = {version=1, historyLimit=24, receiptLimit=512}
Loot.Ecology = Ecology
local motifs = {"scavenged","military","medical","occult","elemental","industrial","mobility","defensive","unstable","expedition"}
Ecology.Motifs = motifs
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function contains(list,value)
    for _,v in ipairs(list or {}) do if v==value then return true end end
    return false
end
local function sortedKeys(t)
    local keys={};for k in pairs(t or {}) do keys[#keys+1]=k end;table.sort(keys);return keys
end
local function keyOf(cell)
    return cell and LOD.MazeGenerator.CellKey(cell.x,cell.y,cell.z)
end
local function pick(rng,rows)
    local total=0;for _,r in ipairs(rows) do total=total+r.weight end
    if total<=0 then return nil end
    local roll=rng:Float(0,total)
    for _,r in ipairs(rows) do roll=roll-r.weight;if roll<=0 then return r.value end end
    return rows[#rows].value
end
function Ecology:NewMemory()
    return {recent={},counts={},families={},serial=0,receipts={},receiptCount=0,
        stats={items=0,replays=0,suppressed=0,novel=0,rare=0,value=0,slots={},families={},rarities={}}}
end
function Ecology:Memory(owner)
    local ps=Run:GetPlayerState(owner)
    if not ps then return nil end
    local run=Run.State
    local m=ps.lootEcology
    if not m or m.runId~=run.RunId or m.epoch~=run.CampaignEpoch then
        m=self:NewMemory();m.runId=run.RunId;m.epoch=run.CampaignEpoch;ps.lootEcology=m
    end
    if m.levelSeed~=run.LevelSeed then
        -- Catalog exposure survives level succession, source receipts do not.
        -- Rebuilding/reconnecting at the same seed cannot clear this ledger.
        m.levelSeed=run.LevelSeed;m.receipts={};m.receiptCount=0
    end
    return m,ps
end
function Ecology:MotifPlan(campaignSeed,level)
    -- Independent ten-sector bags make history reproducible even when a level
    -- is rebuilt out of order. The last three entries are never reordered, so
    -- the next bag can suppress the real preceding motifs in constant work.
    local function rawBag(block)
        local out={};for i,id in ipairs(motifs) do out[i]=id end
        LOD.RNG.New(LOD.Seeds.Derive(campaignSeed,"loot-motif-bag:"..block)):Shuffle(out)
        return out
    end
    local bags,selected={},{}
    for sector=1,4 do
        local serial=(level-1)*4+sector-1
        local block,index=math.floor(serial/#motifs),serial%#motifs+1
        if not bags[block] then
            local bag=rawBag(block)
            if block>0 then
                local previous=rawBag(block-1);local recent={previous[8],previous[9],previous[10]}
                local reordered={}
                for i=1,7 do if not contains(recent,bag[i]) then reordered[#reordered+1]=bag[i] end end
                for i=1,7 do if contains(recent,bag[i]) then reordered[#reordered+1]=bag[i] end end
                for i=8,10 do reordered[#reordered+1]=bag[i] end
                bag=reordered
            end
            bags[block]=bag
        end
        -- Hash a domain suffix after the serial: adjacent numeric labels alone
        -- have correlated first draws in the shared Park–Miller generator.
        local rng=LOD.RNG.New(LOD.Seeds.Derive(campaignSeed,"loot-phrase:"..serial..":pacing-v1"))
        local roll=rng:Int(1,10)
        selected[sector]={id=bags[block][index],phrase=roll<=2 and "lean" or (roll>=9 and "cache" or "scavenge")}
    end
    return selected
end
function Ecology:Candidates(base,level)
    local out={}
    for _,id in ipairs(E.ArchetypeOrder or {}) do
        local a=E.Archetypes[id];local def=E.Definitions[a.base]
        if level>=(a.minLevel or 1) and ((base and a.base==base) or (not base and def.wearable)) then
            out[#out+1]=a
        end
    end
    return out
end
function Ecology:Select(seed,level,base,memory,context)
    context=context or {};memory=memory or self:NewMemory()
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,"loot-ecology-selection-v1"))
    local rows={};local suppressed=0
    for _,a in ipairs(self:Candidates(base,level)) do
        local rarity=a.minimumRarity or 1
        -- Authored weights already include scarcity; do not penalize rarity twice.
        local w=(a.weight or 80)/80
        local seen=memory.counts[a.id] or 0
        w=w*(seen==0 and 2 or 1/math.sqrt(1+seen*.25))
        if contains(a.motifs,context.motif) or a.family==context.motif then w=w*2.8 end
        if context.vertical and contains(a.tags,"mobility") then w=w*1.7 end
        if context.reward and rarity>=2 then w=w*1.5 end
        if context.phrase=="cache" and rarity>=2 then w=w*1.6 end
        if (context.risk or 0)>=2 and rarity>=2 then w=w*1.35 end
        if context.preBoss and (contains(a.tags,"defensive") or contains(a.tags,"medical")) then w=w*1.5 end
        if context.owned and context.owned[a.id] then w=w*.25 end
        if context.emptySlots and context.emptySlots[a.slot] then w=w*1.3 end
        if context.classId=="wizard" and (contains(a.tags,"occult") or contains(a.signature,"magic"))
            or context.classId=="rogue" and contains(a.tags,"mobility")
            or context.classId=="fighter" and (contains(a.tags,"military") or contains(a.signature,"physical")) then w=w*1.2 end
        if context.lowHealth and contains(a.tags,"medical") then w=w*1.35 end
        if context.lowMagic and contains(a.signature,"magic_regen") then w=w*1.25 end
        local last=memory.families[a.family]
        if last and level-last>=3 then w=w*1.5 end
        local repeated=false
        for i=math.max(1,#memory.recent-7),#memory.recent do
            local r=memory.recent[i]
            if r.id==a.id then w=w*.06;repeated=true end
            if i>#memory.recent-4 then
                if r.family==a.family then w=w*.60;repeated=true end
                if r.slot==a.slot then w=w*.72 end
                local overlap=0
                for _,effect in ipairs(a.signature or {}) do if contains(r.effects,effect) then overlap=overlap+1 end end
                w=w*(.82^overlap)
            end
        end
        if repeated then suppressed=suppressed+1 end
        rows[#rows+1]={value=a.id,weight=math.max(.000001,w)}
    end
    -- The old unconstrained vocabulary remains available; it is not relabeled
    -- and counted again. Innate named gear retains its own upstream 1/8 roll.
    if #rows==0 or rng:Chance(.08) then return nil,{suppressed=suppressed,legacy=true} end
    local id=pick(rng,rows)
    return id,{suppressed=suppressed,novel=(memory.counts[id] or 0)==0}
end
function Ecology:Record(memory,item,level,decision,context)
    local a=item.archetypeId and E.Archetypes[item.archetypeId]
    local id=item.archetypeId or item.definitionId
    local def=E:Definition(item)
    local family=a and a.family or "legacy"
    local slot=a and a.slot or def.slots[1]
    memory.serial=memory.serial+1;memory.counts[id]=math.min(65535,(memory.counts[id] or 0)+1)
    memory.families[family]=level
    memory.recent[#memory.recent+1]={id=id,family=family,slot=slot,effects=a and a.signature or {}}
    if #memory.recent>self.historyLimit then table.remove(memory.recent,1) end
    local s=memory.stats;s.items=s.items+1;s.value=s.value+E:Value(item)
    s.suppressed=s.suppressed+(decision.suppressed or 0);s.novel=s.novel+(decision.novel and 1 or 0)
    s.rare=s.rare+(item.rarity>=3 and 1 or 0)
    s.slots[slot]=(s.slots[slot] or 0)+1;s.families[family]=(s.families[family] or 0)+1
    s.rarities[item.rarity]=(s.rarities[item.rarity] or 0)+1
    s.last={id=id,motif=context.motif,role=context.role,seed=item.seed,level=level,value=E:Value(item)}
end
function Ecology:PlayerContext(ps,context)
    local out=table.Copy(context or {});out.owned={};out.emptySlots={}
    local state=ps and ps.equipment
    for _,item in pairs(state and state.items or {}) do if item.archetypeId then out.owned[item.archetypeId]=true end end
    for _,slot in ipairs(E.SlotOrder) do if not state or not state.slots[slot] then out.emptySlots[slot]=true end end
    out.classId=ps and ps.progressionState and ps.progressionState.classId
    out.lowMagic=ps and (ps.magic or 100)<25
    out.lowHealth=false
    -- Inventory snapshots store weapons/ammo, not current HP. This bounded
    -- admission-time lookup samples the native Hero, never a stale save field.
    for _,ply in ipairs(player and player.GetAll and player.GetAll() or {}) do
        if IsValid(ply) and ps and Run:IdentityOf(ply)==ps.identity then
            out.lowHealth=ply:Health()<ply:GetMaxHealth()*.5;break
        end
    end
    return out
end
function Ecology:Generate(owner,seed,level,base,key,context)
    local memory,ps=self:Memory(owner)
    local receipt=memory and memory.receipts[key]
    if receipt then
        memory.stats.replays=memory.stats.replays+1
        if receipt.archetype then return E:GenerateArchetype(seed,receipt.level,receipt.archetype,key) end
        return E:Generate(seed,receipt.level,receipt.base,key)
    end
    local room=memory and memory.receiptCount<self.receiptLimit
    -- Once the bounded receipt ledger fills, use seed-only decisions without
    -- player/history inputs. Do not evict an older reward and let it reroll.
    local ctx=room and self:PlayerContext(ps,context) or {}
    local id,decision
    if base and E.Definitions[base] and E.Definitions[base].moves then decision={} else
        id,decision=self:Select(seed,level,base,room and memory or nil,ctx)
    end
    local item=id and E:GenerateArchetype(seed,level,id,key) or E:Generate(seed,level,base,key)
    if item and room then
        memory.receipts[key]={archetype=id,base=base,level=level}
        memory.receiptCount=memory.receiptCount+1
        self:Record(memory,item,level,decision,ctx)
    end
    return item
end
function Ecology:DecoratePlan(graph,plan)
    local selected=self:MotifPlan(Run.State.CampaignSeed or plan.levelSeed,plan.level)
    local distances,queue={},{}
    local start=keyOf(graph.Start)
    if start and graph.Cells[start] then distances[start]=0;queue[1]=start end
    local head=1
    while queue[head] do
        local key=queue[head];head=head+1
        for _,nextKey in ipairs(sortedKeys(graph.Cells[key].neighbors)) do
            if graph.Cells[nextKey] and distances[nextKey]==nil then distances[nextKey]=distances[key]+1;queue[#queue+1]=nextKey end
        end
    end
    local byCell={}
    for _,key in ipairs(sortedKeys(graph.Cells)) do
        local cell=graph.Cells[key];local tag=graph.CellTags and graph.CellTags[key] or {}
        local degree,vertical,nearBoss=0,false,false
        for nk in pairs(cell.neighbors or {}) do
            degree=degree+1;local other=graph.Cells[nk]
            if other and other.z~=cell.z then vertical=true end
            local neighborTag=graph.CellTags and graph.CellTags[nk]
            if neighborTag and neighborTag.role=="boss" then nearBoss=true end
        end
        local sector=clamp(tonumber(tag.sector) or 1,1,4)
        byCell[key]={sector=sector,motif=selected[sector].id,phrase=selected[sector].phrase,
            vertical=vertical or cell.z~=graph.Start.z,deadEnd=degree==1,distance=distances[key] or 0,
            risk=(plan.sectorThreat and plan.sectorThreat[sector] or 0)/5,
            preBoss=nearBoss or tag.role=="boss" or tag.role=="pre-core",role=tag.role}
    end
    local occupied={};for _,node in ipairs(plan.nodes) do if node.role~="reward" then occupied[keyOf(node.cell)]=true end end
    plan.ecology={version=self.version,motifs=selected,byCell=byCell,bySource={},rewardNodes=0,omittedRewardNodes=0}
    local kept={}
    for _,node in ipairs(plan.nodes) do
        local keep=true
        if node.role=="reward" then
            local function rowsFor(candidates)
                local rows={}
                for _,cell in ipairs(candidates) do
                    local key=keyOf(cell);local c=byCell[key]
                    if not occupied[key] and c then rows[#rows+1]={value=cell,
                        weight=1+(c.deadEnd and 2 or 0)+(c.vertical and 1 or 0)+math.min(3,c.distance/20)+math.min(2,c.risk)} end
                end
                return rows
            end
            local rows=rowsFor(Loot:_RewardCells(graph,node.sector))
            if #rows==0 then rows=rowsFor(Loot:_SectorCandidates(graph,node.sector)) end
            local rng=LOD.RNG.New(LOD.Seeds.Derive(plan.levelSeed,"loot-placement:"..node.staticId))
            local cell=pick(rng,rows)
            if cell then
                node.cell={x=cell.x,y=cell.y,z=cell.z}
                occupied[keyOf(node.cell)]=true;plan.ecology.rewardNodes=plan.ecology.rewardNodes+1
            else
                -- Never pile treasure onto another source when a constrained
                -- sector has no legal space. Required supplies are untouched.
                keep=false;plan.ecology.omittedRewardNodes=plan.ecology.omittedRewardNodes+1
            end
        end
        if keep then
            kept[#kept+1]=node
            local context=table.Copy(byCell[keyOf(node.cell)] or {})
            context.reward=node.role=="reward";context.role=node.role
            if node.role=="pre-core" then context.preBoss=true end
            plan.ecology.bySource[node.staticId]=context
            node.lootMotif=context.motif
        end
    end
    plan.nodes=kept
    return plan
end
function Ecology:ContextForPosition(pos,options)
    local plan=Loot.StaticPlan;local ecology=plan and plan.ecology
    if not ecology then return {} end
    if options.staticId and ecology.bySource[options.staticId] then return ecology.bySource[options.staticId] end
    local graph=Run.State.Graph
    local cell=graph and LOD.MazeNavigator:WorldToCell(graph,pos)
    local context=table.Copy(cell and ecology.byCell[keyOf(cell)] or {})
    context.role=options.lootRole or "enemy"
    context.risk=math.max(context.risk or 0,options.lootRisk or 0)
    context.reward=options.lootRole=="treasure"
    return context
end
local build=Loot.BuildStaticPlan
function Loot:BuildStaticPlan(graph)
    local ok,plan=build(self,graph)
    if ok then Ecology:DecoratePlan(graph,plan) end
    return ok,plan
end
function Loot:_AllowedWeaponClasses(level)
    -- This final authority must include upgraded starter families after the
    -- older firearm-only tuning wrappers. Wands keep their separate 1/8 roll.
    level=level or Run.State.Level or 1
    local allowed={}
    for _,class in ipairs(E.WeaponFamilies) do
        local minimum=class=="weapon_357" and 2 or class=="weapon_ar2" and 3 or 1
        if class~="weapon_lod_wand" and level>=minimum then allowed[#allowed+1]=class end
    end
    return allowed
end
function Loot:_MissingWeaponReward(ply,rng)
    local allowed=self:_AllowedWeaponClasses(Run.State.Level)
    if rng:Chance(E.WeaponLoot.variantChance) then return rng:Pick(allowed) end
    local missing={}
    for _,class in ipairs(allowed) do
        if not IsValid(ply:GetWeapon(class)) then missing[#missing+1]=class end
    end
    return rng:Pick(#missing>0 and missing or allowed)
end
local dropCategory=Loot._DropCategory
function Loot:_DropCategory(ply,state,rng,guaranteed)
    local category,pity=dropCategory(self,ply,state,rng,guaranteed)
    if category~="wearable" and category~="weapon" then return category,pity end
    local ps=Run:GetPlayerState(ply);local bag=ps and ps.equipment
    local free=E:StorageCapacity(bag)-E:StoredEquipmentCount(bag)
    local context=Ecology:ContextForPosition(ply:GetPos(),{})
    local retain=context.phrase=="lean" and .55 or 1
    if free<=4 then retain=retain*.5 end
    if free<=0 or not rng:Chance(retain) then
        -- Resource recovery is separate from catalog novelty; no currency mint,
        -- new entity, bonus drop, or capacity bypass is introduced.
        if ply:Health()<ply:GetMaxHealth() then return "health",pity end
        if self:_AmmoNeed(ply)>0 then return "ammo",pity end
        return nil,false
    end
    return category,pity
end
function E:GenerateFusionCandidate(seed,depth,context)
    -- Deliberately level-independent identity choice throughout binary search.
    local candidates=Ecology:Candidates(nil,999)
    local id=LOD.RNG.New(LOD.Seeds.Derive(seed,"loot-fusion-archetype")):Pick(candidates)
    if id then return self:GenerateArchetype(seed,depth,id.id,context) end
    return self:Generate(seed,depth,nil,context)
end
function E:GenerateContextItem(seed,level,base,key)
    -- Account rewards and explicit slot gifts freeze their result in their
    -- existing ledgers. They use a source-only stream, never mutable loot history.
    if base and self.Definitions[base] and self.Definitions[base].moves then return self:Generate(seed,level,base,key) end
    local id=Ecology:Select(seed,level,base,nil,{reward=true})
    if id then return self:GenerateArchetype(seed,level,id,key) end
    return self:Generate(seed,level,base,key)
end
concommand.Add("lod_loot_ecology_status",function(ply)
    local cv=GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or IsValid(ply) and not ply:IsAdmin() then return end
    local plan=Loot.StaticPlan;local out={version=Ecology.version,catalog=E.BigLootBaseline+#(E.ArchetypeOrder or {}),
        level=Run.State.Level,motifs=plan and plan.ecology and plan.ecology.motifs,
        staticNodes=plan and #plan.nodes or 0,rewardNodes=plan and plan.ecology and plan.ecology.rewardNodes,
        omittedRewardNodes=plan and plan.ecology and plan.ecology.omittedRewardNodes,
        support={pity=Loot.Stats.pityDrops,collected=Loot.Stats.collected,enemyDrops=Loot.Stats.enemyDrops},players={}}
    for _,id in ipairs(sortedKeys(Run.State.PlayerState)) do
        local m=Run.State.PlayerState[id].lootEcology
        if m then out.players[id]={receipts=m.receiptCount,history=#m.recent,stats=m.stats} end
    end
    print("[LOD:LOOT-ECOLOGY] "..util.TableToJSON(out))
end)
concommand.Add("lod_big_loot_testkit",function(ply,_,args)
    local cv=GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or not IsValid(ply) or not ply:IsAdmin() or not E:CanAct(ply) then return end
    local id=args and args[1] or "measured_retreat"
    if not E.Archetypes[id] then E:Report(ply,"Unknown equipment archetype.","loot_testkit");return end
    local state=E:Ensure(Run:GetPlayerState(ply))
    if E:StoredEquipmentCount(state)>=E:StorageCapacity(state) then
        E:Report(ply,"Make room in Equipment first.","loot_testkit");return
    end
    state.serial=(state.serial or 0)+1
    local key=E:RewardKey(Run:IdentityOf(ply),"big-loot-test:"..state.serial)
    local item=E:GenerateArchetype(LOD.Seeds.Derive(Run.State.CampaignSeed,key),Run.State.Level,id,key)
    item.economyExcluded=true
    Run:MarkUnranked("Big Loot testkit")
    E:AcquireWorldItem(ply,item,false,"pickup")
end)
