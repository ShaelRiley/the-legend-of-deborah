-- SPOT-06 executes production Warden/hit-stun/receiver/render seams. Source API
-- doubles are boundaries, not a second phase implementation or native acceptance.
local base=dofile('tools/test_warden.lua')
local env,p,g=base.env,base.hero,base.graph
local W,R,P=LOD.Warden,LOD.RunManager,LOD.ProgressionDirector
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local total=0
local function check(value,label) assert(value,label);total=total+1;print('SPOT06_OK '..total..' '..label) end
local function near(a,b) return math.abs(a-b)<0.00001 end
local epoch,clock=100,1000
local function at(t) clock=t;base.time(t) end
P.Announce=noop;P.SyncAll=noop
local canMove,canAttack,canMagic=true,true,true
LOD.RPGStatusElements.CanMoveVoluntarily=function() return canMove end
LOD.RPGStatusElements.CanInitiateAttack=function() return canAttack end
LOD.RPGStatusElements.CanInitiateMagic=function() return canMagic end
local audio={}
LOD.Audio={Emit=function(_,e,id) audio[#audio+1]={actor=e,id=id,time=clock} end,ToPlayer=noop}
local function fresh(level)
    epoch=epoch+1;at(1000+epoch*20)
    P:ResetLevelState(g)
    local s=R.State;s.Graph=g;s.LevelSeed=1297;s.Level=level or 1;s.CampaignEpoch=epoch
    s.CampaignSeed=71;s.RunId='spot06-'..epoch;s.BuildReady=true;s.GatesOpen={true,true,true,true}
    s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.NeilHunt={started=true}
    p.alive=true;p.hp=100;p.player=true;p:SetPos(LOD.MazeNavigator:CellCenter(base.arena.center))
    p.KeyDown=function() return false end
    canMove=true;canAttack=true;canMagic=true
    assert(W:Prepare());assert(W:Commit());audio={}
    for _,state in ipairs(W:Actors(s.Warden)) do
        local body=state.actor
        body.GetSequence=function() return 1 end;body.GetSequenceName=function() return 'flinch' end
        body.LookupSequence=function() return 1 end;body.ResetSequence=noop;body.SetSequence=noop
        body.SetCycle=noop;body.SetPlaybackRate=noop
    end
    return s,s.Warden,s.Warden.actor,clock
end
local function step(w,e,t) at(t);return W:ServicePhaseOne(w,e,t) end
local function reveal(w,e,t)
    step(w,e,t);step(w,e,t+3);return step(w,e,t+3.46),t+3.46
end
local function damage(e,amount,took,source)
    if took~=false and amount>0 then e.hp=e:Health()-amount end
    env.hooks.LOD_BossDamagePresentation(e,{GetDamage=function() return amount end,GetAttacker=function() return source or p end},took~=false)
end
local s,w,e,t=fresh()
local route,routeCalls=W.Route,0
W.Route=function(self,...) routeCalls=routeCalls+1;return route(self,...) end
W:Tick(e)
check(w.phaseOne.stage=='hidden' and routeCalls==1,'cloaked phase consumes physical route authority')
check(not LOD.M3HitFeedback:ApplyHitStun(e,2,p,2.5),'hidden ordinary hit-stun rejected')
local hp=e:Health();damage(e,1)
check(e:Health()==hp-1 and e.nw.LOD_WardenHidden and not w.phaseOne.followup,'cloaking grants no damage immunity or new window')
step(w,e,t+3)
check(w.phaseOne.stage=='arriving' and e.nw.LOD_WardenHidden,'arrival warns before revealing')
local arrival=w.phaseOne.deadline;local anchor=w.phaseOne.position
check(near(arrival,t+3.45) and #W:Cues(clock)==1 and W:Cues(clock)[1].kind==2,'fixed .45-second actual-destination cue')
check(not LOD.M3HitFeedback:ApplyHitStun(e,2,p),'arrival cannot be stun-pinned')
at(t+3.2);e:SetPos(e:GetPos()+Vector(10,0,0));W:ServicePhaseOne(w,e,clock)
check(near(w.phaseOne.deadline,t+3.65) and w.phaseOne.position:DistToSqr(anchor)==100,'external displacement restarts full warning at actual position')
step(w,e,t+3.46)
check(e.nw.LOD_WardenHidden,'old arrival deadline cannot reveal displaced actor')
step(w,e,t+3.66);local visible=clock
check(w.phaseOne.stage=='attack' and not e.nw.LOD_WardenHidden and near(w.volley.next,visible+.65),'ordinary attack warning follows arrival warning')
local moves=routeCalls;at(visible+.2);W:Tick(e)
check(routeCalls==moves and w.volley.count==0,'visible warning neither travels nor fires early')
at(visible+.65);W:Tick(e)
check(w.volley.count==1 and #w.hazards==1,'first released orb uses unchanged attack scheduler')
local orb=w.hazards[1];at(visible+.7);damage(e,1)
local work=w.phaseOne;local finish=work.followup
check(near(finish,visible+1.9) and not w.volley,'first positive visible hit creates fixed follow-up and cancels remaining shots')
check(w.hazards[1]==orb and orb.expires==visible+.65+W.Config.shotLife,'released ordnance keeps exact original record and fuse')
for i=1,60 do
    at(visible+.7+i*.015);LOD.M3HitFeedback:ApplyHitStun(e,2,p,2.5);damage(e,.01)
end
check(work.followup==finish and work.deadline==finish,'sixty rapid/cooperative hits never renew follow-up')
check((e.LODHitStunUntil or 0)<=finish,'all ordinary hit-stun clamps to fixed window')
local cycle=w.phaseCycle;e.LODHitStunUntil=finish+100
at(finish);env.hooks.LOD_WardenOrdnance()
check(w.phaseCycle==cycle+1 and w.phaseOne.stage=='hidden' and e.nw.LOD_WardenHidden,'independent service expires window despite outer AI stun')
check(e.LODHitStunUntil<=finish and not w.volley,'deadline releases ordinary pin and cannot replay interrupted volley')
check(W:Cues(clock)[1].kind==1 and near(W:Cues(clock)[1].expires,finish+.45),'departure cue has fixed .45-second lifetime')
local frozenExpiry=W:Cues(clock)[1].expires
at(finish+.1);W:Sync();W:Sync()
check(W:Cues(clock)[1].expires==frozenExpiry,'repeated snapshots do not extend departure')
W.Route=route

-- False/zero/negative reports must not open a hit window.
s,w,e,t=fresh();work,visible=reveal(w,e,t)
at(visible+.1);damage(e,0);damage(e,-1);damage(e,10,false)
check(not work.followup and w.volley~=nil,'zero/negative/non-taken damage cannot interrupt or open window')
-- Guard the absolute exposure ceiling even under an injected late scheduler state.
work.deadline=work.cap;at(work.cap-.1);damage(e,1)
check(work.followup==work.cap,'first very late hit clamps to absolute reveal+4 ceiling')
at(work.cap);env.hooks.LOD_WardenOrdnance()
check(w.phaseOne.stage=='hidden','exact absolute ceiling never remains exposed')

-- Shared statuses cancel magic commitments without inventing a private status.
s,w,e,t=fresh();canMove=false;local moved=0;W.Route=function() moved=moved+1 end
W:Tick(e);check(moved==0,'Held prevents voluntary cloaked travel')
canMove=true;W:Tick(e);check(moved==1,'releasing Held restores ordinary route admission')
W.Route=route;canMagic=false;work,visible=reveal(w,e,t)
check(work.stage=='attack' and not w.volley,'Muted appearance never starts a magical wind-up')
canMagic=true;at(visible+.7);W:Tick(e)
check(not w.volley and #w.hazards==0,'unmuting cannot replay a cancelled appearance')
s,w,e,t=fresh();work,visible=reveal(w,e,t);canAttack=false
step(w,e,visible+.1);check(not w.volley,'shared attack prohibition cancels unreleased volley')
canAttack=true;step(w,e,visible+3)
check(w.phaseOne.stage=='hidden','status prohibition cannot extend exposure')

-- Phase transitions retain existing thresholds and clear phase-one presentation.
for _,phase in ipairs({2,3}) do
    s,w,e,t=fresh();work,visible=reveal(w,e,t);damage(e,1)
    e.hp=phase==2 and 600 or 250;at(visible+.2);env.hooks.LOD_WardenOrdnance()
    check(w.phase==phase and not w.phaseOne and not w.tauntUntil and #W:Cues(clock)==0,
        'phase '..phase..' retires exposure/cues without old attacks')
end

-- Exact identity, not equality of seed numbers, governs every new commitment.
local mutations={
    {'run object',function(st,rt,body) local replacement={};for k,v in pairs(st) do replacement[k]=v end;R.State=replacement end},
    {'campaign epoch',function(st) st.CampaignEpoch=st.CampaignEpoch+1 end},
    {'campaign seed',function(st) st.CampaignSeed=st.CampaignSeed+1 end},
    {'run id',function(st) st.RunId='replacement' end},
    {'dungeon level',function(st) st.Level=st.Level+1 end},
    {'dungeon seed',function(st) st.LevelSeed=st.LevelSeed+1 end},
    {'graph object',function(st) local replacement={};for k,v in pairs(st.Graph) do replacement[k]=v end;st.Graph=replacement end},
    {'Warden record',function(st,rt) local replacement={};for k,v in pairs(rt) do replacement[k]=v end;st.Warden=replacement end},
    {'native owner',function(st,rt,body) body.LODWardenOwner={} end},
    {'phase cycle',function(st,rt) rt.phaseCycle=rt.phaseCycle+1 end},
    {'actor-state',function(st,rt,body) rt.actor=base.actor() end},
    {'native removal',function(st,rt,body) body.valid=false end},
    {'native death',function(st,rt,body) body.LODDead=true;body.hp=0 end},
    {'failed dungeon',function(st) st.Failed=true end},
    {'cleared dungeon',function(st) st.LevelCleared=true end},
    {'unready world',function(st) st.BuildReady=false end},
}
for _,case in ipairs(mutations) do
    s,w,e,t=fresh();work,visible=reveal(w,e,t)
    W:PhaseCue(w,2,e:GetPos(),clock,.45)
    local original=R.State;case[2](s,w,e)
    check(not W:PhaseOwner(w,e,work),case[1]..' rejects stale phase work')
    W:ServicePhaseOne(w,e,clock)
    check(not w.phaseOne and not w.volley and #(w.phaseCues or {})==0,case[1]..' retires work and cues')
    R.State=original
end

-- Freeze, disappearance of the party, cleanup and clone replacement cannot heal,
-- reset progression, retain captions or create ordnance.
for _,mode in ipairs({'freeze','no targets','invisible targets'}) do
    s,w,e,t=fresh();work,visible=reveal(w,e,t);e.hp=950
    if mode=='freeze' then s.SimulationFrozen=true
    elseif mode=='no targets' then p.alive=false
    else LOD.RPGPerceptionState={IsInvisible=function() return true end} end
    env.hooks.LOD_WardenOrdnance()
    check(not w.phaseOne and not w.volley and #w.hazards==0 and #W:Cues(clock)==0,mode..' cancels presentation/attacks')
    check(e.hp==950 and w.phase==1 and s.ObjectiveStage==P.Stages.DEFEAT_WARDEN,mode..' preserves HP and progression')
    LOD.RPGPerceptionState=nil;p.alive=true;s.SimulationFrozen=false
end
s,w,e,t=fresh();reveal(w,e,t);P:ResetLevelState(g)
check(not w.phaseOne and not R.State.Warden and #W:Cues(clock)==0,'canonical reset retires previous exact owner')
s,w,e,t=fresh();reveal(w,e,t);e.LODDead=true;e.hp=0;env.hooks.LOD_WardenOrdnance()
check(not w.phaseOne and #W:Cues(clock)==0,'independent service retires removed/dead root without native mutation')

-- Real shared taunt admission and contextual captions, not per-clone cooldowns.
s,w,e,t=fresh(16);work,visible=reveal(w,e,t)
check(#w.clones==4,'existing five-actor maximum remains unchanged')
local firstClone=w.clones[1];firstClone.hiddenUntil=clock
step(firstClone,firstClone.actor,clock);step(firstClone,firstClone.actor,clock+.46)
check(firstClone.phaseOne.stage=='taunt' and near(firstClone.tauntUntil,clock+.8),'taunt is a short owned appearance after an ordinary appearance')
local nextTaunt=w.nextTaunt
check(near(nextTaunt,clock+6) and not w.attackSinceTaunt,'encounter-wide taunt lock and attack-between rule')
local speakers=0
for _,state in ipairs(W:Actors(w)) do
    if state~=firstClone then
        if state.phaseOne then state.phaseOne=nil end
        state.hiddenUntil=clock;step(state,state.actor,clock);step(state,state.actor,clock+.46)
    end
    if state.tauntUntil and clock<state.tauntUntil then speakers=speakers+1 end
end
check(speakers<=1 and w.nextTaunt==nextTaunt,'simultaneous clone appearances cannot create overlapping speakers')
for _,case in ipairs({{1,clock,nil,false},{2,nil,clock,false},{3,nil,nil,false},{4,nil,nil,true}}) do
    w.lastIncoming=case[2];w.lastHeroDamage=case[3];p.KeyDown=function() return case[4] end;IN_ATTACK=1
    check(W:TauntCaption(w,clock,{p})==case[1],'context caption '..case[1]..' selects the authored line')
end
w.lastIncoming=clock-4.01;w.lastHeroDamage=nil;p.KeyDown=function() return false end
check(W:TauntCaption(w,clock,{p})==3,'expired damage context does not pretend to be recent')
-- Start a real taunt, hit it, and prove the caption ends without losing follow-up.
s,w,e,t=fresh();work,visible=reveal(w,e,t);step(w,e,visible+2.66)
step(w,e,clock+3);w.lastIncoming=clock;step(w,e,clock+.46)
check(w.phaseOne.stage=='taunt' and W:Cues(clock)[1].caption==1,'actual taunt snapshot freezes its contextual line')
local tauntStart=clock;at(clock+.1);damage(e,1)
check(not w.tauntUntil and #W:Cues(clock)==0 and near(w.phaseOne.followup,tauntStart+1.3),'hit ends taunt but preserves full nonrenewable follow-up')
-- Only actual positive native damage to a Hero supplies outgoing context.
w.lastHeroDamage=nil
local info={GetDamage=function() return 1 end,GetAttacker=function() return e end}
env.hooks.LOD_BossDamagePresentation(p,info,false)
check(not w.lastHeroDamage,'unapplied damage is not a successful taunt context')
info.GetDamage=function() return 0 end;env.hooks.LOD_BossDamagePresentation(p,info,true)
check(not w.lastHeroDamage,'zero post-mitigation damage is not a successful taunt context')
info.GetDamage=function() return 1 end;env.hooks.LOD_BossDamagePresentation(p,info,true)
check(w.lastHeroDamage==clock,'positive native Hero damage supplies outgoing context')

-- Enforce bounded current cues without extra entities or client sound replay.
s,w,e,t=fresh(16)
for _,state in ipairs(W:Actors(w)) do
    step(state,state.actor,t)
    for i=1,40 do W:PhaseCue(state,2,state.actor:GetPos(),t,.45) end
    check(#state.phaseCues==2,'per-actor cue allocation stays at two')
end
check(#W:Cues(t)==10,'all five actors share the ten-cue ceiling')
local doomed=w.clones[1];W:Killed(doomed.actor)
check(not doomed.phaseOne and #(doomed.phaseCues or {})==0 and #W:Cues(t)==8 and not w.dead,'clone death retires only its owned phase cues')
local old=w.clones[2];local oldWork=old.phaseOne;w.cloneStates[old.actor]={actor=old.actor,phase=1}
check(not W:PhaseOwner(old,old.actor,oldWork),'replacement clone actor-state invalidates old work')
W:ServicePhaseOne(old,old.actor,clock)
check(not old.phaseOne,'replaced clone retires its old presentation')

-- Encode with production Sync, then consume exactly those fields in the actual
-- client receiver. Rendering counts prove geometry/culling, not Source appearance.
s,w,e,t=fresh();step(w,e,t);step(w,e,t+3)
local wire={};local function write(value) wire[#wire+1]=value end
for _,kind in ipairs({'Bool','UInt','Float','Vector','Entity'}) do net['Write'..kind]=write end
local function packet() wire={};W:Sync();local result=wire;wire={};return result end
local first=packet();local soundCount=#audio;local second=packet()
check(#audio==soundCount and #first==#second,'late-join/current snapshots never replay audio')
local serverHooks=env.hooks
local hooks,receivers,queue={},{},{}
hook={Add=function(_,id,fn) hooks[id]=fn end}
local function read() assert(#queue>0,'read past server snapshot');return table.remove(queue,1) end
net.Receive=function(id,fn) receivers[id]=fn end
for _,kind in ipairs({'Bool','UInt','Float','Vector','Entity'}) do net['Read'..kind]=read end
local function receive(q) queue=q;receivers.LOD_WardenState();check(#queue==0,'client consumes exact production snapshot fields') end
local low=false;local beams,sprites,models,labels=0,0,0,{}
function Material() return {} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function GetConVar() return {GetBool=function() return low end} end
local eye=e:GetPos();function EyePos() return eye end
function ScrW() return 1280 end;function ScrH() return 720 end
TEXT_ALIGN_CENTER=1;RENDERGROUP_OPAQUE=1
surface={CreateFont=noop};draw={RoundedBox=noop,SimpleText=function(text) labels[#labels+1]=text end}
getmetatable(Vector()).ToScreen=function() return {visible=true,x=600,y=300} end
render={SetMaterial=noop,SetColorMaterial=noop,DrawBeam=function() beams=beams+1 end,DrawSprite=function() sprites=sprites+1 end}
function ClientsideModel()
    models=models+1;local m={SetNoDraw=noop}
    function m:Remove() check(not self.removed,'client model removed once');self.removed=true;self.valid=false;models=models-1 end
    return m
end
dofile(root..'cl_warden.lua');receive(first)
local client=LOD.WardenPresentation
local function world() beams=0;sprites=0;hooks.LOD_WardenHazards(false,false);return beams,sprites end
local b,sp=world();check(b==12 and sp==1,'arrival square and chevrons render distinctly')
low=true;local lb,lsp=world();check(lb==b and lsp==0,'reduced effects retain identical arrival geometry')
local q={kind=1,pos=e:GetPos(),start=clock,expires=clock+.45}
beams=0;client:DrawPhaseCue(q,clock);check(beams==16,'departure uses distinct contracting ring')
beams=0;client:DrawPhaseCue(q,q.expires);check(beams==0,'exact fixed cue expiry prevents redraw')
eye=e:GetPos()+Vector(6001,0,0);b=world();check(b==0,'6000-unit render culling is preserved');eye=e:GetPos()
local before=clock;at(before+2.01);b=world();check(b==0,'stale snapshots cannot retain cues')
hooks.LOD_WardenPropsRetire();check(models==0,'snapshot timeout retires existing reusable props')
at(before);receive(second);check(models==2,'fresh snapshot reuses exactly the existing two props')
hooks.LOD_WardenPropsMapCleanup();b=world();check(models==0 and b==0,'map cleanup clears snapshot as well as models')
-- Caption snapshot, including deadline and inactive snapshot cancellation.
local captionPacket={true,e,1000,1000,1,0,1,3,e:GetPos(),clock,clock+.8,2}
receive(captionPacket);labels={};hooks.LOD_WardenHealth()
local found=false;for _,line in ipairs(labels) do if line=='Too slow.' then found=true end end
check(found,'actual client HUD renders authored contextual caption')
receive({false});labels={};hooks.LOD_WardenHealth();b=world()
check(#labels==0 and b==0,'inactive snapshot clears caption and geometry')
hooks.LOD_WardenPropsRetire();check(models==0,'inactive snapshot cleans props without new models')
print('SPOT06_GORDON_PASS '..total..'/'..total..' production assertions; native timing/audio/co-op unaccepted')
