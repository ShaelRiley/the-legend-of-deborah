-- B7 commitment geometry. Scheduling/damage and locomotion retain their owners.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:MeleeCellLegal(g,c)
    return c and g.Cells[self.Key(c)]==c and not self:Safe(g,c)
        and not ((g.CellTags or {})[self.Key(c)] or {}).objective and not self:IsTransition(g,c)
end
function E:MeleeSupported(e,g,c,pos)
    if N:WorldToCell(g,pos)~=c or not self:MeleeCellLegal(g,c) then return false end
    local floor=N:CellCenter(c).z
    if math.abs(pos.z-(floor+2))>4 then return false end
    local tr=util.TraceLine({start=pos+Vector(0,0,16),endpos=pos-Vector(0,0,12),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.HitNormal and tr.HitNormal.z>=.7
        and math.abs(tr.HitPos.z-floor)<=4
end
function E:MeleeRouteClear(e,from,to)
    local size=math.Clamp(e:GetNW2Float("LOD_SizeScale",1),.33,1.33)
    local tr=util.TraceHull({start=from,endpos=to,mins=Vector(-16*size,-16*size,0),
        maxs=Vector(16*size,16*size,72*size),mask=MASK_NPCSOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid and not tr.AllSolid
end
function E:BeginMelee(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) or now<(e.LODNextAttack or 0) then return false end
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State;local g=s and s.Graph
    if not g or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function fail() e.LODNextAttack=now+.5;e.LODMeleeAdvanceUntil=now+.5;return false end
    local start=copy(e:GetPos());local cell=N:WorldToCell(g,start)
    if not self:MeleeSupported(e,g,cell,start) or N:WorldToCell(g,p:GetPos())~=cell
        or flat(p:GetPos()-start):Length()>d.range or not self:Visible(e,p) then return fail() end
    local dir=flat(p:GetPos()-start):GetNormalized()
    if dir:LengthSqr()==0 then dir=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({melee=d.melee,kind="melee",target=p,start=start,origin=start,direction=dir,
        cell=cell,ready=now+d.warning,beat=1,participants={}},s)
    if d.melee=="feint" then
        if not LOD.RPGStatusElements:CanMoveVoluntarily(e) then return fail() end
        local goal=LOD.HostileMotionV2:CellFloorPoint(cell,start-dir*80)
        local delta=flat(start-goal);local side=Vector(-dir.y,dir.x,0)
        if delta:Dot(dir)<64 or math.abs(delta:Dot(side))>4
            or not self:MeleeSupported(e,g,cell,goal) or not self:MeleeRouteClear(e,start,goal) then return fail() end
        a.origin=goal;a.retreatEnd=now+.6;a.ready=a.retreatEnd+d.warning
        e.LODMotionLastUpdate=now
    end
    a.second=d.melee=="double" and a.ready+.85 or nil
    a.expires=(a.second or a.ready)+.2;a.life=self:CaptureLife(e,p)
    local heroes=player.GetAll()
    for i=1,math.min(32,#heroes) do
        if self:Target(heroes[i]) then a.participants[#a.participants+1]=self:CaptureLife(e,heroes[i]) end
    end
    e.LODRosterAttack=a;e.LODMeleeAdvanceUntil=nil
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_MeleeMode",d.melee=="sweep" and 1 or (d.melee=="double" and 2 or (d.melee=="single" and 4 or 3)))
    e:SetNW2Vector("LOD_MeleeOrigin",a.origin);e:SetNW2Vector("LOD_MeleeStart",a.start)
    e:SetNW2Vector("LOD_MeleeDirection",dir);e:SetNW2Float("LOD_MeleeReady",a.ready)
    e:SetNW2Float("LOD_MeleeSecond",a.second or 0);e:SetNW2Float("LOD_MeleeUntil",a.expires)
    e:EmitSound(d.melee=="feint" and "npc/metropolice/gear1.wav" or "npc/zombie/zo_attack1.wav",72,100,.75)
    e:_SetActivity(ACT_MELEE_ATTACK1 or ACT_IDLE,true)
    return true
end
function E:MeleeContains(a,p,beat)
    local pos=p:GetPos();local delta=flat(pos-a.origin);local height=pos.z-(a.origin.z-2)
    if height< -4 or height>72 or N:WorldToCell(a.graph,pos)~=a.cell then return false end
    local forward=delta:Dot(a.direction)
    if a.melee=="feint" then
        return forward>=0 and forward<=240 and math.abs(delta:Dot(Vector(-a.direction.y,a.direction.x,0)))<=24
    end
    local radius=a.melee=="sweep" and 144 or (beat==1 and 112 or 184)
    local cosine=a.melee=="sweep" and 0 or math.cos(math.rad(30))
    return delta:LengthSqr()<=radius*radius and forward>=delta:Length()*cosine
end
function E:StepMelee(e,a,now)
    if e.LODRosterAttack~=a then return end
    local motion=LOD.HostileMotionV2
    if not self:ValidLife(a.life) or not self:CanCast(e) or now<(e.LODHitStunUntil or 0)
        or now>a.expires or not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then self:Finish(e,now);return end
    if a.retreatEnd then
        if not LOD.RPGStatusElements:CanMoveVoluntarily(e)
            or not self:MeleeSupported(e,a.graph,a.cell,a.origin)
            or not self:MeleeRouteClear(e,e:GetPos(),a.origin) then self:Finish(e,now);return end
        -- External displacement cannot be converted into a fresh retreat route.
        local moved=flat(e:GetPos()-a.start);local along=-moved:Dot(a.direction)
        if along< -4 or along>84 or math.abs(moved:Dot(Vector(-a.direction.y,a.direction.x,0)))>4 then self:Finish(e,now);return end
        if now<a.retreatEnd then
            motion:MoveToward(e,{pos=a.origin});motion:FaceToward(e,e:GetPos()+a.direction*32);return
        end
        if e:GetPos():DistToSqr(a.origin)>4^2 then self:Finish(e,now);return end
        a.retreatEnd=nil;motion:Stop(e);e:_SetActivity(ACT_MELEE_ATTACK1 or ACT_IDLE,true)
    end
    if e:GetPos():DistToSqr(a.origin)>4^2 then self:Finish(e,now);return end
    -- Disappearance/cover can abort a charge, never update its frozen geometry.
    if not self:AcquireTarget(a.target) or not self:Visible(e,a.target,a.origin+Vector(0,0,48)) then self:Finish(e,now);return end
    local due=a.beat==1 and a.ready or a.second
    if not due or now>due+.2 then self:Finish(e,now);return end
    if now<due then return end
    local event={impactOrigin=a.origin+Vector(0,0,48)};local beat=a.beat
    -- Advance BEFORE native callbacks; a reentrant service cannot repeat a beat.
    a.beat=a.beat+1
    for _,life in ipairs(a.participants) do
        local p=life.hero
        if self:ValidLife(life) and self:MeleeContains(a,p,beat) and self:Visible(e,p,event.impactOrigin) then
            self:Damage(e,p,event,"melee")
            if e.LODRosterAttack~=a or not self:ValidSourceLife(a.life) then return end
        end
    end
    e:EmitSound("npc/zombie/claw_miss1.wav",72,100,.75)
    if not a.second or beat==2 then self:Finish(e,now) end
end
