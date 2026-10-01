'use strict';
// Render the production Web Audio synth in Chromium. No server, internet,
// browser account or mock AudioNode implementation participates in this check.
const assert=require('assert'),fs=require('fs'),path=require('path');
const bank=require('./music/read_catalog.js');
const args=process.argv.slice(2);
function option(name) {const i=args.indexOf(name);return i<0?undefined:args[i+1];}
const executablePath=option('--browser')||process.env.MS2_CHROMIUM;
if(!executablePath)throw new Error('Supply --browser /path/to/chromium or MS2_CHROMIUM. See docs/MUSIC_SYSTEM.md.');
const search=[process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES||'',process.env.MS2_NODE_MODULES||'',process.cwd()];
const {chromium}=require(require.resolve('playwright',{paths:search}));
async function main() {
    const browser=await chromium.launch({executablePath,headless:true,args:['--no-sandbox','--disable-gpu','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']});
    try {
        const page=await browser.newPage();
        await page.setContent('<!doctype html><title>MS2 offline audio gate</title>');
        await page.addScriptTag({content:fs.readFileSync(path.join(__dirname,'music/ms2_engine.js'),'utf8')});
        const assets=Object.keys(bank.catalog.assets).map(id=>bank.asset(id));
        const results=await page.evaluate(async ({assets,bpm})=>{
            const byId={};for(const a of assets)byId[a.id]=a;
            const rate=44100;
            function measure(buffer,start=0,end=buffer.duration) {
                const channels=[buffer.getChannelData(0),buffer.getChannelData(1)];
                let peak=0,sum=0,finite=true,minWindow=1,windows=[];
                const first=Math.ceil(start*rate),last=Math.min(channels[0].length,Math.floor(end*rate));
                for(let i=first;i<last;i++)for(const channel of channels){const x=channel[i];finite=finite&&Number.isFinite(x);peak=Math.max(peak,Math.abs(x));sum+=x*x;}
                for(let s=first;s+rate/10<=last;s+=rate/10) {
                    let power=0;for(let i=s;i<s+rate/10;i++)power+=channels[0][i]*channels[0][i];
                    const rms=Math.sqrt(power/(rate/10));windows.push(rms);minWindow=Math.min(minWindow,rms);
                }
                return {finite,peak,rms:Math.sqrt(sum/Math.max(1,(last-first)*2)),minWindow,windows};
            }
            const arrangements=[];
            for(const asset of assets) {
                const ctx=new OfflineAudioContext(2,Math.ceil(4.4*rate),rate),synth=new MS2.WebSynth(ctx);
                const composer=new MS2.Composer('audition:'+asset.id),phrase=composer.phrase(asset,{role:asset.role,quality:1});
                synth.mix(asset.block,1,0,0);
                for(const n of phrase.notes)synth.note({time:.08+n[0]/48*60/bpm,note:n,lane:asset.block,secondsPerTick:60/bpm/48},{role:asset.role,quality:1,expression:0});
                const rendered=await ctx.startRendering();
                arrangements.push({id:asset.id,notes:phrase.notes.length,peakVoices:synth.peakVoices,...measure(rendered,.8,3.8)});
                synth.stop();
            }
            const instruments=[];
            for(let inst=0;inst<9;inst++) {
                const ctx=new OfflineAudioContext(2,rate*2,rate),synth=new MS2.WebSynth(ctx);
                synth.mix('instrument',1,0,0);
                const pitches=[62,62,69,64,38,45,38,36,46];
                synth.note({time:.5,note:[0,48,inst,pitches[inst],100,1],lane:'instrument',secondsPerTick:1/48},{role:'T2',quality:1,expression:0});
                const rendered=await ctx.startRendering();instruments.push({inst,...measure(rendered,.5,1.1)});synth.stop();
            }
            // Suspended offline rendering advances the genuine AudioContext
            // clock, exercising actual scheduling, fades, node retirement and Off.
            const ctx=new OfflineAudioContext(2,rate*36,rate),synth=new MS2.WebSynth(ctx);
            let blocks=[],victories=0,events=0;
            const originalNote=synth.note.bind(synth);synth.note=(e,s)=>{events++;originalNote(e,s);};
            let state={seed:841,role:'T0',remaining:1800,volume:.55,quality:1,expression:0,targets:[{block:'a',asset:'a-t0',weight:1}]};
            const scheduler=new MS2.Scheduler(bpm,synth,()=>ctx.currentTime,(name,value)=>{
                if(name==='block')blocks.push(value);
                else {victories++;change({role:'T0',expression:0,targets:[{block:'b',asset:'b-t0',weight:1}]});}
            },'offline-audio-gate');
            function change(patch) {state={...state,...patch};for(const t of state.targets)scheduler.install(byId[t.asset]);scheduler.update(state);}
            change({});scheduler.pump();
            let suspended=ctx.suspend(.125),rendering=ctx.startRendering();
            for(let step=1;step<288;step++) {
                await suspended;
                if(step===48)change({role:'T2',targets:[{block:'a',asset:'a-t2',weight:1}]});
                if(step===80)change({targets:[{block:'a',asset:'a-t2',weight:.45},{block:'b',asset:'b-t2',weight:.55}]});
                if(step===96)change({targets:[{block:'a',asset:'a-t2',weight:.75},{block:'b',asset:'b-t2',weight:.25}]});
                if(step===112)change({targets:[{block:'b',asset:'b-t2',weight:1}]});
                if(step===144)change({role:'BOSS',remaining:30,expression:1,targets:[{block:'b',asset:'b-boss',weight:1}]});
                if(step===160)change({quality:0});
                if(step===176)change({quality:1,expression:0});
                if(step===192)change({role:'VICTORY',targets:[{block:'b',asset:'b-victory',weight:1}]});
                if(step===272)scheduler.stop();
                scheduler.pump();
                if(step<287)suspended=ctx.suspend((step+1)*.125);
                await ctx.resume();
            }
            const rendered=await rendering;
            const score=measure(rendered,1,33.9),off=measure(rendered,34.3,36);
            const preview=Array.from(rendered.getChannelData(0));
            return {arrangements,instruments,score,off,events,blocks,victories,peakVoices:synth.peakVoices,maxQueue:scheduler.maxQueue,underruns:scheduler.underruns,remainingLanes:Object.keys(synth.lanes).length,preview,rate};
        },{assets,bpm:bank.catalog.bpm});
        let checks=0;function check(condition,message){checks++;assert(condition,message);}
        for(const a of results.arrangements){check(a.finite&&a.peak<.9,a.id+' finite unclipped audio');check(a.rms>.003,a.id+' audible score');check(a.peakVoices<=24,a.id+' voice ceiling');}
        for(const i of results.instruments){check(i.finite&&i.peak<.9,'instrument headroom '+i.inst);check(i.rms>.002,'instrument audibility '+i.inst);}
        check(results.score.finite&&results.score.peak<.9,'transition rendering remains unclipped');
        check(results.score.minWindow>.0001,'no silent 100ms musical windows across roles/stair reversals/victory');
        check(results.off.peak===0&&results.remainingLanes===0,'Off produces digital silence and disposes all lanes');
        check(results.blocks.join(',')==='a,b'&&results.victories===1,'real audio transport announces floor starts and victory once');
        check(results.peakVoices<=24&&results.maxQueue<=2048&&results.underruns===0,'real synth/transport resource ceilings');
        const output=option('--output');
        if(output) {
            const count=results.preview.length,data=Buffer.alloc(44+count*2);
            data.write('RIFF',0);data.writeUInt32LE(36+count*2,4);data.write('WAVEfmt ',8);data.writeUInt32LE(16,16);
            data.writeUInt16LE(1,20);data.writeUInt16LE(1,22);data.writeUInt32LE(results.rate,24);data.writeUInt32LE(results.rate*2,28);
            data.writeUInt16LE(2,32);data.writeUInt16LE(16,34);data.write('data',36);data.writeUInt32LE(count*2,40);
            results.preview.forEach((x,i)=>data.writeInt16LE(Math.round(Math.max(-1,Math.min(1,x))*32767),44+i*2));
            fs.mkdirSync(path.dirname(path.resolve(output)),{recursive:true});fs.writeFileSync(output,data);
        }
        delete results.preview;
        for(const a of [...results.arrangements,...results.instruments,results.score,results.off])delete a.windows;
        console.log(JSON.stringify({suite:'MS2_WEB_AUDIO',checks,catalogRevision:bank.catalog.revision,...results}));
    } finally {await browser.close();}
}
main().catch(error=>{console.error(error);process.exitCode=1;});
