include("shared.lua")

LOD = LOD or {}
LOD.FieldManual = LOD.FieldManual or {}
local Manual = LOD.FieldManual

surface.CreateFont("LOD_InstructionWall", {
    font = "DejaVu Sans",
    size = 48,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_InstructionHover", {
    font = "DejaVu Sans",
    size = 38,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_InstructionBook", {
    font = "Georgia",
    size = 20,
    weight = 900,
    antialias = true
})

surface.CreateFont("LOD_ManualFailsafeClose", {
    font = "DejaVu Sans",
    size = 22,
    weight = 900,
    antialias = true
})

local function loadChunk(path)
    local ok, value = pcall(include, path)
    return ok and isstring(value) and value or ""
end

local MANUAL_HTML = table.concat({
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
    render.DrawBox(bookCenter - up * 0.5, ang,
        Vector(-0.9, -1.0, -1.0), Vector(0.9, 1.0, 2.0), Color(74, 36, 29))
end

local function drawWallTitle(ent)
    local pos = ent:GetPos() - ent:GetForward() * 16 + Vector(0, 0, 104)
    local ang = facing3D2DAngle(pos)
    cam.Start3D2D(pos, ang, 0.078)
        draw.SimpleTextOutlined("INSTRUCTION MANUAL", "LOD_InstructionWall", 0, 0,
            Color(250, 250, 246), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            4, Color(0, 0, 0, 250))
    cam.End3D2D()
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-96, -96, 0), Vector(96, 96, 170))
end

function ENT:Draw()
    drawPedestal(self)
    drawWallTitle(self)

    local bookPos = self:GetPos() + Vector(0, 0, 49)
    local ang = facing3D2DAngle(bookPos)
    cam.Start3D2D(bookPos, ang, 0.042)
        draw.SimpleTextOutlined("THE LEGEND OF DEBORAH", "LOD_InstructionBook", 0, 0,
            Color(124, 42, 38), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(255, 248, 225, 235))
    cam.End3D2D()
end

local function queuePageTurn(browser)
    if not IsValid(browser) then return end
    if not PAGE_TURN_URI then
        surface.PlaySound("physics/cardboard/cardboard_box_impact_soft2.wav")
        return
    end

    browser:QueueJavascript(string.format([[
        (function(){
            try {
                var a = new Audio(%q);
                a.volume = 0.72;
                var p = a.play();
                if(p && p.catch) p.catch(function(){});
            } catch(e) {}
        })();
    ]], PAGE_TURN_URI))
end

local function destroyFrame(frame)
    if IsValid(frame) then frame:Remove() end
    if Manual.Frame == frame then
        Manual.Frame = nil
        Manual.Browser = nil
    end
end

function Manual:Close(playSound)
    local frame = self.Frame
    if not IsValid(frame) then
        self.Frame = nil
        self.Browser = nil
        return
    end

    if playSound ~= false then surface.PlaySound("buttons/lightswitch2.wav") end
    destroyFrame(frame)
end

local FALLBACK_BOOTSTRAP = [[
(function(){
  try {
    var left=document.getElementById('leftPage'), right=document.getElementById('rightPage');
    if(!left || !right || right.children.length) return;
    var source=[].slice.call(document.querySelectorAll('.source-page'));
    var book=document.getElementById('book'), folio=document.getElementById('folio');
    var reading=document.getElementById('readingView');
    var anchor=0, soundOn=true, motionOn=true, readingOn=false, busy=false;
    function nativeCall(name){
      try { if(window.lod && typeof window.lod[name]==='function') window.lod[name](); } catch(e){}
    }
    function compact(){ return window.matchMedia('(max-width:820px)').matches; }
    function clonePage(index){
      if(index<0 || index>=source.length) return document.createElement('div');
      var node=source[index].querySelector('.page').cloneNode(true);
      [].slice.call(node.querySelectorAll('[data-jump]')).forEach(function(btn){
        btn.addEventListener('click',function(){ jump(parseInt(btn.dataset.jump,10)); });
      });
      return node;
    }
    function render(){
      left.innerHTML=''; right.innerHTML='';
      if(compact()){
        right.appendChild(clonePage(anchor));
        folio.textContent=(source[anchor]&&source[anchor].dataset.title)||'';
        return;
      }
      if(anchor%2!==0) anchor-=1;
      left.appendChild(clonePage(anchor));
      if(anchor+1<source.length) right.appendChild(clonePage(anchor+1));
      folio.textContent=((source[anchor]&&source[anchor].dataset.title)||'') +
        (source[anchor+1] ? '  ·  '+source[anchor+1].dataset.title : '');
    }
    function maxAnchor(){
      if(compact()) return source.length-1;
      return Math.max(0,source.length-(source.length%2?1:2));
    }
    function turn(direction){
      if(readingOn||busy) return;
      var step=compact()?1:2;
      var next=Math.max(0,Math.min(maxAnchor(),anchor+direction*step));
      if(next===anchor) return;
      busy=true;
      if(soundOn) nativeCall('pageTurn');
      var klass=direction>0?'turn-next':'turn-prev';
      if(motionOn){
        book.classList.add(klass);
        setTimeout(function(){anchor=next;render();},185);
        setTimeout(function(){book.classList.remove(klass);busy=false;},430);
      } else { anchor=next;render();busy=false; }
    }
    function buildReading(){
      reading.innerHTML='';
      source.forEach(function(article){
        var out=document.createElement('article');
        out.appendChild(article.querySelector('.page').cloneNode(true));
        [].slice.call(out.querySelectorAll('[data-jump]')).forEach(function(btn){btn.remove();});
        reading.appendChild(out);
      });
    }
    function toggleReading(force){
      readingOn=typeof force==='boolean'?force:!readingOn;
      reading.classList.toggle('active',readingOn);
      document.getElementById('readBtn').textContent=readingOn?'Book View':'Reading Mode';
      if(readingOn){buildReading();reading.scrollTop=0;}
    }
    function jump(index){
      if(readingOn) toggleReading(false);
      anchor=Math.max(0,Math.min(source.length-1,index));
      if(!compact() && anchor%2!==0) anchor-=1;
      render(); if(soundOn) nativeCall('pageTurn');
    }
    document.getElementById('prevEdge').onclick=function(){turn(-1);};
    document.getElementById('nextEdge').onclick=function(){turn(1);};
    document.getElementById('contentsBtn').onclick=function(){jump(2);};
    document.getElementById('readBtn').onclick=function(){toggleReading();};
    document.getElementById('soundBtn').onclick=function(e){soundOn=!soundOn;e.currentTarget.textContent='Sound: '+(soundOn?'On':'Off');};
    document.getElementById('motionBtn').onclick=function(e){motionOn=!motionOn;e.currentTarget.textContent='Motion: '+(motionOn?'On':'Off');};
    document.getElementById('closeBtn').onclick=function(){nativeCall('closeBook');};
    window.addEventListener('keydown',function(e){
      var k=(e.key||'').toLowerCase();
      if(e.key==='Escape'){e.preventDefault();nativeCall('closeBook');return;}
      if(readingOn) return;
      if(e.key==='ArrowRight'||k==='d'){e.preventDefault();turn(1);}
      if(e.key==='ArrowLeft'||k==='a'){e.preventDefault();turn(-1);}
      if(k==='c'){e.preventDefault();jump(2);}
      if(k==='r'){e.preventDefault();toggleReading();}
    });
    window.addEventListener('resize',function(){if(!readingOn)render();});
    render();
  } catch(e) {}
})();
]]

function Manual:Open()
    self:Close(false)

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame.OpenedAt = SysTime()
    frame.Paint = function(_, w, h)
        Derma_DrawBackgroundBlur(frame, frame.OpenedAt)
        surface.SetDrawColor(0, 0, 0, 165)
        surface.DrawRect(0, 0, w, h)
    end
    self.Frame = frame

    local browser = vgui.Create("DHTML", frame)
    browser:Dock(FILL)
    browser:DockMargin(math.max(10, ScrW() * 0.018), math.max(10, ScrH() * 0.018),
        math.max(10, ScrW() * 0.018), math.max(10, ScrH() * 0.018))
    browser:SetAllowLua(true)
    self.Browser = browser

    browser:AddFunction("lod", "pageTurn", function()
        queuePageTurn(browser)
    end)
    browser:AddFunction("lod", "closeBook", function()
        Manual:Close(true)
    end)
    browser:AddFunction("lod", "ready", function()
        surface.PlaySound("buttons/button14.wav")
    end)

    if MANUAL_HTML == "" then
        browser:SetHTML("<html><body style='background:#f4edda;padding:50px;font:22px Georgia;color:#221f1a'><h1>The Legend of Deborah</h1><p>The attached instruction manual could not be loaded.</p><p>Press Escape to close.</p></body></html>")
    else
        browser:SetHTML(MANUAL_HTML)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(150, 38)
    close:SetPos(ScrW() - 166, 10)
    close:SetText("Close Manual")
    close:SetFont("LOD_ManualFailsafeClose")
    close:SetZPos(10000)
    close.DoClick = function() Manual:Close(true) end

    timer.Simple(0.12, function()
        if not IsValid(browser) then return end
        browser:QueueJavascript(FALLBACK_BOOTSTRAP)
        browser:RequestFocus()
    end)
end

net.Receive("LOD_OpenFieldManual", function()
    Manual:Open()
end)

local escapeWasDown = false
hook.Add("Think", "LOD_FieldManualEscapeFailsafe", function()
    if not IsValid(Manual.Frame) then
        escapeWasDown = false
        return
    end

    local down = input.IsKeyDown(KEY_ESCAPE)
    if down and not escapeWasDown then Manual:Close(true) end
    escapeWasDown = down
end)

hook.Add("HUDPaint", "LOD_FieldManualUsePrompt", function()
    if IsValid(Manual.Frame) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_Staged", false) then return end
    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:GetClass() ~= "lod_field_manual" then return end
    if ply:EyePos():DistToSqr(ent:WorldSpaceCenter()) > (250 * 250) then return end

    draw.SimpleTextOutlined("Press 'E' to Read", "LOD_InstructionHover",
        ScrW() * 0.5, ScrH() * 0.64, Color(250, 250, 245),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, 245))
end)

hook.Add("ShutDown", "LOD_FieldManualClose", function()
    Manual:Close(false)
end)
