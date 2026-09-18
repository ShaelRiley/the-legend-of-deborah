-- Static box collision, bounded contact service, shared spell transaction.
-- No VPhysics, free-running timers or client-authored gameplay geometry.
local F=LOD.MagicForms
local function placementFilter(ent)
    return not (IsValid(ent) and ent:IsPlayer() and not ent:GetNW2Bool('LOD_IsSoldier',false))
end
local function counts(caster)
    local own,total=0,0
    for ent,owner in pairs(F.ActiveWalls) do
        if not IsValid(ent) then F.ActiveWalls[ent]=nil
        else total=total+1;if owner==caster then own=own+1 end end
    end
    return own,total
end
function F:SyncWalls(caster)
    if IsValid(caster) then caster:SetNW2Int('LOD_WallRemaining',math.max(0,self.Tuning.Wall.maxActive-counts(caster))) end
end
function F:RetireWall(ent)
    local caster=self.ActiveWalls[ent];self.ActiveWalls[ent]=nil
    ent.LODWallHits=nil;ent.LODWallRiders=nil
    self:SyncWalls(caster)
end
-- Motion V2 deliberately bypasses Source collision with SetPos. Clip its swept
-- hull against only the bounded dynamic barriers; keep graph travel untouched
-- when no Wall exists. Slab intersections prevent high-speed tunneling.
function F:ConstrainWallMovement(actor,from,to)
    if not next(self.ActiveWalls) then return to,false end
    if actor:IsPlayer() and not actor:GetNW2Bool('LOD_IsSoldier',false) then return to,false end
    local hullMin=actor.OBBMins and actor:OBBMins() or Vector(-16,-16,0)
    local hullMax=actor.OBBMaxs and actor:OBBMaxs() or Vector(16,16,72)
    local delta=to-from
    local fraction=1
    for wall in pairs(self.ActiveWalls) do
        if IsValid(wall) and CurTime()<wall:GetExpiresAt() then
            local lo=wall:GetPos()+wall:GetWallMins()-hullMax
            local hi=wall:GetPos()+wall:GetWallMaxs()-hullMin
            local enter,leave,miss=0,1,false
            for _,axis in ipairs({'x','y','z'}) do
                if math.abs(delta[axis])<.00001 then
                    if from[axis]<lo[axis] or from[axis]>hi[axis] then miss=true;break end
                else
                    local a,b=(lo[axis]-from[axis])/delta[axis],(hi[axis]-from[axis])/delta[axis]
                    if a>b then a,b=b,a end
                    enter=math.max(enter,a);leave=math.min(leave,b)
                    if enter>leave then miss=true;break end
                end
            end
            if not miss and leave>0 and enter<fraction then fraction=math.max(0,enter) end
        end
    end
    if fraction>=1 then return to,false end
    return from+delta*math.max(0,fraction-.25/math.max(delta:Length(),.001)),true
end
function F:WallWidth(context)
    local t=self.Tuning.Wall
    return math.min(t.maxWidth,t.baseWidth+t.widthPerBonus*math.max(1,context.spatialBonusCells or 1))
end
function F:WallPlacement(ply,context)
    local t=self.Tuning.Wall
    local aim=ply:GetAimVector();local flat=Vector(aim.x,aim.y,0)
    if flat:LengthSqr()<.01 then return nil end
    flat=flat:GetNormalized()
    -- Cardinal faces match the maze and produce exact Source AABB collision.
    local normal=math.abs(flat.x)>=math.abs(flat.y) and Vector(flat.x>=0 and 1 or -1,0,0)
        or Vector(0,flat.y>=0 and 1 or -1,0)
    local tangent=Vector(-normal.y,normal.x,0)
    local view=util.TraceLine({start=ply:GetShootPos(),endpos=ply:GetShootPos()+aim*t.reach,mask=MASK_SOLID,filter=placementFilter})
    if view.StartSolid or view.HitSky then return nil end
    local point=view.HitPos-(view.Hit and flat*(t.thickness+2) or vector_origin)
    local floor=util.TraceLine({start=point+Vector(0,0,16),endpos=point-Vector(0,0,160),mask=MASK_SOLID,filter=placementFilter})
    if not floor.Hit or floor.StartSolid or floor.HitNormal.z<.7 then return nil end
    local origin=floor.HitPos+Vector(0,0,1)
    local half=t.thickness*.5
    local slim=Vector(half,half,0)
    local high=Vector(half,half,t.height)
    -- Full-height sweeps trim both ends before crates/ceilings/characters.
    local distances={}
    for index,sign in ipairs({-1,1}) do
        local tr=util.TraceHull({start=origin,endpos=origin+tangent*(self:WallWidth(context)*.5*sign),
            mins=-slim,maxs=high,mask=MASK_SOLID,filter=placementFilter})
        if tr.StartSolid or tr.AllSolid then return nil end
        distances[index]=math.max(0,self:WallWidth(context)*.5*(tr.Fraction or 1)-1)
    end
    if distances[1]+distances[2]<t.minWidth then return nil end
    origin=origin+tangent*((distances[2]-distances[1])*.5)
    local width=(distances[1]+distances[2])*.5
    local ext=Vector(math.abs(tangent.x)*width+math.abs(normal.x)*half,
        math.abs(tangent.y)*width+math.abs(normal.y)*half,0)
    local mins,maxs=-ext,ext+Vector(0,0,t.height)
    -- Heroes pass through; geometry and enemy occupancy still constrain placement.
    local volume=util.TraceHull({start=origin,endpos=origin,mins=mins,maxs=maxs,mask=MASK_SOLID,filter=placementFilter})
    if volume.Hit or volume.StartSolid or volume.AllSolid then return nil end
    -- Require support at both ends: never bridge a sealed floor or open pit.
    for _,sign in ipairs({-1,1}) do
        local foot=origin+tangent*(width*sign)
        local support=util.TraceLine({start=foot+Vector(0,0,4),endpos=foot-Vector(0,0,12),mask=MASK_SOLID,filter=placementFilter})
        if not support.Hit or support.StartSolid or support.HitNormal.z<.7 then return nil end
    end
    return {origin=origin,mins=mins,maxs=maxs,normal=normal}
end
function F:CanPlaceWall(ply,context)
    local own,total=counts(ply)
    if own>=self.Tuning.Wall.maxActive or total>=self.Tuning.Wall.maxGlobal then return false,'wall_cap' end
    context.wallPlacement=self:WallPlacement(ply,context)
    if not context.wallPlacement then return false,'wall_placement' end
    return true
end
function F:_CastWall(ply,form,content,context)
    local p=context.wallPlacement
    if not p then return false end
    local ent=ents.Create('lod_magic_wall');if not IsValid(ent) then return false end
    ent.LODCaster=ply;ent.LODCastContext=context;ent.LODContentId=content and content.id or 'raw'
    ent.LODWallNormal=p.normal;ent.LODWallHits={};ent.LODWallRiders={}
    ent.LODRunState=LOD.RunManager.State;ent.LODLevelSeed=ent.LODRunState.LevelSeed
    ent:SetPos(p.origin);ent:SetWallMins(p.mins);ent:SetWallMaxs(p.maxs)
    ent:SetExpiresAt(CurTime()+self.Tuning.Wall.lifetime)
    ent:SetColor(self.ContentColors[ent.LODContentId] or self.ContentColors.raw)
    ent:Spawn();ent:Activate()
    self.ActiveWalls[ent]=ply;self:SyncWalls(ply)
    return true
end
function F:StepWall(ent)
    local caster,run=ent.LODCaster,LOD.RunManager.State
    if CurTime()>=ent:GetExpiresAt() or not IsValid(caster) or not caster:Alive()
        or caster:GetNW2Bool('LOD_Staged',false) or run~=ent.LODRunState
        or run.LevelSeed~=ent.LODLevelSeed or run.Failed or run.LevelCleared or run.SimulationFrozen then
        ent:Remove();return
    end
    local t=self.Tuning.Wall
    local lo,hi=ent:GetPos()+ent:GetWallMins(),ent:GetPos()+ent:GetWallMaxs()
    local margin=Vector(t.contact,t.contact,0)
    local targets=ents.FindInBox(lo-margin,hi+margin)
    table.sort(targets,function(a,b) return a:EntIndex()<b:EntIndex() end)
    for _,target in ipairs(targets) do
        if self:TargetIsOpponent(caster,target) and CurTime()>=(ent.LODWallHits[target] or 0) then
            local center=target:WorldSpaceCenter()
            local origin=Vector(math.Clamp(center.x,lo.x,hi.x),math.Clamp(center.y,lo.y,hi.y),math.Clamp(center.z,lo.z,hi.z))
            -- Begin just outside the corresponding face; the solid Wall itself
            -- must not hide a touching target on either side. Floors still block.
            origin=origin+ent.LODWallNormal*(ent.LODWallNormal:Dot(center-ent:GetPos())>=0 and .5 or -.5)
            if self:LineOfEffect(caster,target,origin) then
                ent.LODWallHits[target]=CurTime()+t.hitDelay
                local content=LOD.RPG.MagicContents[ent.LODContentId]
                if content and ent.LODWallRiders[target] then content=table.Copy(content);content.rider=nil end
                local before=target:Health()
                self:_ApplyDamage(caster,caster,target,LOD.RPG.MagicForms.wall,content,ent.LODCastContext,(center-origin):GetNormalized())
                if not IsValid(target) or target:Health()<before then ent.LODWallRiders[target]=true end
            end
        end
    end
    ent:NextThink(CurTime()+t.interval);return true
end
local function clear(caster)
    for ent,owner in pairs(F.ActiveWalls) do
        if not caster or owner==caster then
            if IsValid(ent) then ent:Remove() end
            F:RetireWall(ent)
        end
    end
end
hook.Add('PlayerDeath','LOD_WallDeath',function(ply) clear(ply) end)
hook.Add('PlayerDisconnected','LOD_WallDisconnect',clear)
hook.Add('PreCleanupMap','LOD_WallCleanup',function() clear() end)
hook.Add('ShutDown','LOD_WallShutdown',function() clear() end)
