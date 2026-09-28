-- Exhaustive discrete route states through the real director and nav cache.
-- Native transport/lifecycle entrypoints are doubles; IsCurrent is production.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
LOD={Config={Maze={},Geometry={}},RunManager={State={}},MazeBuilder={},ProgressionDirector={}}
local Run=LOD.RunManager
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
LOD.EventRegistry={Definitions={}}
CreateConVar=function() return {GetBool=function() return true end} end
util={AddNetworkString=noop}
hook={Add=noop};timer={Simple=noop};net={Receive=noop};concommand={Add=noop}
ents={FindByClass=function() return {} end};scripted_ents={GetStored=function() end}
IsValid=function() return false end
isstring=function(s) return type(s)=='string' end
function Vector(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
math.Clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_event_director.lua')
dofile(root..'sv_phase_zero_runtime_optimization.lua')
local D,N=LOD.EventDirector,LOD.MazeNavigator
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function edge(a,b) a,b=key(a),key(b);return a<b and a..'|'..b or b..'|'..a end
local g={Cells={},Progression={Gates={}}};local cells={}
for i=1,6 do cells[i]={x=i,y=1,z=0,neighbors={}};g.Cells[key(cells[i])]=cells[i] end
for i=1,5 do cells[i].neighbors[key(cells[i+1])]=true;cells[i+1].neighbors[key(cells[i])]=true end
g.Progression.Gates[1]={edgeKey=edge(cells[5],cells[6])}
local s={Graph=g,BuildReady=true,CampaignEpoch=1,RunId='run',Level=1,LevelSeed=10,GatesOpen={true}}
Run.State=s
local context={graph=g,state=s,epoch=1,token='one',byId={},plan={instances={}}}
D.Context=context
for i=1,4 do
    local event={id='event:'..i,contract='BLOCKADE',token='one',runId='run',level=1,levelSeed=10,
        state='active',placement={edgeKey=edge(cells[i],cells[i+1])}}
    context.plan.instances[i]=event;context.byId[event.id]=event
end
local function legacySignature()
    local out={D.Context.token}
    for _,i in ipairs(D.Context.plan.instances) do
        if i.contract=='BLOCKADE' and D:IsCurrent(i) then out[#out+1]=i.id..':'..i.state end
    end
    return table.concat(out,'|')
end
local queries=0
-- Every combination, both ordinary-gate states, every ordered pair of cells.
for mask=0,15 do
    for i,event in ipairs(context.plan.instances) do event.state=math.floor(mask/2^(i-1))%2==1 and 'active' or 'resolved' end
    local actual,token=D:RouteSignature(g)
    assert(actual==mask and token=='one','route classification differs')
    for gate=0,1 do
        s.GatesOpen[1]=gate==1
        for a=1,6 do for b=1,6 do
            local reachable=true
            for i=math.min(a,b),math.max(a,b)-1 do
                if i==5 and gate==0 or i<5 and math.floor(mask/2^(i-1))%2==1 then reachable=false end
            end
            assert(N:Distance(g,cells[a],cells[b])==(reachable and math.abs(a-b) or math.huge),'stale/wrong distance')
            local path=N:FindPath(g,cells[a],cells[b])
            assert((path~=nil)==reachable and (not path or #path==math.abs(a-b)+1),'stale/wrong path')
            queries=queries+1
        end end
    end
end
local first=context.plan.instances[1]
first.state='creating'
N:Distance(g,cells[1],cells[6]);local cache=g.LODPhaseZeroNavCache
first.state='active';N:Distance(g,cells[1],cells[6])
assert(g.LODPhaseZeroNavCache==cache,'same blocked/open state rebuilt navigation')
first.state='resolved';assert(N:Distance(g,cells[1],cells[2])==1)
assert(g.LODPhaseZeroNavCache~=cache,'resolution must invalidate in the same tick')
first.state='active';assert(N:Distance(g,cells[1],cells[2])==math.huge)
context.byId[first.id]=nil;assert(N:Distance(g,cells[1],cells[2])==1,'lost ownership remained blocked')
context.byId[first.id]=first
for _,field in ipairs({'Failed','LevelCleared'}) do
    s[field]=true;assert(N:Distance(g,cells[1],cells[6])==5,field..' stale cache')
    s[field]=false;assert(N:Distance(g,cells[1],cells[6])==math.huge)
end
s.BuildReady=false;assert(N:Distance(g,cells[1],cells[6])==5)
s.BuildReady=true;assert(N:Distance(g,cells[1],cells[6])==math.huge)
s.CampaignEpoch=2;assert(N:Distance(g,cells[1],cells[6])==5)
s.CampaignEpoch=1;assert(N:Distance(g,cells[1],cells[6])==math.huge)
cache=g.LODPhaseZeroNavCache
context.token='two';for _,event in ipairs(context.plan.instances) do event.token='two' end
assert(N:Distance(g,cells[1],cells[6])==math.huge and g.LODPhaseZeroNavCache~=cache,'new context reused old routes')
local clone={Cells=g.Cells,Progression=g.Progression}
assert(D:RouteSignature(clone)==0,'foreign graph inherited event mask')
assert(N:Distance(clone,cells[1],cells[6])==5,'foreign graph inherited blocked path')
assert(not N:FindPath(g,cells[1],cells[6],function(c) return c~=cells[3] end),'filtered path bypassed exclusion')

-- Count actual signature construction; compare the frozen parent algorithm.
local concat=table.concat;local joins=0
table.concat=function(...) joins=joins+1;return concat(...) end
for _=1,10000 do legacySignature() end
local before=joins
for _=1,10000 do D:RouteSignature(g) end
table.concat=concat
assert(before==10000 and joins==before,'hot route query still builds text')
D.Context=nil;assert(D:RouteSignature(g)==0 and N:Distance(g,cells[1],cells[6])==5,'cleanup retained event route state')
print(string.format('QUANTIZED_ROUTES_PASS: %d paired route states/pairs; same-tick resolution, gates, ownership, failure, epoch, context, graph, cleanup; 10000 signature text joins -> 0',queries))
