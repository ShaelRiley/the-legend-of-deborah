if SERVER then return end
LOD = LOD or {}
LOD.SoldierQueueUI = LOD.SoldierQueueUI or {}
local UI = LOD.SoldierQueueUI

function UI:Close()
    if IsValid(self.Panel) then self.Panel:Remove() end
    self.Panel = nil
end

function UI:Open()
    if IsValid(self.Panel) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_Eliminated", false) then return end
    local frame = vgui.Create("DFrame")
    frame:SetTitle("YOUR HERO'S NEXT CHAPTER")
    frame:SetSize(math.min(520, ScrW()-32), 330)
    frame:Center()
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.Paint = function(_, w, h) LOD.UI:Paper(0, 0, w, h, LOD.UI.Colors.red) end
    local choices = {
        {"WAIT FOR RESURRECTION", "Keep your Hero and spectate. A revival restores one life.", "lod_return_to_hero_queue"},
        {"BEGIN A NEW HERO", "Abandon this character. Start at Level 1 in this dungeon.", "lod_begin_new_hero"},
        {"JOIN THE SOLDIERS", "Play an enemy Soldier. Return later to await resurrection.", "lod_join_human_soldier"}
    }
    for i, choice in ipairs(choices) do
        local button = vgui.Create("DButton", frame)
        button:SetPos(16, 40+(i-1)*90)
        button:SetSize(frame:GetWide()-32, 40)
        button:SetText(choice[1])
        local description = vgui.Create("DLabel", frame)
        description:SetPos(16, 82+(i-1)*90)
        description:SetSize(frame:GetWide()-32, 38)
        description:SetWrap(true)
        description:SetText(choice[2])
        description:SetTextColor(Color(240,235,220))
        button.DoClick = function()
            if choice[3] == "lod_begin_new_hero" then
                Derma_Query("Discard this Hero's levels and carried equipment? Your $DEB and DFTs remain.",
                    "BEGIN A NEW HERO", "Begin", function() RunConsoleCommand(choice[3]); UI:Close() end,
                    "Cancel")
            else
                RunConsoleCommand(choice[3])
                UI:Close()
            end
        end
    end
    self.Panel = frame
end

hook.Add("Think", "LOD_SoldierQueueUIThink", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then UI:Close(); return end
    local eliminated = ply:GetNW2Bool("LOD_Eliminated", false)
    if not eliminated then UI.seen = nil; UI:Close(); return end
    local serial = ply:GetNW2Int("LOD_HeroSerial", 0)
    if UI.seen ~= serial then UI.seen = serial; UI:Open() end
    if input.IsKeyDown(KEY_F3) then UI:Open() end
end)
concommand.Add("lod_hero_choices", function() UI:Open() end)
concommand.Add("lod_ui_return_to_hero_queue", function() RunConsoleCommand("lod_return_to_hero_queue") end)
