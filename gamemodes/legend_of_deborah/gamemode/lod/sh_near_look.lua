-- Shared, bounded near-crosshair identification. No aim assistance or wall reveal.
LOD.NearLook={}
local coneCosine = math.cos(math.rad(6))
local coneCosineSquared = coneCosine * coneCosine
local sightMins,sightMaxs=Vector(0,0,0),Vector(0,0,1)
local function intersects(a,b,ent,lo,hi)
    return util.IntersectRayWithOBB(a,b-a,ent:GetPos(),ent:GetAngles(),lo,hi)~=nil
end
local function generatedBody(ent,a,b)
    local class=ent:GetClass()
    if class=="lod_gate" or class=="lod_jail_door" then
        if not ent.GetOpened or ent:GetOpened() then return false end
        local lo,hi=ent:GetCollisionBounds()
        local half=LOD.Config.Progression.GateBlockerHeight*.5
        -- Native blockers extend above the rendered door for jump containment.
        return intersects(a,b,ent,Vector(lo.x,lo.y,math.max(lo.z,-half)),
            Vector(hi.x,hi.y,math.min(hi.z,half)))
    end
    if class~="lod_static_box" or not ent.GetBoxKind or not ent.GetBoxMins or not ent.GetBoxMaxs
        or ent:GetNW2Bool("LOD_GeometryHidden",false) then return false end
    local kind=ent:GetBoxKind()
    local lo,hi=ent:GetBoxMins(),ent:GetBoxMaxs()
    if kind==1 or kind==2 or kind==5 then return intersects(a,b,ent,lo,hi) end
    if kind~=4 then return false end -- invisible rail/hut containment is not cover
    local gc,crate=LOD.Config.Geometry,LOD.CrateVisuals
    -- A merged wall proxy reaches the ceiling; only its two rendered cargo
    -- bodies occlude. Preserve the actual stock bounds and the gap between them.
    for stack=0,1 do
        local center=lo.z+gc.ContainerHeight*.5+stack*(gc.ContainerHeight+gc.StackVisualGap)-gc.ContainerVisualEmbed
        if intersects(a,b,ent,Vector(lo.x,lo.y,center+crate.CargoMins.z),
            Vector(hi.x,hi.y,center+crate.CargoMaxs.z)) then return true end
    end
    return false
end
-- For the positive six-degree cone, dot^2 / length^2 preserves angular
-- ordering without normalizing a vector (or taking a square root). The sign
-- check is essential: squaring must never admit targets behind the viewer.
local function coneScore(delta, forward, distanceSquared)
    if distanceSquared == 0 then return 1 end
    local projection = delta:Dot(forward)
    local squared = projection * projection
    if projection < 0 or squared < distanceSquared * coneCosineSquared then return nil end
    return squared / distanceSquared
end
function LOD.NearLook:Visible(ply,ent)
    if not IsValid(ent) or ent==ply or ent:GetNoDraw() then return false end
    if ent.GetNW2Bool and ent:GetNW2Bool("LOD_WardenHidden",false) then return false end
    if ent:GetNW2Bool('LOD_Watcher',false) then
        local now=CurTime()
        if ent:GetNW2Float('LOD_WatcherInvisibleUntil',0)>now then return false end
        if ent:GetNW2Float('LOD_WatcherBlinkUntil',0)>now and math.floor(now*10)%2~=0 then return false end
    end
    local a,b=ply:EyePos(),ent:WorldSpaceCenter()
    local tr=util.TraceLine({start=a,endpos=b,filter=ply,mask=MASK_VISIBLE})
    if tr.Hit and tr.Entity~=ent then return false end
    -- Native SOLID_BBOX geometry needs both MONSTER mask membership and a hull
    -- collision path. Zero horizontal extent preserves the sight segment. Keep
    -- ordinary world/glass/grate/actor behavior in the original visible ray;
    -- this correction considers only actual rendered generated bodies.
    local box=util.TraceHull({start=a,endpos=b,mins=sightMins,maxs=sightMaxs,
        mask=bit.bor(MASK_VISIBLE,CONTENTS_MONSTER),ignoreworld=true,
        filter=function(candidate)
            return candidate~=ply and candidate~=ent and IsValid(candidate) and generatedBody(candidate,a,b)
        end})
    return not box.Hit
end
function LOD.NearLook:Qualifies(ply,ent,range)
    if not IsValid(ent) then return false end
    local delta=ent:WorldSpaceCenter()-ply:EyePos()
    local d=delta:LengthSqr()
    return d<=range*range and coneScore(delta,ply:EyeAngles():Forward(),d)~=nil
        and self:Visible(ply,ent)
end
function LOD.NearLook:Find(ply,range,accept)
    local origin,forward=ply:EyePos(),ply:EyeAngles():Forward()
    local best,score,distance
    local direct=ply:GetEyeTrace().Entity
    if IsValid(direct) and accept(direct) and direct:GetPos():DistToSqr(origin)<=range*range
        and self:Visible(ply,direct) then return direct end
    local candidates=ents.FindInCone(origin,forward,range,coneCosine)
    for _,ent in ipairs(candidates) do
        if IsValid(ent) and accept(ent) then
            local delta=ent:WorldSpaceCenter()-origin
            local d=delta:LengthSqr()
            local dot=d<=range*range and coneScore(delta,forward,d) or nil
            if dot and (not score or dot>score
                or dot==score and (d<distance or d==distance and ent:EntIndex()<best:EntIndex()))
                and self:Visible(ply,ent) then
                best,score,distance=ent,dot,d
            end
        end
    end
    return best
end
