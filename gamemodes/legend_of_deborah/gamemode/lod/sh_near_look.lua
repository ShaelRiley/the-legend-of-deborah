-- Shared, bounded near-crosshair identification. No aim assistance or wall reveal.
LOD.NearLook={}
local coneCosine = math.cos(math.rad(6))
local coneCosineSquared = coneCosine * coneCosine
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
    local tr=util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),filter=ply,mask=MASK_VISIBLE})
    return not tr.Hit or tr.Entity==ent
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
