-- Human Soldier ESC / Return-to-Hero Queue UI Integration Seam (AG-007R2)
if SERVER then return end

LOD = LOD or {}
LOD.SoldierQueueUI = LOD.SoldierQueueUI or {}

local UI = LOD.SoldierQueueUI
UI.Panel = UI.Panel or nil

local RED = Color(170, 61, 50, 240)
local RED_HOVER = Color(200, 75, 60, 255)
local WHITE = Color(255, 255, 255, 255)
local DARK = Color(30, 30, 30, 220)

surface.CreateFont("LOD_SoldierQueueBtn", {
    font = "DejaVu Sans Condensed",
    size = 18,
    weight = 900,
    antialias = true
})

function UI:Close()
    if IsValid(self.Panel) then
        self.Panel:Remove()
        self.Panel = nil
    end
end

function UI:Open()
    if IsValid(self.Panel) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(280, 50)
    frame:SetPos(ScrW() / 2 - 140, 20)
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetDeleteOnClose(true)
    frame.Paint = function(s, w, h)
        LOD.UI:Paper(0, 0, w, h, LOD.UI.Colors.red)
    end

    local btn = vgui.Create("DButton", frame)
    btn:SetPos(10, 8)
    btn:SetSize(260, 34)
    btn:SetText("RETURN TO HERO QUEUE")
    btn:SetFont("LOD_SoldierQueueBtn")
    btn:SetTextColor(WHITE)
    btn.Paint = function(s, w, h)
        local col = s:IsHovered() and RED_HOVER or RED
        draw.RoundedBox(4, 0, 0, w, h, col)
    end

    btn.DoClick = function()
        RunConsoleCommand("lod_return_to_hero_queue")
        UI:Close()
    end

    self.Panel = frame
end

function UI:Update()
    local ply = LocalPlayer()
    if not IsValid(ply) then
        self:Close()
        return
    end

    local isSoldier = ply:GetNW2Bool("LOD_IsSoldier", false)
    local isEliminated = ply:GetNW2Bool("LOD_Eliminated", false)

    -- Open UI prompt when game menu / ESC is visible while controlling Soldier or spectating in queue
    if gui.IsGameUIVisible() and (isSoldier or isEliminated) then
        self:Open()
    else
        self:Close()
    end
end

hook.Add("Think", "LOD_SoldierQueueUIThink", function()
    UI:Update()
end)

concommand.Add("lod_ui_return_to_hero_queue", function()
    RunConsoleCommand("lod_return_to_hero_queue")
end)
