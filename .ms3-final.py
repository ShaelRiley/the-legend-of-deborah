from pathlib import Path

def edit(path,old,new):
    p=Path(path);s=p.read_text();assert s.count(old)==1,(path,s.count(old));p.write_text(s.replace(old,new))
p='tools/music/ms2_engine.js'
edit(p,"if(!v.disposed){v.disposed=true;v.entry.refs--;try{v.source.disconnect();v.gain.disconnect();}catch(ignore){}}", """if(!v.disposed){
                v.disposed=true;v.entry.refs--;
                var lane=this.lanes[v.lane];if(lane&&lane.current===v)lane.current=null;
                try{v.source.disconnect();v.source.onended=null;v.source.buffer=null;v.gain.disconnect();}catch(ignore){}
            }""")
edit(p,"""    AudioTransport.prototype.schedule=function(j,e){
        var ctx=this.context,now=ctx.currentTime,l=this.lanes[j.lane],old=l&&l.current;""", """    AudioTransport.prototype.schedule=function(j,e){
        this.reap();
        var ctx=this.context,now=ctx.currentTime,l=this.lanes[j.lane],old=l&&l.current;
        if(old&&old.end<=j.due)old=null; // no release/cancellation ownership of an already finished fanfare""")
edit(p,"""            if(!initializing||closed)return;initializing=false;fallbackReason=reason||null;
            var sink=nativeSink,clock=hostClock;
            if(useAudio){
                transport=new AudioTransport(context,function(lane,clip){bridge.readclip(lane,clip);},function(token,played){scheduler.result(token,played);});
                sink=transport;clock=function(){return context.currentTime;};backend='surge-sample-clock';
            }else{disposeContext();backend='surge-rendered';}""", """            if(!initializing||closed)return;
            var sink=nativeSink,clock=hostClock;
            if(useAudio){
                try{
                    // Some older HTML engines expose AudioContext but not the
                    // complete buffer/gain API. Construction failure must still
                    // take the native path, not consume readiness and go silent.
                    for(var i=0,required=['createGain','createBufferSource','createBuffer','decodeAudioData'];i<required.length;i++)
                        if(typeof context[required[i]]!=='function')throw Error('MS3 incomplete audio API: '+required[i]);
                    transport=new AudioTransport(context,function(lane,clip){bridge.readclip(lane,clip);},function(token,played){scheduler.result(token,played);});
                }catch(error){useAudio=false;transport=null;reason=String(error);}
            }
            if(useAudio){sink=transport;clock=function(){return context.currentTime;};backend='surge-sample-clock';}
            else{disposeContext();backend='surge-rendered';}
            initializing=false;fallbackReason=reason||null;""")
p='tools/test_ms3_transport.js'
old="console.log(JSON.stringify({suite:'MS3_SAMPLE_CLOCK',checks,actualAudio:false}));"
new="""// Finished one-shots must release lane ownership as well as the cache ref.
victory.ctx.currentTime=1+va.original.duration+.1;victory.tr.reap();
check(victory.tr.lanes.floor.current===null,'finished fanfare clears resident lane reference');
check(va.refs===0&&victory.ctx.sources[0].buffer===null,'finished source disconnects and releases its buffer');
victory.add('after-victory');victory.tr.prepare('2','floor','after-victory',1,victory.ctx.currentTime+1);
check(!victory.tr.jobs['2'].previous&&!victory.tr.jobs['2'].tail,'successor never retains or crossfades a dead fanfare');
// Constructor presence alone is not evidence that older HTML supports playback.
for(const kind of ['missing','throws','modern']){
 let timers=[],ready=[],errors=[],closes=0,stats;
 let ctx=context();ctx.close=()=>{closes++;ctx.state='closed';};
 if(kind==='missing')delete ctx.createGain;
 if(kind==='throws')ctx.createGain=()=>{throw Error('gain API unavailable');};
 global.window={AudioContext:function(){return ctx;},performance:{now:()=>0},setTimeout:fn=>timers.push(fn),setInterval:()=>1,clearInterval:()=>{}};
 const noop=()=>{},bridge={readclip:noop,prepare:noop,cancel:noop,mix:noop,volume:noop,drop:noop,stop:noop,block:noop,victory:noop,error:e=>errors.push(e),ready:b=>ready.push(b),stats:s=>stats=JSON.parse(s)};
 const attached=MS.attach(bridge);timers.shift()();attached.stats();
 check(ready.length===1&&ready[0]===(kind==='modern'?'surge-sample-clock':'surge-rendered'),'capability negotiation completes exactly once: '+kind);
 check(errors.length===0,'unsupported audio API selects working native path: '+kind);
 if(kind!=='modern')check(closes===1&&!!stats.fallbackReason,'failed context is closed and fallback reason retained: '+kind);
 attached.destroy();check(closes===1,'context disposed exactly once: '+kind);delete global.window;
}
console.log(JSON.stringify({suite:'MS3_SAMPLE_CLOCK',checks,actualAudio:false}));"""
edit(p,old,new)
engine=Path('tools/music/ms2_engine.js').read_text()
Path('gamemodes/legend_of_deborah/gamemode/lod/ms2/engine.lua').write_text('return [==['+engine+']==]\n')
p=Path('docs/validation/MS3_SAMPLE_CLOCK.md')
s=p.read_text();s=s.replace('Initial local run: 8,298 assertions passed.', 'Initial local run: 8,298 assertions passed. Follow-up coverage adds finished-fanfare reference cleanup and missing/throwing HTML audio APIs; these must fall back once without a silent readiness retry.')
p.write_text(s)
print('MS3 final lifecycle and capability regressions applied')
