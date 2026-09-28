local e=dofile('tools/music_test_fixture.lua');local M=LOD.Music;local check=e.check
CLIENT=true;CreateConVar('lod_music_enabled','1')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua');local D=LOD.MusicDirector;D.ServerOn=true
local c=e.catalog()
for _,a in pairs(c.assets) do
 if a.loop then
  a.duration=64;a.loopEnd=64;a.beats=128
  a.cues={version=1,source='authored',pulse={{start=16,finish=32,energy=.9},{start=24,finish=32,energy=.8},
    {start=40,finish=56,energy=.4},{start=48,finish=56,energy=.3}},
    quiet={{start=0,finish=8,energy=.5},{start=56,finish=64,energy=.2}}}
 end
end
check(M.ValidateCatalog(c),'cue catalog valid')
local bad=table.Copy(c);bad.assets[bad.profiles.default.roles.T2].cues.pulse={}
check(not M.ValidateCatalog(bad),'combat cannot advertise quiet-only cues')
bad=table.Copy(c);bad.assets[bad.profiles.default.roles.T0].cues.quiet[1].start=0/0
check(not M.ValidateCatalog(bad),'NaN cue rejected')
bad=table.Copy(c);bad.assets[bad.profiles.default.roles.T0].cues.quiet[1].finish=20
check(not M.ValidateCatalog(bad),'contradictory pulse/quiet overlap rejected')
local p=assert(M.Plan(c,{set='all'},11,'cue-run',4,1));D.Plans[p.id]=p
local block=p.floors[1]
local function state(role)
 D.Current={plan=p.id,epoch=1,sequence=(D.Current and D.Current.sequence or 0)+1,role=role,targets={{block=block,weight=1}}}
end
local function asset(role) return c.profiles.default.roles[role] end
local function finishRequests(buffer)
 for i,req in ipairs(e.requests) do if not req.channel and not req.done then
  req.done=true;local channel=e.complete(i,buffer or 64)
  local original=channel.SetTime
  function channel:SetTime(pos,fast) check(fast==true,'seek avoids decode-to-position');original(self,pos);self.seeks=(self.seeks or 0)+1 end
 end end
end
local function advance(n)
 for _=1,n do
  for _,r in pairs(D.Channels) do
   local ch=r.channel
   if IsValid(ch) and ch.played then ch.time=ch.time+.1 end
  end
  e.step()
  local slots,transfers=D:Counts();check(slots<=4 and transfers<=2,'bounded native slots/transfers')
 end
end
state('T0');e.step();finishRequests();e.step(15)
check(D.Channels[asset('T0')].section.mode=='quiet','staging chooses quiet class')
state('T3');e.step();local n=#e.requests
local partial=e.complete(n,8);e.requests[n].done=true
e.step(15);check(not partial.played and D.Channels[asset('T0')].gain>0,'no unbuffered interior seek; outgoing audio retained')
partial.buffer=64;e.step(20)
local hot=D.Channels[asset('T3')]
check(hot.section.mode=='pulse' and partial.time>=16 and partial.time<32,'rising tension skips intro for strong pulse')
local entries=#e.sent
hot.channel.time=hot.section.finish-7;e.step(3);finishRequests()
local nextVoice=D.Channels[asset('T3')..':next']
check(nextVoice and not nextVoice.started,'renewal is buffered before its boundary')
hot.channel.time=hot.section.finish-1.5;e.step(3)
check(D.Channels[asset('T3')]~=hot and hot.cueTail,'same-file renewal crossfades through spare channel')
check(D.Channels[asset('T3')].section.origin~=hot.section.origin,'pulse entry points rotate')
e.step(20);check(hot.channel.valid and not hot.channel.played and #e.sent==entries,'tail is reserved paused without a new block announcement')
state('T2');e.step();finishRequests();e.step(20)
local lower=D.Channels[asset('T2')]
check(lower.section.mode=='pulse' and lower.section.origin>=40,'falling but still dangerous uses gentler pulse')
state('T0');e.step();finishRequests();e.step(20)
local quiet=D.Channels[asset('T0')]
check(quiet.section.mode=='quiet','genuine relaxation enters quiet')
local plays=e.plays;e.step(20);check(e.plays==plays,'unchanged calm state preserves transport')
quiet.channel.time=quiet.section.finish-7;e.step(3);finishRequests()
quiet.channel.time=quiet.section.finish-1.5;e.step(3);e.step(20)
check(D.Channels[asset('T0')].section.mode=='quiet','prolonged quiet renews quiet, never a pulse')
-- Full slots and an unreturned native callback force the bounded envelope path.
D:Stop();D.Failures={};state('T3');e.step();finishRequests();e.step(20)
hot=D.Channels[asset('T3')]
-- Failed optional renewal must not invalidate the audible asset's role source.
hot.channel.time=hot.section.finish-7;e.step(3)
local pending=#e.requests;e.requests[pending].done=true;e.complete(pending,0,true)
hot.channel.time=hot.section.finish-1.5;e.step(3)
check(hot.reseek and not D.Failures[asset('T3')],'failed overlap triggers local envelope, preserves source')
local before=hot.channel.seeks or 0;advance(30)
check((hot.channel.seeks or 0)>before and hot.section.mode=='pulse','fallback fast-seeks a buffered pulse')
check(not hot.reseek and hot.channel.volume>0,'fallback envelope recovers')
-- Three still-audible outgoing voices consume the remaining slots. Section
-- continuity must not admit a fifth voice even though all bytes are buffered.
D.Failures={}
for _,role in ipairs({'T0','T1','T2'}) do
 local r=D:Request(p,asset(role));finishRequests()
 r.started=true;r.role=role;r.gain=.8;r.channel:Play()
end
check(D:Counts()==4,'saturated crossfade fixture uses exactly four voices')
hot.channel.time=hot.section.finish-1.5;e.step(3)
check(hot.reseek and not D.Channels[asset('T3')..':next'],'no fifth voice; saturated mixer uses envelope fallback')
advance(30)
check(hot.section.mode=='pulse' and not hot.reseek,'saturated mixer restores pulse continuity')
-- Off invalidates a still-pending section voice exactly like a primary stream.
D.Failures={};hot.channel.time=hot.section.finish-7;e.step(3)
local last=#e.requests;e.set('lod_music',0)
local stale=e.complete(last,64);e.requests[last].done=true
check(not stale.valid and D:Counts()==0,'Off discards late renewal callback')
-- Repeated renewal reuses a bounded buffered pair instead of downloading an
-- entire master again each time. Audible voices never cross a class boundary.
e.set('lod_music',1);D.ServerOn=true;D.Victory=nil;D.Failures={}
for _,role in ipairs({'T3','T0'}) do
 D:Stop();state(role);local requests=#e.requests
 e.step();finishRequests();local safe=true
 for _=1,1200 do
  for _,r in pairs(D.Channels) do
   local ch=r.channel
   if IsValid(ch) and ch.played then ch.time=ch.time+.1 end
  end
  e.step();finishRequests()
  for _,r in pairs(D.Channels) do
   if r.gain>.001 and r.started then
    safe=safe and r.section and r.section.mode==M.PulseMode(role)
      and r.channel:GetTime()<=r.section.finish+.01
   end
  end
 end
 check(safe,'two-minute '..role..' sustain stays within required rhythmic class')
 check(#e.requests-requests==2,'two-minute '..role..' sustain downloads only its bounded pair')
end
D:Stop()
-- Victory remains outside all section logic and never enters an outro loop.
e.set('lod_music',1);D.ServerOn=true
D.Victory={id='one-clear',plan=p.id,block=block,endsAt=e.now+10}
state('POST');e.step();finishRequests(64);e.step(2)
local fanfare=D.Channels[asset('VICTORY')]
check(fanfare and fanfare.channel.time==0 and not fanfare.channel.loop and not fanfare.section,'one-shot victory begins at zero without cues')
check(p.assets[asset('T3')].cues.pulse[1].start==16,'plan cue metadata stays immutable')
print('MUSIC_SECTIONS_CLIENT PASS '..e.checks)
