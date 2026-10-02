-- Mock only engine boundaries; the Python runner loads the production owner's
-- actual state/phase/lifecycle/volley methods before executing these checks.
NOW=0
function CurTime() return NOW end
function IsValid(e) return type(e)=="table" and not e.invalid end
function Angle(p,y,r) return {p=p,y=y,r=r} end
function Color(...) return {...} end
math.Clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
local vm={};vm.__index=vm
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},vm) end
function vm:DistToSqr(v) return (self.x-v.x)^2+(self.y-v.y)^2+(self.z-v.z)^2 end
function vm:GetNormalized() local n=math.sqrt(self:DistToSqr(Vector(0,0,0)));if n==0 then return Vector(0,0,0) end;return self*(1/n) end
function vm:ToScreen() return {visible=true,x=self.x,y=self.y} end
vm.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vm.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vm.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
vector_origin=Vector(0,0,0)
ACT_IDLE=0;ACT_WALK=1;ACT_RUN=2;MASK_SHOT=1;TEXT_ALIGN_CENTER=1
hook={handlers={}}
function hook.Add(event,name,fn) hook.handlers[name]=fn end
function hook.Run(...) end
util={TraceLine=function() return {Hit=false} end}
draw={count=0,SimpleText=function(...) draw.count=draw.count+1 end}
function EyePos() return Vector(0,0,100) end
LOD={Warden={},RunManager={},ProgressionDirector={},MazeNavigator={},MazeGenerator={},HostileMotionV2={},WardenPresentation={}}
function LOD.MazeGenerator.CellKey(x,y,z) return x..":"..y..":"..z end
local key=LOD.MazeGenerator.CellKey
function LOD.RunManager:IsActivePlayer(e) return e.player end
function LOD.ProgressionDirector:Announce(...) end
local N=LOD.MazeNavigator
function N:CellCenter(c) return Vector(c.x*128,c.y*128,c.z*256) end
function N:WorldToCell(g,p)
    return g.Cells[key(math.floor(p.x/128+.5),math.floor(p.y/128+.5),math.floor(p.z/256+.5))]
end
function N:FindPath(g,from,dest,allow)
    self.pathCalls=(self.pathCalls or 0)+1
    if self.blocked then return nil end
    local path={from};local c=from
    while c.x~=dest.x or c.y~=dest.y do
        local x,y=c.x,c.y
        if x~=dest.x then x=x+(dest.x>x and 1 or -1) else y=y+(dest.y>y and 1 or -1) end
        c=g.Cells[key(x,y,c.z)]
        if not c or allow and not allow(c) then return nil end
        path[#path+1]=c
    end
    return path
end
function N:PathToWaypoints(g,path)
    local out={};for _,c in ipairs(path) do out[#out+1]={pos=self:CellCenter(c),stair=false} end;return out
end
local M=LOD.HostileMotionV2
function M:Stop(e) e.stopped=true end
function M:FaceToward(e,p) end
function M:HoldHitStun(e,now) if now<(e.LODHitStunUntil or 0) then self:Stop(e);return true end;return false end
function M:MoveToward(e,wp)
    e.moves=(e.moves or 0)+1;e.stopped=false
    local d=wp.pos-e.pos;local distance=math.sqrt(d:DistToSqr(vector_origin))
    e.pos=e.pos+d:GetNormalized()*math.min(distance,24)
end
LOD.RPGStatusElements={}
function LOD.RPGStatusElements:CanInitiateAttack(e) return not e.noAttack end
function LOD.RPGStatusElements:CanInitiateMagic(e) return not e.muted end
function LOD.RPGStatusElements:CanMoveVoluntarily(e) return not e.held end
LOD.RPGPerceptionState={IsInvisible=function(_,e) return e.invisible end}
LOD.Audio={count=0,Emit=function(self,e,cue) if cue=="boss_taunt" then self.count=self.count+1 end end}
local E={};E.__index=E
function actor(isPlayer)
    return setmetatable({pos=Vector(0,0,0),nw={},hp=1000,player=isPlayer,angles={},
        LODArchetypeId=isPlayer and "hero" or "warden",LODConfig={}},E)
end
function E:GetPos() return self.pos end
function E:WorldSpaceCenter() return self.pos+Vector(0,0,36) end
function E:Health() return self.hp end
function E:GetMaxHealth() return 1000 end
function E:IsPlayer() return self.player==true end
function E:Alive() return self.hp>0 end
function E:SetNW2Float(k,v) self.nw[k]=v end
E.SetNW2Int=E.SetNW2Float;E.SetNW2Bool=E.SetNW2Float
function E:GetNW2Float(k,d) local v=self.nw[k];if v==nil then return d end;return v end
E.GetNW2Int=E.GetNW2Float;E.GetNW2Bool=E.GetNW2Float
function E:GetNW2String(k,d) if k=="LOD_Archetype" then return self.LODArchetypeId end;return self:GetNW2Float(k,d) end
function E:EmitSound(...) end
function E:_SetActivity(a) self.activity=a end
function E:_AdvanceWaypoint()
    local index=self.LODWaypointIndex or 1;local path=self.LODWaypoints or {}
    while path[index] and path[index].pos:DistToSqr(self.pos)<1 do index=index+1 end
    self.LODWaypointIndex=index;return path[index]
end
function E:IsDormant() return self.dormant end
function E:GetNoDraw() return self.noDraw end
function E:GetModel() return self.model or "citizen" end
function E:LookupBone(name)
    self.lookups=(self.lookups or 0)+1
    if self.missingBones then return nil end
    return name
end
function E:ManipulateBoneAngles(id,angle) self.angles[id]=angle end
local V=LOD.WardenPresentation
function V:Pose(e)
    e.basePoses=(e.basePoses or 0)+1
    if e.tell and NOW<e.tell.hurtUntil then e.angles["ValveBiped.Bip01_Spine2"]=Angle(99,0,0) end
    if e:GetNW2Int("LOD_WardenPhase",0)==2 then e.seated=true end
end
function V:Tell(e) return e.tell end
local W=LOD.Warden
function W:Actors(w) local t={w};for _,c in ipairs(w.clones or {}) do t[#t+1]=c end;return t end
function W:Targets() return self.targets or {} end
function W:Route(e,...) M:Stop(e) end
function W:AddHazard(w,kind,pos,velocity,target,now) w.hazards[#w.hazards+1]={kind=kind,at=now};return true end
function W:Damage(e,p,kind) e.lastDamageKind=kind end
function fixture(clone)
    if hook.handlers.LOD_WardenDanceCleanup then hook.handlers.LOD_WardenDanceCleanup() end
    NOW=0;N.blocked=false;N.pathCalls=0;LOD.Audio.count=0
    local g={Cells={},Progression={}}
    local a={court={}}
    for x=-1,1 do for y=-1,1 do local k=key(x,y,0);g.Cells[k]={x=x,y=y,z=0};a.court[k]=g.Cells[k] end end
    g.Progression.Warden=a
    local s={Graph=g,BuildReady=true,LevelSeed=37,CampaignEpoch=1,CampaignSeed=20,RunId=1,Level=1}
    local root={phase=1,hazards={},started=true,seed=37,state=s,graph=g,epoch=1,campaignSeed=20,runId=1,level=1,clones={},cloneStates={}}
    root.actor=actor();root.actor.LODWardenOwner=root;root.hiddenUntil=3
    s.Warden=root;LOD.RunManager.State=s;W.phaseRoot=nil
    local w=root
    if clone then w={actor=actor(),phase=1,hazards={},cloneIndex=clone,hiddenUntil=3};w.actor.LODWardenOwner=root;root.clones={w};root.cloneStates[w.actor]=w end
    local p=actor(true);p.pos=Vector(0,128,0);W.targets={p}
    return s,root,w,w.actor,a,p
end
function step(e,t) NOW=t;LOD.Warden:Tick(e) end
function volley(e,w)
    step(e,0);step(e,3);step(e,3.46)
    assert(w.phaseOne.stage=="attack")
    for _,t in ipairs({4.12,4.35,4.58,4.81}) do step(e,t) end
    return w.phaseOne
end
function near(a,b) assert(math.abs(a-b)<0.000001,tostring(a).." ~= "..tostring(b)) end
function check(name,fn) fn();print("PASS: "..name);PASSED=(PASSED or 0)+1 end
-- BEGIN CHECKS --
local key,N=LOD.MazeGenerator.CellKey,LOD.MazeNavigator
local W,V=LOD.Warden,LOD.WardenPresentation
local C=W.Config
check("idempotent tuning and actual fourfold post-volley exposure",function()
    near(C.postShotExposure,4*(2-3*.22));near(C.visible,6.02);near(C.tauntDuration,6.4);near(C.tauntCooldown,3)
    local s,root,w,e=fixture();local work=volley(e,w)
    assert(#w.hazards==4 and work.stage=="taunt" and work.dancing and not w.volley)
    near(work.deadline-4.81,5.36);assert(not e:GetNW2Bool("LOD_WardenHidden",true))
end)
check("late fourth release still receives the full post-shot window",function()
    local s,root,w,e=fixture();step(e,0);step(e,3);step(e,3.46)
    for _,t in ipairs({4.12,5.5,7.5,10}) do step(e,t) end
    assert(w.phaseOne.dancing);near(w.phaseOne.deadline-10,5.36)
end)
check("first and repeated hits cannot truncate or renew the opening",function()
    local s,root,w,e=fixture();local work=volley(e,w);local finish=work.deadline
    NOW=5;W:OnEffectiveHit(e,NOW);local followup=work.followup
    for _,t in ipairs({5.1,5.8,6.7,9.9}) do NOW=t;W:OnEffectiveHit(e,NOW);near(work.followup,followup);near(work.deadline,finish) end
    near(e:GetNW2Float("LOD_WardenTauntUntil",0),finish);assert(work.dancing)
    step(e,finish-.001);assert(not e:GetNW2Bool("LOD_WardenHidden",true))
    step(e,finish);assert(w.phaseOne.stage=="hidden");near(e:GetNW2Int("LOD_WardenDanceMove",-1),0)
end)
check("early interrupt cancels remaining shots without an early disappearance",function()
    local s,root,w,e=fixture();step(e,0);step(e,3);step(e,3.46);step(e,4.12)
    local finish=w.phaseOne.deadline;NOW=4.2;W:OnEffectiveHit(e,NOW)
    assert(not w.volley and w.phaseOne.dancing);near(w.phaseOne.deadline,finish)
    step(e,5);assert(#w.hazards==1)
end)
check("standalone taunt is 6.4 seconds and emits once",function()
    local s,root,w,e=fixture();root.attackSinceTaunt=true
    step(e,0);step(e,3);step(e,3.46);near(w.phaseOne.deadline-3.46,6.4)
    assert(LOD.Audio.count==1);for i=1,20 do step(e,3.46+i*.05) end;assert(LOD.Audio.count==1)
end)
check("root and all four clone slots share the new window",function()
    for i=1,4 do local s,root,w,e=fixture(i);local work=volley(e,w);near(work.deadline-4.81,5.36)
        assert(e:GetNW2Int("LOD_WardenDanceMove",0)==i%4+1)
        NOW=5;W:OnEffectiveHit(e,NOW);assert(work.dancing)
    end
end)
check("four opening dance moves rotate without gameplay RNG",function()
    local s,root,w,e=fixture();local work=volley(e,w)
    for i=2,5 do work.dancing=nil;NOW=NOW+.01;W:StartDance(w,e,work,NOW,NOW+5);assert(e:GetNW2Int("LOD_WardenDanceMove",0)==(i-1)%4+1) end
end)
check("physical dance route crosses court and never enters a non-court cell",function()
    local s,root,w,e,a=fixture();local work=volley(e,w);local start=e:GetPos();local maxDistance=0
    for i=1,70 do step(e,4.81+i*.05);maxDistance=math.max(maxDistance,e:GetPos():DistToSqr(start))
        local c=LOD.MazeNavigator:WorldToCell(s.Graph,e:GetPos());assert(c and a.court[key(c.x,c.y,c.z)]) end
    assert(maxDistance>128^2 and e.moves>0 and e.activity==ACT_WALK)
end)
check("blocked dance route holds and retries at a bounded rate",function()
    local s,root,w,e=fixture();N.blocked=true;volley(e,w);local before=N.pathCalls
    for i=1,9 do step(e,4.81+i*.05) end
    assert(N.pathCalls==before and not e.moves and e.stopped)
end)
check("Held and finite hit-stun stop movement without renewing dance",function()
    local s,root,w,e=fixture();local work=volley(e,w);e.held=true;local pos=e:GetPos();step(e,5);near(e:GetPos():DistToSqr(pos),0)
    e.held=nil;NOW=5.1;W:OnEffectiveHit(e,NOW);e.LODHitStunUntil=99;step(e,5.2)
    near(e:GetPos():DistToSqr(pos),0);near(e.LODHitStunUntil,work.followup)
    step(e,work.followup+.01);assert(e:GetPos():DistToSqr(pos)>0)
end)
check("freeze, target loss and invisibility retire dance state",function()
    for _,reason in ipairs({"freeze","lost","invisible"}) do
        local s,root,w,e=fixture();volley(e,w)
        if reason=="freeze" then s.SimulationFrozen=true elseif reason=="lost" then W.targets={} else W.targets[1].invisible=true end
        step(e,5);assert(not w.phaseOne and not w.tauntUntil and e:GetNW2Int("LOD_WardenDanceMove",-1)==0 and e.stopped)
    end
end)
check("stale phase/campaign and dead owners cannot move or restart a dance",function()
    for _,reason in ipairs({"cycle","epoch","dead"}) do
        local s,root,w,e=fixture();volley(e,w);local moves=e.moves
        if reason=="cycle" then w.phaseCycle=w.phaseCycle+1 elseif reason=="epoch" then s.CampaignEpoch=2 else e.LODDead=true end
        step(e,5);assert(e.moves==moves)
    end
end)
check("phase two still drops bombs and clears the dance route",function()
    local s,root,w,e=fixture();volley(e,w);e.hp=500;step(e,5)
    assert(w.phase==2 and not w.phaseOne and e:GetNW2Int("LOD_WardenDanceMove",-1)==0)
    step(e,6.1);assert(w.hazards[1].kind=="bomb")
end)
check("phase three still warns and performs the crowbar strike",function()
    local s,root,w,e,a,p=fixture();e.hp=200;p.pos=e.pos;step(e,0);assert(w.phase==3 and w.swing)
    step(e,.31);assert(e.lastDamageKind=="crowbar" and not w.phaseOne)
end)
check("non-Warden Tick remains untouched",function()
    local s,root,w,e=fixture();e.LODArchetypeId="other";assert(W:Tick(e)==false and not e.moves)
end)
check("all four client moves are distinct, cached and purely bone-based",function()
    local s,root,w,e=fixture();volley(e,w);e:SetNW2Int("LOD_WardenPhase",1)
    local signatures={}
    for i=1,4 do e:SetNW2Int("LOD_WardenDanceMove",i);NOW=5.03;V:Pose(e)
        local a=e.angles["ValveBiped.Bip01_Pelvis"];signatures[i]=a.y..":"..a.r end
    for i=1,4 do for j=i+1,4 do assert(signatures[i]~=signatures[j]) end end
    assert(e.lookups==8);local pos=e.pos;for i=1,5 do NOW=5.03+i*.4;V:Pose(e) end;near(e.pos:DistToSqr(pos),0)
end)
check("private clone recoil takes priority over dance bones",function()
    local s,root,w,e=fixture(1);volley(e,w);e:SetNW2Int("LOD_WardenPhase",1)
    NOW=5;V:Pose(e);e.tell={hurt=5,hurtUntil=5.3};NOW=5.1;V:Pose(e)
    assert(e.angles["ValveBiped.Bip01_Spine2"].p==99)
end)
check("missing bones and model replacement are safe",function()
    local s,root,w,e=fixture();volley(e,w);e:SetNW2Int("LOD_WardenPhase",1);e.missingBones=true;NOW=5;V:Pose(e)
    e.model="replacement";e.missingBones=nil;V:Pose(e);assert(e.lookups==16)
end)
check("dance cleanup preserves phase-two seating and hides expired captions",function()
    local s,root,w,e=fixture();volley(e,w);e:SetNW2Int("LOD_WardenPhase",1);NOW=5;V:Pose(e)
    local before=draw.count;hook.handlers.LOD_WardenDanceCaptions();assert(draw.count>before)
    e:SetNW2Int("LOD_WardenPhase",2);V:Pose(e);assert(e.seated and not e.LODDancePosed)
    local count=draw.count;hook.handlers.LOD_WardenDanceCaptions();assert(draw.count==count)
    hook.handlers.LOD_WardenDanceCleanup()
end)
print(string.format("PASS: %d focused dancefloor behavior checks (mocked engine boundaries)",PASSED))
