'use strict';
// Exercise production long-buffer transport at native and resampled rates.
const assert=require('assert'),MS=require('./music/ms2_engine.js');
let checks=0;function check(v,m){checks++;assert(v,m);}
class Param{constructor(){this.value=0;this.events=[];}setValueAtTime(value,at){this.events.push({value,at});}linearRampToValueAtTime(value,at){this.events.push({value,at});}cancelScheduledValues(at){this.events=this.events.filter(e=>e.at<at);}}
class Buf{constructor(c,n,r){this.numberOfChannels=c;this.length=n;this.sampleRate=r;this.duration=n/r;this.data=Array.from({length:c},()=>new Float32Array(n));}getChannelData(c){return this.data[c];}}
function context(rate){return {currentTime:0,sampleRate:rate,destination:{},sources:[],decodes:[],createBuffer:(c,n,r)=>new Buf(c,n,r),createGain(){return {gain:new Param(),connect(){},disconnect(){}};},createBufferSource(){const s={connect(){},disconnect(){},start(at,offset=0){this.startAt=at;this.offset=offset;},stop(at=0){this.stopAt=at;}};this.sources.push(s);return s;},decodeAudioData(data,ok,fail){this.decodes.push({ok,fail});}};}
function fixture(ctx,id,scale=1){const frames=Math.round(64*60/130*ctx.sampleRate),tail=Math.round(.55*ctx.sampleRate),buffer=ctx.createBuffer(2,frames+tail,ctx.sampleRate);for(const src of buffer.data)for(let i=0;i<src.length;i++)src[i]=scale*(i<frames?.06*Math.sin(i*.017):.015*(1-(i-frames)/tail));return {buffer,clip:{id,beats:64,duration:buffer.duration,entry:2,exit:2,energy:.4,next:[]},clean:new Float32Array(buffer.data[0])};}
for(const rate of [44100,48000]){
 const ctx=context(rate),requests=[],results=[],tr=new MS.AudioTransport(ctx,(lane,id)=>requests.push(id),(token,on)=>results.push({token,on}));
 tr.mix('lower',1);tr.mix('upper',.5);
 function add(id,assetName=id){const f=fixture(ctx,id),asset={id:assetName,role:'T0',loop:true,bound:.15,clips:[f.clip]};tr.install(asset);const e=tr.build(f.buffer,{asset,clip:f.clip});tr.cache[id]=e;tr.bytes+=e.bytes;return {e,f,asset};}
 const a=add('a'),b=add('b');
 check(a.e.original===a.e.buffer,'no full-body duplicate');
 check(a.e.bytes===(a.f.buffer.length+a.e.head.length)*8,'account every retained PCM buffer');
 check(a.e.bytes<12*1024*1024,'one long-form clip is under 12 MiB at supported rates');
 for(let i=0;i<a.e.frames;i+=211){const want=a.f.clean[i]+(a.f.clean[a.e.frames+i]||0);check(Math.abs(a.e.buffer.data[0][i]-want)<1e-8,'loop body has exactly one release');}
 for(let i=0;i<a.e.head.length;i+=37)check(a.e.head.data[0][i]===a.f.clean[i],'first downbeat is clean source, not folded release');
 tr.prepare('a','lower','a',1,1);tr.prepare('b','upper','b',1,1);
 const j=tr.jobs.a;
 check(j.intro.source.startAt===1&&j.intro.source.offset===0,'attack begins exactly at requested boundary');
 check(j.voice.source.startAt===1+a.e.head.duration&&j.voice.source.offset===a.e.head.duration,'body follows attack without missing/repeated samples');
 check(j.voice.source.loopStart===0&&j.voice.source.loopEnd===a.e.period,'one-period loop excludes encoded tail');
 ctx.currentTime=2;tr.tick();check(tr.voices.length===2,'completed attack buffers release source ownership');
 const c=fixture(ctx,'c'),asset={id:'c',role:'T0',loop:true,bound:.15,clips:[c.clip]};tr.install(asset);
 tr.prepare('c','lower','c',1,1+a.e.period);
 check(tr.bytes+tr.reserved<=32*1024*1024,'two floors plus reservation stay under 32 MiB');
 if(rate===44100){
   check(requests.includes('c'),'two resident floors leave room for successor at 44.1 kHz');tr.receive('c','T2dnUw==');ctx.decodes[0].ok(c.buffer);
   check(tr.jobs.c.scheduled&&tr.jobs.c.tail,'prepared successor has outgoing natural tail');
   tr.cancel('c');check(tr.lanes.lower.current===j.voice&&j.voice.end>80000,'cancelled transition restores original resident');
 }else{
   check(!requests.includes('c')&&results.some(r=>r.token==='c'&&!r.on),'48 kHz excess rejected before decode, not allocated speculatively');
   check(tr.lanes.lower.current===j.voice&&j.voice.end===Infinity,'memory pressure never silences healthy music');
   tr.releaseLane('upper');tr.prepare('c2','lower','c',1,1+a.e.period);check(requests.includes('c'),'successor admitted after obsolete floor is released');
 }
 check(tr.voices.length<=8&&Object.keys(tr.loads).length<=2,'node/decode limits retained');
 const scheduler=new MS.Scheduler(130,tr,()=>ctx.currentTime,()=>{},'long',64);scheduler.install(a.asset);
 check(Math.abs(scheduler.timeForBeat(64000)-scheduler.origin-1000*a.e.period)<1e-9,'one thousand sixteen-bar loops stay on sample grid');
 tr.stop();check(tr.bytes===0&&tr.reserved===0&&tr.voices.length===0,'Off disposes long bodies, short attacks and decode reservations');
 for(const s of ctx.sources)check(s.buffer===null,'Off releases all source buffer references');
}
// MIDI role changes remain musical eight-beat entries, not thirty-second waits.
let now=0,prepared=[];const sink={volume(){},mix(){},drop(){},cancel(){},prepare(token,lane,clip,delay,due){prepared.push({token,lane,clip,due});}};
const scheduler=new MS.Scheduler(130,sink,()=>now,()=>{},'roles',64);
const calm={id:'calm',role:'T0',loop:true,clips:[{id:'a',beats:64,entry:2,exit:2,energy:.2}]},boss={id:'boss',role:'BOSS',loop:true,clips:[{id:'b',beats:64,entry:2,exit:2,energy:.8}]};
scheduler.install(calm);scheduler.install(boss);scheduler.update({role:'T0',targets:[{block:'a',asset:'calm',weight:1}]});scheduler.pump();scheduler.result(prepared[0].token,true);now=5;scheduler.install(boss);scheduler.update({role:'BOSS',targets:[{block:'a',asset:'boss',weight:1}]});
check(scheduler.timeForBeat(scheduler.lanes.a.nextBeat)-now<4,'boss role does not wait sixteen bars');
console.log(JSON.stringify({suite:'MS3_LONGFORM',checks,actualAudio:false,rates:[44100,48000],pcmLimit:32*1024*1024}));
