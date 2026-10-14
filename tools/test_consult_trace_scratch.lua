-- Real roster predicates: identical geometry admission with bounded allocations.
local H=dofile('tools/test_bestiary_b7.lua')
local E=LOD.EnemyRoster
H.reset();local e=H.actor('reaper');local hero=H.hero
local originalVector=Vector;local vectors=0
Vector=function(...) vectors=vectors+1;return originalVector(...) end
local from,to=originalVector(0,0,2),originalVector(10,0,2)
e.WorldSpaceCenter=function() return from end;hero.WorldSpaceCenter=function() return to end
local request,output,filter
local inside=false;local nested=0
util.TraceLine=function(row)
 assert(row.owner==e and row.filter(e)==false and row.filter({LODHostile=true})==false)
 if not inside then
  request=request or row;output=output or row.output;filter=filter or row.filter
  assert(row==request and row.output==output and row.filter==filter,'scratch allocation recurred')
  if nested==0 then
   inside=true
   local other=H.actor('fencer');other.WorldSpaceCenter=function() return from end
   local native=util.TraceLine
   util.TraceLine=function(inner)
    assert(inner~=row and inner.output~=row.output and inner.owner==other)
    assert(row.owner==e and not row.filter(e))
    inner.output.Hit=true;inner.output.Entity=hero
   end
   assert(E:Visible(other,hero));util.TraceLine=native;inside=false;nested=nested+1
  end
 end
 row.output.Hit=true;row.output.Entity=hero
 -- Engine output-only form: never rely on an allocated return table.
end
assert(E:Visible(e,hero))
local startVectors=vectors
for i=1,10000 do assert(E:Visible(e,hero)) end
assert(vectors==startVectors,'steady visibility allocated vectors')
assert(request.owner==nil and request.start==nil and next(output)==nil,'trace retained actor/result')
util.TraceLine=function(row) assert(next(row.output)==nil);return {Hit=true,Entity={}} end
assert(not E:Visible(e,hero),'blocked sight admitted')
util.TraceLine=function() error('native trace failure') end
assert(not pcall(E.Visible,E,e,hero));assert(request.owner==nil,'error retained actor')
util.TraceLine=function(row) assert(row==request);return {Hit=false} end
assert(E:Visible(e,hero),'error leaked nesting depth')
local hull,mins,maxs
util.TraceHull=function(row)
 hull=hull or row;mins=mins or row.mins;maxs=maxs or row.maxs
 assert(row==hull and row.mins==mins and row.maxs==maxs)
 assert(row.filter({IsPlayer=function() return true end})==false)
 return {Hit=false,StartSolid=false,AllSolid=false}
end
startVectors=vectors
for i=1,10000 do assert(E:MeleeRouteClear(e,from,to)) end
assert(vectors==startVectors and request.mins==nil and request.maxs==nil)
util.TraceHull=function(row) row.output.StartSolid=true end
assert(not E:MeleeRouteClear(e,from,to),'embedded hull admitted')
util.TraceHull=function(row) assert(next(row.output)==nil) end
assert(E:MeleeRouteClear(e,from,to),'stale embedded result survived')
print('CONSULT_TRACE_SCRATCH_PASS 20000 predicates reuse request/output/filter/hull vectors; nested actor isolation, output-only and allocated native results, blocked/embedded/error cleanup; collision checks retained; native FPS unmeasured')
