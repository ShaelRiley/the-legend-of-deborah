-- B9 commitments: one service, no attachment/solid prop/status/damage authority.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
E.Screens=E.Screens or setmetatable({}, {__mode="k"})
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:RetireTactical(e)
    self.Screens[e]=nil
    e:SetNW2Int("LOD_TacticalMode",0);e:SetNW2Float("LOD_TacticalUntil",0)
end
function E:TacticalValid(e,a)
    return IsValid(e) and e.LODRosterAttack==a and self:ValidLife(a.life) and self:CanCast(e)
        and CurTime()>=(e.LODHitStunUntil or 0) and CurTime()<a.expires
        and e:GetPos():DistToSqr(a.origin)<=4^2 and self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        and (a.tactical~="screen" or self:MeleeSupported(e,a.graph,a.cell,a.plane))
        and self:AcquireTarget(a.target) and self:Visible(e,a.target)
end
function E:ScreenSpace(e,a)
    local side=Vector(-a.direction.y,a.direction.x,0)
    if not self:MeleeSupported(e,a.graph,a.cell,a.plane) or not self:MeleeRouteClear(e,a.origin,a.plane) then return false end
    for _,sign in ipairs({-1,1}) do
        local pocket=a.plane+side*(100*sign)
        if not self:MeleeSupported(e,a.graph,a.cell,pocket) or not self:MeleeRouteClear(e,a.plane,pocket) then return false end
    end
    return true
end
function E:ServiceTactical()
    for e,a in pairs(self.Screens) do
        if not self:TacticalValid(e,a) then
            if IsValid(e) and e.LODRosterAttack==a then self:Finish(e,CurTime())
            else self.Screens[e]=nil end
        end
    end
end
function E:ScreenRecipient(a,r)
    local p=r.hero
    return self:ValidSourceLife(r) and IsValid(p) and p.LODHostile and p.LODActivated
        and not p.LODDead and p:Health()>0 and LOD.FactionManager:IsEnemyCombatant(p)
        and LOD.RPGAbilityRules:ProgressionState(p)==r.heroState
        and LOD.RPGStatusElements.ActorLives[p]==r.heroLife
        and self:MeleeSupported(p,a.graph,a.cell,p:GetPos())
        and p:GetPos():DistToSqr(a.origin)<=240^2
        and (p:WorldSpaceCenter()-a.plane):Dot(a.direction)<0
        and self:Visible(a.life.source,p)
end
function E:BeginTactical(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0) then return false end
    local s=LOD.RunManager.State;local d=self.Definitions[e.LODArchetypeId]
    if not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function fail()
        e.LODNextAttack=now+.5;e.LODTacticalAdvanceUntil=now+.5;return false
    end
    local origin=copy(e:GetPos());local cell=N:WorldToCell(s.Graph,origin)
    if not self:MeleeSupported(e,s.Graph,cell,origin) or not self:Visible(e,p)
        or origin:DistToSqr(p:GetPos())>d.range^2 then return fail() end
    local direction=flat(p:GetPos()-origin):GetNormalized()
    if direction:LengthSqr()<.01 then return fail() end
    local a=self:Bind({tactical=d.tactical,kind="bullet",target=p,origin=origin,cell=cell,
        direction=direction,ready=now+d.warning,recipients={}},s)
    a.life=self:CaptureLife(e,p);a.expires=a.ready+(d.tactical=="screen" and 3 or .2)
    if d.tactical=="tow" then
        if not self:MeleeSupported(p,s.Graph,cell,p:GetPos()) or origin:DistToSqr(p:GetPos())<96^2 then return fail() end
        a.aim=copy(p:GetPos())
    else
        local count=0
        for source,screen in pairs(self.Screens) do
            if self:TacticalValid(source,screen) then count=count+1
            else self.Screens[source]=nil end
        end
        a.plane=origin+direction*64
        if not self:ScreenSpace(e,a) then return fail() end
        if count<16 then
            local candidates={}
            for index,ally in ipairs(LOD.HostileRegistry:List()) do
                if index>128 then break end
                if ally~=e and LOD.EnemySupport:Ordinary(ally) then
                    local life=self:CaptureLife(e,ally)
                    if self:ScreenRecipient(a,life) then candidates[#candidates+1]=life end
                end
            end
            table.sort(candidates,function(x,y)
                local dx,dy=x.hero:GetPos():DistToSqr(origin),y.hero:GetPos():DistToSqr(origin)
                return dx<dy or dx==dy and x.hero:EntIndex()<y.hero:EntIndex()
            end)
            for i=1,math.min(3,#candidates) do a.recipients[candidates[i].hero]=candidates[i] end
        end
        if not next(a.recipients) then
            self:Begin(e,p,now,{tacticalFallback=true});return e.LODRosterAttack~=nil
        end
        self.Screens[e]=a
    end
    e.LODRosterAttack=a;e.LODTacticalAdvanceUntil=nil
    LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_TacticalMode",d.tactical=="tow" and 1 or 2)
    e:SetNW2Vector("LOD_TacticalOrigin",origin);e:SetNW2Vector("LOD_TacticalAim",a.aim or a.plane)
    e:SetNW2Vector("LOD_TacticalDirection",direction);e:SetNW2Float("LOD_TacticalReady",a.ready)
    e:SetNW2Float("LOD_TacticalUntil",a.expires)
    e:EmitSound("npc/metropolice/gear1.wav",72,100,.75)
    return true
end
function E:TowContains(a,p)
    local delta=flat(p:GetPos()-a.origin)
    return self:MeleeSupported(p,a.graph,a.cell,p:GetPos()) and delta:LengthSqr()>=96^2
        and delta:Dot(a.direction)>=0 and delta:Dot(a.direction)<=flat(a.aim-a.origin):Length()+24
        and math.abs(delta:Dot(Vector(-a.direction.y,a.direction.x,0)))<=24
end
function E:TowPath(e,a,p,from,to,trace)
    if not self:TacticalValid(e,a) or not self:ValidLife(a.life)
        or trace.Hit or trace.StartSolid or trace.AllSolid or from:DistToSqr(to)>64^2+.01
        or to:DistToSqr(a.origin)<64^2 then return false end
    local lo,hi=p:GetCollisionBounds()
    local hull=util.TraceHull({start=from,endpos=to,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,filter={p,e}})
    if hull.Hit or hull.StartSolid or hull.AllSolid then return false end
    local steps=math.max(1,math.ceil(from:Distance(to)/16))
    if steps>4 then return false end
    for i=0,steps do
        if not self:MeleeSupported(p,a.graph,a.cell,from+(to-from)*(i/steps)) then return false end
    end
    return true
end
function E:StepTactical(e,a,now)
    if not self:TacticalValid(e,a) then self:Finish(e,now);return end
    if not a.released then
        if now>a.ready+.2 then self:Finish(e,now);return end
        if now<a.ready then return end
        if a.tactical=="screen" and not self:ScreenSpace(e,a) then self:Finish(e,now);return end
        a.released=true -- claim before damage/push callbacks
        if a.tactical=="tow" then
            local p=a.target
            if self:TowContains(a,p) then
                local dealt=self:Damage(e,p,{impactOrigin=a.origin+Vector(0,0,48)},"bullet")
                if dealt and dealt>0 and self:TacticalValid(e,a) and self:ValidLife(a.life) and self:TowContains(a,p) then
                    LOD.Pushback:Apply(p,{attacker=e,direction=a.origin-p:GetPos(),distance=48,
                        maxTravel=math.min(64,flat(p:GetPos()-a.origin):Length()-64),source="towline",
                        validatePath=function(from,to,trace) return self:TowPath(e,a,p,from,to,trace) end})
                end
            end
            if e.LODRosterAttack==a then self:Finish(e,now) end
            return
        end
        e:SetNW2Int("LOD_RosterAttack",2)
    end
    if a.tactical=="screen" then
        local any=false
        for _,life in pairs(a.recipients) do if self:ScreenRecipient(a,life) then any=true;break end end
        if not any then self:Finish(e,now) end
    end
end
function E:ScreenContribution(target,attacker,info)
    if not IsValid(attacker) or not IsValid(target) or not info then return 0 end
    local ctx=LOD.RPGStatusElements:DamageContext(info,target) or {}
    local contract=ctx.damageContract or {}
    local origin=ctx.equipmentSnapshot and ctx.equipmentSnapshot.origin
        or contract.sourcePosition or contract.originContract and contract.originContract.sourcePosition
        or ctx.attackOrigin or ctx.projectileOrigin or ctx.pushOrigin or attacker:WorldSpaceCenter()
    local goal=target:WorldSpaceCenter()
    for source,a in pairs(self.Screens) do
        local life=a.recipients[target]
        if a.released and life and self:TacticalValid(source,a) and self:ScreenRecipient(a,life) then
            local front=(origin-a.plane):Dot(a.direction);local rear=(goal-a.plane):Dot(a.direction)
            if front>0 and rear<0 then
                local hit=origin+(goal-origin)*(front/(front-rear))
                local side=Vector(-a.direction.y,a.direction.x,0)
                if math.abs((hit-a.plane):Dot(side))<=80 and hit.z>=a.plane.z and hit.z<=a.plane.z+96 then return .25 end
            end
        end
    end
    return 0
end
