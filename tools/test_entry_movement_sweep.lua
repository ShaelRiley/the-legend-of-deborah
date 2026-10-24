-- Differential geometry oracle frozen from pre-scalar movement admission.
-- Retains the original per-axis tables; production uses allocation-free scalars.
local saved=arg[1];arg[1]='--runtime';local H=dofile('tools/test_bestiary_b29.lua');arg[1]=saved
local S,g,R=H.S,H.graph,H.X.R
local P=setmetatable({Stats={movementDenied=0},Config={}},{__index=S})
for k,v in pairs(S.Config)do P.Config[k]=v end
local function key(c)return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z)end
function P:MovementAllowed(e,from,to)
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
R.State.Graph=g;S:Context();P:Context()
local nativeMeta=getmetatable(Vector())
isvector=function(v)return type(v)=='table'and getmetatable(v)==nativeMeta end
local e=H.actor('sweep-hostile',24,true);e.LODHostile=true
local checks=0
local function compare(from,to)
 local a,b=S.Stats.movementDenied,P.Stats.movementDenied
 local actual,expected=S:MovementAllowed(e,from,to),P:MovementAllowed(e,from,to)
 assert(actual==expected,'swept sanctuary admission differs at case '..checks)
 assert(S.Stats.movementDenied-a==P.Stats.movementDenied-b,'denial accounting differs')
 checks=checks+1
end
local center=g.EntrySafety.centers[1];local half=LOD.Config.Maze.CellSize*.5+S.Config.HullMargin
local axes={'x','y','z'}
for _,axis in ipairs(axes)do
 for _,face in ipairs({-1,1})do
  for _,offset in ipairs({-1,-.0001,0,.0001,1})do
   local a,b=Vector(center.x,center.y,center.z),Vector(center.x,center.y,center.z)
   local lo,hi=axis=='z'and -96 or -half,axis=='z'and LOD.Config.Maze.LevelHeight-24 or half
   a[axis]=center[axis]+(face<0 and lo or hi)+offset
   for _,delta in ipairs({-1000,-.00010001,-.0001,-.00009999,0,.00009999,.0001,.00010001,1000})do
    b.x,b.y,b.z=a.x,a.y,a.z;b[axis]=a[axis]+delta;compare(a,b)
   end
  end
 end
end
local seed=941
local function draw()seed=(seed*48271)%2147483647;return seed/2147483647 end
for i=1,12000 do
 local a=Vector(center.x+(draw()-.5)*3000,center.y+(draw()-.5)*3000,center.z+(draw()-.5)*2400)
 local b=Vector(center.x+(draw()-.5)*3000,center.y+(draw()-.5)*3000,center.z+(draw()-.5)*2400)
 compare(a,b)
end
-- In-place inputs/config/centres and empty sets are fresh on every query.
local a,b=Vector(center.x-1000,center.y,center.z+2),Vector(center.x+1000,center.y,center.z+2)
for i=1,40 do a.y=a.y+7;b.y=b.y+13;compare(a,b)end
local old=LOD.Config.Maze.LevelHeight;LOD.Config.Maze.LevelHeight=old+100;compare(a,b);LOD.Config.Maze.LevelHeight=old
old=S.Config.HullMargin;S.Config.HullMargin=old+30;P.Config.HullMargin=old+30;compare(a,b);S.Config.HullMargin=old;P.Config.HullMargin=old
local centers=g.EntrySafety.centers;g.EntrySafety.centers={};compare(a,b);g.EntrySafety.centers=centers
local cx=center.x;center.x=cx+1000;compare(a,b);center.x=cx
-- Mutable/custom coordinate access and custom centres preserve the old path.
local reads={}
local custom=setmetatable({},{__index=function(_,k)reads[#reads+1]=k;return a[k]end})
compare(custom,b);assert(#reads>0)
local savedIsVector=isvector;isvector=nil;compare(a,b);isvector=savedIsVector
local savedCenters=g.EntrySafety.centers;g.EntrySafety.centers={{x=center.x,y=center.y,z=center.z}};compare(a,b);g.EntrySafety.centers=savedCenters
print('ENTRY_MOVEMENT_SWEEP_PASS cases='..checks..' exact_parent_result/denial/parallel_threshold/face/random/current_inputs/config/centres/custom_fallback')
