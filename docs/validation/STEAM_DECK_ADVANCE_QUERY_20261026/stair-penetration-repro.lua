-- Boundary-double control-flow reproduction ONLY; not native stair/physics proof.
local env=dofile('tools/test_enemy_update.lua')
local V=getmetatable(Vector());V.__div=function(a,b)return a*(1/b)end
function V:Length2D()return math.sqrt(self.x*self.x+self.y*self.y)end
LOD.RPGStatusElements=nil;LOD.RPGAbilityRules=nil;LOD.HostileAnimation=nil
LOD.EntrySafety=nil;LOD.MagicForms=nil
LOD.BossEncounter={Hull=function()return Vector(-1,-1,0),Vector(1,1,2)end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_motion_v2.lua')
local M=LOD.HostileMotionV2;M.FaceToward=function()end
env.setTime(100)
local calls=0
util.TraceHull=function(row)
 calls=calls+1
 return {Hit=true,StartSolid=false,AllSolid=false,HitPos=Vector(.5,0,0)}
end
for _,kind in ipairs({'ordinary','warden','hector','neil','generic_boss'})do
 local e=env.actor(1);e:SetPos(Vector());e.LODHostile=true;e.LODConfig={speed=100}
 e.LODMotionLastUpdate=99.95;e.LODDead=false
 if kind=='warden' then e.LODWarden=true;e.LODArchetypeId='warden';e.LODWardenOwner={}
 elseif kind=='hector' then e.LODHector=true;e.LODArchetypeId='hector';e.LODHectorEncounter={}
 elseif kind=='neil' then e.LODNeilBrute=true;e.LODArchetypeId='neil'
 elseif kind=='generic_boss' then e.LODBossEncounter=true end
 local before=calls;M:MoveToward(e,{pos=Vector(10,0,0),stair=false})
 local x=e:GetPos().x;local traced=calls-before
 if kind=='generic_boss' then assert(traced==1 and x==.5,'generic boss did not honor mocked obstruction')
 else assert(traced==0 and x>1,'expected unchecked manual step did not reproduce')end
 print(('STAIR_BOUNDARY_REPRO kind=%s traceCalls=%d finalX=%.3f crossedMockWall=%s'):format(kind,traced,x,tostring(x>1)))
end
print('QUALIFIED_REPRO_PASS: ordinary and legacy boss movement bypasses mocked stair collision; generic BossEncounter respects it. This is NOT native physics, rendered-stair, or gameplay validation.')
