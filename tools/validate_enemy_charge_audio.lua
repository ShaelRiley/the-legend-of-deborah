-- Production server audio authority with native sound/NW calls doubled.
-- No asset decoding, Source engine execution or native audibility is claimed.
-- Optional LOD_AUDIO_BASE points to an unchanged source tree for comparison.
local root=(os.getenv('LOD_AUDIO_BASE') or '.')..'/'
local module='gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_death_audio.lua'
local BEAM='npc/stalker/laser_burn.wav'
local CHARGE='npc/vort/attack_charge.wav'
local passed,failed=0,0
local function test(name,fn)
    local ok,err=pcall(fn)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name..': '..tostring(err)) end
end
local function count(t) local n=0;for _ in pairs(t or {}) do n=n+1 end;return n end
local function fixture()
    local c={now=10,hooks={},starts=0,stops=0,errors={},actors={}}
    LOD={RunManager={State={BuildReady=true,Graph={},LevelSeed=123,CampaignEpoch=1,RunId='r1'}},
        TopologySyncSafety={BuildSerial=1},EnemySupport={Pending={}}}
    LOD.Audio={Muted=function() return c.muted end}
    function CurTime() return c.now end
    function IsValid(e) return type(e)=='table' and e.valid~=false end
    function ErrorNoHalt(err) c.errors[#c.errors+1]=err end
    SND_STOP=4
    hook={Add=function(_,id,fn) c.hooks[id]=fn end}
    -- Any new per-frame world scan or extra timer fails this focused fixture.
    ents=setmetatable({}, {__index=function() error('unexpected world scan') end})
    timer=setmetatable({}, {__index=function() error('unexpected timer') end})
    dofile(root..module);c.A=LOD.HostileDeathAudio
    function c:emit(e,path,original,flags,when)
        local data={Entity=e,SoundName=path,OriginalSoundName=original or path,
            Flags=flags or 0,SoundTime=when or 0,Volume=.75,Pitch=100,Channel=0}
        local result=self.hooks.LOD_HostileDeathAudio_SuppressLegacy(data)
        assert(data.SoundName==path and data.Volume==.75 and data.Pitch==100 and data.Channel==0,
            'audio parameters changed')
        if result~=false and (data.Flags%8)<4 then
            if data.Flags%4==0 then
                e.playing[#e.playing+1]={path=path,original=original or path}
                self.starts=self.starts+1
            end
        end
        return result~=false
    end
    function c:actor(id,bind)
        local e={LODHostile=true,LODArchetypeId=id or 'arccaster',LODActivated=true,hp=40,nw={},playing={},stopped={}}
        function e:Health() return self.hp end
        function e:SetNW2Int(k,v) assert(not c.insideDamage,'NW mutation in lethal stack');self.nw[k]=v end
        e.SetNW2Bool=e.SetNW2Int
        function e:StopSound(path)
            assert(not c.insideDamage,'native stop in lethal stack')
            self.stopped[#self.stopped+1]=path;c.stops=c.stops+1
            assert(c.hooks.LOD_HostileDeathAudio_SuppressLegacy({Entity=self,SoundName=path,Flags=4})~=false,
                'SND_STOP swallowed')
            for i=#self.playing,1,-1 do
                local row=self.playing[i]
                if row.path==path or row.original==path then table.remove(self.playing,i) end
            end
            if c.onStop then c.onStop(self,path) end
            if c.failStop then error('injected native stop failure') end
        end
        self.actors[#self.actors+1]=e
        if bind~=false then self.A:Bind(e) end
        return e
    end
    function c:attack(e,kind)
        local a={kind=kind or 'arc',run=LOD.RunManager.State,ready=self.now+1.25}
        e.LODRosterAttack=a;return a
    end
    function c:support(e,kind)
        local a={kind=kind or 'recovery',ready=self.now+1.5,records={{source=e,run=LOD.RunManager.State}}}
        e.LODSupportCast=a;LOD.EnemySupport.Pending[e]=a;return a
    end
    function c:tick() self.hooks.LOD_HostileAudioOwners() end
    function c:stop(e) self.A:Stop(e);e.LODRosterAttack=nil end
    return c
end
for _,spec in ipairs({{'arccaster','arc'},{'gaoler','arc'},{'repulsor','pulse'},
    {'conductor','bolt'},{'siphoner','arc'},{'accumulator','arc'},{'silencer','bolt'}}) do
    test(spec[1]..' charge stops on valid corpse',function()
        local c=fixture();local e=c:actor(spec[1]);c:attack(e,spec[2])
        assert(c:emit(e,CHARGE) and #e.playing==1,'living charge suppressed')
        e.LODDead=true;e.hp=0;c:tick()
        assert(IsValid(e) and #e.playing==0 and not c.A.Loops[e],'corpse retains charge')
        assert(e.nw.LOD_AudioRetired and not c:emit(e,CHARGE),'late corpse charge admitted')
    end)
end
for _,kind in ipairs({'recovery','protection','cleanse'}) do
    test(kind..' support charge uses pending cast, stops at cancellation',function()
        local c=fixture();local e=c:actor('stitcher');c:support(e,kind)
        assert(not e.LODRosterAttack and c:emit(e,CHARGE) and #e.playing==1)
        LOD.EnemySupport.Pending[e]=nil;e.LODSupportCast=nil;c:tick()
        assert(#e.playing==0 and not c.A.Loops[e],'cancelled support retains charge')
    end)
end
test('support death stops before cast deadline',function()
    local c=fixture();local e=c:actor('absolver');c:support(e);c:emit(e,CHARGE)
    e.LODDead=true;c:tick();assert(#e.playing==0)
end)
test('support completion consumes pending receipt before visual cast field',function()
    local c=fixture();local e=c:actor();c:support(e);c:emit(e,CHARGE)
    LOD.EnemySupport.Pending[e]=nil;c:tick();assert(#e.playing==0 and not c:emit(e,CHARGE))
end)
test('stale support record from another run cannot start',function()
    local c=fixture();local e=c:actor();local a=c:support(e);a.records[1].run={}
    assert(not c:emit(e,CHARGE) and not c.A.Loops[e])
end)
test('support replacement stops old cue without retiring living actor',function()
    local c=fixture();local e=c:actor();c:support(e);c:emit(e,CHARGE)
    c:support(e);c:tick();assert(#e.playing==0 and not e.LODAudioRetired)
    assert(c:emit(e,CHARGE) and #e.playing==1)
end)
test('roster cancellation stops charge and next living attack can start',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);c:stop(e)
    assert(#e.playing==0 and not e.LODAudioRetired)
    c:attack(e);assert(c:emit(e,CHARGE) and #e.playing==1)
end)
test('roster release ends charge without waiting for actor death',function()
    local c=fixture();local e=c:actor();local a=c:attack(e);c:emit(e,CHARGE)
    a.released=true;a.finish=c.now+.15;c:tick();assert(#e.playing==0 and not c:emit(e,CHARGE))
end)
for _,support in ipairs({false,true}) do
    test((support and 'support' or 'roster')..' charge has exact authored deadline even if callback stalls',function()
        local c=fixture();local e=c:actor();local a=support and c:support(e) or c:attack(e)
        c:emit(e,CHARGE);c.now=a.ready;c:tick()
        assert(#e.playing==0 and not c:emit(e,CHARGE))
    end)
end
test('charge rejects missing commitment or unbounded ready time',function()
    local c=fixture();local e=c:actor();assert(not c:emit(e,CHARGE))
    local a=c:attack(e);a.ready=nil;assert(not c:emit(e,CHARGE))
end)
test('an earlier explicit commitment deadline is respected',function()
    local c=fixture();local e=c:actor();local a=c:attack(e);a.deadline=c.now+.1;c:emit(e,CHARGE)
    c.now=c.now+.1;c:tick();assert(#e.playing==0)
end)
test('one death preserves another living charge and ordinary one-shots',function()
    local c=fixture();local a,b=c:actor(),c:actor();c:attack(a);c:attack(b)
    c:emit(a,CHARGE);c:emit(b,CHARGE);a.LODDead=true;c:tick()
    assert(#a.playing==0 and #b.playing==1 and #b.stopped==0)
    assert(c:emit(a,'npc/stalker/stalker_die1.wav'))
    assert(c:emit(b,'weapons/ar2/fire1.wav'))
end)
test('lethal callback is sealed without StopSound or NW writes inside damage',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.insideDamage=true;e.LODDead=true;e.LODAudioRetired=true;e.hp=0;c.A:Stop(e)
    assert(not c:emit(e,CHARGE) and c.stops==0 and not e.nw.LOD_AudioRetired)
    c.insideDamage=false;c:tick();assert(#e.playing==0 and e.nw.LOD_AudioRetired)
end)
test('immediate deferred retirement stops corpse sound',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    e.LODDead=true;c.A:Retire(e);assert(#e.playing==0 and c.stops==1)
end)
test('true removal without damage retires charge',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.hooks.LOD_HostileAudioRemoved(e);assert(#e.playing==0 and not c:emit(e,CHARGE))
end)
test('repeated cancellation death removal cleanup is idempotent',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.A:Retire(e);local stops=c.stops;c.A:Retire(e);c.A:Stop(e)
    c.hooks.LOD_HostileAudioRemoved(e);c.A:Reset();assert(c.stops==stops and #e.playing==0)
end)
test('invalid removed entity releases tracking without native calls',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);e.valid=false;c:tick()
    assert(not c.A.Loops[e] and not c.A.Owners[e] and c.stops==0)
end)
for _,change in ipairs({'run','graph','seed','epoch','runId','build','failed','cleared','unready'}) do
    test('charge rejects and retires lifecycle change: '..change,function()
        local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);local s=LOD.RunManager.State
        if change=='run' then LOD.RunManager.State={BuildReady=true}
        elseif change=='graph' then s.Graph={}
        elseif change=='seed' then s.LevelSeed=456
        elseif change=='epoch' then s.CampaignEpoch=2
        elseif change=='runId' then s.RunId='r2'
        elseif change=='build' then LOD.TopologySyncSafety.BuildSerial=2
        elseif change=='failed' then s.Failed=true
        elseif change=='cleared' then s.LevelCleared=true
        else s.BuildReady=false end
        assert(not c:emit(e,CHARGE));c:tick();assert(#e.playing==0 and not c.A.Loops[e])
    end)
end
for _,change in ipairs({'frozen','muted','inactive'}) do
    test(change..' stops charge without permanently retiring live actor',function()
        local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
        if change=='frozen' then LOD.RunManager.State.SimulationFrozen=true
        elseif change=='muted' then c.muted=true else e.LODActivated=false end
        c:tick();assert(#e.playing==0 and not c:emit(e,CHARGE) and not e.LODAudioRetired)
        LOD.RunManager.State.SimulationFrozen=false;c.muted=false;e.LODActivated=true
        c:attack(e);assert(c:emit(e,CHARGE))
    end)
end
test('same-seed reset stops old actors and accepts new bound actors',function()
    local c=fixture();local a,b=c:actor(),c:actor();c:attack(a);c:support(b)
    c:emit(a,CHARGE);c:emit(b,CHARGE);c.A:Reset()
    assert(#a.playing==0 and #b.playing==0 and count(c.A.Loops)==0)
    assert(not c:emit(a,CHARGE) and not c:emit(b,CHARGE))
    local e=c:actor();c:attack(e);assert(c:emit(e,CHARGE))
end)
test('future-scheduled charge cannot escape owner lifetime',function()
    local c=fixture();local e=c:actor();c:attack(e)
    assert(not c:emit(e,CHARGE,nil,0,c.now+1) and not c.A.Loops[e])
end)
test('spatial prefix and soundscript retain exact stop identifiers',function()
    local c=fixture();local e=c:actor();c:attack(e)
    local path=')NPC\\VORT\\ATTACK_CHARGE.WAV';local script='Vortigaunt.StartShootLoop'
    assert(c:emit(e,path,script));c:stop(e)
    assert(#e.playing==0 and e.stopped[1]==path and e.stopped[2]==script)
end)
test('empty resolved field falls back to original charge filename',function()
    local c=fixture();local e=c:actor();c:attack(e);assert(c:emit(e,'',CHARGE));c:stop(e)
    assert(#e.playing==0 and c.stops==1)
end)
test('1000 duplicate starts retain one sounding resource',function()
    local c=fixture();local e=c:actor();c:attack(e)
    for _=1,1000 do c:emit(e,CHARGE) end
    assert(c.starts==1 and #e.playing==1 and count(c.A.Loops)==1)
    c:stop(e);assert(#e.playing==0 and c.stops==1)
end)
test('pitch and volume changes are not mistaken for duplicate starts',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    for _,flags in ipairs({1,2,3}) do assert(c:emit(e,CHARGE,nil,flags)) end
    assert(c.starts==1);c:stop(e);assert(#e.playing==0)
end)
test('new emitted identifier cannot orphan the earlier charge',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE,'Vortigaunt.StartShootLoop')
    assert(c:emit(e,CHARGE));assert(#e.playing==1)
    c:stop(e);assert(#e.playing==0)
end)
test('replacement attack stops prior charge before starting next',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);c:attack(e)
    assert(c:emit(e,CHARGE) and #e.playing==1 and c.stops==1)
end)
test('all stop flag combinations pass even on dead muted owners',function()
    local c=fixture();local e=c:actor();e.LODDead=true;c.muted=true
    for _,flags in ipairs({4,5,6,7,12}) do
        assert(c.hooks.LOD_HostileDeathAudio_SuppressLegacy({Entity=e,SoundName=CHARGE,Flags=flags})==nil)
    end
end)
test('retirement blocks reentrant start before native calls',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.onStop=function(h) assert(not c:emit(h,CHARGE));c.A:Retire(h) end
    c.A:Retire(e);assert(#e.playing==0 and #c.errors==0 and c.stops==1)
end)
test('ordinary stop blocks reentrant loop recreation',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.onStop=function(h) assert(not c:emit(h,CHARGE));c.A:Stop(h) end
    c:stop(e);assert(#e.playing==0 and not c.A.Loops[e] and #c.errors==0)
end)
test('replacement cannot revive a commitment cancelled by native callback',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);c:attack(e)
    c.onStop=function(h) h.LODRosterAttack=nil end
    assert(not c:emit(e,CHARGE) and #e.playing==0 and not c.A.Loops[e])
end)
test('native stop exception is reported and bookkeeping is detached',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);c.failStop=true
    c:stop(e);assert(not c.A.Loops[e] and #c.errors==1)
    c.failStop=false;c:attack(e);assert(c:emit(e,CHARGE))
end)
test('Beam keeps its full released sweep and stops at finish',function()
    local c=fixture();local e=c:actor('beamsweeper');local a=c:attack(e,'beam')
    assert(c:emit(e,BEAM));c.now=a.ready;a.released=true;a.finish=c.now+1.2;c:tick()
    assert(#e.playing==1 and c.stops==0)
    c.now=a.finish;c:tick();assert(#e.playing==0 and c.stops==1)
end)
test('Beam cancellation and death retain one exact stop',function()
    local c=fixture();local e=c:actor('beamsweeper');c:attack(e,'beam');c:emit(e,BEAM)
    c.A:Retire(e);c.A:Retire(e);assert(c.stops==1 and e.stopped[1]==BEAM)
end)
test('Beam raw sound still requires Beam commitment',function()
    local c=fixture();local e=c:actor();c:attack(e,'arc');assert(not c:emit(e,BEAM))
end)
test('resolved Beam script is stopped by its original identifier too',function()
    local c=fixture();local e=c:actor('beamsweeper');c:attack(e,'beam')
    c:emit(e,BEAM,'NPC_Stalker.BurnWall');c:stop(e)
    assert(#e.playing==0 and e.stopped[#e.stopped]=='NPC_Stalker.BurnWall')
end)
test('non-hostile sounds and projectile-owned audio are not claimed',function()
    local c=fixture();local e=c:actor();e.LODHostile=false;e.LODDead=true
    assert(c:emit(e,CHARGE) and c:emit(e,BEAM) and not c.A.Loops[e])
    assert(c:emit(e,'ambient/gas/steam2.wav') and c.stops==0)
end)
test('legacy death blips stay suppressed and independent death cue stays allowed',function()
    local c=fixture();local e=c:actor();e.LODDead=true
    assert(not c:emit(e,'buttons/blip1.wav') and not c:emit(e,'buttons/button15.wav'))
    assert(c:emit(e,'npc/vort/vort_die1.wav'))
end)
test('legacy Seeker cleanup is retained',function()
    local c=fixture();local e=c:actor('seeker');c.A:Retire(e);local seen={}
    for _,path in ipairs(e.stopped) do seen[path]=true end
    assert(seen['npc/roller/mine/rmine_seek_loop1.wav'] and seen['npc/roller/mine/rmine_seek_loop2.wav'])
end)
test('pre-refresh untracked charge receives actor-specific retirement stop',function()
    local c=fixture();local e=c:actor();e.playing={{path=CHARGE,original=CHARGE}}
    c.A:Retire(e);assert(#e.playing==0)
end)
test('hot reload preserves current charge ownership',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE);local a=c.A
    dofile(root..module);assert(LOD.HostileDeathAudio==a)
    c.A:Retire(e);assert(#e.playing==0)
end)
test('old Beam row format remains stoppable after hot reload',function()
    local c=fixture();local e=c:actor('beamsweeper');local a=c:attack(e,'beam')
    e.playing={{path=BEAM,original=BEAM}};c.A.Loops[e]={path=BEAM,attack=a}
    dofile(root..module);c.A:Retire(e);assert(#e.playing==0 and c.stops==1)
end)
test('shutdown stops current and rejects later charge starts',function()
    local c=fixture();local e=c:actor();c:attack(e);c:emit(e,CHARGE)
    c.hooks.LOD_HostileAudioShutdown();assert(#e.playing==0 and not c:emit(e,CHARGE))
    local fresh=c:actor();c:attack(fresh);assert(not c:emit(fresh,CHARGE))
end)
print(string.format('ENEMY_CHARGE_AUDIO_RESULT passed=%d failed=%d native=false',passed,failed))
if failed>0 then error('enemy charge audio gate failed') end
