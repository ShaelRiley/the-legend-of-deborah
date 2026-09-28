local O,UI=LOD.PlayerOptions,LOD.UI
function O:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil
    if UI.ActivePage=="options" then UI.ActivePage=nil end
end
function O:Open()
    if UI:IsMinigameLocked() then return end
    UI:SelectPage("options");self:Close();UI.ActivePage="options"
    local f=vgui.Create("DFrame");self.Frame=f
    f:SetSize(math.min(980,ScrW()-32),math.min(500,ScrH()-32));f:Center();f:SetTitle("");f:MakePopup()
    f.Paint=function(_,w,h) UI:Paper(0,0,w,h) end
    f.OnRemove=function() if O.Frame==f then O.Frame=nil;if UI.ActivePage=="options" then UI.ActivePage=nil end end end
    UI:CloseButton(f,function() self:Close() end);UI:PageLinks(f,"options",70)
    local function label(text,y,font)
        local l=vgui.Create("DLabel",f);l:SetPos(28,y);l:SetSize(f:GetWide()-56,26)
        l:SetFont(font or "LOD_SheetBody");l:SetTextColor(UI.Colors.ink);l:SetText(text);return l
    end
    label("OPTIONS",24,"LOD_SheetTitle");label("Audio",118,"LOD_SheetHeading")
    local music=vgui.Create("DCheckBoxLabel",f);music:SetPos(30,158);music:SetText("Music");music:SetTextColor(UI.Colors.ink);music:SetConVar("lod_music");music:SizeToContents()
    local status=label("",185)
    status.Think=function(l)
        local cv=GetConVar("lod_music_enabled")
        l:SetText(cv and cv:GetBool() and "Music follows your location and the danger around you." or "Disabled by server — your preference is saved.")
    end
    local slider=vgui.Create("DNumSlider",f);slider:SetPos(28,222);slider:SetSize(math.min(550,f:GetWide()-56),32)
    slider:SetText("Music volume");slider:SetMinMax(0,1);slider:SetDecimals(2);slider:SetConVar("lod_music_volume")
    slider.Label:SetTextColor(UI.Colors.ink)
    label("Controls",290,"LOD_SheetHeading")
    local run=vgui.Create("DCheckBoxLabel",f);run:SetPos(30,335)
    local binding=input.LookupBinding("+speed") or "Shift"
    run:SetText("Always Run (hold "..string.upper(binding).." to walk)");run:SetTextColor(UI.Colors.ink);run:SetConVar("lod_always_run");run:SizeToContents()
    label("Options are saved between sessions. Menus do not pause the game.",387)
end
