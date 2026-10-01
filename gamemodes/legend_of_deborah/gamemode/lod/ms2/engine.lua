return [==[/* MS2: one offline-capable composer, transport and instrument engine.
 * ES5 deliberately supports GMod's older HTML engine. No network API is used.
 * Notes: [1/48-beat onset, gate, instrument, MIDI pitch, velocity]. */
(function (root, factory) {
    var api = factory();
    if (typeof module === 'object' && module.exports) module.exports = api;
    else root.MS2 = api;
}(this, function () {
    'use strict';
    var PPQ = 48, POLY = [1, 3, 3, 2, 1, 2, 1, 1, 1];
    var LEVEL = {T0:0, INTERLUDE:0, T1:1, T2:2, T3:3, BOSS:3, VICTORY:2};
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    function hash(s) { var h=2166136261,i; s=String(s); for(i=0;i<s.length;i++) h=((h^s.charCodeAt(i))*16777619)>>>0; return h||1; }
    function Random(seed) { this.value=hash(seed); }
    Random.prototype.next=function () { this.value=(1664525*this.value+1013904223)>>>0; return this.value/4294967296; };
    function frequency(p) { return 440*Math.pow(2,(p-69)/12); }
    function expression(state) { return !state.staged && state.expression===1 && (state.role==='T3'||state.role==='BOSS') ? 1 : 0; }
    function tempo(base, state) {
        var elapsed=state.staged||state.remaining<0?0:clamp(1-state.remaining/1800,0,1);
        return base*(1+.06*elapsed*elapsed);
    }
    function Composer(seed) { this.random=new Random(seed); this.count=0; this.history=[]; this.last=null; this.fillAt=6; }
    Composer.prototype.choose=function (asset) {
        var r=this.random, last=this.last, candidates=[], i, c, score, distance, preferred={};
        if(last) for(i=0;i<(last.next||[]).length;i++) preferred[last.next[i]]=1-i*.08;
        for(i=0;i<asset.clips.length;i++) {
            c=asset.clips[i];
            if(asset.clips.length>3 && this.history.indexOf(c.id)!==-1) continue;
            distance=last?Math.min((c.entry-last.exit+12)%12,(last.exit-c.entry+12)%12):0;
            score=(preferred[c.id]||0)+.3*c.energy-.04*distance+r.next()*.6;
            candidates.push({clip:c,score:score});
        }
        candidates.sort(function(a,b){return b.score-a.score;});
        c=candidates.length?candidates[0].clip:asset.clips[0];
        this.last=c;this.history.push(c.id);if(this.history.length>3)this.history.shift();
        return c;
    };
    Composer.prototype.phrase=function (asset, state) {
        var clip=this.choose(asset), r=this.random, source=clip.notes, out=[], i,n,t,d,v;
        var level=LEVEL[asset.role]||0, swing=(r.next()-.5)*.6, gate=.94+r.next()*.12;
        var color=.9+r.next()*.2, fill=asset.loop && level>0 && this.count>=this.fillAt;
        this.count++;
        if(fill) this.fillAt=this.count+6+Math.floor(r.next()*5);
        for(i=0;i<source.length;i++) {
            n=source[i];
            // Quiet material retains melody and harmony, with sparse percussion.
            if(level===0 && n[2]>=5 && (n[2]!==7 || n[0]%192!==0)) continue;
            // Fills replace the last beat's snare/toms/hats; they do not stack
            // a second drum arrangement or erase the downbeat/kick foundation.
            if(fill && n[0]>=clip.beats*PPQ-PPQ && (n[2]===5||n[2]===6||n[2]===8)) continue;
            if(state.quality===0 && (n[2]===8 && n[0]%24!==0 || n[2]===1 && n[4]<60)) continue;
            t=n[0]+(n[0]%24===12?swing:0)+(r.next()-.5)*.35;
            t=clamp(t,0,clip.beats*PPQ-1);
            d=Math.min(n[1]*gate,clip.beats*PPQ-t);
            v=n[4]*(.94+r.next()*.12);
            if(level===0 && n[2]>=5)v*=.45;
            // Rare register inversion leaves bass, mode and interval spelling intact.
            var pitch=n[3];
            if(asset.loop && n[2]===0 && n[0]%192===0 && r.next()<.08 && pitch<=67) pitch+=12;
            out.push([t,Math.max(1,d),n[2],pitch,clamp(v,1,120),color]);
        }
        if(fill) {
            var start=clip.beats*PPQ-PPQ, roll=[45,48,43,41];
            for(i=0;i<4;i++)out.push([start+i*12,7,5,roll[i],72+i*8,color]);
            out.push([start+18,6,6,38,66,color]);out.push([start+42,6,6,38,101,color]);
        }
        out.sort(function(a,b){return a[0]-b[0]||b[4]-a[4];});
        // Monophonic gates end at the next onset, in both sound backends.
        for(i=0;i<out.length;i++)if(out[i][2]===0||out[i][2]===4) {
            for(var j=i+1;j<out.length;j++)if(out[j][2]===out[i][2]) {
                out[i][1]=Math.min(out[i][1],Math.max(1,out[j][0]-out[i][0]));break;
            }
        }
        return {clip:clip.id,beats:clip.beats,notes:out,fill:fill,entry:clip.entry};
    };

    // Small deterministic percussion buffers. Their PCM is synthesized once,
    // then reused; no FFT, sample-by-sample JavaScript mixer or soundfont.
    function percussion(kind, rate) {
        var seconds=kind==='open'?.48:kind==='closed'?.09:kind==='kick'?.42:kind==='tom'?.38:.26;
        var out=new Float32Array(Math.ceil(seconds*rate)), random=new Random('ms2-'+kind);
        var phase=0, prev=0, i,t,f,x,env,noise;
        for(i=0;i<out.length;i++) {
            t=i/rate;noise=random.next()*2-1;
            if(kind==='kick') { f=48+115*Math.exp(-t*65);phase+=2*Math.PI*f/rate; x=Math.sin(phase)*Math.exp(-t*11)+noise*.16*Math.exp(-t*300); }
            else if(kind==='tom') { f=108+60*Math.exp(-t*34);phase+=2*Math.PI*f/rate;x=(Math.sin(phase)+.18*Math.sin(phase*1.6))*Math.exp(-t*12); }
            else if(kind==='snare') { x=(noise-prev*.7)*.52*Math.exp(-t*22)+.38*Math.sin(2*Math.PI*181*t)*Math.exp(-t*29); }
            else { env=Math.exp(-t*(kind==='open'?10:65)); x=((noise-prev)*.33+.055*Math.sin(2*Math.PI*587*t)+.045*Math.sin(2*Math.PI*1427*t))*env; }
            prev=noise;out[i]=clamp(x*Math.min(1,t/.002)*Math.min(1,(seconds-t)/.006)*.66,-.9,.9);
        }
        return out;
    }

    function WebSynth(context, report) {
        this.context=context;this.report=report;this.voices=[];this.lanes={};this.buffers={};this.waves={};this.peakVoices=0;
        var master=context.createGain(), low=context.createBiquadFilter(), high=context.createBiquadFilter(), compressor=context.createDynamicsCompressor();
        high.type='highpass';high.frequency.value=28;high.Q.value=.55;
        low.type='lowpass';low.frequency.value=10500;low.Q.value=.55;
        compressor.threshold.value=-12;compressor.knee.value=12;compressor.ratio.value=2.5;compressor.attack.value=.008;compressor.release.value=.18;
        master.gain.value=.55;master.connect(high);high.connect(low);low.connect(compressor);compressor.connect(context.destination);
        this.master=master;this.lowpass=low;
        var kinds=['kick','tom','snare','open','closed'];
        for(var k=0;k<kinds.length;k++) {
            var pcm=percussion(kinds[k],context.sampleRate), b=context.createBuffer(1,pcm.length,context.sampleRate);
            b.getChannelData(0).set(pcm);this.buffers[kinds[k]]=b;
        }
        for(var inst=0;inst<5;inst++) {
            var real=new Float32Array(33),imag=new Float32Array(33);
            for(var h=1;h<33;h++) {
                if(inst===0)imag[h]=1/h;
                if(inst===1)imag[h]=(h%2?1:.4)/Math.pow(h,1.15);
                if(inst===2)imag[h]=1/Math.pow(h,1.35);
                if(inst===3)imag[h]=h<7?Math.pow(.57,h-1):0;
                if(inst===4)imag[h]=h%2?1/Math.pow(h,1.35):.15/h;
            }
            this.waves[inst]=context.createPeriodicWave(real,imag);
        }
        var curve=new Float32Array(256);
        for(var c=0;c<curve.length;c++){var z=(c/(curve.length-1)*2-1)*2.1;curve[c]=z/(1+Math.abs(z));}
        this.curve=curve;
    }
    WebSynth.prototype.lane=function (id) {
        if(this.lanes[id])return this.lanes[id];
        var ctx=this.context,gain=ctx.createGain(),bed=ctx.createGain(),osc=ctx.createOscillator();
        gain.gain.value=0;gain.connect(this.master);bed.gain.value=.014;bed.connect(gain);
        osc.type='triangle';osc.frequency.value=frequency(50);osc.connect(bed);osc.start();
        var lane={gain:gain,bed:bed,osc:osc,value:0,from:0,at:ctx.currentTime};this.lanes[id]=lane;return lane;
    };
    WebSynth.prototype.mix=function (id,value,now,pitch) {
        var lane=this.lane(id),param=lane.gain.gain;
        var current=lane.from+(lane.value-lane.from)*clamp((now-lane.at)/.7,0,1);
        param.cancelScheduledValues(now);param.setValueAtTime(current,now);param.linearRampToValueAtTime(value,now+.7);
        lane.from=current;lane.value=value;lane.at=now;
        lane.osc.detune.setTargetAtTime(pitch||0,now,.4);
    };
    WebSynth.prototype.volume=function (v,quality) {
        this.master.gain.setTargetAtTime(v,this.context.currentTime,.08);
        this.lowpass.frequency.setTargetAtTime(quality===0?8000:10500,this.context.currentTime,.3);
    };
    WebSynth.prototype.release=function (voice,when) {
        voice.gain.gain.cancelScheduledValues(when);
        voice.gain.gain.setTargetAtTime(.00001,when,.004);
        for(var i=0;i<voice.sources.length;i++)try{voice.sources[i].stop(when+.025);}catch(ignore){}
        voice.end=when+.025;
    };
    WebSynth.prototype.note=function (e,state) {
        var ctx=this.context,now=ctx.currentTime,t=Math.max(e.time,now+.003),n=e.note,inst=n[2],lane=this.lane(e.lane);
        var max=state.quality===0?16:24, live=[], same=[], i;
        for(i=0;i<this.voices.length;i++) {
            var v=this.voices[i];
            if(v.end>t){live.push(v);if(v.lane===e.lane&&v.inst===inst)same.push(v);}
        }
        this.voices=live;
        if(same.length>=POLY[inst]) { this.release(same[0],t);this.voices.splice(this.voices.indexOf(same[0]),1); }
        if(this.voices.length>=max) {
            // Keep the bass/drum foundation where a less prominent layer exists.
            var quiet=this.voices[0];
            for(i=0;i<this.voices.length;i++)if(this.voices[i].inst!==4&&this.voices[i].inst!==7&&this.voices[i].level<quiet.level)quiet=this.voices[i];
            this.release(quiet,t);this.voices.splice(this.voices.indexOf(quiet),1);
        }
        var duration=clamp(n[1]*e.secondsPerTick,.025,4),gain=ctx.createGain(),nodes=[],sources=[];
        var level=[.10,.10,.09,.115,.16,.22,.21,.28,.12][inst]*Math.pow(n[4]/127,1.25)*(1+.08*expression(state));
        var release=[.08,.16,.23,.13,.06,.03,.02,.02,.02][inst],end=t+duration+release;
        gain.connect(lane.gain);nodes.push(gain);
        if(inst>=5) {
            var kind=inst===5?'tom':inst===6?'snare':inst===7?'kick':n[3]===46?'open':'closed';
            var source=ctx.createBufferSource();source.buffer=this.buffers[kind];
            source.playbackRate.value=inst===5?Math.pow(2,(n[3]-45)/12):1;
            source.connect(gain);sources.push(source);end=t+source.buffer.duration/source.playbackRate.value;
            gain.gain.setValueAtTime(level,t);source.start(t);source.stop(end+.01);
            // A closed hat chokes the existing open hat in this lane.
            if(inst===8&&kind==='closed')for(i=0;i<this.voices.length;i++)if(this.voices[i].lane===e.lane&&this.voices[i].inst===8)this.release(this.voices[i],t);
        } else {
            var filter=ctx.createBiquadFilter();filter.type='lowpass';filter.Q.value=inst===0?2.1:.65;
            filter.connect(gain);nodes.push(filter);
            var freq=frequency(n[3]),color=n[5]||1,cutoff=inst===0?clamp(freq*5*color,700,3800):inst===4?720:inst===3?2100:inst===2?3400:2400;
            filter.frequency.setValueAtTime(inst===0?cutoff*.5:cutoff,t);
            if(inst===0){filter.frequency.exponentialRampToValueAtTime(cutoff*1.3,t+.018);filter.frequency.exponentialRampToValueAtTime(Math.max(180,cutoff*.35),t+duration);}
            var target=filter;
            if(inst===1){var drive=ctx.createWaveShaper();drive.curve=this.curve;drive.connect(filter);target=drive;nodes.push(drive);}
            var oscillators=inst===1||inst===2||inst===4?2:1;
            for(var o=0;o<oscillators;o++) {
                var osc=ctx.createOscillator();osc.setPeriodicWave(this.waves[inst]);
                osc.frequency.setValueAtTime(o===1&&inst===4?freq*.5:freq,t);
                osc.detune.setValueAtTime(expression(state)*22+(inst===1||inst===2?(o===0?-6:6):0),t);
                osc.connect(target);osc.start(t);osc.stop(end+.01);sources.push(osc);
            }
            var attack=inst===0||inst===4?.006:inst===2?(state.role==='T0'||state.staged?.18:.025):.028;
            attack=Math.min(attack,duration*.4);
            gain.gain.setValueAtTime(.00001,t);gain.gain.linearRampToValueAtTime(level/oscillators,t+attack);
            gain.gain.linearRampToValueAtTime(level*.65/oscillators,t+Math.min(duration,attack+.10));
            gain.gain.setValueAtTime(level*.65/oscillators,t+duration);gain.gain.exponentialRampToValueAtTime(.00001,end);
        }
        var record={lane:e.lane,inst:inst,gain:gain,sources:sources,end:end,level:level};
        this.voices.push(record);this.peakVoices=Math.max(this.peakVoices,this.voices.length);
        sources[0].onended=function(){for(var a=0;a<nodes.length;a++)nodes[a].disconnect();for(var b=0;b<sources.length;b++)sources[b].disconnect();};
    };
    WebSynth.prototype.drop=function (id) {
        var lane=this.lanes[id];if(!lane)return;
        var now=this.context.currentTime,current=lane.from+(lane.value-lane.from)*clamp((now-lane.at)/.7,0,1);
        lane.gain.gain.cancelScheduledValues(now);lane.gain.gain.setValueAtTime(current,now);
        lane.gain.gain.linearRampToValueAtTime(0,now+.03);
        for(var i=0;i<this.voices.length;i++)if(this.voices[i].lane===id)this.release(this.voices[i],now);
        lane.osc.onended=function(){lane.osc.disconnect();lane.bed.disconnect();lane.gain.disconnect();};
        lane.osc.stop(now+.04);delete this.lanes[id];
    };
    WebSynth.prototype.stop=function () {
        for(var i=0;i<this.voices.length;i++)this.release(this.voices[i],this.context.currentTime);
        for(var id in this.lanes)this.drop(id);
        this.voices=[];this.master.gain.setValueAtTime(0,this.context.currentTime);
    };

    function Scheduler(base, sink, clock, callback, performanceSeed) {
        this.base=base;this.bpm=base;this.sink=sink;this.clock=clock;this.callback=callback||function(){};
        this.assets={};this.lanes={};this.queue=[];this.state={remaining:-1,role:'T0',quality:1};this.lastPump=clock();
        this.grid=[{beat:0,time:clock()+.08,bpm:base}];this.plannedBpm=base;this.receivedAt=clock();
        this.announcements=[];this.underruns=0;this.maxQueue=0;this.enabled=true;
        // Presentation entropy never touches campaign/layout/gameplay RNG. A
        // genuine return and a restarted renderer both receive a new realization.
        this.performanceSeed=performanceSeed===undefined?String(Date.now())+':'+Math.random():performanceSeed;
        this.visits={};
    }
    Scheduler.prototype.install=function (asset) {
        if(!asset||!asset.id||!asset.clips||asset.clips.length>256)throw new Error('invalid MIDI arrangement');
        for(var i=0;i<asset.clips.length;i++) {
            var c=asset.clips[i];if(!c.notes||c.notes.length>2048||c.beats<1)throw new Error('invalid MIDI phrase');
        }
        this.assets[asset.id]=asset;
    };
    Scheduler.prototype.ensureGrid=function (now) {
        var last=this.grid[this.grid.length-1],desired,dt,remaining;
        if(now-last.time>2) {
            // Rebase a genuinely stalled timer without replaying missed notes.
            this.grid=[{beat:last.beat+8,time:now+.08,bpm:this.plannedBpm}];last=this.grid[0];
        }
        while(last.time<now+12) {
            remaining=this.state.remaining<0?-1:Math.max(0,this.state.remaining-(last.time-this.receivedAt));
            desired=tempo(this.base,{staged:this.state.staged,remaining:remaining});dt=60/this.plannedBpm;
            this.plannedBpm+=clamp(desired-this.plannedBpm,-this.base*.003*dt,this.base*.003*dt);
            last={beat:last.beat+1,time:last.time+60/this.plannedBpm,bpm:this.plannedBpm};this.grid.push(last);
        }
        while(this.grid.length>2&&this.grid[1].time<now-1)this.grid.shift();
        for(var i=0;i<this.grid.length;i++)if(this.grid[i].time<=now)this.bpm=this.grid[i].bpm;
    };
    Scheduler.prototype.timeForBeat=function (beat) {
        for(var i=0;i<this.grid.length-1;i++) {
            var a=this.grid[i],b=this.grid[i+1];
            if(beat>=a.beat&&beat<=b.beat)return a.time+(b.time-a.time)*(beat-a.beat);
        }
        var last=this.grid[this.grid.length-1];return last.time+(beat-last.beat)*60/last.bpm;
    };
    Scheduler.prototype.boundary=function (now,beats) {
        this.ensureGrid(now);
        for(var i=0;i<this.grid.length;i++)if(this.grid[i].time>=now+.07&&this.grid[i].beat%beats===0)return this.grid[i].beat;
        return this.grid[this.grid.length-1].beat;
    };
    Scheduler.prototype.update=function (state) {
        var now=this.clock(),wanted={},i,t,l,id;
        this.state=state;this.receivedAt=now;this.enabled=true;this.ensureGrid(now);
        this.sink.volume(state.volume===undefined?.55:state.volume,state.quality);
        for(i=0;i<(state.targets||[]).length&&i<2;i++) {
            t=state.targets[i];if(t.weight<=0||!this.assets[t.asset])continue;
            id=t.block;wanted[id]=true;l=this.lanes[id];
            if(!l) {
                this.visits[id]=(this.visits[id]||0)+1;
                l={id:id,asset:t.asset,nextBeat:this.boundary(now,4),weight:t.weight,
                    composer:new Composer(state.seed+':'+this.performanceSeed+':'+id+':'+this.visits[id]),began:false};
                this.lanes[id]=l;
            } else if(l.asset!==t.asset) {
                l.asset=t.asset;l.nextBeat=this.boundary(now,state.role==='VICTORY'?1:4);l.finished=false;
                var boundaryTime=this.timeForBeat(l.nextBeat);
                this.queue=this.queue.filter(function(e){return e.lane!==id||e.time<boundaryTime;});
            }
            l.weight=t.weight;l.retire=null;
            this.sink.mix(id,Math.sqrt(t.weight),now,expression(state)*22);
        }
        for(id in this.lanes)if(!wanted[id]) {
            l=this.lanes[id];
            if(!l.retire){l.retire=now+1.2;this.sink.mix(id,0,now,0);}
        }
        // Rapid movement/replacements may not accumulate a choir of faded
        // floors. Keep two desired lanes and only the two newest retired tails.
        var retired=[];
        for(id in this.lanes)if(this.lanes[id].retire)retired.push(this.lanes[id]);
        retired.sort(function(a,b){return a.retire-b.retire;});
        while(retired.length>2){l=retired.shift();this.sink.drop(l.id);delete this.lanes[l.id];}
        // Release unreferenced arrangement payloads; active/fading lanes retain
        // them until their tails finish. History is bounded in each composer.
        var used={};for(id in this.lanes)used[this.lanes[id].asset]=true;
        for(id in this.assets)if(!used[id])delete this.assets[id];
    };
    Scheduler.prototype.pump=function () {
        if(!this.enabled)return;
        var now=this.clock(),horizon=.65,id,l,asset,phrase,i,n,t,nextTime,gate;
        this.ensureGrid(now);
        if(now-this.lastPump>horizon)this.underruns++;
        this.lastPump=now;
        for(id in this.lanes) {
            l=this.lanes[id];
            if(l.retire&&now>=l.retire){this.sink.drop(id);delete this.lanes[id];continue;}
            if(l.finished||l.retire)continue;
            asset=this.assets[l.asset];if(!asset)continue;
            nextTime=this.timeForBeat(l.nextBeat);
            if(nextTime<now-.06){l.nextBeat=this.boundary(now,1);nextTime=this.timeForBeat(l.nextBeat);this.queue=this.queue.filter(function(e){return e.lane!==id||e.time>=now;});}
            if(nextTime<now+horizon) {
                phrase=l.composer.phrase(asset,this.state);
                for(i=0;i<phrase.notes.length;i++) {
                    n=phrase.notes[i];t=this.timeForBeat(l.nextBeat+n[0]/PPQ);
                    gate=this.timeForBeat(l.nextBeat+(n[0]+n[1])/PPQ)-t;
                    this.queue.push({time:t,note:n,lane:id,secondsPerTick:gate/n[1]});
                }
                if(!l.began){this.announcements.push({time:nextTime,block:id});l.began=true;}
                if(!asset.loop){l.finished=true;this.victoryEnd=this.timeForBeat(l.nextBeat+phrase.beats);}
                l.nextBeat+=phrase.beats;
            }
        }
        this.queue.sort(function(a,b){return a.time-b.time||b.note[4]-a.note[4];});
        if(this.queue.length>2048)this.queue.length=2048;
        this.maxQueue=Math.max(this.maxQueue,this.queue.length);
        var pending=[];
        for(i=0;i<this.queue.length;i++) {
            var e=this.queue[i];
            if(e.time<now+horizon) {
                if(this.lanes[e.lane]&&e.time>=now-.08)this.sink.note(e,this.state);
            } else pending.push(e);
        }
        this.queue=pending;
        for(i=this.announcements.length-1;i>=0;i--)if(this.announcements[i].time<=now) {
            var a=this.announcements[i];if(this.lanes[a.block])this.callback('block',a.block);this.announcements.splice(i,1);
        }
        if(this.victoryEnd&&now>=this.victoryEnd){this.victoryEnd=null;this.callback('victory','');}
    };
    Scheduler.prototype.stop=function () {this.enabled=false;this.queue=[];this.announcements=[];this.lanes={};this.assets={};this.sink.stop();};

    function attach(bridge) {
        var context,web=false,clock,sink,scheduler,mode='native',nativeBatch=[],nativeMix={};
        try {
            var Constructor=window.AudioContext||window.webkitAudioContext;
            if(Constructor){context=new Constructor();if(typeof context.resume==='function')context.resume();web=true;}
        } catch(ignore) {web=false;}
        function nativeSink() {
            return {note:function(e,state){nativeBatch.push({delay:Math.max(0,e.time-clock()),lane:e.lane,inst:e.note[2],pitch:e.note[3],velocity:e.note[4],duration:e.note[1]*e.secondsPerTick,expression:expression(state)});},
                mix:function(id,value,now,pitch){nativeMix[id]=value;bridge.mix(id,value,pitch);},
                volume:function(v,q){bridge.volume(v,q);},drop:function(id){delete nativeMix[id];bridge.drop(id);},
                stop:function(){nativeBatch=[];nativeMix={};bridge.stop();}};
        }
        function initialize() {
            // A suspended/autoplay-blocked context gets a native-audio fallback,
            // not a silent enabled score. Both use exactly this composer.
            try {
                if(web&&context.state==='running'){sink=new WebSynth(context,bridge);mode='web';clock=function(){return context.currentTime;};}
            } catch(ignore) {sink=null;}
            if(!sink) {
                mode='native';clock=function(){return Date.now()/1000;};sink=nativeSink();
                if(context&&typeof context.close==='function')try{context.close();}catch(ignoreClose){}
            }
            scheduler=new Scheduler(130,sink,clock,function(name,value){if(name==='block')bridge.block(value);else bridge.victory();});
            bridge.ready(mode);
        }
        window.setTimeout(initialize,200);
        var interval=window.setInterval(function(){
            if(!scheduler)return;
            try {
                scheduler.pump();
                if(nativeBatch.length){bridge.notes(JSON.stringify(nativeBatch));nativeBatch=[];}
            } catch(e){bridge.error(String(e));scheduler.stop();}
        },25);
        return {install:function(a){scheduler.install(a);},state:function(s){scheduler.base=s.bpm||130;scheduler.update(s);},
            stop:function(){if(scheduler)scheduler.stop();},
            stats:function(){bridge.stats(JSON.stringify({backend:mode,bpm:scheduler&&scheduler.bpm,underruns:scheduler&&scheduler.underruns,
                queue:scheduler&&scheduler.queue.length,maxQueue:scheduler&&scheduler.maxQueue,peakVoices:sink.peakVoices||0}));},
            destroy:function(){window.clearInterval(interval);if(scheduler)scheduler.stop();
                if(context&&context.state!=='closed'&&typeof context.close==='function')try{context.close();}catch(ignoreClose){}}};
    }
    return {Composer:Composer,Scheduler:Scheduler,WebSynth:WebSynth,Random:Random,tempo:tempo,expression:expression,
        frequency:frequency,percussion:percussion,attach:attach,polyphony:POLY};
}));
]==]
