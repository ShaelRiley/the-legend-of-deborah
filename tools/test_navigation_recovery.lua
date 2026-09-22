-- Real waypoint compiler, motion kernel and summon service; native entities doubled.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local V=getmetatable(Vector())
V.__div=function(a,b) return a*(1/b) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
LOD.RPGStatusElements={CanMoveVoluntarily=function() return true end,
    LocomotionMultiplier=function() return 1 end,ObserveCell=function() end}
dofile(root..'sv_hostile_motion_v2.lua')
local M,N=LOD.HostileMotionV2,LOD.MazeNavigator
M.FaceToward=function() end
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_magic_summon/init.lua')
local summonClass=ENT
local key=LOD.MazeGenerator.CellKey
local function actor(cell)
    local a=env.actor(1)
    a:SetPos(N:CellCenter(cell)+Vector(0,0,2))
    a.GetAngles=function() return {y=0} end
    a._AdvanceWaypoint=nil
    a.LODConfig={speed=165};a.LODWaypoints={};a.LODWaypointIndex=1
    return a
end
for _,direction in ipairs({'E','N','W','S'}) do
    local lower={x=3,y=3,z=0,neighbors={}}
    local upper={x=3,y=3,z=1,neighbors={}}
    lower.neighbors[key(3,3,1)]=true;upper.neighbors[key(3,3,0)]=true
    local graph={Cells={[key(3,3,0)]=lower,[key(3,3,1)]=upper},
        VerticalEdges={{a=lower,b=upper,LODStairDirection=direction}},Progression={Gates={}}}
    LOD.RunManager.State.Graph=graph
    for _,ascending in ipairs({true,false}) do
        local from,to=ascending and lower or upper,ascending and upper or lower
        local route=N:PathToWaypoints(graph,{from,to})
        local a,target=actor(from),actor(to)
        setmetatable(a,{__index=summonClass})
        a:SetPos(route[1].pos);a.LODWaypoints=route;a.LODWaypointIndex=1
        local time=100;a.LODMotionLastUpdate=time
        local index=1
        for tick=1,600 do
            time=time+.05;env.setTime(time)
            a:_RouteTo(graph,target)
            assert(a.LODWaypoints==route,'Summon reset the flight during periodic route refresh')
            local wp=a:_AdvanceWaypoint()
            assert(a.LODWaypointIndex>=index,'Stair progress moved backwards')
            index=a.LODWaypointIndex
            if not wp then break end
            M:MoveToward(a,wp)
        end
        assert(a.LODWaypointIndex>#route,'Summon never finished the stair flight')
        assert(math.abs(a:GetPos().z-route[#route].pos.z)<18,'Wrong landing elevation')
    end
    local a=actor(lower)
    local center=N:CellCenter(lower)
    local safe=M:CellFloorPoint(lower,center+Vector(999,999,0))
    local inside=LOD.Config.Maze.CellSize*.5-LOD.Config.Geometry.ContainerWidth*.5
    assert(math.abs(safe.x-center.x)+16<inside and math.abs(safe.y-center.y)+16<inside,
        'Local pursuit embeds a humanoid hull inside a closed container')
    a.LODRosterPlacement={pos=center+Vector(100,0,100),wallLane={side=1}}
    M:SnapSpawn(a)
    assert(a:GetPos().z==center.z+100 and a.LODWallInitialized,'Spawn settlement flattened a Climber lane')
end
-- The service commits stair travel before its ordinary charge/target decisions.
local a=actor({x=3,y=3,z=0});setmetatable(a,{__index=summonClass})
a.LODCaster={valid=true};a.LODExpiresAt=9999
a.LODWaypoints={{pos=a:GetPos()+Vector(20,0,20),stair=true,tolerance=1}}
a._RunCharge=function() error('Charge interrupted a committed stair flight') end
a._RunRetreat=function() error('Retreat interrupted a committed stair flight') end
a.LODMotionLastUpdate=CurTime()-.05
LOD.RunManager.State.Failed=false;LOD.RunManager.State.LevelCleared=false
a:_BehaviourTick()
print('NAVIGATION_RECOVERY_PASS: eight complete bidirectional flights, four stair orientations, route retention, charge exclusion, container hull clearance, direct Climber lane settlement')
