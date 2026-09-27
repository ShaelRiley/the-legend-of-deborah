if SERVER then return end
LOD = LOD or {}
LOD.SoldierQueueUI = LOD.SoldierQueueUI or {}
local UI = LOD.SoldierQueueUI

function UI:Close()
    if IsValid(self.Confirm) then self.Confirm:Remove() end
    if IsValid(self.Panel) then self.Panel:Remove() end
    self.Panel, self.Confirm, self.context, self.mode = nil, nil, nil, nil
end

function UI:Mode(ply)
    if not IsValid(ply) then return nil end
    if ply:GetNW2Bool("LOD_IsSoldier", false) or ply:GetNW2Bool("LOD_SoldierWaiting", false) then return "soldier" end
    if ply:GetNW2String("LOD_HeroQueue", "hero") == "spectator" then return "spectator" end
    if ply:GetNW2Bool("LOD_Eliminated", false) then return "eliminated" end
    return "hero"
end

function UI:Blocked(ply)
    if not IsValid(ply) then return true end
    local state = LOD.ClientState or {}
    if state.failed or state.levelCleared or ply:GetNW2Bool("LOD_DeathTetrisActive", false) then return true end
    if LOD.UI and LOD.UI:IsMinigameLocked() then return true end
    if LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return true end
    return false
end

function UI:InputBusy()
    if self.chatOpen or gui.IsConsoleVisible() or gui.IsGameUIVisible() then return true end
    local focus = vgui.GetKeyboardFocus()
    if IsValid(focus) then
        local class = focus:GetClassName()
        return class == "DTextEntry" or class == "DBinder"
    end
    return false
end

function UI:Current(context)
    local ply = LocalPlayer()
    return not self:Blocked(ply) and self:Mode(ply) ~= "hero" and context ~= ""
        and ply:GetNW2String("LOD_TeamMenuContext", "") == context
end

function UI:Send(command, context)
    if not self:Current(context) then self:Close(); return false end
    RunConsoleCommand(command, context)
    self:Close()
    return true
end

function UI:Open()
    local ply = LocalPlayer()
    local context = IsValid(ply) and ply:GetNW2String("LOD_TeamMenuContext", "") or ""
    if not self:Current(context) or self:InputBusy() then return false end
    if IsValid(self.Panel) then return true end
    local mode = self:Mode(ply)
    local choices
    if mode == "soldier" then
        choices = {
            {"RETURN TO HERO QUEUE", "Retire this Soldier. Your saved Hero waits for future resurrection.", "lod_return_to_hero_queue"},
            {"SPECTATE ONLY", "Retire this Soldier without queuing for resurrection. F3 lets you rejoin the queue.", "lod_spectate_only"}
        }
    elseif mode == "spectator" then
        choices = {{"RETURN TO HERO QUEUE", "Rejoin with your saved Hero: await resurrection, or an open Hero slot if you have a life.", "lod_return_to_hero_queue"}}
    else
        choices = {
            {"WAIT FOR RESURRECTION", "Keep your Hero and spectate. A revival restores one life.", "lod_return_to_hero_queue"},
            {"BEGIN A NEW HERO", "Abandon this character. Start at Level 1 in this dungeon.", "lod_begin_new_hero"},
            {"JOIN THE SOLDIERS", "Play an enemy Soldier. Return later to await resurrection.", "lod_join_human_soldier"}
        }
    end
    local frame = vgui.Create("DFrame")
    self.Panel, self.context, self.mode = frame, context, mode
    frame:SetTitle("")
    frame:SetSize(math.min(520, ScrW()-32), math.min(100+#choices*110, ScrH()-32))
    frame:Center()
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.Paint = function(_, w, h) LOD.UI:Paper(0, 0, w, h, LOD.UI.Colors.red) end
    frame.OnKeyCodePressed = function(_, key) if key == KEY_ESCAPE then UI:Close() end end
    frame.OnClose = function() UI:Close() end
    local title = vgui.Create("DLabel", frame)
    title:SetPos(16, 32); title:SetSize(frame:GetWide()-32, 26)
    title:SetFont("LOD_SheetSubheading"); title:SetTextColor(LOD.UI.Colors.ink)
    title:SetText(mode == "eliminated" and "YOUR HERO'S NEXT CHAPTER" or "TEAM MENU")
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(16, 64); scroll:SetSize(frame:GetWide()-32, frame:GetTall()-80)
    for _, choice in ipairs(choices) do
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP); card:SetTall(110); card.Paint = function() end
        local button = vgui.Create("DButton", card)
        button:Dock(TOP); button:SetTall(40); button:SetText(choice[1])
        LOD.UI:Button(button, LOD.UI.Colors.blue)
        local description = vgui.Create("DLabel", card)
        description:Dock(FILL); description:DockMargin(0, 4, 0, 8)
        description:SetWrap(true); description:SetContentAlignment(7)
        description:SetFont("LOD_SheetBody"); description:SetTextColor(LOD.UI.Colors.ink)
        description:SetText(choice[2])
        button.DoClick = function()
            if UI.Panel ~= frame then return end
            if not UI:Current(context) then UI:Close(); return end
            if choice[3] == "lod_begin_new_hero" then
                if IsValid(UI.Confirm) then return end
                UI.Confirm = Derma_Query("Discard this Hero's levels and carried equipment? Your $DEB and DFTs remain.",
                    "BEGIN A NEW HERO", "Begin", function()
                        if UI.Panel == frame then UI:Send(choice[3], context) end
                    end, "Cancel")
            else
                UI:Send(choice[3], context)
            end
        end
    end
    return true
end

hook.Add("StartChat", "LOD_SoldierQueueChat", function() UI.chatOpen = true end)
hook.Add("FinishChat", "LOD_SoldierQueueChat", function() UI.chatOpen = false end)
hook.Add("Think", "LOD_SoldierQueueUIThink", function()
    local ply = LocalPlayer()
    local down = input.IsKeyDown(KEY_F3)
    local pressed = down and not UI.f3Down
    UI.f3Down = down -- sample even while blocked: no deferred press after typing
    if not IsValid(ply) then UI:Close(); UI.lastMode = nil; UI.pending = nil; return end
    local mode = UI:Mode(ply)
    local context = ply:GetNW2String("LOD_TeamMenuContext", "")
    if mode == "eliminated" and (UI.lastMode == nil or UI.lastMode == "hero") then UI.pending = context end
    if mode == "eliminated" and UI.pending == "" then UI.pending = context end
    UI.lastMode = mode
    if mode ~= "eliminated" then UI.pending = nil end
    if IsValid(UI.Panel) and (UI.context ~= context or UI.mode ~= mode or UI:Blocked(ply) or mode == "hero") then UI:Close() end
    if UI:Blocked(ply) or UI:InputBusy() then return end
    if pressed then
        UI.pending = nil
        if IsValid(UI.Panel) then UI:Close() else UI:Open() end
    elseif UI.pending and UI.pending ~= "" and UI.pending == context and UI:Open() then
        UI.pending = nil
    end
end)

hook.Add("HUDPaint", "LOD_SoldierQueueHint", function()
    local ply = LocalPlayer()
    if UI:Blocked(ply) or IsValid(UI.Panel) or gui.IsGameUIVisible() then return end
    local mode = UI:Mode(ply)
    if mode ~= "soldier" and mode ~= "spectator" then return end
    local text = mode == "spectator" and "SPECTATING ONLY | F3: HERO QUEUE"
        or ply:GetNW2Bool("LOD_SoldierWaiting", false) and "SOLDIER RESPAWN WAIT | F3: TEAM MENU"
        or "F3: TEAM MENU"
    draw.SimpleTextOutlined(text, "LOD_HUD_Small", ScrW()/2, ScrH()*0.60,
        Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,220))
end)
concommand.Add("lod_hero_choices", function() UI:Open() end)
concommand.Add("lod_ui_return_to_hero_queue", function()
    local ply = LocalPlayer()
    if IsValid(ply) then UI:Send("lod_return_to_hero_queue", ply:GetNW2String("LOD_TeamMenuContext", "")) end
end)
