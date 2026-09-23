-- Dungeon-owned event lifecycle; RunManager owns the campaign and graph.
LOD = LOD or {}
LOD.EventDirector = LOD.EventDirector or {Serial = 0}
local D, Registry = LOD.EventDirector, LOD.EventRegistry
local Run, Builder = LOD.RunManager, LOD.MazeBuilder
local cvEnabled = CreateConVar("lod_events_enabled", "1", FCVAR_ARCHIVE,
    "Enable approved full 1d4 dungeon events; existing explicit off settings are respected.")
D.MaxPlacementAttempts = 64
util.AddNetworkString("LOD_DungeonEvents")

local function key(c)
    return c and LOD.MazeGenerator.CellKey(c.x, c.y, c.z)
end
local function edge(a, b) return a < b and a .. "|" .. b or b .. "|" .. a end
local function sorted(t)
    local out = {}; for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out); return out
end
local function copy(t)
    local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
end
local function sameData(a, b, seen)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    seen = seen or {}
    seen[a] = seen[a] or {}
    if seen[a][b] then return true end
    seen[a][b] = true
    for k, v in pairs(a) do if not sameData(v, b[k], seen) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

-- Authored placement callbacks are queries, never graph-editing authorities.
-- Isolate their inputs and reject altered proofs instead of validating topology
-- that differs from the actual maze already built by the production builder.
function D:GraphCallback(def, name, g, argument, reach)
    local isolated, arg, reached = table.Copy(g), table.Copy(argument), reach and table.Copy(reach)
    local ok, result
    if name == "Place" then ok, result = pcall(def[name], def, self, isolated, arg, reached)
    else ok, result = pcall(def[name], def, isolated, arg, reached) end
    if not ok then return false, nil, "event callback failed: " .. name end
    if not sameData(g, isolated) or not sameData(argument, arg) or not sameData(reach, reached) then
        return false, nil, "event callback mutated placement proof: " .. name
    end
    return true, result
end
local function walk(g, start, blockedEdges, blockedCells)
    local seen, queue = {}, {}
    if g.Cells[start] and not (blockedCells and blockedCells[start]) then seen[start] = true; queue[1] = start end
    local i = 1
    while queue[i] do
        local current = queue[i]; i = i + 1
        for _, n in ipairs(sorted(g.Cells[current].neighbors)) do
            if g.Cells[n] and not seen[n] and not (blockedEdges and blockedEdges[edge(current, n)])
                and not (blockedCells and blockedCells[n]) then
                seen[n] = true; queue[#queue + 1] = n
            end
        end
    end
    return seen
end

function D:ProtectedCells(g)
    local out, p = {}, g.Progression
    local function add(c) if c then out[key(c)] = true end end
    add(g.Start); add(g.Goal); add(p.CoreCell); add(p.DeborahCell)
    for _, gate in ipairs(p.Gates or {}) do add(gate.beforeCell); add(gate.afterCell) end
    if p.JailEdge then add(p.JailEdge.beforeCell); add(p.JailEdge.afterCell) end
    for _, card in ipairs(p.Keycards or {}) do add(card.cell) end
    for _, v in ipairs(g.VerticalEdges or {}) do add(v.a); add(v.b) end
    for k, tag in pairs(g.CellTags or {}) do
        if tag.safe or tag.objective or tag.role == "resupply" or tag.role == "boss" then out[k] = true end
    end
    for k in pairs(p.Warden and p.Warden.cells or {}) do out[k] = true end
    if p.Hunt then add(p.Hunt.neilCell); add(p.Hunt.bruteCell) end
    for _, encounter in ipairs(g.EncounterPlan and g.EncounterPlan.encounters or {}) do
        out[encounter.cellKey or key(encounter.cell)] = true
    end
    return out
end

-- Replay the actual ordered progression graph under proposed obstructions.
-- Paired shortcuts separately prove equivalent progression reachability at every
-- lock stage; no callback may alter the canonical navigation graph.
function D:ValidateRoutes(g, extraEdges, extraCells)
    local p = g.Progression
    if not p or not p.JailEdge or not p.CoreCell or not p.DeborahCell then return false, "missing progression" end
    local blocked = copy(extraEdges)
    for _, gate in ipairs(p.Gates or {}) do blocked[gate.edgeKey] = true end
    blocked[p.JailEdge.edgeKey] = true
    for i, gate in ipairs(p.Gates or {}) do
        local reach = walk(g, key(g.Start), blocked, extraCells)
        local objective = p.Keycards and p.Keycards[i] and p.Keycards[i].cell
            or (i == 4 and p.Hunt and p.Hunt.neilCell)
        if objective and not reach[key(objective)] then return false, "unreachable gate objective " .. i end
        if not reach[key(gate.beforeCell)] or reach[key(gate.afterCell)] then return false, "gate route invalid " .. i end
        blocked[gate.edgeKey] = extraEdges and extraEdges[gate.edgeKey] or nil
    end
    local reach = walk(g, key(g.Start), blocked, extraCells)
    if not reach[key(p.CoreCell)] or reach[key(p.DeborahCell)] then return false, "invalid core/jail sequence" end
    blocked[p.JailEdge.edgeKey] = extraEdges and extraEdges[p.JailEdge.edgeKey] or nil
    if not walk(g, key(g.Start), blocked, extraCells)[key(p.DeborahCell)] then return false, "unreachable rescue" end
    return true
end

-- Both physical shortcut endpoints must already belong to the same reachable
-- component at EVERY ordered lock stage, including jail and Warden lockdown.
-- The ordinary two-way route remains authoritative; shortcuts add no graph edge.
function D:ValidateEndpointPair(g, placement, reserved, environment)
    local source, destination = g.Cells[placement.cellKey], g.Cells[placement.destinationCellKey]
    if not source or not destination or source == destination then return false, "missing distinct endpoints" end
    local protected = self:ProtectedCells(g)
    for _, k in ipairs({placement.cellKey, placement.destinationCellKey}) do
        if protected[k] or (reserved and reserved[k]) then return false, "shortcut endpoint reserved" end
        for _, cell in ipairs(g.CriticalPath or {}) do
            if key(cell) == k then return false, "shortcut endpoint must be optional" end
        end
    end
    local p, blocked = g.Progression, copy(environment and environment.edges)
    local cells = environment and environment.cells
    for _, gate in ipairs(p.Gates or {}) do blocked[gate.edgeKey] = true end
    blocked[p.JailEdge.edgeKey] = true
    if p.Warden and p.Warden.lock then blocked[p.Warden.lock.edgeKey] = true end
    local reached = false
    for stage = 0, #p.Gates + 1 do
        local reach = walk(g, key(g.Start), blocked, cells)
        if not not reach[placement.cellKey] ~= not not reach[placement.destinationCellKey] then
            return false, "shortcut crosses progression stage"
        end
        if reach[placement.cellKey] then
            reached = true
            if not walk(g, placement.destinationCellKey, blocked, cells)[placement.cellKey]
                or not walk(g, placement.cellKey, blocked, cells)[placement.destinationCellKey] then
                return false, "shortcut has no ordinary return route"
            end
        end
        local gate = p.Gates[stage + 1]
        local ek = gate and gate.edgeKey or p.JailEdge.edgeKey
        blocked[ek] = environment and environment.edges and environment.edges[ek] or nil
    end
    return reached, reached and nil or "shortcut endpoints unreachable"
end

function D:ValidateDrop(g, placement, reserved, environment)
    local source, destination = g.Cells[placement.cellKey], g.Cells[placement.destinationCellKey]
    if not source or not destination or source.x ~= destination.x or source.y ~= destination.y
        or source.z ~= destination.z + 1 then return false, "drop must reach the floor immediately below" end
    return self:ValidateEndpointPair(g, placement, reserved, environment)
end

-- Earliest legitimately reachable blockade approach. Never unlock a gate in
-- the proof when its key/encounter or reader is trapped behind this toll.
function D:BlockadeApproach(g, placement, environment)
    local e=g.Edges[placement.edgeKey]
    if not e then return nil end
    local p,blocked=g.Progression,copy(environment and environment.edges)
    blocked[placement.edgeKey]=true
    blocked[p.JailEdge.edgeKey]=true
    if p.Warden and p.Warden.lock then blocked[p.Warden.lock.edgeKey]=true end
    for _,gate in ipairs(p.Gates) do blocked[gate.edgeKey]=true end
    for stage=0,#p.Gates do
        local reach=walk(g,key(g.Start),blocked,environment and environment.cells)
        if reach[key(e.a)] or reach[key(e.b)] then return reach end
        local gate=p.Gates[stage+1]
        if gate then
            local objective=p.Keycards and p.Keycards[stage+1] and p.Keycards[stage+1].cell
                or (stage+1==4 and p.Hunt and p.Hunt.neilCell)
            if not reach[key(gate.beforeCell)] or (objective and not reach[key(objective)]) then return nil end
            blocked[gate.edgeKey]=environment and environment.edges[gate.edgeKey] or nil
        end
    end
end

function D:ValidatePlacement(g, def, placement, reserved, environment)
    if not g or not g.Cells or not g.Progression or type(placement) ~= "table" then return false, "missing placement graph" end
    local k = placement.cellKey or key(placement.cell)
    if not k or not g.Cells[k] then return false, "missing event cell" end
    local protected = self:ProtectedCells(g)
    if protected[k] or (reserved and reserved[k]) then return false, "reserved event cell" end
    if placement.addedEdges or placement.destination or placement.destinationCell
        or (placement.destinationCellKey and not ((def.contract == "HAZARD" and def.dropFloor == true)
            or (def.contract == "UTILITY" and def.pairedWarp == true))) then
        return false, "shortcut contract not implemented"
    end
    local valid, err = self:ValidateRoutes(g)
    if not valid then return false, err end
    if def.contract == "UTILITY" or def.contract == "REWARD" then
        if def.nonblocking ~= true or next(placement.blockedCells or {}) or next(placement.blockedEdges or {}) then
            return false, "optional event must be nonblocking"
        end
        if def.pairedWarp then
            valid, err = self:ValidateEndpointPair(g, placement, reserved, environment)
            if not valid then return false, err end
        end
        if def.contract == "REWARD" then
            for _, c in ipairs(g.CriticalPath or {}) do if key(c) == k then return false, "reward must be optional" end end
        end
    elseif def.contract == "HAZARD" then
        if def.reversible ~= true then return false, "hazard requires reversible contract" end
        if def.dropFloor then
            valid, err = self:ValidateDrop(g, placement, reserved, environment)
            if not valid then return false, err end
        end
        for c in pairs(placement.blockedCells or {}) do
            if not g.Cells[c] or protected[c] or (reserved and reserved[c]) then return false, "hazard affects protected cell" end
        end
        for e in pairs(placement.blockedEdges or {}) do if not g.Edges[e] then return false, "hazard has missing edge" end end
        valid, err = self:ValidateRoutes(g, placement.blockedEdges, placement.blockedCells)
        if not valid then return false, err end
    elseif def.contract == "BLOCKADE" then
        local e = placement.edgeKey and g.Edges[placement.edgeKey]
        if not e or def.reversible ~= true or type(def.CanResolve) ~= "function" then return false, "blockade requires reversible resolution proof" end
        if protected[key(e.a)] or protected[key(e.b)] then return false, "blockade overlaps protected route" end
        if reserved and (reserved[key(e.a)] or reserved[key(e.b)] or reserved[placement.edgeKey]) then return false, "blockade overlaps another event" end
        if k ~= key(e.a) and k ~= key(e.b) then return false, "blockade must occupy its edge endpoint" end
        local blocked = {[placement.edgeKey] = true}
        local reach = walk(g, key(g.Start), blocked)
        if reach[key(g.Progression.DeborahCell)] then return false, "blockade is not on required route" end
        if not reach[key(e.a)] and not reach[key(e.b)] then return false, "blockade cannot be approached" end
        if placement.blockedCells or placement.blockedEdges then return false, "blockade supports one canonical edge" end
        local approach=self:BlockadeApproach(g,placement,environment)
        if placement.cacheCellKey then
            if not g.Cells[placement.cacheCellKey] or protected[placement.cacheCellKey]
                or (reserved and reserved[placement.cacheCellKey])
                or placement.cacheCellKey==key(e.a) or placement.cacheCellKey==key(e.b) then
                return false, "blockade payment cache reserved"
            end
        end
        if not approach then return false, "blockade cannot be resolved" end
        local called, resolvable, callbackErr = self:GraphCallback(def, "CanResolve", g, placement, approach)
        if not called then return false, callbackErr, true end
        if resolvable ~= true then return false, "blockade cannot be resolved" end
    else return false, "unknown contract" end
    if def.Validate then
        local called, accepted, callbackErr = self:GraphCallback(def, "Validate", g, placement)
        if not called then return false, callbackErr, true end
        if accepted ~= true then return false, "definition rejected placement" end
    end
    return true
end

function D:Plan(g, options)
    options = options or {}
    local seed = g.MasterLevelSeed or g.LevelSeed or 1
    local plan = {seed = seed, mode = "disabled", selectedCount = 0, instances = {}}
    if not options.enabled and not options.preview then return true, plan end
    if not options.preview and Registry.PopulationReady ~= true then
        return false, "production event population gated: catalog activation and rarity tuning pending"
    end
    if LOD.GraphIntegrity and not LOD.GraphIntegrity:Audit(g).valid then return false, "invalid maze graph integrity" end
    local selected, count
    if options.preview then
        if not Registry.Definitions[options.preview] then return false, "unknown event preview" end
        selected, count, plan.mode = {options.preview}, 1, "preview"
    else
        selected, count = Registry:Select(seed, g.DungeonLevel or Run.State.Level or 1)
        if not selected then return false, count end
        plan.mode = "full"
    end
    plan.selectedCount = count
    local reserved, hazardEdges, hazardCells = {}, {}, {}
    for ordinal, id in ipairs(selected) do
        local def = Registry.Definitions[id]
        local eventSeed = LOD.Seeds.Derive(seed, "dungeon-events:archetype:" .. id .. ":v1")
        -- A selected archetype remains one event. Its finite REWARD members each
        -- require a full placement proof; a rejected child rejects the whole plan.
        local multiple = def.maxInstances == 2
        local memberCount = multiple and LOD.RNG.New(LOD.Seeds.Derive(eventSeed, "instance-count:v1")):Int(1, 2) or 1
        for memberIndex = 1, memberCount do
            local memberSeed = multiple and LOD.Seeds.Derive(eventSeed, "instance:" .. memberIndex .. ":v1") or eventSeed
            local candidates = sorted(g.Cells)
            if def.contract=="BLOCKADE" then
                -- A required-route obstruction can only cut the canonical
                -- start-to-rescue path. Spend the finite budget on those cells.
                local critical={}
                for _,c in ipairs(g.CriticalPath or {}) do critical[key(c)]=true end
                candidates=sorted(critical)
            end
            local placeEnvironment={edges=copy(hazardEdges),cells=copy(hazardCells),reserved=copy(reserved)}
            for _,prior in ipairs(plan.instances) do
                if prior.contract=="BLOCKADE" then placeEnvironment.edges[prior.placement.edgeKey]=true end
            end
            LOD.RNG.New(LOD.Seeds.Derive(memberSeed, "placement")):Shuffle(candidates)
            local accepted, lastErr
            for i = 1, math.min(#candidates, self.MaxPlacementAttempts) do
                local cell = g.Cells[candidates[i]]
                local placement
                if def.Place then
                    local called, result, callbackErr = self:GraphCallback(def, "Place", g, cell, placeEnvironment)
                    if not called then return false, callbackErr end
                    placement = result
                else placement = {cellKey = candidates[i]} end
                if placement then
                    local ok, err, fatal = self:ValidatePlacement(g, def, placement, reserved)
                    if fatal then return false, err end
                    if ok then
                        -- Test the growing combined proof while candidates can
                        -- still be rejected. A later toll must not strand an
                        -- earlier pair/cache; a later shortcut may not bypass a toll.
                        local env={edges=copy(hazardEdges),cells=copy(hazardCells)}
                        for _,prior in ipairs(plan.instances) do
                            if prior.contract=="BLOCKADE" then env.edges[prior.placement.edgeKey]=true end
                        end
                        for ek in pairs(placement.blockedEdges or {}) do env.edges[ek]=true end
                        for ck in pairs(placement.blockedCells or {}) do env.cells[ck]=true end
                        if def.contract=="BLOCKADE" then env.edges[placement.edgeKey]=true end
                        local routes=copy(env.edges)
                        for _,prior in ipairs(plan.instances) do
                            if prior.contract=="BLOCKADE" then routes[prior.placement.edgeKey]=nil end
                        end
                        if def.contract=="BLOCKADE" then routes[placement.edgeKey]=nil end
                        ok,err=self:ValidateRoutes(g,routes,env.cells)
                        if ok then ok,err,fatal=self:ValidatePlacement(g,def,placement,reserved,env) end
                        if ok then
                            for _,prior in ipairs(plan.instances) do
                                local pd=Registry.Definitions[prior.archetype]
                                if prior.contract=="BLOCKADE" or pd.dropFloor or pd.pairedWarp then
                                    ok,err,fatal=self:ValidatePlacement(g,pd,prior.placement,nil,env)
                                    if not ok then break end
                                end
                            end
                        end
                        if fatal then return false,err end
                    end
                    if ok then accepted = placement; break end
                    lastErr = err
                end
            end
            if not accepted then return false, "event placement exhausted: " .. id .. ": " .. tostring(lastErr) end
            local cellKey = accepted.cellKey or key(accepted.cell)
            reserved[cellKey] = true
            if accepted.destinationCellKey then reserved[accepted.destinationCellKey] = true end
            if accepted.cacheCellKey then reserved[accepted.cacheCellKey] = true end
            for c in pairs(accepted.blockedCells or {}) do reserved[c] = true end
            if accepted.edgeKey then
                local e = g.Edges[accepted.edgeKey]
                reserved[accepted.edgeKey], reserved[key(e.a)], reserved[key(e.b)] = true, true, true
            end
            for ek in pairs(accepted.blockedEdges or {}) do
                local e = g.Edges[ek]
                reserved[ek], reserved[key(e.a)], reserved[key(e.b)] = true, true, true
            end
            if def.contract == "HAZARD" then
                for e in pairs(accepted.blockedEdges or {}) do hazardEdges[e] = true end
                for c in pairs(accepted.blockedCells or {}) do hazardCells[c] = true end
            end
            plan.instances[#plan.instances + 1] = {id = tostring(ordinal) .. ":" .. id .. (multiple and (":" .. memberIndex) or ""), archetype = id,
                memberIndex = memberIndex, memberCount = memberCount,
                contract = def.contract, cellKey = cellKey, cell = g.Cells[cellKey], placement = accepted,
                seed = memberSeed, state = "planned", claims = {}, entities = {}}
        end
    end
    -- Prove every blockade can resolve without borrowing access through another
    -- unresolved event. Conservative rejection is preferable to a circular cost
    -- dependency; richer staged-payment planning belongs with that catalog.
    local environment = {edges = copy(hazardEdges), cells = copy(hazardCells)}
    for _, instance in ipairs(plan.instances) do
        if instance.contract == "BLOCKADE" then environment.edges[instance.placement.edgeKey] = true end
    end
    for _, instance in ipairs(plan.instances) do
        if instance.contract == "BLOCKADE" or Registry.Definitions[instance.archetype].dropFloor
            or Registry.Definitions[instance.archetype].pairedWarp then
            local ok, err = self:ValidatePlacement(g, Registry.Definitions[instance.archetype], instance.placement, nil, environment)
            if not ok then return false, "combined event contract rejected: " .. tostring(err) end
        end
    end
    return true, plan
end

function D:IsCurrent(instance)
    local s = Run.State
    return instance and self.Context and instance.token == self.Context.token
        and self.Context.state == s and self.Context.graph == s.Graph and s.BuildReady
        and self.Context.epoch == s.CampaignEpoch and instance.runId == s.RunId
        and instance.level == s.Level and instance.levelSeed == s.LevelSeed
        and not s.Failed and not s.LevelCleared and instance.state ~= "cleaned"
        and self.Context.byId[instance.id] == instance
end

-- Reused at transaction commit, after fallible SQL/native presentation work.
-- The initially authorized entity and Hero must still be the exact live owners.
function D:InteractionCurrent(instance, ply, identity, ps, entity)
    if not self:IsCurrent(instance) or instance.state ~= "active" or not IsValid(entity)
        or entity.LODEventInstance ~= instance or not IsValid(ply) or not ply:IsPlayer()
        or not ply:Alive() or ply:SteamID64() ~= identity or not Run:IsActivePlayer(ply)
        or Run:IsSoldierControl(ply) or Run:GetPlayerState(ply) ~= ps then return false end
    local tracked = false
    for _, candidate in ipairs(instance.entities) do if candidate == entity then tracked = true; break end end
    if not tracked or not ps or not ps.deploymentComplete or ps.inStaging or ps.eliminated
        or (ps.lives or 0) <= 0 or Run.State.SimulationFrozen then return false end
    local clock = Run.State.CampaignClock
    if clock and (clock.expired or clock.scene or (clock.deadline and SysTime() >= clock.deadline)) then return false end
    if ply:GetPos():DistToSqr(entity:GetPos()) > 160 * 160 then return false end
    local trace = util.TraceLine({start = ply:EyePos(), endpos = entity:WorldSpaceCenter(), filter = ply, mask = MASK_SOLID})
    return not trace.Hit or trace.Entity == entity
end

-- Navigation reads current event ownership; no graph topology is changed.
function D:BlocksEdge(g,edgeKey)
    if not self.Context or self.Context.graph~=g then return false end
    for _,i in ipairs(self.Context.plan.instances) do
        if i.contract=="BLOCKADE" and i.placement.edgeKey==edgeKey
            and self:IsCurrent(i) and i.state~="resolved" then return true end
    end
    return false
end
function D:RouteSignature(g)
    if not self.Context or self.Context.graph~=g then return "" end
    local out={self.Context.token}
    for _,i in ipairs(self.Context.plan.instances) do
        if i.contract=="BLOCKADE" and self:IsCurrent(i) then out[#out+1]=i.id..":"..i.state end
    end
    return table.concat(out,"|")
end

function D:Track(instance, entity)
    if not IsValid(entity) then return false end
    local context = self.Context
    if not instance or not context or context.state ~= Run.State or instance.token ~= context.token
        or context.epoch ~= Run.State.CampaignEpoch or instance.runId ~= Run.State.RunId
        or instance.level ~= Run.State.Level or instance.levelSeed ~= Run.State.LevelSeed
        or context.byId[instance.id] ~= instance
        or (instance.state ~= "creating" and instance.state ~= "active") then
        return false
    end
    for _, tracked in ipairs(instance.entities) do if tracked == entity then return true end end
    entity.LODEventInstance = instance
    instance.entities[#instance.entities + 1] = entity
    return true
end

function D:Cleanup(reason)
    local context = self.Context
    self.Context = nil -- invalidate first; entity OnRemove callbacks cannot claim
    self.Serial = self.Serial + 1
    if not context then return end
    for _, instance in ipairs(context.plan.instances) do
        instance.state = "cleaned"
        local def = Registry.Definitions[instance.archetype]
        if def and def.Cleanup then pcall(def.Cleanup, self, instance, reason) end
        for _, entity in ipairs(instance.entities) do if IsValid(entity) then entity:Remove() end end
        instance.entities = {}
    end
    self:SyncAll()
end

function D:Resolve(instance)
    if not self:IsCurrent(instance) or instance.state ~= "active" then return false end
    instance.state = "resolved"
    self:SyncAll()
    return true
end

function D:Activate(g, plan)
    self:Cleanup("replacement")
    local s = Run.State
    self.Context = {token = tostring(self.Serial), state = s, graph = g, plan = plan, byId = {}, epoch = s.CampaignEpoch}
    for _, instance in ipairs(plan.instances) do
        instance.token = self.Context.token
        instance.runId, instance.level, instance.levelSeed = s.RunId, s.Level, s.LevelSeed
        instance.state = "creating"
        self.Context.byId[instance.id] = instance
        local def = Registry.Definitions[instance.archetype]
        local ok, entity, err = pcall(def.Create, self, instance, g)
        if not ok or not IsValid(entity) then
            self:Cleanup("creation failed")
            return false, "event creation failed: " .. instance.archetype .. ": " .. tostring(err or entity)
        end
        if entity.LODEventInstance ~= instance then self:Track(instance, entity)
        else
            local tracked = false; for _, e in ipairs(instance.entities) do if e == entity then tracked = true end end
            if not tracked then self:Track(instance, entity) end
        end
        instance.state = "active"
    end
    return true
end

function D:Claim(instance, identity)
    if not instance.claims[identity] then
        local def = Registry.Definitions[instance.archetype]
        if def.Claim then
            local ok, result, err = pcall(def.Claim, instance, identity)
            if not ok or err then return nil, "claim storage unavailable" end
            if ok and result then instance.claims[identity] = {state = "resolved", result = result} end
        end
    end
    return instance.claims[identity]
end

function D:Interact(entity, ply)
    local instance = IsValid(entity) and entity.LODEventInstance
    if not self:IsCurrent(instance) or instance.state ~= "active" then return false, "stale event" end
    local tracked = false; for _, e in ipairs(instance.entities) do if e == entity then tracked = true end end
    if not tracked then return false, "stale entity" end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or not Run:IsActivePlayer(ply)
        or (Run.IsSoldierControl and Run:IsSoldierControl(ply)) then return false, "active Hero required" end
    local s, ps = Run.State, Run:GetPlayerState(ply)
    if s.CampaignClock and s.CampaignClock.deadline and SysTime() >= s.CampaignClock.deadline then
        if LOD.CampaignTimeout and LOD.CampaignTimeout.Expire then LOD.CampaignTimeout:Expire() end
        return false, "campaign expired"
    end
    if not ps or not ps.deploymentComplete or ps.inStaging or ps.eliminated or (ps.lives or 0) <= 0
        or s.SimulationFrozen or (s.CampaignClock and (s.CampaignClock.expired or s.CampaignClock.scene)) then
        return false, "deployed Hero required"
    end
    if ply:GetPos():DistToSqr(entity:GetPos()) > 160 * 160 then return false, "too far away" end
    local tr = util.TraceLine({start = ply:EyePos(), endpos = entity:WorldSpaceCenter(), filter = ply, mask = MASK_SOLID})
    if tr.Hit and tr.Entity ~= entity then return false, "event obstructed" end
    local identity = ply:SteamID64()
    if not LOD.CryptoStore:ValidAccount(identity) then return false, "valid account required" end
    local def = Registry.Definitions[instance.archetype]
    -- Repeatable utility traversals own no economic/account claim. Serialize
    -- only this body during native safety callbacks, then release immediately.
    if def.repeatable then
        instance.interactions = instance.interactions or {}
        local interactions=instance.interactions
        if interactions[ply] then return false, "busy" end
        interactions[ply] = true
        local ok, accepted, result = pcall(def.Interact, self, instance, ply, identity, entity)
        interactions[ply] = nil
        if not ok then return false, "event unavailable" end
        if not self:IsCurrent(instance) then return false, "stale event" end
        return accepted, result
    end
    local claim, claimErr = self:Claim(instance, identity)
    if claimErr then return false, claimErr end
    if claim then return false, claim.state == "resolving" and "busy" or "already" end
    instance.claims[identity] = {state = "resolving"}
    local def = Registry.Definitions[instance.archetype]
    local ok, accepted, result = pcall(def.Interact, self, instance, ply, identity)
    if not self:IsCurrent(instance) then return false, "stale event" end
    if ok and accepted then
        instance.claims[identity] = {state = "resolved", result = result}
        if def.sharedResolution then self:Resolve(instance) end
        self:SyncPlayer(ply)
        return true, result
    end
    instance.claims[identity] = nil
    self:Claim(instance, identity) -- hydrate any durable duplicate receipt
    self:SyncPlayer(ply)
    return false, ok and result or "event unavailable"
end

function D:Snapshot(ply)
    local context, s = self.Context, Run.State
    local snapshot = {token = tostring(self.Serial), epoch = s.CampaignEpoch, level = s.Level,
        seed = s.LevelSeed, mode = "disabled", selectedCount = 0, events = {}}
    if not context or context.state ~= s or context.graph ~= s.Graph or not s.BuildReady
        or context.epoch ~= s.CampaignEpoch or s.Failed or s.LevelCleared then return snapshot end
    snapshot.mode, snapshot.selectedCount = context.plan.mode, context.plan.selectedCount
    local identity = IsValid(ply) and ply:SteamID64() or nil
    for _, instance in ipairs(context.plan.instances) do
        local claim, err
        if identity then claim, err = self:Claim(instance, identity) end
        local def, details = Registry.Definitions[instance.archetype]
        if identity and def.Snapshot and self:IsCurrent(instance) then
            local ok, value = pcall(def.Snapshot, instance, ply, identity)
            details = ok and value or {unavailable = true}
        end
        if self:IsCurrent(instance) then snapshot.events[#snapshot.events + 1] = {id = instance.id, archetype = instance.archetype,
            contract = instance.contract, cellKey = instance.cellKey, state = instance.state,
            memberIndex = instance.memberIndex, memberCount = instance.memberCount,
            claimed = claim and claim.state == "resolved" or false, result = claim and claim.result, claimUnavailable = err ~= nil, details = details,
            entityIndex = IsValid(instance.entities[1]) and instance.entities[1]:EntIndex() or 0} end
    end
    return snapshot
end

function D:SyncPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("LOD_DungeonEvents"); net.WriteTable(self:Snapshot(ply)); net.Send(ply)
end
function D:SyncAll() for _, ply in ipairs(player.GetAll()) do self:SyncPlayer(ply) end end

-- Canonical build path: encounter tags exist, real geometry exists, and players
-- are still held until RunManager commits this exact graph.
local baseBuild = Builder.Build
function Builder:Build(g)
    local ok, report = baseBuild(self, g)
    if not ok then return ok, report end
    local options = D.BuildOptions or {enabled = cvEnabled:GetBool()}
    local planned, plan = D:Plan(g, options)
    if not planned then self:Cleanup(); return false, plan end
    g.EventPlan = plan
    local activated, err = D:Activate(g, plan)
    if not activated then self:Cleanup(); return false, err end
    report.eventCount, report.eventInstanceCount, report.eventMode = plan.selectedCount, #plan.instances, plan.mode
    return true, report
end
local baseCleanup = Builder.Cleanup
function Builder:Cleanup(...)
    D:Cleanup("maze cleanup")
    return baseCleanup(self, ...)
end
local baseLevel = Run.BuildCurrentLevel
function Run:BuildCurrentLevel(...)
    D:Cleanup("dungeon replacement")
    D.BuildOptions = {enabled = D.NextPopulationPreview == true or cvEnabled:GetBool(), preview = D.NextPreview}
    D.NextPreview, D.NextPopulationPreview = nil, nil
    local ok, result = baseLevel(self, ...)
    D.BuildOptions = nil
    if not ok then D:Cleanup("build failed") end
    D:SyncAll()
    return ok, result
end
local baseSync = LOD.ProgressionDirector.SyncPlayer
function LOD.ProgressionDirector:SyncPlayer(ply)
    local result = baseSync(self, ply); D:SyncPlayer(ply); return result
end
local baseCampaign = Run.NewCampaign
function Run:NewCampaign(...)
    D:Cleanup("campaign replacement")
    return baseCampaign(self, ...)
end
local baseFailure = Run.FailCampaign
function Run:FailCampaign(...)
    D:Cleanup("campaign failed")
    local result = baseFailure(self, ...); D:SyncAll(); return result
end
hook.Add("Think", "LOD_DungeonEventThink", function()
    local context = D.Context
    if not context then return end
    for _, instance in ipairs(context.plan.instances) do
        local def = Registry.Definitions[instance.archetype]
        if def.Tick and D:IsCurrent(instance) and instance.state == "active" then
            def.Tick(D, instance)
        end
    end
end)
hook.Add("ShutDown", "LOD_DungeonEventCleanup", function() D:Cleanup("shutdown") end)
hook.Add("PlayerInitialSpawn", "LOD_DungeonEventSnapshot", function(ply)
    timer.Simple(1, function() if IsValid(ply) then D:SyncPlayer(ply) end end)
end)
local function preview(ply, id, population, seed)
    local dev = GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    if not population and not Registry.Definitions[id] then return end
    local notice = population and "Full event preview uses the normal 1d4 count and actual keys, $DEB and persistent DFTs. Campaign unranked."
        or Registry.Definitions[id].previewNotice
    if notice then
        print('[LOD:EVENT-PREVIEW] ' .. notice)
        if IsValid(ply) then ply:ChatPrint(notice) end
    end
    D.NextPreview = not population and id or nil
    D.NextPopulationPreview = population == true
    Run:MarkUnranked(population and "full dungeon event preview" or "single dungeon event preview")
    local ok, err = Run:Regenerate(seed)
    local lines = {}
    if ok and D.Context and D.Context.plan.instances[1] then
        for _, instance in ipairs(D.Context.plan.instances) do
            local cells={instance.cellKey}
            if Registry.Definitions[instance.archetype].pairedWarp then cells[2]=instance.placement.destinationCellKey end
            if instance.placement.cacheCellKey then cells[2]=instance.placement.cacheCellKey end
            for endpoint,cellKey in ipairs(cells) do
                local pos = Builder:CellCenter(D.Context.graph.Cells[cellKey])
                local label=instance.archetype..(#cells>1 and (" endpoint "..endpoint) or "")
                lines[#lines + 1] = string.format("[LOD:EVENT-PREVIEW] %s (%d/%d) at cell %s; developer locator: setpos %.1f %.1f %.1f",
                    label, instance.memberIndex, instance.memberCount, cellKey, pos.x, pos.y, pos.z + 64)
            end
        end
    else lines[1] = "[LOD:EVENT-PREVIEW] generation rejected: " .. tostring(err) end
    for _, line in ipairs(lines) do
        print(line)
        if IsValid(ply) then ply:ChatPrint(line) end
    end
end
concommand.Add("lod_event_preview_generate", function(ply, _, args)
    preview(ply, args[1] or "slot_machine", false)
end)
concommand.Add("lod_event_population_preview", function(ply, _, args)
    local seed = args and args[1] and tonumber(args[1])
    if args and args[1] and (not seed or seed ~= seed or seed < 1 or seed > 2147483646 or seed % 1 ~= 0) then return end
    preview(ply, nil, true, seed)
end)
