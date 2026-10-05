-- Exact legacy BFS path oracle, including deterministic ties and sanctuary,
-- through the production bounded navigation cache. Native boundaries doubled.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
LOD={Config={Maze={},Geometry={}},RunManager={State={}},MazeBuilder={}}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
isstring=function(v) return type(v)=='string' end
IsValid=function() return false end
Vector=function(x,y,z) return {x=x,y=y,z=z} end
hook={Add=noop};concommand={Add=noop};ents={FindByClass=function() return {} end}
scripted_ents={GetStored=noop};CurTime=function() return 1 end
local tests,filterVisits=0,0
LOD.EntrySafety={HostilePathCell=function(_,g,c)
    filterVisits=filterVisits+1
    return not (g.EntrySafety and g.EntrySafety.cells[LOD.MazeGenerator.CellKey(c.x,c.y,c.z)])
end}
dofile(root..'sv_maze_navigator.lua')
local N=LOD.MazeNavigator
local legacy=N.FindPath
dofile(root..'sv_phase_zero_runtime_optimization.lua')
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function signature(path)
    if not path then return 'none' end
    local t={};for _,c in ipairs(path) do t[#t+1]=key(c) end;return table.concat(t,'|')
end
local function graph(size)
    local g={Cells={},Progression={Gates={}},EntrySafety={cells={}}}
    local cells={}
    for y=1,size do for x=1,size do
        local c={x=x,y=y,z=0,neighbors={}};g.Cells[key(c)]=c;cells[#cells+1]=c
    end end
    for _,c in ipairs(cells) do for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local nextKey=(c.x+d[1])..':'..(c.y+d[2])..':0'
        if g.Cells[nextKey] then c.neighbors[nextKey]=true end
    end end
    return g,cells
end
local g,cells=graph(6)
LOD.RunManager.State.Graph=g;LOD.RunManager.State.GatesOpen={false}
g.Progression.Gates[1]={edgeKey=N:EdgeKey(cells[3],cells[4])}
local eventMask=0
LOD.EventDirector={RouteSignature=function() return eventMask,'current' end,
    BlocksEdge=function(_,_,edge) return eventMask==1 and edge==N:EdgeKey(cells[18],cells[24]) end}
local function compare()
    for _,a in ipairs(cells) do for _,b in ipairs(cells) do
        local old=legacy(N,g,a,b,function(c) return LOD.EntrySafety:HostilePathCell(g,c) end)
        assert(signature(N:FindHostilePath(g,a,b))==signature(old),'path/tie/sanctuary changed')
        tests=tests+1
    end end
end
compare()
g.EntrySafety.cells[key(cells[8])]=true
-- Production Build replaces graph.EntrySafety as a unit; no mutable anonymous
-- predicate is cached. Replacing only the cells table is also explicitly safe.
g.EntrySafety={cells=g.EntrySafety.cells};compare()
g.EntrySafety.cells={[key(cells[7])]=true,[key(cells[8])]=true,[key(cells[9])]=true};compare()
LOD.RunManager.State.GatesOpen[1]=true;compare()
eventMask=1;compare();eventMask=0;compare()
local cache=g.LODPhaseZeroNavCache
local oldFilter=LOD.EntrySafety.HostilePathCell
LOD.EntrySafety.HostilePathCell=function(_,_,c) return c~=cells[15] end
compare();assert(g.LODPhaseZeroNavCache~=cache,'filter replacement retained a tree')
LOD.EntrySafety.HostilePathCell=oldFilter
assert(not N:FindHostilePath(g,nil,cells[1]) and not N:FindHostilePath(g,cells[1],{x=0,y=0,z=0}))
-- Arbitrary predicates stay live/uncached, including a changing captured value.
local excluded=cells[2]
local allow=function(c) return c~=excluded end
assert(signature(N:FindPath(g,cells[1],cells[3],allow))==signature(legacy(N,g,cells[1],cells[3],allow)))
excluded=cells[7]
assert(signature(N:FindPath(g,cells[1],cells[3],allow))==signature(legacy(N,g,cells[1],cells[3],allow)))
-- Stable patrol/chase requests on a loaded graph, same source/goal sequences.
g,cells=graph(21);g.EntrySafety.cells[key(cells[1])]=true
LOD.RunManager.State.Graph=g
eventMask=0
filterVisits=0;local before=os.clock()
for _=1,30 do for i=1,64 do legacy(N,g,cells[i+21],cells[441-i],function(c) return oldFilter(LOD.EntrySafety,g,c) end) end end
local legacyVisits,legacySeconds=filterVisits,os.clock()-before
filterVisits=0;before=os.clock()
for _=1,30 do for i=1,64 do N:FindHostilePath(g,cells[i+21],cells[441-i]) end end
local cachedVisits,cachedSeconds=filterVisits,os.clock()-before
assert(cachedVisits<legacyVisits/10,'stable requests still rebuild filtered BFS')
-- Unfiltered+hostile caches share the original TOTAL 72-tree bound.
for i=1,100 do N:FindPath(g,cells[i],cells[441]);N:FindHostilePath(g,cells[i],cells[441]) end
local n=0;for _ in pairs(g.LODPhaseZeroNavCache.trees) do n=n+1 end
for _ in pairs(g.LODPhaseZeroNavCache.hostileTrees) do n=n+1 end
assert(n<=72 and #g.LODPhaseZeroNavCache.order<=72,'combined tree bound exceeded')
local clone={Cells=g.Cells,Progression=g.Progression,EntrySafety={cells={[key(cells[441])]=true}}}
assert(not N:FindHostilePath(clone,cells[23],cells[441]),'graph replacement leaked a route')
print(string.format('HOSTILE_ROUTE_CACHE_PASS exact_path_cases=%d requests=1920 legacy_filter_visits=%d cached_filter_visits=%d legacy_lua_seconds=%.6f cached_lua_seconds=%.6f total_tree_limit=72 native_fps_measured=false',tests,legacyVisits,cachedVisits,legacySeconds,cachedSeconds))
