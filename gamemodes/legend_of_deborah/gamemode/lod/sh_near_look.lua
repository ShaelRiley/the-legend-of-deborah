-- Shared, bounded near-crosshair identification. No aim assistance or wall reveal.
LOD.NearLook={}
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
    return d<=range*range and (d==0 or delta:GetNormalized():Dot(ply:EyeAngles():Forward())>=math.cos(math.rad(6)))
        and self:Visible(ply,ent)
end
function LOD.NearLook:Find(ply,range,accept)
    local origin,forward=ply:EyePos(),ply:EyeAngles():Forward()
    local best,score,distance
    local direct=ply:GetEyeTrace().Entity
    if IsValid(direct) and accept(direct) and direct:GetPos():DistToSqr(origin)<=range*range
        and self:Visible(ply,direct) then return direct end
    local candidates=ents.FindInCone(origin,forward,range,math.cos(math.rad(6)))
    for _,ent in ipairs(candidates) do
        if accept(ent) and self:Visible(ply,ent) then
            local delta=ent:WorldSpaceCenter()-origin
            local d=delta:LengthSqr();local dot=d>0 and delta:GetNormalized():Dot(forward) or 1
            if d<=range*range and dot>=math.cos(math.rad(6)) and (not score or dot>score
                or dot==score and (d<distance or d==distance and ent:EntIndex()<best:EntIndex())) then
                best,score,distance=ent,dot,d
            end
        end
    end
    return best
end
