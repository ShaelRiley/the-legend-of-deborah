-- Execute production Warden admission/transport/shared hit-stun and client art.
-- Only Source engine boundaries are doubled. This is not native acceptance.
local base=dofile('tools/test_warden.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local W,R,P=LOD.Warden,LOD.RunManager,LOD.ProgressionDirector
local noop=function() end
local function shallow(t) local copy={};for k,v in pairs(t) do copy[k]=v end;return copy end
local total,clock,epoch,frame=0,10000,600,0
local function check(ok,label) assert(ok,label);total=total+1;print('SPOT07_OK '..total..' '..label) end
local function near(a,b) return math.abs(a-b)<.00001 end
local function at(t) clock=t;frame=frame+1;base.time(t) end
function FrameNumber() return frame end
MASK_VISIBLE=77
local function boundary(e)
    function e:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
    e.GetNW2Int=e.GetNW2Bool;e.GetNW2Float=e.GetNW2Bool;e.GetNW2String=e.GetNW2Bool
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    function e:GetNoDraw() return self.noDraw==true end
    function e:IsDormant() return self.dormant==true end
    function e:EyePos() return self:GetPos()+Vector(0,0,64) end
    function e:GetModel() return self.model or 'models/Humans/Group01/male_02.mdl' end
    e.LookupSequence=function() return 1 end;e.ResetSequence=noop;e.SetCycle=noop;e.SetPlaybackRate=noop
    e.GetSequence=function() return 1 end;e.GetSequenceName=function() return "flinch" end;e.SetSequence=noop
    e.nw.LOD_Archetype=e.LODArchetypeId
    return e
end
local p=boundary(base.hero)
p.ps={identity='hero-a',ordinal=11,progressionState={derivedStats={wisMod=4}}}
p.nw.LOD_HeroSerial=11;p.nw.LOD_Deployed=true
p.player=true;p.LODHostile=false;p.active=true
local poor=boundary(base.actor());poor.player=true;poor.LODHostile=false;poor.active=true
poor.ps={identity='hero-b',ordinal=12,progressionState={derivedStats={wisMod=0}}}
poor.nw.LOD_Deployed=true;poor.nw.LOD_HeroSerial=12
local players={p,poor}
player.GetAll=function() return players end
R.GetPlayerState=function(_,e) return e.ps end
R.IsActivePlayer=function(_,e) return e.active and not e.nw.LOD_IsSoldier and e.nw.LOD_Deployed end
LOD.RPG=LOD.RPG or {}
-- Real canonical Derived/ProgressionState/CHA stun delegates, not an invented WIS formula.
dofile(root..'sv_rpg_gate_d.lua')
local status=LOD.RPGStatusElements
status.ActorLives={};status.CanInitiateMagic=function() return true end
P.Announce=noop;P.SyncAll=noop
local traceMode,traceEntity,traces,lastTrace='clear',nil,0,nil
util.TraceLine=function(spec)
    traces=traces+1;lastTrace=spec
    return {Hit=traceMode=='blocked',StartSolid=traceMode=='inside',Entity=traceEntity}
end
local function fresh()
    epoch=epoch+1;at(10000+epoch*20)
    P:ResetLevelState(base.graph)
    local s=R.State;s.Graph=base.graph;s.LevelSeed=1297;s.Level=16;s.CampaignEpoch=epoch
    s.CampaignSeed=71;s.RunId='spot07-'..epoch;s.BuildReady=true;s.GatesOpen={true,true,true,true}
    s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.NeilHunt={started=true}
    p.alive=true;p.hp=100;p.active=true;p.nw.LOD_IsSoldier=false;p.nw.LOD_Deployed=true
    p.nw.LOD_Staged=false;p.nw.LOD_Eliminated=false;p.ps.progressionState.derivedStats.wisMod=4
    p:SetPos(LOD.MazeNavigator:CellCenter(base.arena.center));poor:SetPos(p:GetPos())
    status.ActorLives[p]={};status.ActorLives[poor]={};traceMode='clear';traceEntity=nil
    assert(W:Prepare() and W:Commit())
    local w=s.Warden
    for _,a in ipairs(W:Actors(w)) do boundary(a.actor);W:ServicePhaseOne(a,a.actor,clock) end
    at(clock+5)
    for _,a in ipairs(W:Actors(w)) do W:ServicePhaseOne(a,a.actor,clock) end
    at(clock+.46)
    for _,a in ipairs(W:Actors(w)) do W:ServicePhaseOne(a,a.actor,clock) end
    for i,a in ipairs(w.clones) do
        a.actor:SetPos(p:GetPos()+Vector(i*8,0,0));a.actor.nw.LOD_WardenHidden=i~=1
    end
    return s,w,w.clones[1],w.clones[1].actor
end
local s,w,c,e=fresh()
for _,case in ipairs({{-4,0,0},{0,0,0},{1,192,1},{1,192.01,0},{2,384,1},{3,576,1},{3,576.01,0}}) do
    p.ps.progressionState.derivedStats.wisMod=case[1];e:SetPos(p:GetPos()+Vector(case[2],0,0))
    check(#W:TellRecords(p,clock)==case[3],'canonical Wisdom '..case[1]..' at '..case[2]..' units')
end
p.ps.progressionState.derivedStats.wisMod=3;e:SetPos(p:GetPos()+Vector(0,0,576))
check(#W:TellRecords(p,clock)==1,'inclusive 3D vertical boundary')
e:SetPos(p:GetPos()+Vector(0,0,576.01));check(#W:TellRecords(p,clock)==0,'no planar/cross-floor distance shortcut')
e:SetPos(p:GetPos()+Vector(460,460,0));check(#W:TellRecords(p,clock)==0,'Euclidean rather than square/Chebyshev radius')
e:SetPos(p:GetPos()+Vector(8,0,0))
for _,mode in ipairs({'blocked','inside'}) do traceMode=mode;check(#W:TellRecords(p,clock)==0,mode..' sightline fails closed') end
traceMode='blocked';traceEntity=e;check(#W:TellRecords(p,clock)==1,'trace may terminate on the actual observed actor')
check(lastTrace.mask==MASK_VISIBLE and lastTrace.filter==p and lastTrace.start.z==p:EyePos().z,'actual eye-to-body visibility query')
traceMode='clear';traceEntity=nil
check(#W:TellRecords(poor,clock)==0,'nearby zero-Wisdom Hero learns nothing from another Hero')
poor.ps.progressionState.derivedStats.wisMod=1
check(#W:TellRecords(poor,clock)==1,'current canonical derived-stat increase is observed')
poor.ps.progressionState.derivedStats.wisMod=0
check(#W:TellRecords(poor,clock)==0,'canonical derived-stat reduction revokes next receipt')
for _,field in ipairs({'active','alive'}) do local old=p[field];p[field]=false;check(#W:TellRecords(p,clock)==0,'observer '..field..' eligibility');p[field]=old end
p.nw.LOD_IsSoldier=true;check(#W:TellRecords(p,clock)==0,'human Soldier receives no Hero tell');p.nw.LOD_IsSoldier=false
p.nw.LOD_Deployed=false;check(#W:TellRecords(p,clock)==0,'staged/nondeployed Hero receives no tell');p.nw.LOD_Deployed=true
local profile=p.ps.progressionState;p.ps.progressionState=nil
check(#W:TellRecords(p,clock)==0,'missing canonical progression fails closed');p.ps.progressionState=profile
for _,value in ipairs({0/0,math.huge,-math.huge}) do profile.derivedStats.wisMod=value;check(#W:TellRecords(p,clock)==0,'nonfinite Wisdom fails closed') end
profile.derivedStats.wisMod=4

-- Change one identity at a time; do not replace production owner/admission code.
local changes={
 {'run object',function() local old=R.State;R.State=shallow(old);return function() R.State=old end end},
 {'graph',function() local old=s.Graph;s.Graph=shallow(old);return function() s.Graph=old end end},
 {'campaign epoch',function() local old=s.CampaignEpoch;s.CampaignEpoch=old+1;return function() s.CampaignEpoch=old end end},
 {'campaign seed',function() local old=s.CampaignSeed;s.CampaignSeed=old+1;return function() s.CampaignSeed=old end end},
 {'run ID',function() local old=s.RunId;s.RunId='other';return function() s.RunId=old end end},
 {'level',function() s.Level=17;return function() s.Level=16 end end},
 {'level seed',function() s.LevelSeed=1;return function() s.LevelSeed=1297 end end},
 {'Warden record',function() s.Warden={seed=1297};return function() s.Warden=w end end},
 {'clone actor-state',function() w.cloneStates[e]={};return function() w.cloneStates[e]=c end end},
 {'native owner',function() e.LODWardenOwner={};return function() e.LODWardenOwner=w end end},
 {'native token',function() e.nw.LOD_WardenVisualLife=c.visualLife+1;return function() e.nw.LOD_WardenVisualLife=c.visualLife end end},
 {'clone state death',function() c.dead=true;return function() c.dead=false end end},
 {'native clone death',function() e.LODDead=true;return function() e.LODDead=false end end},
 {'native removal',function() e.valid=false;return function() e.valid=true end end},
 {'root death',function() w.dead=true;return function() w.dead=false end end},
 {'root removal',function() w.actor.valid=false;return function() w.actor.valid=true end end},
 {'cloaking',function() e.nw.LOD_WardenHidden=true;return function() e.nw.LOD_WardenHidden=false end end},
 {'NoDraw',function() e.noDraw=true;return function() e.noDraw=false end end},
 {'freeze',function() s.SimulationFrozen=true;return function() s.SimulationFrozen=false end end},
 {'failed run',function() s.Failed=true;return function() s.Failed=false end end},
 {'cleared level',function() s.LevelCleared=true;return function() s.LevelCleared=false end end},
 {'unready build',function() s.BuildReady=false;return function() s.BuildReady=true end end},
 {'no targets',function() LOD.RPGPerceptionState={IsInvisible=function() return true end};return function() LOD.RPGPerceptionState=nil end end}
}
for _,case in ipairs(changes) do local restore=case[2]();check(#W:TellRecords(p,clock)==0,case[1]..' invalidates admission');restore() end
check(#W:TellRecords(p,clock)==1,'valid current owner remains observable after rejection cases')
check(not W:TellVisible(p,w,10000),'real Gordon can never be a fake tell')
check(e.nw.LOD_WardenClone==nil and e.nw.LOD_MonsterName=='Gordon the Warden','no global fake name/ordinal label')
local rng=math.random;math.random=function() error('cosmetic stream touched global combat randomness') end
local eyes={}
for cycle=0,31 do
    local a,b=W:TellEye(c,c.tellEpoch+cycle*2.4+.01)
    local same,start=W:TellEye(c,c.tellEpoch+cycle*2.4+.01)
    assert(a==same and b==start);eyes[a]=true
end
math.random=rng
check(eyes[0] and eyes[1],'separately seeded deterministic cycles reach either eye without global RNG')

-- Native transport boundary: record field types/widths as well as values.
local sent,current={},nil
net.Start=function(name) current={name=name,fields={}} end
for _,kind in ipairs({'Bool','UInt','Float','Vector','Entity'}) do
    net['Write'..kind]=function(value,bits) assert(current);current.fields[#current.fields+1]={kind=kind,value=value,bits=bits} end
end
net.Send=function(recipient) current.recipient=recipient;sent[#sent+1]=current;current=nil end
net.Broadcast=function() current.broadcast=true;sent[#sent+1]=current;current=nil end
local function sync() sent={};W:SyncTells();return sent end
local packets=sync()
check(#packets==1 and packets[1].recipient==p and not packets[1].broadcast,'only the eligible observer receives private identity')
local token=W.tellObservers[p].token
local oldProfile=p.ps.progressionState;p.ps.progressionState={derivedStats={wisMod=4}};sync()
check(W.tellObservers[p].token~=token,'new canonical Hero profile changes receipt lifetime');token=W.tellObservers[p].token
status.ActorLives[p]={};sync();check(W.tellObservers[p].token~=token,'new shared combat life changes receipt lifetime')
base.env.hooks.LOD_WardenTellObserverLife(p)
check(p.nw.LOD_WardenObserverLife==0 and not W.tellObservers[p],'native observer lifecycle retires private authorization')
for _,clone in ipairs(w.clones) do clone.actor.nw.LOD_WardenHidden=false end
packets=sync();check(#packets==1 and packets[1].fields[1].value==4 and packets[1].fields[1].bits==3,'maximum four clone records at bounded wire width')
local expiry=packets[1].fields[3].value
check(near(expiry,clock+.4),'server authors a fixed .4-second lease')
local serial=W.visualSerial
p.ps.progressionState.derivedStats.wisMod=0;packets=sync()
check(#packets==1 and #packets[1].fields==1 and packets[1].fields[1].value==0,'loss of Wisdom sends a private revocation, not fake data')
packets=sync();check(#packets==0 and W.visualSerial==serial,'ineligible scans create no token/network churn')
p.ps.progressionState.derivedStats.wisMod=4

-- Real shared stun admission: no duplicate retrigger, no new status authority.
s,w,c,e=fresh()
e.LODHitStunUntil=nil;e.LODNextHitStun=nil
local hp=e:Health()
check(LOD.M3HitFeedback:ApplyHitStun(e,1,p),'ordinary shared hit-stun admits a visible fake')
check(c.tellHit and near(c.tellHit.expires,math.min(clock+.35,e.LODHitStunUntil)),'fake recoil is bounded by actual remaining shared stun')
local hit=c.tellHit
check(not LOD.M3HitFeedback:ApplyHitStun(e,1,p) and c.tellHit==hit,'rejected duplicate cannot restart cosmetic hit reaction')
e.hp=hp-1;base.env.hooks.LOD_BossDamagePresentation(e,{GetDamage=function() return 1 end,GetAttacker=function() return p end},true)
local finish=c.phaseOne.followup
check(near(finish,clock+1.2) and c.tellHit==hit and not c.volley,'effective damage retains SPOT-06 fixed follow-up and cancelled unreleased shots')
for i=1,10 do at(clock+.01);base.env.hooks.LOD_BossDamagePresentation(e,{GetDamage=function() return .01 end},true) end
check(c.phaseOne.followup==finish and e:Health()==hp-1,'presentation cannot extend exposure or apply extra damage')
local records=W:TellRecords(p,clock);check(records[1].hurt==hit.start,'admitted stun is carried in actual private record')
e.LODHitStunUntil=clock;records=W:TellRecords(p,clock)
check(records[1].hurt==0 and records[1].hurtUntil==0,'early shared-stun end cannot retain a reaction')
W:SetPhase(c,e,2,clock);check(not c.tellHit and #W:TellRecords(p,clock)==1,'visible later phase retains tells but discards old recoil')
W:SetPhase(c,e,3,clock);check(#W:TellRecords(p,clock)==1,'phase three retains observer-specific tells')
W:OnTellHitStun(w.actor,clock);check(not w.tellHit,'real Gordon gets no fake reaction')
e.nw.LOD_WardenHidden=true;e.LODHitStunUntil=clock+1;W:OnTellHitStun(e,clock)
check(not c.tellHit,'cloaked actor gets no fake reaction')

-- Fresh exact production packets for the actual client receiver and art.
s,w,c,e=fresh();e.LODHitStunUntil=nil;e.LODNextHitStun=nil
assert(LOD.M3HitFeedback:ApplyHitStun(e,1,p));at(clock+.10)
-- Keep the eyelid interval current independently of the hit reaction.
c.tellEpoch=clock-.10
sent={};W:Sync();local public=sent[1];local private=sync()[1]
local sourceHooks=base.env.hooks
local hooks,receivers,queue={},{},{}
hook={Add=function(_,id,fn) hooks[id]=fn end}
net.Receive=function(id,fn) receivers[id]=fn end
for _,kind in ipairs({'Bool','UInt','Float','Vector','Entity'}) do
    net['Read'..kind]=function(bits)
        local field=table.remove(queue,1);assert(field and field.kind==kind and field.bits==bits,'wire type/width mismatch')
        return field.value
    end
end
local function receive(packet)
    queue={};for _,field in ipairs(packet.fields) do queue[#queue+1]=field end
    receivers[packet.name]();check(#queue==0,'receiver consumes exact '..packet.name..' production wire')
end
local function copyPacket(packet)
    local out={name=packet.name,fields={}}
    for i,v in ipairs(packet.fields) do out.fields[i]={kind=v.kind,value=v.value,bits=v.bits} end
    return out
end
local low=false
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function Material() return {} end
function CreateMaterial() return {} end
function GetConVar() return {GetBool=function() return low end} end
function LocalPlayer() return p end
function EyePos() return p:EyePos() end
function ScrW() return 1280 end;function ScrH() return 720 end
local angle={};angle.__index=angle
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},angle) end
function angle:Forward() return Vector(1,0,0) end
function angle:Right() return Vector(0,1,0) end
function angle:Up() return Vector(0,0,1) end
surface={CreateFont=noop};draw={RoundedBox=noop,SimpleText=noop}
local models=0
function ClientsideModel()
    models=models+1;return {SetNoDraw=noop,Remove=function(self) self.valid=false;models=models-1 end}
end
local shapes,modulation,errors={}, {.8,.7,.6},0
render={SetMaterial=noop,SetColorMaterial=noop,DrawBeam=noop,DrawSprite=noop,
    GetColorModulation=function() return table.unpack(modulation) end,
    SetColorModulation=function(r,g,b) modulation={r,g,b} end,
    DrawSphere=function(pos,radius,segments,rings,color) shapes[#shapes+1]={kind='sphere',pos=pos,radius=radius,segments=segments,color=color} end,
    DrawQuad=function(a,b,c,d,color) shapes[#shapes+1]={kind='quad',color=color} end}
function ErrorNoHalt() errors=errors+1 end
local function renderBoundary(body)
    body.bones={};body.boneIDs={};body.nextBone=0
    function body:LookupBone(name)
        if self.missingBones then return end
        if not self.boneIDs[name] then self.nextBone=self.nextBone+1;self.boneIDs[name]=self.nextBone end
        return self.boneIDs[name]
    end
    function body:ManipulateBoneAngles(id,a) self.bones[id]=a end
    body.ManipulateBoneScale=noop
    function body:LookupAttachment() return self.missingAttachment and 0 or 1 end
    function body:GetAttachment() return {Pos=self:GetPos()+Vector(0,0,64),Ang=Angle()} end
    function body:GetBoneMatrix() return nil end
    function body:GetAngles() return Angle() end
    function body:DrawModel() self.drawColor={table.unpack(modulation)};if self.drawError then error('native draw boundary failure') end end
end
for _,body in ipairs({w.actor,e}) do renderBoundary(body) end
LOD.Equipment.StatusOrder={};LOD.MagicArea={Colors={}}
dofile(root..'cl_warden.lua');local V=LOD.WardenPresentation
receive(public);receive(private);check(models==2,'tells add zero models to the existing two reusable Warden props')
traces=0;check(V:Tell(e) and not V:Tell(w.actor),'actual client recognizes only admitted fake')
V:Tell(e);V:Tell(e);check(traces==1,'one visibility trace per admitted actor per frame')
local health=e.Health;e.Health=function() return 0 end;at(clock)
check(V:Tell(e),'client Health is not invented as custom-hostile death authority');e.Health=health
shapes={};V:DrawPigMask(e,1)
local spheres,quads,tongue=0,0,false
for _,q in ipairs(shapes) do if q.kind=='sphere' then spheres=spheres+1 else quads=quads+1 end;if q.color.r==244 then tongue=true end end
check(spheres==6 and quads==12 and tongue,'actual fake mask draws one closed eye and protruding tongue')
check(shapes[1].color.r==187 and shapes[1].segments==16,'subtle greenish mask tint in full effects')
low=true;shapes={};V:DrawPigMask(e,1)
check(#shapes==18 and shapes[1].segments==10,'reduced effects retain wink/tongue/tint geometry')
low=false
V:Pose(e)
local spine=e.boneIDs['ValveBiped.Bip01_Spine2']
local function restoredSpine() return near(e.bones[spine].r,(e:GetNW2Float('LOD_WardenTauntUntil',0)>clock) and math.sin(clock*12)*12.5 or 0) end
check(e.bones[spine] and math.abs(e.bones[spine].r)>1,'actual fake hit-stun pose adds distinct sideways recoil')
V:Pose(w.actor)
check(not w.actor.bones[w.actor.boneIDs['ValveBiped.Bip01_Spine2'] or -1],'real Gordon does not receive fake recoil')
dofile(root..'cl_monster_identity.lua')
e.nw.LOD_MonsterClass='wizard';LOD.MonsterIdentity:DrawBody(e)
check(near(e.drawColor[1],.8*.92*.86) and near(e.drawColor[3],.6*.90),'body tint composes with existing class tint')
check(near(modulation[1],.8) and near(modulation[2],.7) and near(modulation[3],.6),'ordinary native draw restores prior modulation')
e.drawError=true;LOD.MonsterIdentity:DrawBody(e);e.drawError=false
check(errors==1 and near(modulation[1],.8) and near(modulation[3],.6),'draw errors still restore render state')
local originalPos=e:GetPos();e:SetPos(p:GetPos()+Vector(2000,0,0));at(clock)
check(not V:Tell(e),'client rechecks physical distance before drawing')
hooks.LOD_WardenPropsRetire();check(restoredSpine(),'loss of eligibility removes recoil while preserving ordinary taunt pose')
e:SetPos(originalPos);at(clock);check(V:Tell(e),'current unexpired observation may be reacquired, not a permanent reveal')
for _,mode in ipairs({'blocked','inside'}) do traceMode=mode;at(clock);check(not V:Tell(e),'client '..mode..' LOS rejects presentation') end
traceMode='clear'
local invalidations={
 {'observer role',p.nw,'LOD_IsSoldier',true}, {'staging',p.nw,'LOD_Staged',true},
 {'observer lifetime',p.nw,'LOD_WardenObserverLife',0}, {'Hero serial',p.nw,'LOD_HeroSerial',99},
 {'native lifetime',e.nw,'LOD_WardenVisualLife',0}, {'root lifetime',w.actor.nw,'LOD_WardenVisualLife',0},
 {'phase transition',e.nw,'LOD_WardenPhase',2}, {'cloak',e.nw,'LOD_WardenHidden',true},
 {'death pulse',e.nw,'LOD_DeathPulseStart',clock}, {'retired owner',e.nw,'LOD_AudioRetired',true},
 {'PVS loss',e,'dormant',true}, {'removed clone',e,'valid',false}, {'removed root',w.actor,'valid',false}
}
for _,case in ipairs(invalidations) do
    local old=case[2][case[3]];case[2][case[3]]=case[4];at(clock)
    check(not V:Tell(e),case[1]..' rejects cached client truth');case[2][case[3]]=old
end
LOD.ClientState={failed=true};at(clock);check(not V:Tell(e),'failed client world suppresses tell');LOD.ClientState=nil
at(clock);V:Pose(e);check(e.bones[spine].r~=0,'reaction can resume only inside its original lifetime')
V:ClearTells();check(restoredSpine() and not V:Tell(e),'explicit revocation restores pose and clears identity')
receive(private);at(clock);V:Pose(e);e.nw.LOD_Archetype='soldier';at(clock);hooks.LOD_WardenPropsRetire()
check(e.bones[spine].r==0 and not V:Tell(e),'archetype replacement removes old fake bone manipulation')
e.nw.LOD_Archetype='warden';at(clock);V:Pose(e)
receive({name='LOD_WardenState',fields={{kind='Bool',value=false}}})
check(not V:Tell(e) and restoredSpine(),'inactive public owner revokes same-frame private cache and recoil')
receive(public)
local nearExpiry=private.fields[3].value
local rejected=copyPacket(private);rejected.fields[1].value=0;rejected.fields={rejected.fields[1]}
receive(private);V:Pose(e);receive(rejected)
check(not V:Tell(e) and restoredSpine(),'actual zero-record private revocation removes art and recoil')
receive(private);e.missingAttachment=true;e.missingBones=true;shapes={};V:DrawPigMask(e,1);V:Pose(e)
check(#shapes==0,'missing attachment/bones never float mask at actor origin or throw')
e.missingAttachment=false;e.missingBones=false
local untilTime=private.fields[3].value;at(untilTime);hooks.LOD_WardenPropsRetire()
check(not V:Tell(e) and restoredSpine(),'exact fixed receipt expiry clears recognition and pose')
receive(private);check(not V:Tell(e),'late stale packet cannot restart recognition')
at(untilTime-.2);local future=copyPacket(private);future.fields[2].value=clock+1;future.fields[3].value=clock+1.4
receive(future);check(not V:Tell(e),'future-authored packet fails closed')
local replaced=copyPacket(private);replaced.fields[5].value=replaced.fields[5].value+1
receive(replaced);check(not V:Tell(e),'stale wire cannot attach to replacement root')
local absent=copyPacket(private);absent.fields[9].value=nil
receive(absent);check(not V:Tell(e),'unavailable native entity in packet cannot throw or reveal')
receive(private);at(clock);hooks.LOD_WardenPropsMapCleanup()
check(models==0 and not V:Tell(e),'map cleanup retires private state and existing props')
receive(public);receive(private);V:Pose(e)
dofile(root..'cl_warden.lua');V=LOD.WardenPresentation
check(models==0 and not V:Tell(e) and restoredSpine(),'client module replacement clears old callbacks/poses without extra models')
print('SPOT07_TELLS_PASS '..total..'/'..total..' production assertions; native appearance/co-op/performance unaccepted')
