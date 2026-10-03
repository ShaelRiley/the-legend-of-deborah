-- Button for Punishment: a route-and-use encounter. Native HP is the only HP.
local B = LOD.BossEncounter
local D = {
    name = "Button for Punishment", model = "models/props_lab/reciever01b.mdl",
    baseHP = 800, speed = 0, size = 1, useOnly = true, manualPhase = true,
    deferKey = true, maxObjects = 24, maxAdds = 6,
    phaseNames = {"Press Here", "Obstacle Course", "PUNISHMENT"},
    arena = {theme = "The Gauntlet", width = 7, depth = 7, upper = true},
    deathCaption = "GAUNTLET SHUTDOWN — PRESS JAIL KEY", keyLocation = "center"
}
local function copy(v) return Vector(v.x,v.y,v.z) end
local function alive(o) return o and not o.retired and IsValid(o.ent) end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function now(c) return c.now or CurTime() end
local function clearCycle(c)
    B:Clear(c,"gauntlet_button");B:Clear(c,"gauntlet_fake")
    B:Clear(c,"gauntlet_lane");B:Clear(c,"gauntlet_barricade")
    c.data.real={};c.data.fake={};c.data.deadline=nil
end
function D:Pedestals(c)
    local d=c.data
    if d.pedestals then return #d.pedestals>=8 end
    local legal={}
    for _,p in ipairs(c.points or {}) do
        local safe=B:SafePoint(c,p)
        if safe then legal[#legal+1]=copy(safe) end
    end
    -- Deterministic farthest-point sampling spreads the ten destinations across
    -- lanes/elevations rather than clustering at the start of sorted grid keys.
    local points={};local used={}
    for n=1,10 do
        local best,bestDistance
        for i,p in ipairs(legal) do if not used[i] then
            local distance=#points==0 and p:DistToSqr(B:Center(c)) or math.huge
            for _,chosen in ipairs(points) do distance=math.min(distance,p:DistToSqr(chosen)) end
            if distance>=128*128 and (not bestDistance or distance>bestDistance) then best=i;bestDistance=distance end
        end end
        if not best then break end
        used[best]=true;points[#points+1]=legal[best]
    end
    -- Never substitute an unreachable or cramped mandatory destination.
    if #points<8 or not B:ValidateRoutes(c,{},24) then return false end
    d.pedestals=points
    for i,p in ipairs(points) do
        B:Object(c,{kind="gauntlet_pedestal",role="pedestal",pos=p,
            model="models/props_c17/Concrete_Barrier001a.mdl",scale=.22,
            label="BUTTON PEDESTAL "..i,solid=false,permanent=true,hp=0})
    end
    return true
end
function D:Choose(c,origin,exclude,farthest)
    local candidates={}
    for i,p in ipairs(c.data.pedestals or {}) do
        if i~=c.data.lastPoint and not (exclude and exclude[i]) and B:SafePoint(c,p) then
            candidates[#candidates+1]={index=i,pos=p,distance=p:DistToSqr(origin)}
        end
    end
    table.sort(candidates,function(a,b)
        if a.distance==b.distance then return a.index<b.index end
        return a.distance>b.distance
    end)
    if #candidates==0 then return nil end
    local n=farthest and 1 or B:Random(c,"button_destination",1,math.max(1,math.ceil(#candidates/2)))
    return candidates[n]
end
function D:MakeButton(c,choice,kind,label)
    local o=B:Object(c,{kind=kind,role="button",pos=choice.pos+Vector(0,0,26),
        model="models/props_lab/reciever01b.mdl",scale=kind=="gauntlet_fake" and .65 or 1,
        use=true,useLabel=label,label=label,permanent=true,solid=false,hp=0,
        color=kind=="gauntlet_fake" and Color(245,175,35) or Color(255,35,35)})
    if o then o.pedestal=choice.index;o.approach={};o.cycle=c.data.cycle end
    return o
end
function D:BeginCycle(c,targets)
    if not self:Pedestals(c) then c.data.nextCycle=now(c)+1;return false end
    clearCycle(c)
    local d=c.data;d.cycle=(d.cycle or 0)+1;d.pressed={}
    local origin=(targets[1] and targets[1]:GetPos()) or d.lastPosition or B:Center(c)
    local final=d.successes>=d.required-1
    local first=self:Choose(c,origin,nil,final)
    if not first then d.nextCycle=now(c)+1;return false end
    local pair=not final and c.party>1 and #targets>1 and c.phase>=2 and d.cycle%3==0
    local choices={first}
    if pair then
        local second=self:Choose(c,first.pos,{[first.index]=true},true)
        if second and second.pos:DistToSqr(first.pos)>=256*256 then choices[2]=second end
    end
    for _,choice in ipairs(choices) do
        local o=self:MakeButton(c,choice,"gauntlet_button",final and "DO NOT PRESS — THE BIG RED BUTTON" or "E: PRESS HERE")
        if not o then clearCycle(c);d.nextCycle=now(c)+1;return false end
        d.real[#d.real+1]=o
    end
    d.final=final;d.lastPoint=first.index;d.lastPosition=copy(first.pos)
    local window=c.phase==3 and 32 or 40
    -- Extra baseline traversal allowance grows with actual court extent.
    window=math.max(window,math.sqrt(first.distance)/150+18)
    if #choices==2 then window=window+6 end
    d.deadline=now(c)+window;d.nextCycle=nil
    B:Announce(c,final and "THE BIG RED BUTTON — DO NOT PRESS" or (#choices==2 and "TWO REAL BUTTONS — SAME WINDOW" or "PRESS HERE"))
    for _,o in ipairs(d.real) do B:Warn(c,"REAL BUTTON — E",o.pos,window,72,{color=Color(255,55,55)}) end
    if c.phase==3 and not final then
        local exclude={};for _,v in ipairs(choices) do exclude[v.index]=true end
        local fake=self:Choose(c,first.pos,exclude,false)
        if fake then local o=self:MakeButton(c,fake,"gauntlet_fake","FAKE — PUNISHMENT");if o then d.fake[1]=o end end
    end
    self:Obstructions(c)
    return true
end
function D:Obstructions(c)
    local d=c.data
    -- One narrow hazardous lane; button destinations and their last approach stay dry.
    local start=B:Point(c,2);local finish=B:Point(c,3)
    local safe=true
    for _,o in ipairs(d.real) do
        if o.pos:DistToSqr(start)<240*240 or o.pos:DistToSqr(finish)<240*240 then safe=false end
    end
    if safe then B:Zone(c,{kind="gauntlet_lane",label="OBSTACLE LANE",pos=start,finish=finish,
        shape="lane",width=c.phase>=2 and 54 or 36,delay=2,life=6,interval=1,
        damage={kind="bullet",dice={1,4,0},reference=2.5},safeGap=180}) end
    if c.phase>=2 then
        local p=B:Point(c,5)
        if B:ValidateRoutes(c,{p},24) then
            B:Object(c,{kind="gauntlet_barricade",pos=p,model="models/props_junk/wood_crate001a.mdl",
                label="TEMPORARY BARRICADE",life=7,hp=20,scale=.55,solid=true,pushable=true})
        end
    end
    d.nextReplenish=now(c)
end
function D:Start(c)
    c.data.successes=0;c.data.required=8+math.max(0,c.party-1)
    c.data.real={};c.data.fake={};c.data.nextCycle=now(c)
    c.data.segment=c.actor:GetMaxHealth()/c.data.required
    B:Stop(c,c.actor)
end
function D:BeforeDamage(c,actor,info)
    if actor~=c.actor then return true end
    return info==c.useDamage -- only the framework's atomic E receipt may remove HP
end
function D:TrackApproaches(c,targets,t)
    for _,list in ipairs({c.data.real or {},c.data.fake or {}}) do
        for _,o in ipairs(list) do if alive(o) then
            for _,p in ipairs(targets) do
                local v=p:GetPos();local a=o.approach[p]
                if a and not B:TargetLive(c,a.binding) then a=nil;o.approach[p]=nil end
                if not a then a={binding=B:BindTarget(c,p),last=copy(v),at=t};o.approach[p]=a end
                local distance=v:DistToSqr(o.pos)
                local elapsed=math.max(.01,t-a.at)
                -- A teleport into the last 144 units never earns a press. Walk out,
                -- then enter continuously. Normal fast movement keeps its advantage.
                local jumped=v:DistToSqr(a.last)>math.max(96,elapsed*600)^2
                if jumped then a.entered=nil;a.readyAt=nil end
                if distance>=144*144 then a.entered=true;a.readyAt=nil end
                if distance<80*80 and a.entered and not jumped then a.readyAt=a.readyAt or t+.25 end
                a.last=copy(v);a.at=t
            end
        end end
    end
end
function D:Think(c,t,dt,targets)
    local d=c.data
    if d.paused then
        if d.deadline then d.deadline=t+(d.remaining or 0) end
        d.paused=nil;d.remaining=nil
    end
    if d.nextCycle and t>=d.nextCycle then self:BeginCycle(c,targets) end
    self:TrackApproaches(c,targets,t)
    if d.deadline and t>=d.deadline then
        B:Announce(c,"TOO SLOW");clearCycle(c);d.nextCycle=t+1
        return
    end
    if d.deadline and t>=(d.nextReplenish or 0) then
        d.nextReplenish=t+4
        if B:CountActors(c,"gauntlet_obstruction")<math.min(6,2+c.party) then
            local kind=c.phase>=2 and (d.cycle%2==0 and "blitzer" or "soldier") or "runner"
            B:QueueAdd(c,kind,"gauntlet_obstruction",B:Point(c,6),{manual=false})
        end
    end
end
function D:ObjectEvent(c,o,event,p)
    if event~="use" or not B:Hero(c,p) then return end
    if o.spec.kind=="gauntlet_key_button" then
        if not c.dead or not c.receipt or c.keyReady or o.claimed then return end
        o.claimed=true;c.keyReady=true
        B:Announce(c,"THANK YOU FOR YOUR COOPERATION")
        B:EnsureKey(c);B:RemoveObject(c,o,"key requested")
        return
    end
    local d=c.data
    if c.dead or not d.deadline or now(c)>=d.deadline or o.cycle~=d.cycle or o.retired or o.claimed then return end
    local a=o.approach and o.approach[p]
    if not a or not a.readyAt or now(c)<a.readyAt or not B:TargetLive(c,a.binding)
        or p:GetPos():DistToSqr(o.pos)>96*96 then return end
    if o.spec.kind=="gauntlet_fake" then
        o.claimed=true
        B:Announce(c,"FAKE BUTTON — PUNISHMENT")
        B:Damage(c,p,{kind="melee",dice={1,4,0},reference=2.5,push=80},c.actor)
        B:RemoveObject(c,o,"fake pressed")
        return -- real button, deadline and success count remain untouched
    end
    if o.spec.kind~="gauntlet_button" then return end
    o.claimed=true;d.pressed[o.id]=true
    if count(d.pressed)<#d.real then B:Announce(c,"ONE PRESSED — REACH THE OTHER");return end
    d.successes=d.successes+1
    local final=d.final
    clearCycle(c)
    if final then
        for ent,role in pairs(c.owned) do if role=="gauntlet_obstruction" then B:RetireActor(c,ent) end end
        B:UseDamage(c,c.actor:Health(),p,"button:"..d.cycle)
    else
        B:UseDamage(c,math.min(c.actor:Health()-1,d.segment),p,"button:"..d.cycle)
        local fraction=d.successes/d.required
        B:SetPhase(c,fraction>=.65 and 3 or (fraction>=.3 and 2 or 1))
        d.nextCycle=now(c)+1
    end
end
function D:Pause(c)
    local d=c.data
    if not d.paused then d.remaining=d.deadline and math.max(0,d.deadline-now(c));d.paused=true end
    for _,o in ipairs(d.real or {}) do o.approach={} end
    for _,o in ipairs(d.fake or {}) do o.approach={} end
end
function D:Defeat(c)
    clearCycle(c);c.data.keyButton=nil;c.keyReady=false
end
function D:PostDefeat(c,t)
    if c.keyReady then B:EnsureKey(c);return end
    local d=c.data
    if alive(d.keyButton) then return end
    d.keyButton=B:Object(c,{kind="gauntlet_key_button",role="key_button",
        pos=B:Center(c)+Vector(0,0,24),model="models/props_lab/reciever01b.mdl",scale=.4,
        use=true,useLabel="E: JAIL KEY",label="JAIL KEY",permanent=true,solid=false,hp=0,
        postDefeat=true})
end
function D:Snapshot(c)
    if c.dead then return c.keyReady and "THANK YOU FOR YOUR COOPERATION" or "E: JAIL KEY" end
    local d=c.data
    return string.format("PRESSES %d/%d | %s",d.successes or 0,d.required or 8,
        d.deadline and (math.max(0,math.ceil(d.deadline-now(c))).."s") or "NEXT BUTTON")
end
B:Register("button",D)
