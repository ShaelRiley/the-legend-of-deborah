/* MS2 Surge-rendered control plane. ES5 for GMod's older HTML engine.
 * Composition uses curated phrase metadata; no note synthesis or audio DSP.
 * Missed boundaries are discarded. Native playback independently enforces time. */
(function(root,factory){var api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.MS2=api;}(this,function(){
    'use strict';
    var LOOKAHEAD=1.0,LATE=.06;
    function clamp(v,a,b){return Math.max(a,Math.min(b,v));}
    function hash(s){var h=2166136261,i;s=String(s);for(i=0;i<s.length;i++)h=((h^s.charCodeAt(i))*16777619)>>>0;return h||1;}
    function Random(seed){this.value=hash(seed);}
    Random.prototype.next=function(){this.value=(1664525*this.value+1013904223)>>>0;return this.value/4294967296;};
    function expression(s){return !s.staged&&s.expression===1&&(s.role==='T3'||s.role==='BOSS')?1:0;}
    function Composer(seed){this.random=new Random(seed);this.history=[];this.last=null;}
    Composer.prototype.choose=function(asset){
        var r=this.random,last=this.last,candidates=[],preferred={},i,c,dist;
        if(last)for(i=0;i<(last.next||[]).length;i++)preferred[last.next[i]]=1-i*.08;
        for(i=0;i<asset.clips.length;i++){
            c=asset.clips[i];if(asset.clips.length>3&&this.history.indexOf(c.id)!==-1)continue;
            dist=last?Math.min((c.entry-last.exit+12)%12,(last.exit-c.entry+12)%12):0;
            candidates.push({clip:c,score:(preferred[c.id]||0)+.3*c.energy-.04*dist+r.next()*.6});
        }
        candidates.sort(function(a,b){return b.score-a.score;});
        c=candidates.length?candidates[0].clip:asset.clips[0];this.last=c;
        this.history.push(c.id);if(this.history.length>3)this.history.shift();return c;
    };
    function Scheduler(base,sink,clock,callback,seed){
        this.base=base;this.bpm=base;this.sink=sink;this.clock=clock;this.callback=callback||function(){};
        this.origin=clock()+LOOKAHEAD;this.assets={};this.lanes={};this.jobs={};this.serial=0;this.visits={};
        this.enabled=true;this.state={role:'T0'};this.skipped=0;this.resyncs=0;this.maxQueue=0;
        this.performanceSeed=seed===undefined?String(Date.now())+':'+Math.random():seed;
    }
    Scheduler.prototype.timeForBeat=function(beat){return this.origin+beat*60/this.base;};
    Scheduler.prototype.boundary=function(now,beats,lead){return Math.max(0,Math.ceil((now+(lead===undefined?LOOKAHEAD:lead)-this.origin)*this.base/60/beats)*beats);};
    Scheduler.prototype.install=function(a){
        if(!a||!a.id||!a.clips||!a.clips.length||a.clips.length>256)throw Error('invalid phrase arrangement');
        for(var i=0;i<a.clips.length;i++)if(!/^[a-z0-9][a-z0-9_-]{0,63}$/.test(a.clips[i].id)||(a.clips[i].beats!==8&&a.clips[i].beats!==12))throw Error('invalid rendered phrase');
        this.assets[a.id]=a;
    };
    Scheduler.prototype.cancel=function(l){if(l.pending){this.sink.cancel(l.pending);delete this.jobs[l.pending];l.pending=null;}};
    Scheduler.prototype.update=function(s){
        var now=this.clock(),wanted={},i,t,l,id,retired=[];this.state=s;this.enabled=true;
        this.sink.volume((s.volume===undefined?.55:s.volume)*(1+.08*expression(s)),s.quality);
        for(i=0;i<(s.targets||[]).length&&i<2;i++){
            t=s.targets[i];if(t.weight<=0||!this.assets[t.asset])continue;id=t.block;wanted[id]=true;l=this.lanes[id];
            if(!l){
                this.visits[id]=(this.visits[id]||0)+1;
                l={id:id,asset:t.asset,nextBeat:this.boundary(now,s.role==='VICTORY'?1:4,s.role==='VICTORY'?.25:LOOKAHEAD),
                    composer:new Composer(s.seed+':'+this.performanceSeed+':'+id+':'+this.visits[id]),began:false};this.lanes[id]=l;
            }else if(l.asset!==t.asset){
                this.cancel(l);l.asset=t.asset;l.finished=false;
                l.nextBeat=this.boundary(now,s.role==='VICTORY'?1:4,s.role==='VICTORY'?.25:LOOKAHEAD);
            }
            l.retire=null;l.weight=t.weight;this.sink.mix(id,Math.sqrt(t.weight),now);
        }
        for(id in this.lanes)if(!wanted[id]){
            l=this.lanes[id];if(!l.retire){this.cancel(l);l.retire=now+1.2;this.sink.mix(id,0,now);}retired.push(l);
        }
        retired.sort(function(a,b){return a.retire-b.retire;});
        while(retired.length>2){l=retired.shift();this.sink.drop(l.id);delete this.lanes[l.id];}
        var used={};for(id in this.lanes)used[this.lanes[id].asset]=true;
        for(id in this.assets)if(!used[id])delete this.assets[id];
    };
    Scheduler.prototype.result=function(token,played){
        var j=this.jobs[token];if(!j)return;delete this.jobs[token];var l=this.lanes[j.lane];
        if(!l||l.pending!==token)return;l.pending=null;
        if(played){
            if(!l.began){l.began=true;this.callback('block',l.id);}
            if(!j.loop){l.finished=true;this.victoryEnd=j.time+j.beats*60/this.base;}
        }else{
            this.skipped++;this.resyncs++;
            if(!j.loop){l.finished=true;this.callback('victory','');}
            else l.nextBeat=this.boundary(this.clock(),4);
        }
    };
    Scheduler.prototype.pump=function(){
        if(!this.enabled)return;var now=this.clock(),id,l,a,t,c,j,queued=0;
        for(id in this.lanes){
            l=this.lanes[id];if(l.retire&&now>=l.retire){this.sink.drop(id);delete this.lanes[id];continue;}if(l.retire||l.finished)continue;
            a=this.assets[l.asset];if(!a)continue;
            if(l.pending){
                j=this.jobs[l.pending];
                if(j&&j.time<now-LATE){this.sink.cancel(l.pending);this.result(l.pending,false);}else continue;
                if(l.finished)continue;
            }
            t=this.timeForBeat(l.nextBeat);
            if(t<now-LATE){this.skipped++;this.resyncs++;l.nextBeat=this.boundary(now,4);t=this.timeForBeat(l.nextBeat);}
            if(t<=now+LOOKAHEAD+.001){
                // One preparation per lane/pump. Never drain overdue debt.
                c=l.composer.choose(a);var token=String(++this.serial);
                j={lane:id,clip:c.id,beats:c.beats,time:t,loop:a.loop};this.jobs[token]=j;l.pending=token;
                l.nextBeat+=c.beats;this.sink.prepare(token,id,c.id,Math.max(0,t-now),t);
            }
        }
        for(id in this.jobs)queued++;this.maxQueue=Math.max(this.maxQueue,queued);
        if(this.victoryEnd&&now>=this.victoryEnd){this.victoryEnd=null;this.callback('victory','');}
    };
    Scheduler.prototype.stop=function(){this.enabled=false;this.jobs={};this.lanes={};this.assets={};this.victoryEnd=null;this.sink.stop();};
    function attach(bridge){
        var scheduler,interval,clock=window.performance&&window.performance.now?function(){return window.performance.now()/1000;}:function(){return Date.now()/1000;};
        var sink={prepare:function(token,lane,clip,delay,deadline){bridge.prepare(token,lane,clip,delay,deadline);},cancel:function(token){bridge.cancel(token);},
            mix:function(id,g){bridge.mix(id,g);},volume:function(v,q){bridge.volume(v,q);},drop:function(id){bridge.drop(id);},stop:function(){bridge.stop();}};
        scheduler=new Scheduler(130,sink,clock,function(name,value){if(name==='block')bridge.block(value);else bridge.victory();});
        interval=window.setInterval(function(){try{scheduler.pump();}catch(e){bridge.error(String(e));scheduler.stop();}},25);
        // Delay ready so attach has returned and window.lodScore exists.
        window.setTimeout(function(){bridge.ready('surge-rendered',clock());},0);
        return {install:function(a){scheduler.install(a);},state:function(s){if((s.bpm||130)!==scheduler.base)throw Error('rendered bank tempo mismatch');scheduler.update(s);},
            result:function(token,played){scheduler.result(String(token),played);},stop:function(){scheduler.stop();},
            stats:function(){bridge.stats(JSON.stringify({backend:'surge-rendered',bpm:scheduler.base,lateSkipped:scheduler.skipped,resyncs:scheduler.resyncs,
                prepared:Object.keys(scheduler.jobs).length,peakPrepared:scheduler.maxQueue}));},
            destroy:function(){window.clearInterval(interval);scheduler.stop();}};
    }
    return {Composer:Composer,Scheduler:Scheduler,Random:Random,expression:expression,tempo:function(base){return base;},attach:attach,lookahead:LOOKAHEAD,lateTolerance:LATE};
}));
