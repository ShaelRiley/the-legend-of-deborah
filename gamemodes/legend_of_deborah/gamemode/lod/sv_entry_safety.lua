-- B29: one graph-owned spatial and opening-engagement authority. This is not
-- another population director: existing directors still own actors and rewards.
LOD = LOD or {}
LOD.EntrySafety = LOD.EntrySafety or {}
local S = LOD.EntrySafety
S.Version = "b29-entry-safety"
S.Config = {Apron=3, HullMargin=24, Acquire=3, Locality=4, Disengage=6,
    ServiceSeconds=.1, AdmissionSeconds=1, RespiteSeconds=4, ProjectileTailSeconds=4,
    Depths={6,10,15,20,24}, Quotas={1,2,3,4,6}}
S.Basic = {shambler=true, runner=true, soldier=true}
S.Readable = {reaper=true, drubber=true, caromer=true, afterburst=true}
S.Lungers = {deadcrab=true, razor=true, blitzer=true, climber=true, lurker=true, stalker=true}
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function sorted(t) local a={} for k in pairs(t or {}) do a[#a+1]=k end table.sort(a);return a end
local function alive(e) return IsValid(e) and not e.LODDead and e:Health()>0 end
local function state() return LOD.RunManager and LOD.RunManager.State end
local function nav() return LOD.MazeNavigator end
local function identity(p)
    return LOD.RunManager and LOD.RunManager:IdentityOf(p)
end

-- Called from the existing tag builder before either population planner runs.
function S:Build(graph, tags)
    local start=graph and graph.Start and graph.Cells[key(graph.Start)]
    if not start then return end
    local data={cells={},centers={},depth={},version=self.Version}
    local transitions={}
    for _,v in ipairs(graph.VerticalEdges or {}) do transitions[key(v.a)]=true;transitions[key(v.b)]=true end
    for _,g in ipairs(graph.Progression and graph.Progression.Gates or {}) do
        transitions[key(g.beforeCell)]=true;transitions[key(g.afterCell)]=true
    end
    local function protect(c)
        local k=key(c);data.cells[k]=true;data.centers[#data.centers+1]=nav():CellCenter(c)
        tags[k].entrySanctuary=true;tags[k].safe=true
    end
    protect(start)
    for _,k in ipairs(sorted(start.neighbors)) do
        local c,t=graph.Cells[k],tags[k]
        if c and t and c.z==start.z and not t.objective and t.role~="boss"
            and not transitions[k] and nav():CanTraverse(graph,key(start),k) then protect(c) end
    end
    -- Sector-one route distance is topology, not elapsed generation/staging time.
    -- All later sectors retain their own gates and ordinary population rules.
    local queue={key(start)};data.depth[queue[1]]=0;local head=1
    while queue[head] do
        local k=queue[head];head=head+1
        for _,n in ipairs(sorted(graph.Cells[k].neighbors)) do
            if tags[n] and tags[n].sector==tags[key(start)].sector and data.depth[n]==nil
                and nav():CanTraverse(graph,k,n) then
                data.depth[n]=data.depth[k]+1;queue[#queue+1]=n
            end
        end
    end
    for k,d in pairs(data.depth) do
        if d<=self.Config.Apron then tags[k].entryApron=true end
        if d<10 then tags[k].entryRoamOpening=true end
    end
    graph.EntrySafety=data
end

function S:Reset()
    for _,r in pairs(self.Records or {}) do
        if IsValid(r.actor) and r.actor.SetNW2Bool then
            r.actor:SetNW2Bool("LOD_EntrySanctuary",false)
            if r.actor.SetNW2Int then r.actor:SetNW2Int("LOD_EntryCells",0) end
        end
    end
    self.Owner=nil;self.Records={};self.Active={};self.NextService=0;self.FrozenAt=nil;self.EventSerial=0
    self.Stats={damageDenied=0,statusDenied=0,movementDenied=0,correctedIngress=0,admissionDenied=0}
end
S:Reset()
function S:Context()
    local s=state();local o=self.Owner
    if not s or not s.Graph or not s.Graph.EntrySafety then
        if o then self:Reset() end
        return nil
    end
    if not o or o.state~=s or o.graph~=s.Graph or o.seed~=s.LevelSeed or o.level~=s.Level
        or o.epoch~=s.CampaignEpoch or o.run~=s.RunId then
        self:Reset();self.Owner={state=s,graph=s.Graph,seed=s.LevelSeed,level=s.Level,
            epoch=s.CampaignEpoch,run=s.RunId}
    end
    return s,s.Graph,s.Graph.EntrySafety
end

-- Deliberately NOT WorldToCell's nearest/clamped fallback. A staging hut above
-- the maze, or a different deck, must never count as actual dungeon deployment.
function S:ExactCell(graph,pos)
    if not graph or not pos then return nil end
    local m=LOD.Config.Maze
    local x=math.floor((pos.x-m.Origin.x)/m.CellSize+(m.Width+1)*.5+.5)
    local y=math.floor((pos.y-m.Origin.y)/m.CellSize+(m.Height+1)*.5+.5)
    local z=math.floor((pos.z-m.Origin.z+24)/m.LevelHeight)
    local c=graph.Cells[LOD.MazeGenerator.CellKey(x,y,z)]
    if not c then return nil end
    local p=nav():CellCenter(c)
    if math.abs(pos.x-p.x)>m.CellSize*.5 or math.abs(pos.y-p.y)>m.CellSize*.5
        or pos.z<p.z-24 or pos.z>=p.z+m.LevelHeight-24 then return nil end
    return c
end
function S:ProtectedPosition(pos,padding)
    local s=state();local data=s and s.Graph and s.Graph.EntrySafety
    if not data or not pos then return false end
    local m=LOD.Config.Maze;local half=m.CellSize*.5+(padding or 0)
    for _,c in ipairs(data.centers) do
        if math.abs(pos.x-c.x)<=half and math.abs(pos.y-c.y)<=half
            and pos.z>=c.z-24 and pos.z<c.z+m.LevelHeight-24 then return true end
    end
    return false
end
function S:Protected(actor)
    return IsValid(actor) and actor.GetPos and self:ProtectedPosition(actor:GetPos()) or false
end
function S:Source(actor)
    local seen={}
    for _=1,4 do
        if not IsValid(actor) or seen[actor] then return nil end
        seen[actor]=true
        if actor.LODHostile or actor:IsPlayer() then return actor end
        local owner=actor.GetOwner and actor:GetOwner()
        if not IsValid(owner) then return actor end
        actor=owner
    end
    return actor
end

function S:SpawnPositionAllowed(pos)
    local s=state();local g=s and s.Graph
    if not g or not g.EntrySafety then return true end
    local c=self:ExactCell(g,pos)
    return not self:ProtectedPosition(pos,self.Config.HullMargin) and (not c or self:SpawnCellAllowed(g,c))
end
function S:SpawnCellAllowed(graph,c)
    local t=c and graph and graph.CellTags and graph.CellTags[key(c)]
    return not (t and (t.entrySanctuary or t.entryApron))
end
function S:HomeCandidateAllowed(graph,c,actors)
    local data=graph.EntrySafety;if not data then return true end
    local d=data.depth[key(c)];if not d or d>=10 then return true end
    for _,e in ipairs(actors or {}) do
        local h=data.depth[e.LODWanderAnchorCellKey or e.LODHomeCellKey or ""]
        if alive(e) and h and h<10 and ((d<6)==(h<6)) then return false end
    end
    return true
end
function S:HomeArchetypeAllowed(graph,c,id)
    local d=graph.EntrySafety and graph.EntrySafety.depth[key(c)]
    if not d then return true end
    if d<6 then return self.Basic[id]==true end
    if d<10 then return self.Basic[id] or self.Readable[id] or false end
    return true
end
function S:OrderHomes(graph,floor,ordinal,cells)
    if not graph.EntrySafety or floor~=graph.Start.z or ordinal>2 then return cells end
    local depths=graph.EntrySafety.depth
    local ranks={};for i,c in ipairs(cells) do ranks[c]=i end
    local function rank(c)
        local d=depths[key(c)] or math.huge
        local lo,hi=ordinal==1 and 4 or 7,ordinal==1 and 6 or 10
        return d>=lo and d<hi and 0 or 1
    end
    table.sort(cells,function(a,b) local x,y=rank(a),rank(b);return x==y and ranks[a]<ranks[b] or x<y end)
    return cells
end
function S:PatrolCellAllowed(graph,e,c)
    if not self:SpawnCellAllowed(graph,c) then return false end
    local data=graph.EntrySafety;if not data then return true end
    local home=data.depth[e.LODWanderAnchorCellKey or e.LODHomeCellKey or ""]
    local d=data.depth[key(c)]
    if not d then return not home or home>=10 end
    if home and home<6 then return d>=4 and d<7 end
    if home and home<10 then return d>=6 and d<12 end
    return d>=10
end

function S:SyncBoundary(p,data)
    if not p.SetNW2Int then return end
    p:SetNW2Int("LOD_EntryCells",#data.centers)
    p:SetNW2Float("LOD_EntryHalf",LOD.Config.Maze.CellSize*.5)
    for i,c in ipairs(data.centers) do p:SetNW2Vector("LOD_EntryCell"..i,c) end
end
function S:Deployed(p,expected)
    local s,g,data=self:Context()
    if not s or s~=expected or not IsValid(p) then return false end
    local id=identity(p);if not id then return false end
    local r=self.Records[id] or {completed=0,highWater=0,firstDeploy=CurTime()}
    self.Records[id]=r;r.actor=p;r.deployedAt=CurTime();r.exitedAt=nil
    r.deployments=(r.deployments or 0)+1;r.wave=nil;r.restUntil=0
    r.firstAttack=nil;r.firstAttackAfterDeploy=nil;r.firstAttackAfterExit=nil;r.firstAttackSource=nil
    self.EventSerial=self.EventSerial+1
    local c=self:ExactCell(g,p:GetPos())
    -- Actual checkpoint/boss deployment is not a fresh entrance tutorial.
    r.checkpoint=c and not data.depth[key(c)] and not self:Protected(p) or false
    self:SyncBoundary(p,data);self.NextService=0
    return true
end
function S:Distances(graph,c,observe)
    local out={[key(c)]=0};local q={key(c)};local head=1
    while q[head] do
        local k=q[head];head=head+1
        if out[k]<self.Config.Disengage then
            for _,n in ipairs(sorted(graph.Cells[k].neighbors)) do
                if out[n]==nil and (observe or not graph.EntrySafety.cells[n]) and nav():CanTraverse(graph,k,n) then
                    out[n]=out[k]+1;q[#q+1]=n
                end
            end
        end
    end
    return out
end
function S:Quota(r)
    local stage=1
    for i,d in ipairs(self.Config.Depths) do if r.depth>=d then stage=i+1 end end
    return self.Config.Quotas[math.min(stage,r.completed+1,#self.Config.Quotas)]
end
function S:MemberDistance(r,e,g)
    local c=IsValid(e) and self:ExactCell(g,e:GetPos())
    return c and r.distances and r.distances[key(c)] or math.huge
end
function S:Service()
    local s,g,data=self:Context();if not s then return end
    local now=CurTime()
    if now<(self.NextService or 0) then return end
    self.NextService=now+self.Config.ServiceSeconds;self.Active={}
    for _,r in pairs(self.Records) do
        r.active=false
        if not self:Protected(r.actor) then
            r.safe=false
            if IsValid(r.actor) and r.actor.SetNW2Bool then r.actor:SetNW2Bool("LOD_EntrySanctuary",false) end
        end
    end
    if s.SimulationFrozen then self.FrozenAt=self.FrozenAt or now;return end
    if self.FrozenAt then
        local pause=now-self.FrozenAt;self.FrozenAt=nil
        for _,r in pairs(self.Records) do
            if r.restUntil and r.restUntil>0 then r.restUntil=r.restUntil+pause end
            if r.wave then
                r.wave.openUntil=r.wave.openUntil+pause
                for _,m in pairs(r.wave.members) do if m.deadAt then m.deadAt=m.deadAt+pause end end
            end
        end
    end
    if not s.BuildReady or s.Failed or s.LevelCleared then return end
    for _,p in ipairs(LOD.FactionManager:LivingTargets()) do
        local id=identity(p);local r=id and self.Records[id]
        local ps=id and s.PlayerState and s.PlayerState[id]
        -- Fallback is only for an already deployed life restored by an older
        -- lifecycle provider; staging players never create a deployment record.
        if not r and ps and ps.deploymentComplete and ps.deployedDungeonLevel==s.Level
            and self:ExactCell(g,p:GetPos()) then self:Deployed(p,s);r=self.Records[id] end
        if r and r.actor==p and alive(p) then
            local c=self:ExactCell(g,p:GetPos());local safe=self:Protected(p)
            if r.safe~=safe then self.EventSerial=self.EventSerial+1 end
            r.safe=safe;r.cell=c and key(c);r.observation=c and self:Distances(g,c,true) or {}
            r.depth=c and (data.depth[key(c)] or 24) or 0
            if c then r.highWater=math.max(r.highWater,r.depth) end
            if p.SetNW2Bool then p:SetNW2Bool("LOD_EntrySanctuary",safe) end
            if c and not safe then
                r.exitedAt=r.exitedAt or now;r.firstExit=r.firstExit or now
                r.active=true;r.distances=self:Distances(g,c)
                r.limited=not r.checkpoint and (r.completed<#self.Config.Quotas or r.depth<24)
                r.cap=self:Quota(r);self.Active[#self.Active+1]=r
                local w=r.wave
                if w then
                    local live,near=0,0
                    for e,m in pairs(w.members) do
                        if not alive(e) then m.deadAt=m.deadAt or now end
                        if not m.deadAt or now<m.deadAt+self.Config.ProjectileTailSeconds then
                            live=live+1
                            if self:MemberDistance(r,e,g)<=self.Config.Disengage then near=near+1 end
                        end
                    end
                    if live==0 or (near==0 and now>w.openUntil+2) then
                        if live==0 or r.depth>=w.startDepth+2 then r.completed=r.completed+1 end
                        r.wave=nil;r.restUntil=now+self.Config.RespiteSeconds;self.EventSerial=self.EventSerial+1
                    end
                end
            end
        end
    end
end
function S:WaveAllows(r,id,e)
    if not r.limited then return true end
    if CurTime()<(r.restUntil or 0) then return false end
    local w=r.wave
    if w and w.members[e] then return w.members[e].ordinal<=r.cap end
    if w and (CurTime()>w.openUntil or w.count>=math.min(w.cap,r.cap)) then return false end
    if r.completed==0 and not self.Basic[id] then return false end
    if r.completed==1 and not (self.Basic[id] or self.Readable[id]) then return false end
    if not self.Basic[id] and w and w.specialists>=1 then return false end
    return true
end
function S:AddMember(r,e)
    if not r.limited then return end
    local w=r.wave
    if not w then
        w={members={},count=0,specialists=0,cap=r.cap,openUntil=CurTime()+self.Config.AdmissionSeconds,startDepth=r.depth}
        r.wave=w
    end
    if not w.members[e] then
        w.members[e]={admittedAt=CurTime(),ordinal=w.count+1,source=e.LODSpawnSource or "other",archetype=e.LODArchetypeId or "soldier"}
        self.EventSerial=self.EventSerial+1
        w.count=w.count+1
        if not self.Basic[e.LODArchetypeId] then w.specialists=w.specialists+1 end
    end
end
-- A single actor is reserved against EVERY nearby opening Hero, not one quota
-- per director/player. Safe Heroes never participate in these reservations.
function S:Claim(e)
    self:Service();local s,g=self:Context();if not s then return nil,false end
    local nearby={};local target,best;local limited=false
    for _,r in ipairs(self.Active) do
        local d=self:MemberDistance(r,e,g)
        local committed=r.wave and r.wave.members[e] and d<=self.Config.Disengage
        if d<=self.Config.Locality or committed then
            nearby[#nearby+1]=r;limited=limited or r.limited
            if (d<=self.Config.Acquire or committed) and (not best or d<best) and LOD.FactionManager:CanAcquirePlayerTarget(r.actor) then
                target,best=r.actor,d
            end
        end
    end
    if not target then return nil,limited end
    for _,r in ipairs(nearby) do
        if (self.Lungers[e.LODArchetypeId] and r.depth<=self.Config.Apron+1)
            or not self:WaveAllows(r,e.LODArchetypeId,e) then
            self.Stats.admissionDenied=self.Stats.admissionDenied+1;return nil,true
        end
    end
    for _,r in ipairs(nearby) do self:AddMember(r,e) end
    return target,limited
end
function S:Permit(e,target)
    self:Service()
    if self:Protected(target) or self:Protected(e) then return false end
    local _,g=self:Context();if not g then return true end
    -- A newly arrived/returning nearby Hero cannot inherit a larger distant
    -- group's existing volley. Reservations are shared and rechecked at impact.
    for _,r in ipairs(self.Active) do
        if r.limited and (r.actor==target or self:MemberDistance(r,e,g)<=self.Config.Locality) then
            if CurTime()<(r.restUntil or 0) or not r.wave or not r.wave.members[e]
                or r.wave.members[e].ordinal>r.cap then return false end
        end
    end
    return true
end
function S:Cancel(e)
    e.LODTarget=nil;e.LODEntryTarget=nil;e.LODSoldierBurst=nil
    e.LODWaypoints={};e.LODWaypointIndex=1;e.LODNextTargetRefresh=0;e.LODNextRouteRefresh=0
    if e.LODRosterAttack and LOD.EnemyRoster then LOD.EnemyRoster:Cancel(e) end
    if LOD.EnemyPursuit and LOD.EnemyPursuit.Cancel then LOD.EnemyPursuit:Cancel(e) end
    if e.LODDeadcrabState=="latched" or e.LODDeadcrabState=="leaping" then
        e.LODDeadcrabState=nil;e.LODDeadcrabTarget=nil;e.LODDeadcrabManualLatchTarget=nil
        if e.SetParent then e:SetParent(nil) end
    end
    e.LODBioState=nil;e.LODBioTarget=nil;e.LODBioBlast=nil
    e.LODWatcherScan=nil;e.LODSeekerState=nil;e.LODSeekerRetreat=nil
    local personality=LOD.SeekerPersonality
    if personality then
        for _,name in ipairs({"Active","PendingFeint","PendingOrbit"}) do
            if personality[name] then personality[name][e]=nil end
        end
    end
end
function S:Withdraw(e,g)
    local motion=LOD.HostileMotionV2;if not motion then return end
    local current=self:ExactCell(g,e:GetPos())
    local home=g.Cells[e.LODWanderAnchorCellKey or e.LODHomeCellKey or ""]
    if not current or not home then motion:Stop(e);return end
    local now=CurTime()
    if now>=(e.LODEntryRouteAt or 0) or e.LODEntryRouteOwner~=self.Owner then
        e.LODEntryRouteAt=now+.5;e.LODEntryRouteOwner=self.Owner
        local minDepth=math.min(g.EntrySafety.depth[key(current)] or 4,4)
        local function unpressured(c)
            for _,r in ipairs(self.Active) do
                if r.limited and (r.distances[key(c)] or math.huge)<self.Config.Locality then return false end
            end
            return true
        end
        local destination=home
        if not unpressured(home) then
            local queue={current};local seen={[key(current)]=0};local head=1
            while queue[head] do
                local c=queue[head];head=head+1
                if self:SpawnCellAllowed(g,c) and unpressured(c) then destination=c;break end
                if seen[key(c)]<self.Config.Disengage then
                    for _,k in ipairs(sorted(c.neighbors)) do
                        if not seen[k] and not g.EntrySafety.cells[k] and nav():CanTraverse(g,key(c),k) then
                            seen[k]=seen[key(c)]+1;queue[#queue+1]=g.Cells[k]
                        end
                    end
                end
            end
        end
        local path=nav():FindPath(g,current,destination,function(c)
            return not g.EntrySafety.cells[key(c)] and (g.EntrySafety.depth[key(c)] or 4)>=minDepth
        end)
        e.LODEntryRoute=path and nav():PathToWaypoints(g,path) or {};e.LODEntryRouteIndex=1
    end
    local route=e.LODEntryRoute or {};local i=e.LODEntryRouteIndex or 1;local w=route[i]
    if w and e:GetPos():DistToSqr(w.pos)<(w.tolerance or 18)^2 then i=i+1;e.LODEntryRouteIndex=i;w=route[i] end
    if w then e.LODEntryWithdrawing=true;motion:MoveToward(e,w);e.LODEntryWithdrawing=nil
    else motion:Stop(e) end
end
function S:BeforeAI(e)
    local s,g=self:Context();if not s or not alive(e) then return false end
    if not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    self:Service()
    local motion=LOD.HostileMotionV2
    if self:ProtectedPosition(e:GetPos(),self.Config.HullMargin) then
        self:Cancel(e);if motion then motion:Stop(e) end
        -- A diagnostic fallback for native/manual displacement, not ordinary
        -- navigation. The movement seams prevent entry before SetPos.
        if e.LODEntryLastOutside then e:SetPos(e.LODEntryLastOutside);self.Stats.correctedIngress=self.Stats.correctedIngress+1 end
        return true
    end
    e.LODEntryLastOutside=e:GetPos()
    if e.LODHector or e.LODWarden or e.LODNeilBrute then return false end
    local target,limited=self:Claim(e)
    local c=self:ExactCell(g,e:GetPos());local depth=c and g.EntrySafety.depth[key(c)]
    if target then
        e.LODEntrySuppressed=nil;e.LODEntryTarget=target;e.LODEntryPermitUntil=CurTime()+self.Config.ServiceSeconds*2
        -- Admission is necessary, not sufficient: the native archetype still
        -- owns perception, target selection, telegraphs and attack formulas.
        return false
    end
    e.LODEntryPermitUntil=nil;e.LODEntryTarget=nil
    -- No safe/staged Hero can attract a patrol. Inhabited areas beyond the local
    -- opening retain ordinary autonomy when no opening Hero is nearby.
    if limited or (depth and depth<=self.Config.Apron) or (IsValid(e.LODTarget) and self:Protected(e.LODTarget)) then
        if not e.LODEntrySuppressed then self:Cancel(e);e.LODEntrySuppressed=true end
        self:Withdraw(e,g);return true
    end
    e.LODEntrySuppressed=nil
    return false
end

-- Swept segment versus the compact sanctuary, expanded by the hostile hull.
-- This also covers long special moves and pushback that skip a logical cell.
function S:MovementAllowed(e,from,to)
    local s,g,data=self:Context();if not s or not IsValid(e) then return true end
    if not e.LODHostile and not (LOD.FactionManager and LOD.FactionManager:IsEnemyCombatant(e)) then return true end
    local half=LOD.Config.Maze.CellSize*.5+self.Config.HullMargin
    for _,c in ipairs(data.centers) do
        local lo={x=c.x-half,y=c.y-half,z=c.z-96}
        local hi={x=c.x+half,y=c.y+half,z=c.z+LOD.Config.Maze.LevelHeight-24}
        local enter,leave=0,1;local hit=true
        for _,axis in ipairs({"x","y","z"}) do
            local delta=to[axis]-from[axis]
            if math.abs(delta)<.0001 then
                if from[axis]<lo[axis] or from[axis]>hi[axis] then hit=false;break end
            else
                local a,b=(lo[axis]-from[axis])/delta,(hi[axis]-from[axis])/delta
                if a>b then a,b=b,a end
                enter=math.max(enter,a);leave=math.min(leave,b)
                if enter>leave then hit=false;break end
            end
        end
        if hit then self.Stats.movementDenied=self.Stats.movementDenied+1;return false end
    end
    local dest=self:ExactCell(g,to)
    if dest and g.CellTags[key(dest)].entryApron and not e.LODEntryWithdrawing
        and (self.Lungers[e.LODArchetypeId] or CurTime()>(e.LODEntryPermitUntil or -1)) then
        self.Stats.movementDenied=self.Stats.movementDenied+1;return false
    end
    return true
end
function S:HostilePathCell(graph,c)
    return not (graph.EntrySafety and graph.EntrySafety.cells[key(c)])
end
function S:EncounterAllowed(graph,enc,p)
    self:Service()
    if self:Protected(p) then return false end
    local r=self.Records[identity(p) or false]
    if not r or not r.active then return false end
    if not r.limited then return true end
    if CurTime()<(r.restUntil or 0) then return false end
    if enc.objective then return true end -- Composition/objective contract retained; AI shares admission.
    local count,specialists=0,0
    for id,n in pairs(enc.composition or {}) do
        count=count+n;if not self.Basic[id] then specialists=specialists+n end
        if not self:WaveAllows(r,id,enc) then return false end
    end
    return count+(r.wave and r.wave.count or 0)<=r.cap and specialists<=1
end

function S:CombatAllowed(target,source)
    source=self:Source(source)
    if self:Protected(target) then return false end
    if self:Protected(source) then return false end
    local faction=LOD.FactionManager
    if IsValid(source) and faction and faction:IsEnemyCombatant(source)
        and IsValid(target) and target:IsPlayer() then return self:Permit(source,target) end
    return true
end
function S:DamageGate(target,info)
    local source=info and self:Source(info:GetAttacker())
    if not info then return false end
    if not self:CombatAllowed(target,source) then
        self.Stats.damageDenied=self.Stats.damageDenied+1;info:SetDamage(0)
        if info.SetDamageForce then info:SetDamageForce(vector_origin) end
        if LOD.CombatRolls and LOD.CombatRolls.PendingDamageReports then LOD.CombatRolls.PendingDamageReports[info]=nil end
        return true
    end
    if IsValid(source) and LOD.FactionManager:IsEnemyCombatant(source) and IsValid(target) and target:IsPlayer()
        and info:GetDamage()>0 then
        local r=self.Records[identity(target) or false]
        if r and not r.firstAttack then
            self.EventSerial=self.EventSerial+1
            r.firstAttack=CurTime();r.firstAttackAfterDeploy=CurTime()-r.deployedAt
            r.firstAttackAfterExit=r.exitedAt and CurTime()-r.exitedAt or nil
            r.firstAttackSource=source.LODSpawnSource or "other"
        end
    end
    return false
end
function S:Snapshot()
    local s=state();local g=s and s.Graph;local data=g and g.EntrySafety
    if not data or not self.Owner or self.Owner.state~=s or self.Owner.graph~=g then
        return {version=self.Version,ready=false}
    end
    local out={version=self.Version,ready=true,eventSerial=self.EventSerial,bindings={
        ai=self.BeforeAI==self.FunctionBindings.BeforeAI,damage=self.DamageGate==self.FunctionBindings.DamageGate,
        spawn=self.SpawnPositionAllowed==self.FunctionBindings.SpawnPositionAllowed},cells=sorted(data.cells),stats=table.Copy(self.Stats),heroes={}}
    local actors={};local seen={}
    local function collect(list) for _,e in ipairs(list or {}) do if not seen[e] then seen[e]=true;actors[#actors+1]=e end end end
    collect(LOD.HostileRegistry and LOD.HostileRegistry:List())
    collect(LOD.EncounterDirector and LOD.EncounterDirector.Entities)
    collect(LOD.WanderingDirector and LOD.WanderingDirector.Entities)
    for _,id in ipairs(sorted(self.Records)) do
        local r=self.Records[id];local row={entity=IsValid(r.actor) and r.actor:EntIndex() or -1,
            safe=r.safe,active=r.active,depth=r.depth,highWater=r.highWater,completed=r.completed,cap=r.cap,
            deployedAt=r.deployedAt,exitedAt=r.exitedAt,deployments=r.deployments,
            firstAttackAfterDeploy=r.firstAttackAfterDeploy,firstAttackAfterExit=r.firstAttackAfterExit,
            firstAttackSource=r.firstAttackSource,respite=math.max(0,(r.restUntil or 0)-CurTime()),nearby=0,engaged=0,admitted=0,nearbySources={},sources={},archetypes={}}
        for _,e in ipairs(actors) do
            local c=alive(e) and self:ExactCell(g,e:GetPos())
            if c and (r.observation and r.observation[key(c)] or math.huge)<=self.Config.Locality then
                row.nearby=row.nearby+1
                local src=e.LODSpawnSource or "other";row.nearbySources[src]=(row.nearbySources[src] or 0)+1
                local m=r.wave and r.wave.members[e]
                if r.active and not r.safe and not e.LODEntrySuppressed and (not r.limited or (m and m.ordinal<=r.cap))
                    and (e.LODTarget==r.actor or e.LODEntryTarget==r.actor) then row.engaged=row.engaged+1 end
            end
        end
        for e,m in pairs(r.wave and r.wave.members or {}) do
            if alive(e) and not r.safe and m.ordinal<=(r.cap or 0) then row.admitted=row.admitted+1;row.sources[m.source]=(row.sources[m.source] or 0)+1
                row.archetypes[m.archetype]=(row.archetypes[m.archetype] or 0)+1 end
        end
        out.heroes[#out.heroes+1]=row
    end
    return out
end

S.FunctionBindings={BeforeAI=S.BeforeAI,DamageGate=S.DamageGate,SpawnPositionAllowed=S.SpawnPositionAllowed}
