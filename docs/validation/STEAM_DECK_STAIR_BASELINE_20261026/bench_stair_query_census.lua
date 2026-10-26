assert(SERVER and LOD.HostileMotionV2 and LOD.HostileRegistry)
local M=LOD.HostileMotionV2; local state=assert(LOD.RunManager.State)
local rows={}; local qcount,native,empty=0,0,0
local function intersects(a,b,lo,hi,c,d)
 return math.min(a.x,b.x)+lo.x<=d.x+2 and math.max(a.x,b.x)+hi.x>=c.x-2
 and math.min(a.y,b.y)+lo.y<=d.y+2 and math.max(a.y,b.y)+hi.y>=c.y-2
 and math.min(a.z,b.z)+lo.z<=d.z+2 and math.max(a.z,b.z)+hi.z>=c.z-2
end
local function query(e,a,b,kind)
 qcount=qcount+1;local tr=M:TraceStairMovement(e,a,b);if not tr then return end;native=native+1
 local index=assert(state.Graph.LODHostileStairCollision);local lo,hi=e:GetCollisionBounds();local count=0
 for _,f in ipairs(index.flights)do for _,solid in ipairs(f.solids)do if IsValid(solid)then
  local pos=solid:GetPos();local sl,sh=solid:GetCollisionBounds();if intersects(a,b,lo,hi,pos+sl,pos+sh)then count=count+1 end
 end end end
 if count==0 then empty=empty+1 end
 rows[#rows+1]={entity=e:EntIndex(),archetype=e.LODArchetypeId,kind=kind,actual_solid_aabb_candidates=count,hit=tr.Hit,start_solid=tr.StartSolid,all_solid=tr.AllSolid}
end
local actors=0;local stair=0
for _,e in ipairs(LOD.HostileRegistry:List())do if IsValid(e)and not e.LODDead then
 actors=actors+1;local wp=(e.LODWaypoints or{})[e.LODWaypointIndex or 1]
 if wp and wp.pos then
  if wp.stair then stair=stair+1 else
   query(e,wp.pos,wp.pos,'current-flat-waypoint-point')
   local a=e:GetPos();local delta=wp.pos-a;delta.z=0;local length=delta:Length()
   if length>.05 then local b=a+delta*(math.min(length,math.max(1,(e.LODConfig or{}).speed or 90)*.05)/length);b.z=wp.pos.z;query(e,a,b,'nominal-50ms-step')end
  end
 end
end end
local result={level=state.Level,actors=actors,stair_waypoints=stair,queries=qcount,native_traces=native,provably_empty_conservative_aabb_queries=empty,rows=rows,seconds=SysTime(),scope='One out-of-FPS read-only snapshot of current flat waypoints and nominal 50ms unmodified-speed steps. Actual public TraceStairMovement called without wrappers; actual generated collision bounds with 2-unit conservative padding. Not actual production call frequency, timings, per-rendered-frame cost, throughput or overhead evidence; does not cover dynamic status speed or future combat positions. No actor/resource/AI/provider writes.'}
file.Write('legend_of_deborah/bench_stair_query_census.json',util.TableToJSON(result,true))
print('LOD_STAIR_QUERY_CENSUS',actors,qcount,native,empty)
