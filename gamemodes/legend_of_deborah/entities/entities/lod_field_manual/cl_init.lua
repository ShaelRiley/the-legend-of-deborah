include("shared.lua")

LOD = LOD or {}
LOD.FieldManual = LOD.FieldManual or {}
local Manual = LOD.FieldManual

surface.CreateFont("LOD_InstructionWall", {
    font = "DejaVu Sans",
    size = 42,
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

-- Exact attached page-turn WAV, shipped through AddCSLuaFile-safe base64 chunks.
local PAGE_TURN_DATA = loadChunk("assets/page_1_01.lua") .. loadChunk("assets/page_1_02.lua")
local PAGE_TURN_URI = "data:audio/wav;base64," .. PAGE_TURN_DATA

local function facing3D2DAngle(pos)
    local ang = (EyePos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    return ang
end

local function drawPedestal(ent)
    local pos, ang = ent:GetPos(), ent:GetAngles()
    render.SetColorMaterial()
    render.DrawBox(pos, ang, Vector(-18, -15, 0), Vector(18, 15, 38), Color(76, 53, 42))
    render.DrawBox(pos + Vector(0, 0, 38), ang, Vector(-22, -18, 0), Vector(22, 18, 4), Color(115, 78, 54))

    local up, right = Vector(0, 0, 1), ent:GetRight()
    local bookCenter = pos + up * 45
    -- burgundy cover beneath two ivory pages
    render.DrawQuadEasy(bookCenter - up * 1.2 - right * 7.5, (up + right * 0.20):GetNormalized(), 20, 27, Color(104, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - up * 1.2 + right * 7.5, (up - right * 0.20):GetNormalized(), 20, 27, Color(104, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - right * 7.2, (up + right * 0.24):GetNormalized(), 18, 25, Color(246, 237, 207), 0)
    render.DrawQuadEasy(bookCenter + right * 7.2, (up - right * 0.24):GetNormalized(), 18, 25, Color(246, 237, 207), 0)
    render.DrawBox(bookCenter - up * 0.5, ang, Vector(-0.8, -1.0, -1.0), Vector(0.8, 1.0, 2.0), Color(74, 36, 29))
end

local function drawWallTitle(ent)
    local pos = ent:GetPos() - ent:GetForward() * 39 + Vector(0, 0, 98)
    local ang = facing3D2DAngle(pos)
    cam.Start3D2D(pos, ang, 0.075)
        draw.SimpleTextOutlined("INSTRUCTION MANUAL", "LOD_InstructionWall", 0, 0,
            Color(248, 248, 243), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            4, Color(0, 0, 0, 245))
    cam.End3D2D()
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-80, -80, 0), Vector(80, 80, 150))
end

function ENT:Draw()
    drawPedestal(self)
    drawWallTitle(self)

    local bookPos = self:GetPos() + Vector(0, 0, 48)
    local ang = facing3D2DAngle(bookPos)
    cam.Start3D2D(bookPos, ang, 0.045)
        draw.SimpleTextOutlined("THE LEGEND OF DEBORAH", "LOD_InstructionBook", 0, 0,
            Color(128, 48, 42), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(255, 248, 225, 230))
    cam.End3D2D()
end

local function playPageTurn(browser)
    if PAGE_TURN_DATA == "" or not IsValid(browser) then
        surface.PlaySound("physics/cardboard/cardboard_box_impact_soft2.wav")
        return
    end
    browser:QueueJavascript(string.format([[
        (function(){
            try {
                var s = new Audio(%q);
                s.volume = 0.72;
                s.play();
            } catch(e) {}
        })();
    ]], PAGE_TURN_URI))
end

function Manual:Close(playSound)
    if IsValid(self.Frame) then
        if playSound ~= false then surface.PlaySound("buttons/lightswitch2.wav") end
        self.Frame:Remove()
    end
    self.Frame = nil
    self.Browser = nil
end

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
        surface.SetDrawColor(0, 0, 0, 155)
        surface.DrawRect(0, 0, w, h)
    end
    self.Frame = frame

    local browser = vgui.Create("DHTML", frame)
    browser:Dock(FILL)
    browser:DockMargin(math.max(8, ScrW() * 0.018), math.max(8, ScrH() * 0.018),
        math.max(8, ScrW() * 0.018), math.max(8, ScrH() * 0.018))
    browser:SetAllowLua(false)
    self.Browser = browser

    -- Install the exact package bridge before HTML is loaded so its initial
    -- ready() call is not lost.
    browser:AddFunction("lod", "pageTurn", function()
        playPageTurn(browser)
    end)
    browser:AddFunction("lod", "closeBook", function()
        Manual:Close(true)
    end)
    browser:AddFunction("lod", "ready", function()
        surface.PlaySound("buttons/button14.wav")
    end)

    if MANUAL_HTML == "" then
        browser:SetHTML("<html><body style='background:#f4edda;padding:40px;font-family:serif'><h1>The Legend of Deborah</h1><p>Instruction manual asset failed to load.</p></body></html>")
    else
        browser:SetHTML(MANUAL_HTML)
    end
end

net.Receive("LOD_OpenFieldManual", function()
    Manual:Open()
end)

hook.Add("HUDPaint", "LOD_FieldManualUsePrompt", function()
    if IsValid(Manual.Frame) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_Staged", false) then return end
    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:GetClass() ~= "lod_field_manual" then return end
    if ply:EyePos():DistToSqr(ent:WorldSpaceCenter()) > (240 * 240) then return end

    draw.SimpleTextOutlined("Press 'E' to Read", "LOD_InstructionHover",
        ScrW() * 0.5, ScrH() * 0.64, Color(250, 250, 245),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, 245))
end)

hook.Add("ShutDown", "LOD_FieldManualClose", function()
    Manual:Close(false)
end)
