// Run the exact shipped ES5 script; this test does not launch or control a browser.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync('docs/manual/manual.html','utf8');
const blocks=[...html.matchAll(/<article class="([^"]+)"[^>]*data-title="([^"]+)"[^>]*>([\s\S]*?)<\/article>/g)];
const pages=blocks.map(m=>({className:m[1],style:{},textContent:m[3].replace(/<[^>]+>/g,' '),getAttribute:()=>m[2]}));
const nodes={};for(const id of ['reader','contents','prev','next','status','search','find','smaller','larger'])nodes[id]={scrollTop:0,value:'',textContent:''};
const events=[];let ready=0;
const document={querySelectorAll:()=>pages,getElementById:id=>nodes[id]};
const window={lod:{position:(...a)=>events.push(a),ready:()=>ready++,close:()=>events.push('close'),tab:n=>events.push(n)}};
vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],{document,window});
assert.equal(ready,1);assert(nodes.prev.disabled);assert.equal(pages.filter(p=>p.className.includes(' active')).length,1);
window.LODManual.restore(20,187,23);assert.equal(nodes.contents.value,'20');assert.equal(nodes.reader.scrollTop,187);assert.equal(pages[20].style.fontSize,'23px');
nodes.next.onclick();nodes.prev.onclick();assert.equal(nodes.reader.scrollTop,187,'chapter navigation remembers scroll');
nodes.search.value='Black Keycard';nodes.find.onclick();assert(nodes.status.textContent.startsWith('Match 1 of'));
const firstMatch=nodes.contents.value;nodes.find.onclick();assert.notEqual(nodes.contents.value,firstMatch);
nodes.search.value='no_such_deborah_term_91';nodes.find.onclick();assert(nodes.status.textContent.startsWith('No match'));
let prevented=0;document.onkeydown({target:{tagName:'INPUT'},keyCode:80,preventDefault:()=>prevented++});assert.equal(prevented,0,'typing P does not switch menu');
document.onkeydown({target:{tagName:'BODY'},keyCode:80,preventDefault:()=>prevented++});assert.equal(events.at(-1),80);
document.onkeydown({target:{tagName:'INPUT'},keyCode:27,preventDefault:()=>prevented++});assert.equal(events.at(-1),'close');
document.onkeydown({target:{tagName:'BODY'},keyCode:79,key:'o',preventDefault:()=>prevented++});assert.equal(events.at(-1),79,'O reaches the restricted tab bridge');
const before=events.length;document.onkeydown({target:{tagName:'INPUT'},keyCode:79,key:'o',preventDefault:()=>prevented++});assert.equal(events.length,before,'O remains usable in search text');
let rebound;window.lod.tab=(code,name)=>rebound=[code,name];
document.onkeydown({target:{tagName:'BODY'},keyCode:85,key:'u',preventDefault:()=>prevented++});assert.deepEqual(rebound,[85,'u'],'Non-default bindings forward their key name');
for(let i=0;i<40;i++)nodes.larger.onclick();assert.equal(pages[0].style.fontSize,'26px');
for(let i=0;i<40;i++)nodes.smaller.onclick();assert.equal(pages[0].style.fontSize,'15px');
for(let i=0;i<pages.length;i++){nodes.contents.value=String(i);nodes.contents.onchange();assert.equal(pages.filter(p=>p.className.includes(' active')).length,1);assert.equal(nodes.contents.value,String(i));}
assert(nodes.next.disabled);console.log('PASS: all '+pages.length+' chapters, search cycling, bookmarks, zoom limits, keyboard isolation');
