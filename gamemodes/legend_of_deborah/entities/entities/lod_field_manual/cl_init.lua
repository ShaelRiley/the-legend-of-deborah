include("shared.lua")

LOD = LOD or {}
LOD.FieldManual = LOD.FieldManual or {}
local Manual = LOD.FieldManual

surface.CreateFont("LOD_InstructionWall", {font = "DejaVu Sans", size = 52, weight = 1000, antialias = true})
surface.CreateFont("LOD_InstructionHover", {font = "DejaVu Sans", size = 38, weight = 1000, antialias = true})
surface.CreateFont("LOD_InstructionBook", {font = "Georgia", size = 20, weight = 900, antialias = true})
surface.CreateFont("LOD_ManualControl", {font = "DejaVu Sans", size = 20, weight = 900, antialias = true})
surface.CreateFont("LOD_ManualHelp", {font = "DejaVu Sans", size = 17, weight = 700, antialias = true})
surface.CreateFont("LOD_StagingWallHotfix", {font = "DejaVu Sans", size = 52, weight = 1000, antialias = true})
surface.CreateFont("LOD_StagingPortalHotfix", {font = "DejaVu Sans", size = 38, weight = 1000, antialias = true})

local function loadChunk(path)
    local ok, value = pcall(include, path)
    return ok and isstring(value) and value or ""
end

local RAW_MANUAL_HTML = table.concat({
    loadChunk("assets/html_01.lua"),
    loadChunk("assets/html_02.lua"),
    loadChunk("assets/html_03.lua"),
    loadChunk("assets/html_04.lua")
})

-- Exact page-turn WAV from the attached package.
local PAGE_TURN_DATA = loadChunk("assets/page_1_01.lua") .. loadChunk("assets/page_1_02.lua")
local PAGE_TURN_URI = PAGE_TURN_DATA ~= "" and ("data:audio/wav;base64," .. PAGE_TURN_DATA) or nil

local function facing3D2DAngle(pos)
    local ang = (EyePos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    return ang
end

local function drawPedestal(ent)
    local pos, ang = ent:GetPos(), ent:GetAngles()
    local up, right = Vector(0, 0, 1), ent:GetRight()
    render.SetColorMaterial()
    render.DrawBox(pos, ang, Vector(-18, -15, 0), Vector(18, 15, 36), Color(66, 48, 40))
    render.DrawBox(pos + up * 36, ang, Vector(-23, -19, 0), Vector(23, 19, 4), Color(122, 82, 55))
    render.DrawBox(pos + up * 40, ang, Vector(-21, -17, 0), Vector(21, 17, 2), Color(72, 46, 33))

    local bookCenter = pos + up * 45
    render.DrawQuadEasy(bookCenter - up * 1.3 - right * 7.6,
        (up + right * 0.22):GetNormalized(), 21, 28, Color(103, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - up * 1.3 + right * 7.6,
        (up - right * 0.22):GetNormalized(), 21, 28, Color(103, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - right * 7.3,
        (up + right * 0.25):GetNormalized(), 19, 26, Color(246, 237, 207), 0)
    render.DrawQuadEasy(bookCenter + right * 7.3,
        (up - right * 0.25):GetNormalized(), 19, 26, Color(246, 237, 207), 0)
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-180, -180, -16), Vector(180, 180, 190))
end

function ENT:Draw()
    drawPedestal(self)
    local bookPos = self:GetPos() + Vector(0, 0, 49)
    cam.Start3D2D(bookPos, facing3D2DAngle(bookPos), 0.06)
        draw.SimpleTextOutlined("THE LEGEND OF DEBORAH", "LOD_InstructionBook", 0, 0,
            Color(124, 42, 38), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(255, 248, 225, 235))
    cam.End3D2D()
end

function ENT:DrawTranslucent()
    self:Draw()
end

local COMPAT_SCRIPT = [=[
(function(){
  var sourceNodes=document.querySelectorAll('.source-page');
  var source=[];
  var i;
  for(i=0;i<sourceNodes.length;i++) source.push(sourceNodes[i]);
  var book=document.getElementById('book');
  var left=document.getElementById('leftPage');
  var right=document.getElementById('rightPage');
  var folio=document.getElementById('folio');
  var reading=document.getElementById('readingView');
  var anchor=0, soundOn=true, motionOn=true, readingOn=false, busy=false;

  function nativeCall(name){
    try {
      var args=Array.prototype.slice.call(arguments,1);
      if(window.lod && typeof window.lod[name]==='function') window.lod[name].apply(window.lod,args);
    } catch(e) {}
  }
  function compact(){ return document.documentElement.clientWidth<=820; }
  function titleAt(index){
    if(index<0 || index>=source.length) return '';
    return source[index].getAttribute('data-title') || '';
  }
  function bindJumps(root){
    var buttons=root.querySelectorAll('[data-jump]');
    var n;
    for(n=0;n<buttons.length;n++){
      (function(btn){
        btn.onclick=function(){ jump(parseInt(btn.getAttribute('data-jump'),10)||0); };
      })(buttons[n]);
    }
  }
  function clonePage(index){
    if(index<0 || index>=source.length) return document.createElement('div');
    var page=source[index].querySelector('.page');
    if(!page) return document.createElement('div');
    var node=page.cloneNode(true);
    bindJumps(node);
    return node;
  }
  function render(){
    left.innerHTML=''; right.innerHTML='';
    if(compact()){
      right.appendChild(clonePage(anchor));
      folio.innerHTML=titleAt(anchor);
      return;
    }
    if(anchor%2!==0) anchor-=1;
    left.appendChild(clonePage(anchor));
    if(anchor+1<source.length) right.appendChild(clonePage(anchor+1));
    folio.innerHTML=titleAt(anchor)+(anchor+1<source.length?' &nbsp;·&nbsp; '+titleAt(anchor+1):'');
  }
  function maxAnchor(){
    if(compact()) return Math.max(0,source.length-1);
    return Math.max(0,source.length-(source.length%2?1:2));
  }
  function finishTurn(next){ anchor=next; render(); busy=false; }
  function turn(direction){
    if(readingOn || busy) return;
    var step=compact()?1:2;
    var next=Math.max(0,Math.min(maxAnchor(),anchor+direction*step));
    if(next===anchor) return;
    busy=true;
    if(soundOn) nativeCall('pageTurn',next,direction);
    var klass=direction>0?'turn-next':'turn-prev';
    if(motionOn && book && book.classList){
      book.classList.add(klass);
      setTimeout(function(){anchor=next;render();},185);
      setTimeout(function(){book.classList.remove(klass);busy=false;},430);
    } else finishTurn(next);
  }
  function setReadingActive(active){
    if(!reading) return;
    if(reading.classList){
      if(active) reading.classList.add('active'); else reading.classList.remove('active');
    } else reading.className=active?'reading active':'reading';
  }
  function buildReading(){
    reading.innerHTML='';
    var a,b,out,page,buttons,j;
    for(a=0;a<source.length;a++){
      page=source[a].querySelector('.page');
      if(!page) continue;
      out=document.createElement('article');
      out.appendChild(page.cloneNode(true));
      buttons=out.querySelectorAll('[data-jump]');
      for(j=buttons.length-1;j>=0;j--){
        b=buttons[j]; if(b && b.parentNode) b.parentNode.removeChild(b);
      }
      reading.appendChild(out);
    }
  }
  function toggleReading(force){
    readingOn=typeof force==='boolean'?force:!readingOn;
    setReadingActive(readingOn);
    document.getElementById('readBtn').innerHTML=readingOn?'Book View':'Reading Mode';
    if(readingOn){ buildReading(); reading.scrollTop=0; }
  }
  function jump(index){
    if(readingOn) toggleReading(false);
    anchor=Math.max(0,Math.min(source.length-1,index));
    if(!compact() && anchor%2!==0) anchor-=1;
    render();
    if(soundOn) nativeCall('pageTurn',anchor,1);
  }
  function toggleSound(){
    soundOn=!soundOn;
    document.getElementById('soundBtn').innerHTML='Sound: '+(soundOn?'On':'Off');
  }
  function toggleMotion(){
    motionOn=!motionOn;
    document.getElementById('motionBtn').innerHTML='Motion: '+(motionOn?'On':'Off');
  }

  window.lodManualTurn=turn;
  window.lodManualContents=function(){jump(2);};
  window.lodManualReading=function(){toggleReading();};
  window.lodManualSound=toggleSound;
  window.lodManualMotion=toggleMotion;

  document.getElementById('prevEdge').onclick=function(){turn(-1);};
  document.getElementById('nextEdge').onclick=function(){turn(1);};
  document.getElementById('contentsBtn').onclick=function(){jump(2);};
  document.getElementById('readBtn').onclick=function(){toggleReading();};
  document.getElementById('soundBtn').onclick=toggleSound;
  document.getElementById('motionBtn').onclick=toggleMotion;
  document.getElementById('closeBtn').onclick=function(){nativeCall('closeBook');};
  window.onresize=function(){if(!readingOn)render();};
  document.onkeydown=function(e){
    e=e||window.event;
    var key=e.key || '';
    var code=e.keyCode || 0;
    var lower=String(key).toLowerCase();
    if(key==='Escape' || code===27){nativeCall('closeBook');return false;}
    if(readingOn) return true;
    if(key==='ArrowRight' || code===39 || lower==='d'){turn(1);return false;}
    if(key==='ArrowLeft' || code===37 || lower==='a'){turn(-1);return false;}
    if(lower==='c' || code===67){jump(2);return false;}
    if(lower==='r' || code===82){toggleReading();return false;}
    return true;
  };
  render();
  nativeCall('ready',source.length);
})();
]=]

local EXTRA_STYLE = [=[
<style>
html,body,#manualApp{opacity:1!important;background:#17191c!important}
.book-stage{background:#17191c!important}
.page-slot{background:#f4edda!important;color:#20201d!important;opacity:1!important}
.page{color:#20201d!important}
.toolbar{background:#202329!important;color:#f8f4e8!important}
.reading{background:#f4edda!important;color:#20201d!important}
</style>
]=]

local function compatibleHTML(raw)
    if not raw or raw=="" then return "" end
    local html=raw
    local headClose=string.find(html,"</head>",1,true)
    if headClose then html=string.sub(html,1,headClose-1)..EXTRA_STYLE..string.sub(html,headClose) end
    local scriptStart=string.find(html,"<script>",1,true)
    local scriptClose=scriptStart and string.find(html,"</script>",scriptStart,true) or nil
    if scriptStart and scriptClose then
        html=string.sub(html,1,scriptStart-1).."<script>"..COMPAT_SCRIPT.."</script>"..string.sub(html,scriptClose+9)
    end
    return html
end

local MANUAL_HTML=compatibleHTML(RAW_MANUAL_HTML)

local function queuePageTurn(browser)
    if not IsValid(browser) then return end
    if not PAGE_TURN_URI then
        surface.PlaySound("physics/cardboard/cardboard_box_impact_soft2.wav")
        return
    end
    browser:QueueJavascript(string.format([[
      try { var a=new Audio(%q); a.volume=.72; a.play(); } catch(e) {}
    ]],PAGE_TURN_URI))
end

function Manual:Close(playSound)
    if IsValid(self.Frame) then
        if playSound~=false then surface.PlaySound("buttons/lightswitch2.wav") end
        self.Frame:Remove()
    end
    self.Frame=nil
    self.Browser=nil
end

local function makeControl(parent,text,x,w,js)
    local b=vgui.Create("DButton",parent)
    b:SetPos(x,6); b:SetSize(w,36); b:SetText(text); b:SetFont("LOD_ManualControl")
    b.DoClick=function()
        if js=="close" then Manual:Close(true)
        elseif IsValid(Manual.Browser) then Manual.Browser:QueueJavascript(js) end
    end
    return b
end

function Manual:Open()
    self:Close(false)
    local frame=vgui.Create("DFrame")
    frame:SetSize(ScrW(),ScrH()); frame:SetPos(0,0); frame:SetTitle("")
    frame:SetDraggable(false); frame:ShowCloseButton(false); frame:MakePopup(); frame:SetKeyboardInputEnabled(true)
    frame.Paint=function(_,w,h) surface.SetDrawColor(20,22,25,255); surface.DrawRect(0,0,w,h) end
    self.Frame=frame

    local browser=vgui.Create("DHTML",frame)
    browser:SetPos(12,12); browser:SetSize(ScrW()-24,ScrH()-72); browser:SetAllowLua(true)
    self.Browser=browser
    browser:AddFunction("lod","pageTurn",function() queuePageTurn(browser) end)
    browser:AddFunction("lod","closeBook",function() Manual:Close(true) end)
    browser:AddFunction("lod","ready",function() surface.PlaySound("buttons/button14.wav") end)
    if MANUAL_HTML=="" then
        browser:SetHTML("<html><body style='background:#f4edda;color:#20201d;padding:50px;font:22px Georgia'><h1>The Legend of Deborah</h1><p>The attached manual failed to load.</p></body></html>")
    else browser:SetHTML(MANUAL_HTML) end

    local bar=vgui.Create("DPanel",frame)
    bar:SetPos(0,ScrH()-54); bar:SetSize(ScrW(),54)
    bar.Paint=function(_,w,h) surface.SetDrawColor(31,34,39,255); surface.DrawRect(0,0,w,h) end
    local x=10
    local function add(text,w,js) makeControl(bar,text,x,w,js); x=x+w+8 end
    add("← Previous (A)",150,"if(window.lodManualTurn)lodManualTurn(-1);")
    add("Contents (C)",130,"if(window.lodManualContents)lodManualContents();")
    add("Reading Mode (R)",175,"if(window.lodManualReading)lodManualReading();")
    add("Next (D) →",140,"if(window.lodManualTurn)lodManualTurn(1);")
    local close=makeControl(bar,"Close Manual (Esc)",ScrW()-196,186,"close")
    close:SetZPos(10)

    timer.Simple(.08,function() if IsValid(browser) then browser:RequestFocus() end end)
end

net.Receive("LOD_OpenFieldManual",function() Manual:Open() end)

local escapeWasDown=false
hook.Add("Think","LOD_FieldManualEscapeFailsafe",function()
    if not IsValid(Manual.Frame) then escapeWasDown=false return end
    local down=input.IsKeyDown(KEY_ESCAPE)
    if down and not escapeWasDown then Manual:Close(true) end
    escapeWasDown=down
end)

local function aimedAt(ply,className,kind,maxDist,minDot)
    local eye=ply:EyePos(); local forward=ply:EyeAngles():Forward()
    local best,bestDot
    for _,ent in ipairs(ents.FindByClass(className)) do
        if IsValid(ent) and (not kind or (ent.GetStageKind and ent:GetStageKind()==kind)) then
            local delta=ent:WorldSpaceCenter()-eye
            local dist2=delta:LengthSqr()
            if dist2<=(maxDist*maxDist) and dist2>1 then
                delta:Normalize(); local dot=forward:Dot(delta)
                if dot>=(minDot or .94) and (not bestDot or dot>bestDot) then best,bestDot=ent,dot end
            end
        end
    end
    return best
end

hook.Add("HUDPaint","LOD_FieldManualAndPortalPrompts",function()
    if IsValid(Manual.Frame) then return end
    local ply=LocalPlayer()
    if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed",false) then return end

    if IsValid(aimedAt(ply,"lod_field_manual",nil,260,.94)) then
        draw.SimpleTextOutlined("Press 'E' to Read","LOD_InstructionHover",ScrW()*.5,ScrH()*.64,
            Color(250,250,245),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,4,Color(0,0,0,245))
        return
    end
    if IsValid(aimedAt(ply,"lod_staging_prop",2,320,.92)) then
        draw.SimpleTextOutlined("Press \"E\" to Enter the Labyrinth","LOD_StagingPortalHotfix",ScrW()*.5,ScrH()*.64,
            Color(250,250,245),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,4,Color(0,0,0,245))
    end
end)

-- Draw the two requested wall inscriptions from a global render hook so they are
-- never culled with the tiny invisible helper model that owns their network state.
hook.Add("PostDrawTranslucentRenderables","LOD_StagingPhysicalWallLetters",function(depth,sky)
    if depth or sky then return end
    local ply=LocalPlayer()
    if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed",false) then return end

    for _,ent in ipairs(ents.FindByClass("lod_staging_prop")) do
        if IsValid(ent) and ent.GetStageKind and ent:GetStageKind()==4 then
            local pos=ent:GetPos(); local label=string.Replace(ent:GetStageLabel() or "","\\n","\n")
            local lines=string.Explode("\n",label)
            cam.Start3D2D(pos,facing3D2DAngle(pos),.28)
                for i,line in ipairs(lines) do
                    draw.SimpleTextOutlined(line,"LOD_StagingWallHotfix",0,(i-1)*58,
                        Color(250,250,246),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,4,Color(0,0,0,250))
                end
            cam.End3D2D()
        end
    end

    for _,ent in ipairs(ents.FindByClass("lod_field_manual")) do
        if IsValid(ent) then
            local pos=ent:GetPos()+Vector(0,0,108)
            cam.Start3D2D(pos,facing3D2DAngle(pos),.23)
                draw.SimpleTextOutlined("INSTRUCTION MANUAL","LOD_InstructionWall",0,0,
                    Color(250,250,246),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,4,Color(0,0,0,250))
            cam.End3D2D()
        end
    end
end)

hook.Add("ShutDown","LOD_FieldManualClose",function() Manual:Close(false) end)
