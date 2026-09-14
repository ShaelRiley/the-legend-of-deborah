-- Production geometry, scan and client notification; Source boundaries only are faked.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local hooks,timers,events={},{},{}
local now=10
function CurTime() return now end
function IsValid(v) return type(v)=='table' and v.valid end
function math.NormalizeAngle(v) return (v+180)%360-180 end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
local vector={};vector.__index=vector
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vector) end
function vector.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vector_origin=Vector()
hook={Add=function(event,id,fn) hooks[id]=fn end}
timer={Create=function(id,_,_,fn) timers[id]=fn end}
concommand={Add=function() end}
util={AddNetworkString=function() end,TraceLine=function(spec) return {Hit=spec.endpos.blocked==true} end}
net={Receive=function() end}
local state={featIds={'WIS_SPATIAL_AWARENESS'}}
local ply={valid=true,alive=true,IsPlayer=function() return true end,Alive=function(self) return self.alive end,
    GetPos=function() return Vector() end,EyePos=function() return Vector() end,EyeAngles=function() return {y=0} end}
player={GetHumans=function() return {ply} end}
local hostiles={}
LOD={RPG={IdentityCatalog={OrdinaryFeats={}}},Config={Maze={CellSize=384,LevelHeight=384,Origin=Vector()}},
    RunManager={State={LevelSeed=1}},HostileRegistry={List=function() return hostiles end},
    RPGAbilityRules={ProgressionState=function() return state end,Derived=function() return {wisMod=3} end},
    CombatRolls={_Send=function(_,recipient,_,text,family,fields)
        assert(recipient==ply and family=='awareness' and fields.position)
        events[#events+1]={text=text,fields=fields}
    end}}
dofile(root..'sv_rpg_checkpoint_d_wis_information_feats.lua')
local RPG=LOD.RPG
local ok,errors=RPG:ValidateCheckpointDWisInformationFeats();assert(ok,table.concat(errors,','))
for _,mod in ipairs({-3,1,2,3,4,5}) do
    for _,yaw in ipairs({0,90,180,270}) do
        local offsets=RPG:CheckpointDWisRearOffsets(mod,yaw)
        local depth=math.max(1,mod)
        assert(#offsets==depth*3+2*math.ceil(depth/2),'rounded-up side range')
        local seen={}
        for _,v in ipairs(offsets) do
            local key=v.x..':'..v.y;assert(not seen[key]);seen[key]=true
            if v.direction~='BEHIND YOU' then assert(v.depth<=math.ceil(depth/2)) end
        end
    end
end
local function enemy(id,x,y,z)
    return {valid=true,LODHostile=true,LODArchetypeId='shambler',pos=Vector(x*384,y*384,(z or 0)*384),
        GetPos=function(self) return self.pos end,WorldSpaceCenter=function(self) return self.pos end,
        EntIndex=function() return id end,Health=function() return 10 end}
end
local rear,left,right,front,far,floor=enemy(1,-2,0),enemy(2,0,2),enemy(3,0,-2),enemy(4,1,0),enemy(5,0,3),enemy(6,-1,0,1)
hostiles={rear,left,right,front,far,floor}
local found=RPG:CheckpointDWisRearHostiles(ply,3)
assert(#found==3 and found[1].entity==rear,'only rear/side rays on current floor')
local tick=timers.LOD_CheckpointDWisInformation
tick();assert(#events==1 and events[1].text:find('BEHIND YOU: SHAMBLER',1,true))
tick();assert(#events==1,'same selected monster does not spam')
rear.pos=Vector(-3*384,0,0);tick();assert(#events==1,'retain selected monster when another becomes nearer')
rear.pos.blocked=true;tick();assert(#events==2 and events[2].text:find('LEFT: SHAMBLER',1,true))
left.pos.blocked=true;tick();assert(#events==3 and events[3].text:find('RIGHT: SHAMBLER',1,true))
right.pos.blocked=true;tick();assert(#events==3,'blocked monsters do not alert')
right.pos.blocked=false;tick();assert(#events==4,'reacquisition after occlusion')
ply.alive=false;tick();ply.alive=true;tick();assert(#events==5,'death/respawn resets selection')
state={featIds={}};tick();state={featIds={'WIS_SPATIAL_AWARENESS'}};tick();assert(#events==6,'new incarnation resets selection')
LOD.RunManager.State.LevelSeed=2;tick();assert(#events==7,'level boundary resets selection')
function LocalPlayer() return ply end
function ScrW() return 1280 end;function ScrH() return 800 end
local polygons=0
draw={NoTexture=function() end}
surface={SetDrawColor=function() end,DrawPoly=function() polygons=polygons+1 end}
LOD.UI={HUDRoles={awareness={r=195,g=130,b=255}}}
dofile(root..'cl_rpg_wis_information.lua')
local info=LOD.RPGWisInformation
for _,case in ipairs({{Vector(0,384,0),'left'},{Vector(0,-384,0),'right'},{Vector(-384,0,0),'rear'}}) do
    local x,y=info:AwarenessScreenPoint(ply,case[1],1280,800)
    assert(case[2]=='left' and x<640 or case[2]=='right' and x>640 or case[2]=='rear' and y>400)
end
info:OnFeedback({family='awareness',position=right.pos});hooks.LOD_SpatialAwarenessLight()
assert(polygons==3,'small layered violet light')
now=12;hooks.LOD_SpatialAwarenessLight();assert(not info.Awareness,'light expires without tracking')
info:OnFeedback({family='awareness',position=right.pos});hooks.LOD_SpatialAwarenessClear();assert(not info.Awareness)
print('WIS_INFORMATION_HARNESS_PASS: production geometry, LOS, selection, lifecycle and directional light')
