-- B10 finite moving zones. EnemyRoster owns service/damage/life; MotionV2 owns travel.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function pocket(e,from,to)
    local tr=util.TraceHull({start=from,endpos=to,mins=Vector(-16,-16,0),maxs=Vector(16,16,72),mask=MASK_NPCSOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid and not tr.AllSolid
end
function E:MobileGeometry(e,a)
    -- Fixed three route anchors and six lateral escape pockets, no graph/world search.
    local side=Vector(-a.direction.y,a.direction.x,0)
    if not self:MeleeRouteClear(e,a.start,a.goal) then return false end
    for i=0,2 do
        local point=a.start+(a.goal-a.start)*(i/2)
        if not self:MeleeSupported(e,a.graph,a.cell,point) then return false end
        for _,sign in ipairs({-1,1}) do
            local exit=point+side*(112*sign)
            if not pocket(e,point,exit) then return false end
            -- Escape is a supported route, not merely a supported destination.
            -- A newly opened false floor between endpoints must disarm the zone.
            for step=1,5 do
                if not self:MeleeSupported(e,a.graph,a.cell,point+(exit-point)*(step/5)) then return false end
            end
        end
    end
    return true
end
function E:BeginMobile(e,p,now)
    if e.LODRosterAttack or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not self:AcquireTarget(p) or not self:CanCast(e)
        or not LOD.RPGStatusElements:CanMoveVoluntarily(e) then return false end
    local s=LOD.RunManager.State;local g=s and s.Graph
    if not g or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function fail() e.LODNextAttack=now+.5;e.LODMobileAdvanceUntil=now+.5;return false end
    local count=0
    for actor in pairs(self.Active) do
        if IsValid(actor) and actor.LODRosterAttack and actor.LODRosterAttack.mobile then count=count+1 end
        if count>=16 then return fail() end
    end
    local d=self.Definitions[e.LODArchetypeId];local start=copy(e:GetPos());local cell=N:WorldToCell(g,start)
    if not self:MeleeSupported(e,g,cell,start) or N:WorldToCell(g,p:GetPos())~=cell
        or flat(p:GetPos()-start):Length()>d.range or not self:Visible(e,p) then return fail() end
    local dir=flat(p:GetPos()-start):GetNormalized()
    if dir:LengthSqr()==0 then return fail() end
    if d.mobile=="trail" then dir=dir*-1 end
    local goal=start+dir*144
    local a=self:Bind({mobile=d.mobile,kind="bullet",target=p,start=start,goal=goal,direction=dir,cell=cell,
        ready=now+d.warning,participants={},patches={},hit={},event={},lastPos=copy(start)},s)
    if not self:MobileGeometry(e,a) then return fail() end
    a.life=self:CaptureLife(e,p);a.moveEnd=a.ready+1.8;a.expires=a.ready+(d.mobile=="trail" and 3.8 or 1.8)
    local heroes=player.GetAll()
    for i=1,math.min(32,#heroes) do
        if self:Target(heroes[i]) then a.participants[#a.participants+1]=self:CaptureLife(e,heroes[i]) end
    end
    e.LODRosterAttack=a;e.LODMobileAdvanceUntil=nil
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Int("LOD_MobileMode",d.mobile=="carrier" and 1 or 2)
    e:SetNW2Vector("LOD_MobileStart",start);e:SetNW2Vector("LOD_MobileGoal",goal)
    e:SetNW2Float("LOD_MobileReady",a.ready);e:SetNW2Float("LOD_MobileUntil",a.expires)
    for i=1,3 do e:SetNW2Float("LOD_MobilePatchReady"..i,0);e:SetNW2Float("LOD_MobilePatchUntil"..i,0) end
    e:EmitSound("npc/turret_floor/active.wav",72,100,.75)
    LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    return true
end
function E:MobilePatch(e,a,index,now)
    if a.patches[index] then return end
    local origin=a.start+(a.goal-a.start)*((index-1)/2)
    local patch={origin=origin,ready=now+.8,expires=math.min(a.expires,now+2)}
    a.patches[index]=patch
    e:SetNW2Float("LOD_MobilePatchReady"..index,patch.ready)
    e:SetNW2Float("LOD_MobilePatchUntil"..index,patch.expires)
end
function E:StepMobile(e,a,now)
    if e.LODRosterAttack~=a or a.servicing then return end
    local motion=LOD.HostileMotionV2
    if not self:ValidLife(a.life) or not self:CanCast(e) or not LOD.RPGStatusElements:CanMoveVoluntarily(e)
        or now<(e.LODHitStunUntil or 0) or now>=a.expires or e:GetPos():DistToSqr(a.lastPos)>4^2
        or not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then self:Finish(e,now);return end
    -- At most ten full route/pocket validations per second per admitted source;
    -- every actual movement still receives a fresh swept hull and support preflight.
    if now>=(a.nextGeometry or 0) then
        if not self:MobileGeometry(e,a) then self:Finish(e,now);return end
        a.nextGeometry=now+.1
    end
    if not a.released then
        if now>a.ready+.2 or not self:AcquireTarget(a.target) or not self:Visible(e,a.target) then self:Finish(e,now);return end
        if now<a.ready then return end
        a.released=true;a.lastService=now;e.LODMotionLastUpdate=now;e:SetNW2Int("LOD_RosterAttack",2)
        if a.mobile=="trail" then self:MobilePatch(e,a,1,now) end
    elseif now-a.lastService>.2 then self:Finish(e,now);return end -- stalled service never catches up travel/hazards
    a.lastService=now
    if not a.arrived then
        if now>a.moveEnd then self:Finish(e,now);return end
        local pos=e:GetPos()
        -- Probe the remaining fixed path in <=24-unit steps: no void/gate bypass.
        local distance=pos:Distance(a.goal);local steps=math.max(1,math.ceil(distance/24))
        if not self:MeleeRouteClear(e,pos,a.goal) then self:Finish(e,now);return end
        for i=1,steps do
            if not self:MeleeSupported(e,a.graph,a.cell,pos+(a.goal-pos)*(i/steps)) then self:Finish(e,now);return end
        end
        motion:MoveToward(e,{pos=a.goal});a.lastPos=copy(e:GetPos())
        if not self:ValidLife(a.life) or e.LODRosterAttack~=a then return end
        local along=flat(e:GetPos()-a.start):Dot(a.direction)
        if a.mobile=="trail" then
            for i=2,3 do if along>=(i-1)*72-.05 then self:MobilePatch(e,a,i,now) end end
        end
        a.arrived=e:GetPos():DistToSqr(a.goal)<=.05^2
        if a.arrived then motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    end
    local zones={}
    if a.mobile=="carrier" then zones[1]={origin=copy(e:GetPos()),radius=64}
    else
        for i=1,3 do
            local patch=a.patches[i]
            if patch and now>=patch.ready and now<patch.expires then zones[#zones+1]={origin=patch.origin,radius=44} end
        end
    end
    -- Freeze eligible hits before callbacks. One shared attack roll and one settlement
    -- per Hero across the entire route/trail; no player rescans or catch-up damage.
    local victims={}
    for _,life in ipairs(a.participants) do
        local p=life.hero
        if not a.hit[p] and self:ValidLife(life) and N:WorldToCell(a.graph,p:GetPos())==a.cell then
            for _,zone in ipairs(zones) do
                local delta=p:GetPos()-zone.origin;local height=delta.z+2
                if height>=-4 and height<=72 and flat(delta):LengthSqr()<=zone.radius^2
                    and self:Visible(e,p,zone.origin+Vector(0,0,24)) then
                    victims[#victims+1]={life=life,origin=zone.origin};break
                end
            end
        end
    end
    if #victims>0 then
        -- An escape pocket changed since the last geometry cadence: fail closed.
        if not self:MobileGeometry(e,a) then self:Finish(e,now);return end
        a.servicing=true
        for _,victim in ipairs(victims) do
            if e.LODRosterAttack~=a or not self:ValidSourceLife(a.life) or not self:CanCast(e)
                or not LOD.RPGStatusElements:CanMoveVoluntarily(e) or now<(e.LODHitStunUntil or 0) then break end
            local p=victim.life.hero
            if self:ValidLife(victim.life) and not a.hit[p] then
                a.hit[p]=true;a.event.impactOrigin=victim.origin+Vector(0,0,24)
                self:Damage(e,p,a.event,"bullet")
            end
        end
        a.servicing=nil
    end
    if e.LODRosterAttack==a and a.mobile=="carrier" and a.arrived then self:Finish(e,now) end
end
