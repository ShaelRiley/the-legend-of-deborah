if engine.ActiveGamemode and engine.ActiveGamemode() ~= "legend_of_deborah" then return end

LOD = LOD or {}

-- Canonical manual scrolling authority. The attached booklet's original fixed-height
-- layout clips content before ordinary page scrolling can reach it, so this runtime
-- normalizes the document into flowing content and provides one explicit gold
-- document scrollbar plus GMod input fallbacks.
local MANUAL_DOCUMENT_SCROLL = [=[
(function(){
  if(window.LODManualDocumentScrollInstalled) return;
  window.LODManualDocumentScrollInstalled=true;

  var left=document.getElementById('leftPage');
  var right=document.getElementById('rightPage');
  var reading=document.getElementById('readingView');
  var stage=document.querySelector('.book-stage');
  var book=document.getElementById('book');
  var folio=document.getElementById('folio');
  if(!left || !right || !stage || !book) return;

  var style=document.createElement('style');
  style.type='text/css';
  style.innerHTML=
    'html,body{height:auto!important;min-height:100%!important;overflow-y:auto!important;overflow-x:hidden!important;}'+
    'body{padding-right:54px!important;}'+
    '#manualApp{height:auto!important;min-height:100vh!important;display:block!important;}'+
    '.toolbar{position:sticky!important;top:0!important;z-index:90000!important;}'+
    '.book-stage{display:flex!important;flex:none!important;height:auto!important;min-height:calc(100vh - 48px)!important;align-items:flex-start!important;overflow:visible!important;padding-top:20px!important;padding-bottom:40px!important;}'+
    '.book{height:auto!important;min-height:calc(100vh - 116px)!important;align-items:stretch!important;overflow:visible!important;}'+
    '.page-slot{height:auto!important;min-height:calc(100vh - 116px)!important;overflow:visible!important;position:relative!important;}'+
    '.page-slot .page{height:auto!important;min-height:calc(100vh - 116px)!important;overflow:visible!important;position:relative!important;padding-right:60px!important;padding-bottom:54px!important;}'+
    '.page-slot .page .note{position:static!important;margin-top:18px!important;}'+
    '.page-slot .page .folio-num{position:static!important;display:block!important;text-align:right!important;margin-top:14px!important;}'+
    '.page-slot .page.cover,.page-slot .page.back-cover{height:calc(100vh - 116px)!important;min-height:620px!important;overflow:hidden!important;padding:0!important;}'+
    '.reading{position:relative!important;inset:auto!important;display:none!important;height:auto!important;min-height:calc(100vh - 48px)!important;overflow:visible!important;padding-bottom:90px!important;}'+
    '.reading.active{display:block!important;}'+
    '.reading .page{height:auto!important;min-height:0!important;overflow:visible!important;}'+
    '.reading .note{position:static!important;margin-top:18px!important;}'+
    '#lodDocScroll{position:fixed;z-index:999999;right:8px;top:64px;bottom:12px;width:38px;background:#202228;border:3px solid #ffd84a;border-radius:9px;box-shadow:0 0 16px rgba(0,0,0,.75);}'+
    '#lodDocUp,#lodDocDown{position:absolute;left:4px;width:24px;height:30px;border:0;background:#ffd84a;color:#15171a;font:bold 18px Arial,sans-serif;line-height:30px;text-align:center;cursor:pointer;}'+
    '#lodDocUp{top:4px;}#lodDocDown{bottom:4px;}'+
    '#lodDocTrack{position:absolute;left:5px;right:5px;top:40px;bottom:40px;background:#4a4d54;border:1px solid #b18c21;cursor:pointer;}'+
    '#lodDocThumb{position:absolute;left:2px;right:2px;top:0;height:64px;background:#ffd84a;border:2px solid #fff4b3;border-radius:6px;cursor:pointer;box-shadow:0 0 8px rgba(255,216,74,.55);}'+
    '#lodDocScroll.lodNoOverflow{opacity:.28;}'+
    'html::-webkit-scrollbar,body::-webkit-scrollbar{width:0!important;height:0!important;}';
  (document.head||document.documentElement).appendChild(style);

  var bar=document.getElementById('lodDocScroll');
  if(!bar){
    bar=document.createElement('div');
    bar.id='lodDocScroll';
    bar.innerHTML='<button id="lodDocUp">&#9650;</button><div id="lodDocTrack"><div id="lodDocThumb"></div></div><button id="lodDocDown">&#9660;</button>';
    document.body.appendChild(bar);
  }
  var up=document.getElementById('lodDocUp');
  var down=document.getElementById('lodDocDown');
  var track=document.getElementById('lodDocTrack');
  var thumb=document.getElementById('lodDocThumb');
  var dragging=false,dragStartY=0,dragStartScroll=0,lastFolio='';

  function docTop(){return Math.max(document.documentElement.scrollTop||0,document.body.scrollTop||0,window.pageYOffset||0);}
  function docHeight(){var d=document.documentElement,b=document.body;return Math.max(d?d.scrollHeight:0,b?b.scrollHeight:0,d?d.offsetHeight:0,b?b.offsetHeight:0);}
  function viewport(){return Math.max(1,window.innerHeight||document.documentElement.clientHeight||600);}
  function maximum(){return Math.max(0,docHeight()-viewport());}
  function setTop(value){
    var v=Math.max(0,Math.min(maximum(),Number(value)||0));
    if(document.documentElement)document.documentElement.scrollTop=v;
    if(document.body)document.body.scrollTop=v;
    try{window.scrollTo(0,v);}catch(e){}
    updateBar();
  }
  function by(amount){setTop(docTop()+(Number(amount)||0));}
  function page(direction){by(Math.max(180,Math.floor(viewport()*.80))*(Number(direction)||1));}
  function edge(toEnd){setTop(toEnd?maximum():0);}

  function normalizePage(page){
    if(!page)return;
    var cls=' '+String(page.className||'')+' ';
    if(cls.indexOf(' cover ')>=0 || cls.indexOf(' back-cover ')>=0)return;
    page.style.height='auto';page.style.minHeight='calc(100vh - 116px)';page.style.overflow='visible';page.style.position='relative';
    var notes=page.querySelectorAll('.note'),i;
    for(i=0;i<notes.length;i++){notes[i].style.position='static';notes[i].style.marginTop='18px';}
    var folios=page.querySelectorAll('.folio-num');
    for(i=0;i<folios.length;i++){folios[i].style.position='static';folios[i].style.display='block';folios[i].style.textAlign='right';folios[i].style.marginTop='14px';}
  }

  function readingActive(){
    if(!reading)return false;
    if(reading.classList&&reading.classList.contains('active'))return true;
    return (' '+String(reading.className||'')+' ').indexOf(' active ')>=0;
  }

  function normalize(){
    normalizePage(left.querySelector('.page'));normalizePage(right.querySelector('.page'));
    if(reading){
      var pages=reading.querySelectorAll('.page'),i,j,notes;
      for(i=0;i<pages.length;i++){
        pages[i].style.height='auto';pages[i].style.minHeight='0';pages[i].style.overflow='visible';
        notes=pages[i].querySelectorAll('.note');for(j=0;j<notes.length;j++)notes[j].style.position='static';
      }
    }
    var active=readingActive();
    stage.style.display=active?'none':'flex';
    if(reading)reading.style.display=active?'block':'none';
    var current=folio?String(folio.innerHTML||''):'';
    if(current!==lastFolio){lastFolio=current;setTop(0);}
    updateBar();
  }

  function updateBar(){
    if(!bar||!track||!thumb)return;
    var max=maximum(),trackH=Math.max(1,track.clientHeight),thumbH=trackH;
    if(max>0){thumbH=Math.max(60,Math.floor(trackH*(viewport()/Math.max(viewport(),docHeight()))));if(thumbH>trackH)thumbH=trackH;}
    var travel=Math.max(0,trackH-thumbH),top=max>0?Math.floor((docTop()/max)*travel):0;
    thumb.style.height=thumbH+'px';thumb.style.top=top+'px';bar.className=max>0?'':'lodNoOverflow';
  }

  up.onmousedown=function(e){by(-86);if(e&&e.preventDefault)e.preventDefault();return false;};
  down.onmousedown=function(e){by(86);if(e&&e.preventDefault)e.preventDefault();return false;};
  track.onmousedown=function(e){e=e||window.event;if(e.target===thumb)return false;var r=track.getBoundingClientRect();setTop((((e.clientY||r.top)-r.top)/Math.max(1,r.height))*maximum());if(e.preventDefault)e.preventDefault();return false;};
  thumb.onmousedown=function(e){e=e||window.event;dragging=true;dragStartY=e.clientY||0;dragStartScroll=docTop();if(e.preventDefault)e.preventDefault();if(e.stopPropagation)e.stopPropagation();return false;};
  document.addEventListener('mousemove',function(e){if(!dragging)return;var max=maximum();if(max<=0)return;var travel=Math.max(1,track.clientHeight-thumb.offsetHeight);setTop(dragStartScroll+(((e.clientY||0)-dragStartY)/travel)*max);if(e.preventDefault)e.preventDefault();},true);
  document.addEventListener('mouseup',function(){dragging=false;},true);

  document.addEventListener('wheel',function(e){var delta=typeof e.deltaY==='number'?e.deltaY:(typeof e.wheelDelta==='number'?-e.wheelDelta:90);if(delta===0)delta=90;by(delta);if(e.preventDefault)e.preventDefault();if(e.stopPropagation)e.stopPropagation();if(e.stopImmediatePropagation)e.stopImmediatePropagation();return false;},true);
  document.addEventListener('mousewheel',function(e){e=e||window.event;by(e.wheelDelta?-e.wheelDelta:90);if(e.preventDefault)e.preventDefault();if(e.stopPropagation)e.stopPropagation();e.returnValue=false;return false;},true);
  document.addEventListener('DOMMouseScroll',function(e){by((e.detail||1)*54);if(e.preventDefault)e.preventDefault();if(e.stopPropagation)e.stopPropagation();return false;},true);

  document.addEventListener('keydown',function(e){
    e=e||window.event;var code=e.keyCode||0,handled=true;
    if(code===40||code===83)by(76);else if(code===38||code===87)by(-76);else if(code===34)page(1);else if(code===33)page(-1);else if(code===36)edge(false);else if(code===35)edge(true);else handled=false;
    if(handled){if(e.preventDefault)e.preventDefault();if(e.stopPropagation)e.stopPropagation();e.returnValue=false;return false;}return true;
  },true);

  window.lodManualScroll=function(amount){by(Number(amount)||0);};
  window.lodManualPageScroll=function(direction){page(Number(direction)||1);};
  window.lodManualScrollHome=function(){edge(false);};
  window.lodManualScrollEnd=function(){edge(true);};
  window.addEventListener('scroll',updateBar,false);
  setInterval(normalize,120);setTimeout(normalize,0);setTimeout(normalize,180);setTimeout(normalize,500);
})();
]=]

local lastBrowser
local keyState = {}

local function queueManualJS(js)
    local manual = LOD and LOD.FieldManual
    local browser = manual and manual.Browser
    if IsValid(browser) then browser:QueueJavascript(js) end
end

local function injectManualDocumentScroll(browser)
    if IsValid(browser) then browser:QueueJavascript(MANUAL_DOCUMENT_SCROLL) end
end

local function keyPulse(key, js)
    local down = input.IsKeyDown(key)
    local state = keyState[key]
    local now = RealTime()
    if not down then keyState[key] = nil return end
    if not state then
        keyState[key] = {nextRepeat = now + 0.34}
        queueManualJS(js)
        return
    end
    if now >= state.nextRepeat then
        state.nextRepeat = now + 0.075
        queueManualJS(js)
    end
end

hook.Add("Think", "LOD_FieldManualDocumentScroll", function()
    local manual = LOD and LOD.FieldManual
    local browser = manual and manual.Browser
    if not IsValid(browser) then
        lastBrowser = nil
        keyState = {}
        return
    end

    if browser ~= lastBrowser then
        lastBrowser = browser
        -- DHTML is populated asynchronously; two bounded injections are enough.
        timer.Simple(0.18, function() if IsValid(browser) then injectManualDocumentScroll(browser) end end)
        timer.Simple(0.55, function() if IsValid(browser) then injectManualDocumentScroll(browser) end end)
        browser.OnMouseWheeled = function(_, delta)
            if delta == 0 then return false end
            queueManualJS(string.format("if(window.lodManualScroll)lodManualScroll(%d);", math.floor(-delta * 104)))
            return true
        end
    end

    keyPulse(KEY_DOWN, "if(window.lodManualScroll)lodManualScroll(76);")
    keyPulse(KEY_S, "if(window.lodManualScroll)lodManualScroll(76);")
    keyPulse(KEY_UP, "if(window.lodManualScroll)lodManualScroll(-76);")
    keyPulse(KEY_W, "if(window.lodManualScroll)lodManualScroll(-76);")
    keyPulse(KEY_PAGEDOWN, "if(window.lodManualPageScroll)lodManualPageScroll(1);")
    keyPulse(KEY_PAGEUP, "if(window.lodManualPageScroll)lodManualPageScroll(-1);")
    keyPulse(KEY_HOME, "if(window.lodManualScrollHome)lodManualScrollHome();")
    keyPulse(KEY_END, "if(window.lodManualScrollEnd)lodManualScrollEnd();")
end)
