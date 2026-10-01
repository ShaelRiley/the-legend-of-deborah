'use strict';
const assert=require('assert'),{performance}=require('perf_hooks');
const engine=require('./music/ms2_engine.js'),bank=require('./music/read_catalog.js');
let checks=0;function check(ok,msg){checks++;assert(ok,msg);}
const start=performance.now(),scale=new Set([0,2,4,5,7,9,11]);
let clipCount=0,noteCount=0,maxNotes=0;
for(const id of Object.keys(bank.catalog.assets)) {
    const asset=bank.asset(id),composer=new engine.Composer('catalog:'+id);
    for(const clip of asset.clips) {
        check(clip.notes.length<=2048,'bounded phrase');clipCount++;noteCount+=clip.notes.length;maxNotes=Math.max(maxNotes,clip.notes.length);
        for(const n of clip.notes) {
            check(n.length===5&&n[0]>=0&&n[0]<clip.beats*48&&n[1]>0&&n[0]+n[1]<=clip.beats*48,'gated phrase boundaries');
            if(n[2]<5)check(scale.has(n[3]%12),'D Dorian maintained');
        }
    }
    let prior=null;
    for(let i=0;i<24;i++) {
        const p=composer.phrase(asset,{quality:1,role:asset.role});
        if(asset.clips.length>3)check(prior!==p.clip,'recent phrases do not repeat');prior=p.clip;
        for(const n of p.notes)check(n[0]>=0&&n[0]<p.beats*48&&n[1]>0&&n[4]>0&&n[4]<=120,'bounded mutators');
    }
}
const one=bank.asset('a-t1');one.clips=[one.clips[0]];
const c=new engine.Composer('mutation');const variants=[];let fills=0;
for(let i=0;i<32;i++){const p=c.phrase(one,{quality:1,role:'T1'});variants.push(JSON.stringify(p.notes));if(p.fill)fills++;}
check(new Set(variants).size===32,'same clip receives distinct gated/velocity/timbre/humanized realizations');
check(fills>=2&&fills<=6,'periodic bounded fills');
check(engine.tempo(130,{remaining:1800})===130,'normal initial tempo');
check(engine.tempo(130,{remaining:0})===137.8,'timer tempo ceiling six percent');
check(engine.tempo(130,{remaining:0,staged:true})===130,'staging retains baseline');
check(engine.expression({role:'T3',remaining:0,expression:0})===0,'timer alone never raises pitch');
check(engine.expression({role:'T3',expression:1})===1,'confirmed desperate combat permits expression');
check(engine.expression({role:'BOSS',expression:0})===0,'ordinary boss fights retain baseline pitch/dynamics');
let now=0,notes=[],announcements=[],victories=0,beds={},stops=0;
const sink={note:e=>notes.push(e),mix:(id,g)=>beds[id]=g,volume:()=>{},drop:id=>delete beds[id],stop:()=>{beds={};stops++;}};
const scheduler=new engine.Scheduler(130,sink,()=>now,(name,value)=>{if(name==='block')announcements.push(value);else victories++;},'sequence-gate');
let state={role:'T1',targets:[{block:'a',asset:'a-t1',weight:1}],seed:19,remaining:1800,quality:1,volume:.55};
function change(next){state={...state,...next};for(const t of state.targets)scheduler.install(bank.asset(t.asset));scheduler.update(state);}
function step(seconds){for(let t=0;t<seconds;t+=.025){now+=.025;scheduler.pump();}}
change({});const firstRealization=scheduler.lanes.a.composer.random.value;
step(9);check(announcements.join(',')==='a','initial block announced exactly once');
change({role:'T2',targets:[{block:'a',asset:'a-t2',weight:1}]});step(4);
check(announcements.length===1,'same-block tension has no announcement');
change({targets:[{block:'a',asset:'a-t2',weight:.4},{block:'b',asset:'b-t2',weight:.6}]});step(3);
check(announcements.join(',')==='a,b','incoming stairs block starts once');
const sourceBeat=scheduler.lanes.a.nextBeat,destBeat=scheduler.lanes.b.nextBeat;
check(Number.isInteger(sourceBeat)&&Number.isInteger(destBeat),'lanes reference the shared musical grid');
for(let beat=Math.max(sourceBeat,destBeat)-8;beat<Math.max(sourceBeat,destBeat);beat++) {
    check(scheduler.timeForBeat(beat+.5)>scheduler.timeForBeat(beat),'shared grid is monotone');
}
change({targets:[{block:'a',asset:'a-t2',weight:.8},{block:'b',asset:'b-t2',weight:.2}]});step(2);
check(announcements.length===2,'stair reversal does not announce existing lanes again');
change({targets:[{block:'b',asset:'b-t2',weight:1}]});step(2);
check(!scheduler.lanes.a&&Object.keys(scheduler.lanes).length===1,'retired layers release after fade');
change({targets:[{block:'a',asset:'a-t2',weight:1}]});
check(scheduler.lanes.a.composer.random.value!==firstRealization&&scheduler.visits.a===2,'genuine return gets fresh presentation randomness');
step(3);
check(announcements.join(',')==='a,b,a','genuine return announces once');
const before=notes.length;now+=5;scheduler.pump();step(1);
check(scheduler.underruns===1&&notes.length>before,'long scheduler stall resynchronizes without note debt');
check(Object.keys(beds).length>0,'sustained bridge remains during a scheduler stall');
change({role:'VICTORY',targets:[{block:'a',asset:'a-victory',weight:1}]});step(12);
check(victories===1,'fanfare completes once');const atEnd=notes.length;step(8);
check(victories===1&&notes.length===atEnd,'fanfare does not loop');
check(scheduler.maxQueue<=2048&&scheduler.grid.length<40,'event and shared-clock storage bounded');
scheduler.stop();check(stops===1&&scheduler.queue.length===0&&Object.keys(beds).length===0,'Off releases renderer queues and bridge');
// Old HTML engines may expose an incomplete prefixed AudioContext. Their
// missing resume/close/node methods must fall back, rather than time out silently.
let initialize,tick,backend,bridgedNotes=0;
global.window={AudioContext:function(){this.state='running';},setTimeout:fn=>initialize=fn,
 setInterval:fn=>{tick=fn;return 1;},clearInterval:()=>{}};
const renderer=engine.attach({ready:v=>backend=v,mix:()=>{},volume:()=>{},drop:()=>{},stop:()=>{},
 block:()=>{},victory:()=>{},error:e=>{throw new Error(e);},stats:()=>{},notes:raw=>bridgedNotes+=JSON.parse(raw).length});
initialize();renderer.install(bank.asset('a-t1'));
renderer.state({role:'T1',seed:1,remaining:1800,quality:1,targets:[{block:'a',asset:'a-t1',weight:1}]});tick();
check(backend==='native'&&bridgedNotes>0,'incomplete Web Audio implementation plays through the shared native composer');
renderer.destroy();delete global.window;
const rapid=new engine.Scheduler(130,sink,()=>now,()=>{},'rapid-gate');
for(const block of ['a','b','c','d','e','f','g','h']) {
 rapid.install(bank.asset(block+'-t1'));rapid.update({seed:1,role:'T1',remaining:1800,quality:1,
  targets:[{block,asset:block+'-t1',weight:1}]});
 check(Object.keys(rapid.lanes).length<=3&&Object.keys(rapid.assets).length<=3,'rapid replacements keep two retirement tails');
}
rapid.stop();
for(const kind of ['kick','tom','snare','closed','open']) {
 const pcm=engine.percussion(kind,22050);let peak=0,sum=0;
 for(const n of pcm){check(Number.isFinite(n),'finite synthetic PCM');peak=Math.max(peak,Math.abs(n));sum+=n*n;}
 check(peak<1&&sum/pcm.length>.00001,'audible drum with digital headroom');
}
console.log(JSON.stringify({suite:'MS2_SEQUENCE',checks,clips:clipCount,notes:noteCount,maxClipNotes:maxNotes,maxQueue:scheduler.maxQueue,milliseconds:+(performance.now()-start).toFixed(1)}));
