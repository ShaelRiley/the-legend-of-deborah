-- Actual production modules, native/network/audio boundaries doubled. No audibility claim.
local base=os.getenv('LOD_SPOT04_BASELINE')
local function source(path) return (base and (base..'/') or '')..path end
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local passed,failed=0,0
local function test(name,fn)
    local ok,err=pcall(fn)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name..': '..tostring(err)) end
end
local noop=function() end
function string.EndsWith(s,suffix) return s:sub(-#suffix)==suffix end
function IsValid(e) return type(e)=='table' and e.valid~=false end
local function nw(e,k,d) local v=e.nw[k];if v==nil then return d end return v end
local function client()
    local c={now=10,hooks={},created=0,stops=0,plays=0,errors={},packets={},silent=false}
    LOD={ClientTopologyIdentity={key='1:1:1:123',buildSerial=1},Audio={Muted=function() return c.silent end}}
    function CurTime() return c.now end
    function EyePos() return 0 end
    function LocalPlayer() return {GetNW2Bool=function() return c.staged end} end
    function Color(...) return {...} end
    function ErrorNoHalt(err) c.errors[#c.errors+1]=err end
    hook={Add=function(_,id,fn) c.hooks[id]=fn end,Remove=function(_,id) c.hooks[id]=nil end}
    file={Exists=function() return true end};halo={Add=noop}
    net={Receive=function(id,fn) c.packets[id]=fn end}
    function c:actor(dist,build)
        return {nw={LOD_RosterAlive=true,LOD_AudioBuild=build or 1},distance=dist or 100,
            GetPos=function(e) return {DistToSqr=function() return e.distance end} end,
            GetNW2Bool=nw,GetNW2Float=nw,GetNW2Int=nw,IsDormant=function(e) return e.dormant end}
    end
    function CreateSound(ent,path)
        if c.noPatch then return end
        c.created=c.created+1
        local p={path=path}
        function p:SetSoundLevel(level)
            self.level=level
            if c.onLevel then c.onLevel(self) end
            if c.failLevel then error('injected level failure') end
        end
        function p:PlayEx(volume,pitch)
            assert(not self.stopped,'restarted detached patch')
            c.plays=c.plays+1;self.volume=volume;self.pitch=pitch
            if c.onPlay then c.onPlay(self) end
            if c.failPlay then error('injected play failure') end
        end
        function p:Stop()
            assert(not self.stopped,'double stop');self.stopped=true;c.stops=c.stops+1
            if c.onStop then c.onStop(self) end
            if c.failStop then error('injected stop failure') end
        end
        return p
    end
    dofile(source(root..'cl_loop_audio.lua'));c.A=LOD.LoopAudio
    function c:touch(e,group) return self.A:Touch(group or 'gas',e,'test-loop',.2,100,60,.35) end
    function c:tick() self.hooks.LOD_LoopAudioLeases() end
    function c:watch(e)
        if not self.packets.LOD_RPGSixthSenseSnapshot then dofile(source(root..'cl_rpg_sixth_sense.lua')) end
        local stream=e and {0,0,1,e} or {0,0,0};local index=0
        local function read() index=index+1;return stream[index] end
        net.ReadUInt=read;net.ReadEntity=read
        self.packets.LOD_RPGSixthSenseSnapshot()
    end
    return c
end

test('living gas starts at original level, volume share and pitch',function()
    local c=client();local p=c:touch(c:actor());assert(p and p.level==60 and p.volume==.1 and p.pitch==100)
end)
test('1000 renewals keep one owned patch',function()
    local c=client();local e=c:actor();for _=1,1000 do c:touch(e) end;assert(c.created==1)
end)
test('nearest-two cap and displacement retained',function()
    local c=client();c:touch(c:actor(100));c:touch(c:actor(200));c:touch(c:actor(300));assert(c.created==2)
    c:touch(c:actor(1));assert(c.created==3 and c.stops==1)
end)
test('ordinary finite lease expires',function()
    local c=client();c:touch(c:actor());c.now=c.now+.36;c:tick();assert(c.stops==1)
end)
test('maximum watcher lease remains two seconds',function()
    local c=client();local e=c:actor();c.A:Touch('watcher',e,'x',1,100,70,1000)
    c.now=c.now+2.01;c:tick();assert(c.stops==1)
end)
test('death presentation stops loop while corpse is valid',function()
    local c=client();local e=c:actor();c:touch(e);e.nw.LOD_DeathPulseStart=c.now;c:tick()
    assert(IsValid(e) and c.stops==1 and not c:touch(e))
end)
test('server audio retirement rejects previously unaudible corpse',function()
    local c=client();local e=c:actor();e.nw.LOD_AudioRetired=true;assert(not c:touch(e,'watcher') and c.created==0)
end)
test('gas retirement rejects stale draw renewal',function()
    local c=client();local e=c:actor();c:touch(e);e.nw.LOD_RosterAlive=false
    assert(not c:touch(e) and c.stops==1)
end)
test('one dead enemy leaves another living enemy audible',function()
    local c=client();local a,b=c:actor(),c:actor();c:touch(a);local live=c:touch(b)
    a.nw.LOD_AudioRetired=true;c:tick();assert(c.stops==1 and c:touch(b)==live and not live.stopped)
end)
test('actual Sixth Sense authorization starts watcher loop',function()
    local c=client();local e=c:actor();c:watch(e);assert(c.A.Groups.watcher[e] and c.created==1)
end)
test('late actual Sixth Sense packet cannot renew dying watcher',function()
    local c=client();local e=c:actor();c:watch(e);e.nw.LOD_DeathPulseStart=c.now
    c:watch(e);assert(c.created==1 and c.stops==1 and not c.A.Groups.watcher[e])
end)
test('actual Sixth Sense revocation stops its owned loop',function()
    local c=client();c:watch(c:actor());c:watch();assert(c.stops==1)
end)
test('custom hostile does not rely on unreplicated client health',function()
    local c=client();local e=c:actor();e.Health=function() error('client health is not authority') end
    assert(c:touch(e,'watcher'))
end)
test('permanent removal is terminal even before IsValid turns false',function()
    local c=client();local e=c:actor();c:touch(e);c.hooks.LOD_LoopAudioEntityRemoved(e,false)
    assert(IsValid(e) and not c:touch(e) and c.stops==1)
end)
test('repeated removal and cleanup stop a patch only once',function()
    local c=client();local e=c:actor();c:touch(e)
    c.hooks.LOD_LoopAudioEntityRemoved(e,false);c.hooks.LOD_LoopAudioEntityRemoved(e,false);c.A:Reset()
    assert(c.stops==1 and #c.errors==0)
end)
test('full-update removal permits legitimate living renewal',function()
    local c=client();local e=c:actor();c:touch(e);c.hooks.LOD_LoopAudioEntityRemoved(e,true)
    assert(c:touch(e) and c.created==2 and c.stops==1)
end)
test('dormant owner stops and cannot renew out of PVS',function()
    local c=client();local e=c:actor();c:touch(e);e.dormant=true;c:tick()
    assert(c.stops==1 and not c:touch(e))
end)
test('transmission loss stops before dormant flag updates',function()
    local c=client();local e=c:actor();c:touch(e);c.hooks.LOD_LoopAudioTransmit(e,false);assert(c.stops==1)
end)
test('returning living PVS owner can renew',function()
    local c=client();local e=c:actor();c:touch(e);e.dormant=true;c:tick();e.dormant=false
    assert(c:touch(e) and c.created==2)
end)
test('same-seed different build stops prior owners',function()
    local c=client();local e=c:actor();c:touch(e)
    LOD.ClientTopologyIdentity={key='2:1:1:123',buildSerial=2};c:tick()
    assert(c.stops==1 and not c:touch(e))
end)
test('new build rejects previously unseen stale entity callback',function()
    local c=client();LOD.ClientTopologyIdentity={key='2:1:1:123',buildSerial=2}
    assert(not c:touch(c:actor(100,1),'watcher') and c.created==0)
end)
test('new build owner starts before next maintenance Think',function()
    local c=client();c:touch(c:actor());LOD.ClientTopologyIdentity={key='2:1:1:123',buildSerial=2}
    assert(c:touch(c:actor(100,2)) and c.stops==1)
end)
test('ordinary same-build identity snapshot preserves audio',function()
    local c=client();local e=c:actor();local p=c:touch(e);LOD.ClientTopologyIdentity={key='1:1:1:123',buildSerial=1}
    c:tick();assert(c:touch(e)==p and c.stops==0)
end)
test('fuse survives caster death but not projectile retirement',function()
    local c=client();local e=c:actor();e.nw.LOD_AudioRetired=true;e.nw.LOD_DeathPulseStart=c.now
    assert(c:touch(e,'fuse'));c.hooks.LOD_LoopAudioEntityRemoved(e,false);assert(not c:touch(e,'fuse'))
end)
test('fuse cannot restart across same-seed rebuild',function()
    local c=client();local e=c:actor();c:touch(e,'fuse');LOD.ClientTopologyIdentity={key='2:1:1:123',buildSerial=2}
    assert(not c:touch(e,'fuse') and c.stops==1)
end)
for _,mode in ipairs({'staging','failed','levelCleared','generation'}) do
    test(mode..' suspends loops without globally disabling later living audio',function()
        local c=client();local e=c:actor();c:touch(e)
        if mode=='staging' then c.staged=true elseif mode=='generation' then c.silent=true else LOD.ClientState={[mode]=true} end
        c:tick();assert(c.stops==1 and not c:touch(e))
        c.staged=false;c.silent=false;LOD.ClientState=nil;assert(c:touch(e))
    end)
end
test('map cleanup rejects stale owners but permits new entities',function()
    local c=client();local e=c:actor();c:touch(e);c.hooks.LOD_LoopAudioCleanup()
    assert(not c:touch(e) and c:touch(c:actor()))
end)
test('shutdown is terminal for late callbacks including unseen owners',function()
    local c=client();c:touch(c:actor());c.hooks.LOD_LoopAudioShutdown()
    assert(c.stops==1 and not c:touch(c:actor()))
end)
test('hot refresh closes old authority and preserves legitimate living audio',function()
    local c=client();local e=c:actor();c:touch(e);local old=c.A
    dofile(source(root..'cl_loop_audio.lua'));c.A=LOD.LoopAudio
    assert(c.stops==1 and not old:Touch('gas',e,'x',1,100,70) and c:touch(e))
end)
test('reset rejects reentrant touch and remains idempotent',function()
    local c=client();local e=c:actor();c:touch(e)
    c.onStop=function() assert(not c:touch(e)) end;c.A:Reset();c.A:Reset()
    assert(c.created==1 and c.stops==1 and #c.errors==0)
end)
test('creation failure owns no phantom loop',function()
    local c=client();c.noPatch=true;assert(not c:touch(c:actor()));assert(c.created==0)
end)
test('level mutation reentrant cleanup cannot play detached patch',function()
    local c=client();c.onLevel=function() c.A:Reset() end
    assert(not c:touch(c:actor()) and c.plays==0 and c.stops==1 and #c.errors==0)
end)
test('native play failure is cleaned and reported, not a pass for audibility',function()
    local c=client();c.failPlay=true;assert(not c:touch(c:actor()) and c.stops==1 and #c.errors==1)
end)
test('one failed native stop does not skip other owned cleanup',function()
    local c=client();c:touch(c:actor());c:touch(c:actor());c.failStop=true;c.A:Reset()
    assert(c.stops==2 and #c.errors==2 and next(c.A.Groups.gas)==nil)
end)

-- Use the existing production-enemy boundary environment, not a second AI model.
local env=dofile('tools/test_enemy_update.lua')
local v=getmetatable(Vector());v.__div=function(a,b) return a*(1/b) end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,Forward=function() return Vector(1,0,0) end} end
ACT_IDLE,ACT_RANGE_ATTACK1=4,7
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
LOD.RPGAbilityRules={RateOfFireMultiplier=function() return 1 end}
LOD.RPGStatusElements={CanInitiateAttack=function() return true end,Has=function() return false end}
LOD.CombatAudio=nil
dofile(source(root..'sv_enemy_roster.lua'));local E=LOD.EnemyRoster
local function server()
    local c={now=100,hooks={},stops={},starts={},errors={},insideDamage=false}
    function CurTime() return c.now end
    function ErrorNoHalt(err) c.errors[#c.errors+1]=err end
    local function newState() return {Graph={Progression={}},LevelSeed=123,CampaignEpoch=1,RunId='r1',BuildReady=true} end
    LOD.RunManager.State=newState();LOD.TopologySyncSafety={BuildSerial=1};LOD.HostileDeathAudio=nil
    LOD.Audio=nil;SERVER=true;CLIENT=false;SND_STOP=4
    hook={Add=function(_,id,fn) c.hooks[id]=fn end,Run=function(id,...)
        if id=='OnNPCKilled' then E:Cancel((...)) end
    end}
    timer={Create=noop,Exists=function() return false end,Adjust=noop,Remove=noop,Simple=noop}
    util.AddNetworkString=noop;resource={AddFile=noop};concommand={Add=noop}
    player.GetAll=function() return {} end
    AddCSLuaFile=noop;include=noop;function GetGlobalBool() return false end
    function SetGlobalBool(_,val) c.silent=val end
    dofile(source(root..'sh_audio.lua'));LOD.Audio.Building=false
    dofile(source(root..'sv_hostile_death_audio.lua'));c.A=LOD.HostileDeathAudio
    dofile(source(root..'sv_seeker_sound_safety.lua'))
    function c:dispatch(data)
        for _,id in ipairs({'LOD_GenerationSoundBarrier','LOD_SeekerSoundAssetSafety','LOD_HostileDeathAudio_SuppressLegacy'}) do
            local result=self.hooks[id](data);if result~=nil then return result end
        end
    end
    function c:actor(id,bind)
        local e=env.actor(1);e.LODArchetypeId=id or 'beamsweeper';e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[e.LODArchetypeId] or {})
        e.LODActivated=true;e.nw={};e.hp=50;e.stoppedPaths={};e.startedPaths={}
        e.SetNW2Int=function(h,k,x) if k=='LOD_AudioBuild' or k=='LOD_AudioRetired' then assert(not c.insideDamage,'audio NW write in lethal stack') end;h.nw[k]=x end
        e.SetNW2Bool=e.SetNW2Int;e.SetNW2Float=e.SetNW2Int;e.SetNW2Entity=e.SetNW2Int
        e.GetNW2Int=nw;e.GetNW2Bool=nw;e.GetNW2Float=nw
        e.Health=function(h) return h.hp end;e.GetAngles=function() return Angle() end
        e._SetActivity=noop;e.SetColor=noop
        function e:StopSound(path)
            assert(not c.insideDamage,'StopSound in lethal stack')
            self.stoppedPaths[#self.stoppedPaths+1]=path;c.stops[#c.stops+1]={e=self,path=path}
            assert(c:dispatch({Entity=self,SoundName=path,OriginalSoundName=path,Flags=SND_STOP})~=false,'native stop swallowed')
            if c.onStop then c.onStop(self) end
        end
        function e:EmitSound(path)
            local data={Entity=self,SoundName=path,OriginalSoundName=path,Flags=0}
            local result=c:dispatch(data)
            if result~=false then self.startedPaths[#self.startedPaths+1]=path;c.starts[#c.starts+1]={e=self,path=path} end
            return result~=false
        end
        if bind~=false and c.A then c.A:Bind(e) end
        return e
    end
    function c:beam(e) E:Begin(e,self:actor('soldier'),self.now);return self.A and self.A.Loops[e] end
    function c:tick() self.hooks.LOD_HostileAudioOwners() end
    function c:deathEntity()
        LOD.HostileDeathPresentation=nil;LOD.PlaceholderLoot=nil;ENT={}
        dofile(source('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua'))
        local e=self:actor();local mt=getmetatable(e) or {};local old=mt.__index
        mt.__index=function(h,k) return ENT[k] or (type(old)=='function' and old(h,k) or type(old)=='table' and old[k]) end
        setmetatable(e,mt)
        -- Only native boundary methods, not death/AI logic, are replaced.
        e.SetNoDraw=noop;e.DrawShadow=noop;e.SetVelocity=noop;e.SetSolid=noop;e.SetMoveType=noop;e.SetCollisionGroup=noop
        e._SetActivity=noop;e.SetPlaybackRate=noop;e.loco={SetDesiredSpeed=noop}
        self:beam(e);return e
    end
    return c
end
local BEAM='npc/stalker/laser_burn.wav'
test('real roster Beam warning acquires owned loop',function()
    local c=server();local e=c:actor();local row=c:beam(e)
    assert(row and row.path==BEAM and #e.startedPaths==1 and e.nw.LOD_AudioBuild==1)
end)
test('real roster cancellation stops the same loop',function()
    local c=server();local e=c:actor();c:beam(e);E:Cancel(e)
    assert(not c.A.Loops[e] and #e.stoppedPaths==1 and e.stoppedPaths[1]==BEAM)
end)
test('real roster finish preserves living next-attack audio',function()
    local c=server();local e=c:actor();c:beam(e);E:Finish(e,c.now+3)
    assert(#e.stoppedPaths==1 and not e.LODAudioRetired and c:beam(e))
end)
test('maintainer stops expired Beam commitment',function()
    local c=server();local e=c:actor();c:beam(e);e.LODRosterAttack.finish=c.now-.01;c:tick()
    assert(not c.A.Loops[e] and #e.stoppedPaths==1)
end)
test('maintainer stops replaced commitment, not later living attack',function()
    local c=server();local e=c:actor();c:beam(e);e.LODRosterAttack={};c:tick()
    assert(not c.A.Loops[e] and c:beam(e))
end)
test('logical death blocks delayed emit before corpse changes',function()
    local c=server();local e=c:actor();c:beam(e);e.LODDead=true
    assert(not e:EmitSound(BEAM));c:tick();assert(e.nw.LOD_AudioRetired and #e.stoppedPaths==1)
end)
test('death of one Beam owner does not silence another',function()
    local c=server();local a,b=c:actor(),c:actor();c:beam(a);c:beam(b);c.A:Retire(a)
    assert(c.A.Loops[b] and #b.stoppedPaths==0 and #a.stoppedPaths==1)
end)
test('repeated retirement, cancellation and removal are idempotent',function()
    local c=server();local e=c:actor();c:beam(e);c.A:Retire(e);c.A:Retire(e);E:Cancel(e)
    c.hooks.LOD_HostileAudioRemoved(e);assert(#e.stoppedPaths==1 and #c.errors==0)
end)
test('live native entity removal stops loop without death',function()
    local c=server();local e=c:actor();c:beam(e);c.hooks.LOD_HostileAudioRemoved(e)
    assert(e.nw.LOD_AudioRetired and not e:EmitSound(BEAM) and #e.stoppedPaths==1)
end)
for _,change in ipairs({'state','graph','seed','epoch','runId','build'}) do
    test('server rejects exact lifecycle replacement: '..change,function()
        local c=server();local e=c:actor();c:beam(e);local s=LOD.RunManager.State
        if change=='state' then LOD.RunManager.State=table.Copy(s)
        elseif change=='graph' then s.Graph=table.Copy(s.Graph)
        elseif change=='seed' then s.LevelSeed=456 elseif change=='epoch' then s.CampaignEpoch=2
        elseif change=='runId' then s.RunId='r2' else LOD.TopologySyncSafety.BuildSerial=2 end
        assert(not e:EmitSound(BEAM));c:tick();assert(e.nw.LOD_AudioRetired and not c.A.Loops[e])
    end)
end
test('pre-ready spawn binds build identity without borrowing old graph',function()
    local c=server();LOD.RunManager.State.BuildReady=false;local e=c:actor()
    LOD.RunManager.State.Graph={};LOD.RunManager.State.BuildReady=true;assert(c:beam(e))
end)
test('cleanup rejects stale callbacks, including previously silent owners',function()
    local c=server();local e=c:actor();c.A:Reset();c.A:Bind(e)
    assert(not c:beam(e) and #e.startedPaths==0);assert(c:beam(c:actor()))
end)
test('expired deferred native start is refused',function()
    local c=server();local e=c:actor();c:beam(e);c.A:Stop(e)
    assert(c:dispatch({Entity=e,SoundName=BEAM,Flags=0,SoundTime=c.now+1})==false and not c.A.Loops[e])
end)
test('ordinary death and attack one-shots are not suppressed',function()
    local c=server();local e=c:actor();assert(e:EmitSound('weapons/ar2/fire1.wav'))
    e.LODDead=true;c.A:Retire(e);assert(e:EmitSound('npc/stalker/stalker_die1.wav'))
end)
test('legacy administrative death blip remains suppressed',function()
    local c=server();local e=c:actor();e.LODDead=true;assert(not e:EmitSound('buttons/blip1.wav'))
end)
test('resolved stock script owns its original stop identifier',function()
    local c=server();local e=c:actor();c:beam(e);c.A:Stop(e)
    assert(c:dispatch({Entity=e,OriginalSoundName='NPC_Stalker.BurnWall',SoundName=BEAM})~=false)
    c.A:Stop(e);assert(e.stoppedPaths[#e.stoppedPaths]=='NPC_Stalker.BurnWall')
end)
test('generation barrier passes SND_STOP and combined stop flags',function()
    local c=server();LOD.Audio.Building=true
    for _,flags in ipairs({4,5,6,7,12}) do assert(c:dispatch({Entity=c:actor(),SoundName=BEAM,Flags=flags})~=false) end
    assert(c:dispatch({Entity=c:actor(),SoundName=BEAM,Flags=0})==false)
end)
test('Seeker missing-file filter never substitutes stop events',function()
    local c=server();local e=c:actor('seeker');local old=file.Exists;file.Exists=function() return false end
    local data={Entity=e,SoundName='npc/roller/mine/rmine_seek_loop1.wav',Flags=4}
    assert(c.hooks.LOD_SeekerSoundAssetSafety(data)==nil and data.SoundName=='npc/roller/mine/rmine_seek_loop1.wav');file.Exists=old
end)
test('current living Seeker one-shots remain eligible',function()
    local c=server();local e=c:actor('seeker');assert(e:EmitSound('ambient/energy/zap9.wav'))
end)
test('retirement cleans both legacy Seeker loops',function()
    local c=server();local e=c:actor('seeker');c.A:Retire(e)
    local seen={};for _,p in ipairs(e.stoppedPaths) do seen[p]=true end
    assert(seen['npc/roller/mine/rmine_seek_loop1.wav'] and seen['npc/roller/mine/rmine_seek_loop2.wav'])
end)
test('shutdown rejects new and old server loop callbacks',function()
    local c=server();local e=c:actor();c:beam(e);c.hooks.LOD_HostileAudioShutdown()
    assert(not e:EmitSound(BEAM) and not c:beam(c:actor()))
end)
test('native hostile OnKilled seals without new native audio mutations',function()
    local c=server();local e=c:deathEntity();e.hp=0;c.insideDamage=true
    e:OnKilled({GetAttacker=function() return e end,GetInflictor=function() return e end});c.insideDamage=false
    assert(e.LODDead and e.LODAudioRetired and #c.stops==0 and #c.errors==0 and c.A.Loops[e])
    c:tick();assert(e.nw.LOD_AudioRetired and #e.stoppedPaths==1)
end)
test('native deferred corpse presentation retires audio, preserves death cue',function()
    local c=server();local e=c:deathEntity();e.hp=0;e.LODDead=true
    local cues=0;LOD.Audio.At=function(_,_,id) assert(id=='enemy_defeated');cues=cues+1 end
    e:_BeginDeathPresentation();assert(e.nw.LOD_AudioRetired and e.nw.LOD_DeathPulseStart==c.now and cues==1)
    assert(#e.stoppedPaths==1 and #c.errors==0)
end)
test('native hostile OnRemove uses shared retirement',function()
    local c=server();local e=c:deathEntity();e:OnRemove();assert(e.nw.LOD_AudioRetired and not c.A.Loops[e])
end)
test('native constructor binds before model initialization',function()
    local c=server();c:deathEntity();local e=c:actor('beamsweeper',false)
    function e:SetModel() assert(self.LODAudioContext and self.nw.LOD_AudioBuild==1);error('bound-before-model') end
    local ok,err=pcall(ENT.Initialize,e);assert(not ok and tostring(err):find('bound%-before%-model'))
end)
test('server cleanup invalidates before reentrant late emission',function()
    local c=server();local e=c:actor();c:beam(e);c.onStop=function(h) assert(not h:EmitSound(BEAM));c.A:Retire(h) end
    c.A:Reset();assert(#e.stoppedPaths==1 and #c.errors==0)
end)
test('same actor cannot bind into a later generation after retirement',function()
    local c=server();local e=c:actor();local original=e.LODAudioContext;c.A:Retire(e)
    LOD.TopologySyncSafety.BuildSerial=2;c.A:Bind(e);assert(e.LODAudioContext==original and not c:beam(e))
end)
test('server auto-refresh retains owned resource and retirement state',function()
    local c=server();local e=c:actor();c:beam(e);local a=c.A
    dofile(source(root..'sv_hostile_death_audio.lua'));assert(LOD.HostileDeathAudio==a and a.Loops[e])
    c.A:Retire(e);assert(#e.stoppedPaths==1)
end)
test('actual build/campaign barriers retire old audio before construction',function()
    local c=server();local e=c:actor();c:beam(e)
    LOD.RunManager.BuildCurrentLevel=function()
        assert(e.LODAudioRetired and not c.A.Loops[e]);return true
    end
    LOD.RunManager.NewCampaign=function(self) return self:BuildCurrentLevel() end
    dofile(source(root..'sv_audio_lifecycle.lua'));LOD.RunManager:NewCampaign()
    assert(e.nw.LOD_AudioRetired and #c.errors==0)
end)
test('actual map cleanup barrier retires existing owners',function()
    local c=server();local e=c:actor();c:beam(e)
    LOD.RunManager.BuildCurrentLevel=noop;LOD.RunManager.NewCampaign=noop
    dofile(source(root..'sv_audio_lifecycle.lua'));c.hooks.LOD_AudioCleanupBarrier()
    assert(e.nw.LOD_AudioRetired and not c.A.Loops[e])
end)
test('raw loop on unrelated non-hostile entity is not suppressed or claimed',function()
    local c=server();local e=c:actor();e.LODHostile=false
    assert(e:EmitSound(BEAM) and not c.A.Loops[e])
end)
test('no unshipped Razor startup path remains in executable references',function()
    local f=assert(io.open(source(root..'sv_enemy_roster.lua')));local s=f:read('*a');f:close()
    assert(not s:find('"npc/manhack/mh_engine_start1.wav"',1,true))
    assert(s:find('dive="NPC_Manhack.ChargeAnnounce"',1,true))
end)
print(string.format('SPOT04_AUDIO_RESULT passed=%d failed=%d native=false',passed,failed))
if failed>0 then error('SPOT-04 audio gate failed') end
