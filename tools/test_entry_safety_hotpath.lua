-- Production sanctuary queries; native vector access, ownership and time are
-- doubled. Optional parent source enables a paired, unchanged-code comparison.
local parentPath=arg[1]
local savedArg=arg[1];arg[1]='--runtime'
local H=dofile('tools/test_bestiary_b29.lua');arg[1]=savedArg
local S,g,N,R=H.S,H.graph,LOD.MazeNavigator,H.X.R
R.State.Graph=g;S:Context()
local parent
if parentPath then
    local f=assert(io.open(parentPath));local source=f:read('*a');f:close()
    parent={}
    local isolatedLOD=setmetatable({EntrySafety=parent},{__index=LOD})
    local env=setmetatable({LOD=isolatedLOD},{__index=_G})
    assert(load(source,'@entry-safety-parent','t',env))()
end
local m=LOD.Config.Maze
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local checks,reads=0,0
local function position(x,y,z)
    local values={x=x,y=y,z=z}
    return setmetatable({}, {__index=function(_,axis)
        assert(values[axis]~=nil,'unexpected native position access')
        reads=reads+1;return values[axis]
    end}),values
end
local cells={g.Start,H.cell(2),H.cell(4),H.cell(6),H.cell(24)}
for _,c in ipairs(cells) do
    local center=N:CellCenter(c);local half=m.CellSize*.5
    for _,dx in ipairs({-half-.001,-half,-half+.001,0,half-.001,half,half+.001}) do
        for _,dy in ipairs({-half-.001,-half,-half+.001,0,half-.001,half,half+.001}) do
            for _,dz in ipairs({-24.001,-24,-23.999,12,m.LevelHeight-24-.001,m.LevelHeight-24,m.LevelHeight-24+.001}) do
                local p=position(center.x+dx,center.y+dy,center.z+dz)
                local actual=S:ExactCell(g,p)
                if parent then assert(actual==parent:ExactCell(g,p),'parent/candidate cell disagreement') end
                if math.abs(dx)<half and math.abs(dy)<half and dz>=-24 and dz<m.LevelHeight-24 then
                    assert(actual==g.Cells[key(c)],'interior/vertical half-open cell membership changed')
                end
                for _,padding in ipairs({0,24,96}) do
                    local protected=S:ProtectedPosition(p,padding)
                    local expected=false
                    for _,v in ipairs(g.EntrySafety.centers) do
                        if math.abs(center.x+dx-v.x)<=half+padding and math.abs(center.y+dy-v.y)<=half+padding
                            and center.z+dz>=v.z-24 and center.z+dz<v.z+m.LevelHeight-24 then expected=true;break end
                    end
                    assert(protected==expected,'sanctuary boundary/padding disagreement')
                    if parent then assert(protected==parent:ProtectedPosition(p,padding),'parent/candidate sanctuary disagreement') end
                    checks=checks+1
                end
            end
        end
    end
end
assert(not S:ExactCell(nil,Vector()) and not S:ExactCell(g,nil))
assert(not S:ExactCell(g,Vector(1e9,1e9,1e9)),'nearest-cell fallback admitted staging')

-- Same native object, mutated scalars: no cross-call membership/owner cache.
local center=N:CellCenter(g.Start)
local p,v=position(center.x,center.y,center.z+12)
assert(S:ExactCell(g,p)==g.Cells[key(g.Start)] and S:ProtectedPosition(p))
v.z=center.z+m.LevelHeight*10;assert(not S:ExactCell(g,p) and not S:ProtectedPosition(p))
v.z=center.z+12
local cellKey=key(g.Start);local original=g.Cells[cellKey]
g.Cells[cellKey]=nil;assert(not S:ExactCell(g,p));g.Cells[cellKey]=original
local oldCenters=g.EntrySafety.centers
g.EntrySafety.centers={};assert(not S:ProtectedPosition(p));g.EntrySafety.centers=oldCenters
local originalOrigin=m.Origin;m.Origin=originalOrigin+Vector(1e6,1e6,1e6)
assert(not S:ExactCell(g,p));m.Origin=originalOrigin
local oldSize=m.CellSize;m.CellSize=oldSize/2
local edge=Vector(center.x+oldSize*.45,center.y,center.z+12)
local fresh=S:ProtectedPosition(edge)
if parent then assert(fresh==parent:ProtectedPosition(edge),'config mutation stale') end
m.CellSize=oldSize

local function proxy(owner)
    return {valid=true,owner=owner,IsPlayer=function()return false end,GetOwner=function(e)return e.owner end}
end
local hero=H.actor('hotpath-hero',4)
local hostile=H.actor('hotpath-hostile',4,true)
local one=proxy(hero);local chain=proxy(proxy(proxy(hero)));local four=proxy(chain);local five=proxy(four)
local cycle=proxy();cycle.owner=cycle
local invalid=proxy();invalid.valid=false
local sourceCases={{hero,hero},{hostile,hostile},{one,hero},{chain,hero},{four,hero},{five,chain.owner.owner},
    {cycle,false},{invalid,false},{proxy(),false}}
-- An unowned valid proxy resolves to itself, preserving the native contract.
sourceCases[#sourceCases][2]=sourceCases[#sourceCases][1]
for i,case in ipairs(sourceCases) do
    local actual=S:Source(case[1]);assert(actual==(case[2] or nil),'owner/source/four-hop contract case '..i)
    if parent then assert(actual==parent:Source(case[1]),'parent/candidate source disagreement') end
end
one.owner=hostile;assert(S:Source(one)==hostile)
hostile.valid=false;assert(not S:Source(hostile) and S:Source(one)==one);hostile.valid=true

-- Native component work is measured against the same fixed position, not time.
local far=position(center.x+1e6,center.y+1e6,center.z+12)
local function nativeReads(authority)
    local initial=reads
    for _=1,10000 do assert(not authority:ProtectedPosition(far)) end
    return reads-initial
end
local candidateReads=nativeReads(S)
assert(candidateReads==10000,'membership repeats native position-component reads')
local parentReads=parent and nativeReads(parent)
if parent then assert(candidateReads<parentReads,'unchanged parent did not fail reduced-work gate') end
local inside=position(center.x,center.y,center.z+12)
reads=0;assert(S:ExactCell(g,inside)==g.Cells[key(g.Start)] and reads==3,'exact cell repeats native position reads')
local function allocation(authority)
    collectgarbage('collect');collectgarbage('stop')
    local before=collectgarbage('count')
    for i=1,50000 do assert(authority:Source(i%2==0 and hero or hostile)==(i%2==0 and hero or hostile)) end
    local delta=collectgarbage('count')-before
    collectgarbage('restart');collectgarbage('collect');return delta
end
local candidateKB=allocation(S)
assert(candidateKB<16,'direct combat sources still allocate owner-cycle tables')
local parentKB=parent and allocation(parent)
if parent then assert(candidateKB<parentKB*.1,'unchanged parent did not fail allocation gate') end

-- Empty admission must still perform live service/context calls before return.
local service,context=S.Service,S.Context
local serviceCalls,contextCalls=0,0
S.Service=function(self)serviceCalls=serviceCalls+1;self.Active={} end
S.Context=function()contextCalls=contextCalls+1;return R.State,g,g.EntrySafety end
local target,limited=S:Claim(hostile)
assert(target==nil and limited==false and serviceCalls==1 and contextCalls==1,'empty admission skipped live ownership/service')
S.Service,S.Context=service,context
S:Reset();S:Context();S:Service()
-- An active Hero elsewhere must still receive every current distance query,
-- without allocating a nearby array when no record qualifies for admission.
local function farClaims(authority)
    local oldService,oldContext,oldDistance=authority.Service,authority.Context,authority.MemberDistance
    local oldActive=authority.Active;local distances=0
    authority.Active={{}}
    authority.Service=function()end
    authority.Context=function()return R.State,g,g.EntrySafety end
    authority.MemberDistance=function()distances=distances+1;return math.huge end
    collectgarbage('collect');collectgarbage('stop')
    local before=collectgarbage('count')
    for _=1,10000 do local t,l=authority:Claim(hostile);assert(t==nil and l==false) end
    local delta=collectgarbage('count')-before
    collectgarbage('restart');collectgarbage('collect')
    authority.Service,authority.Context,authority.MemberDistance,authority.Active=oldService,oldContext,oldDistance,oldActive
    assert(distances==10000,'far admission retained stale distance or skipped active queries')
    return delta
end
local farKB=farClaims(S);assert(farKB<16,'far admission still allocates an empty nearby array')
local parentFarKB=parent and farClaims(parent)
if parent then assert(farKB<parentFarKB*.1,'unchanged parent passed empty-array work gate') end
local finalParentReads=parentReads or -1;local finalParentKB=parentKB or -1
print(string.format('ENTRY_HOTPATH_PASS boundaries=%d direct_sources=50000 native_reads=%d parent_reads=%d allocation_kb=%.3f parent_kb=%.3f far_claim_kb=%.3f parent_far_kb=%.3f; immediate mutations, four-hop/cycle/invalid ownership, live empty/far admission',
    checks,candidateReads,finalParentReads,candidateKB,finalParentKB,farKB,parentFarKB or -1))
