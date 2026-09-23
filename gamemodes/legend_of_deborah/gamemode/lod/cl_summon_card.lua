local E,UI=LOD.Equipment,LOD.UI
function E:CloseSummonCard(cancel)
    local frame=self.SummonFrame
    self.SummonFrame=nil
    if UI.ActivePage=="summon_card" then UI.ActivePage=nil end
    if not IsValid(frame) then return end
    if cancel then
        net.Start("LOD_SummonCardChoose");net.WriteUInt(frame.Nonce,32);net.WriteEntity(NULL);net.SendToServer()
    end
    frame:Remove()
end
net.Receive("LOD_SummonCardMenu",function()
    local nonce,here,count=net.ReadUInt(32),net.ReadBool(),net.ReadUInt(8)
    local choices={}
    for i=1,count do choices[i]={entity=net.ReadEntity(),name=net.ReadString()} end
    E:CloseSummonCard(false)
    local ply=LocalPlayer()
    if not E:IsActive(ply) or ply:GetNW2String("LOD_ThrowableItem","")~="summon_card" then return end
    UI:SelectPage("summon_card")
    local frame=vgui.Create("DFrame");E.SummonFrame=frame;frame.Nonce=nonce
    frame:SetTitle("");frame:SetSize(math.min(520,ScrW()-32),math.min(480,ScrH()-32))
    frame:Center();frame:MakePopup()
    UI:CloseButton(frame,function() E:CloseSummonCard(true) end)
    frame.Paint=function(_,w,h) UI:Paper(0,0,w,h,UI.Colors.red,255,8) end
    local heading=vgui.Create("DLabel",frame)
    heading:SetPos(24,20);heading:SetSize(frame:GetWide()-164,68)
    heading:SetFont("Trebuchet24");heading:SetTextColor(UI.Colors.red);heading:SetWrap(true)
    heading:SetText(here and "Summon a Hero to your square" or "Summon a Hero to a nearby square")
    local hint=vgui.Create("DLabel",frame)
    hint:SetPos(24,88);hint:SetSize(frame:GetWide()-48,50);hint:SetWrap(true)
    hint:SetTextColor(UI.Colors.ink);hint:SetText("Choose a Hero. Gameplay continues. One card is spent only if a safe landing is found.")
    local scroll=vgui.Create("DScrollPanel",frame)
    scroll:SetPos(24,144);scroll:SetSize(frame:GetWide()-48,frame:GetTall()-168)
    for _,choice in ipairs(choices) do
        local row=vgui.Create("DPanel",scroll);row:Dock(TOP);row:DockMargin(0,0,0,8);row:SetTall(76)
        row.Paint=function(_,w,h) UI:Paper(0,0,w,h,UI.Colors.red,255,2) end
        local button=vgui.Create("DButton",row);button:Dock(RIGHT);button:SetWide(84);button:SetText("Summon")
        local label=vgui.Create("DLabel",row);label:Dock(FILL);label:DockMargin(10,4,10,4)
        label:SetWrap(true);label:SetTextColor(UI.Colors.ink);label:SetText(choice.name);label:SetTooltip(choice.name)
        button.DoClick=function()
            if E.SummonFrame~=frame then return end
            net.Start("LOD_SummonCardChoose");net.WriteUInt(nonce,32);net.WriteEntity(choice.entity);net.SendToServer()
            E:CloseSummonCard(false)
        end
        button.Think=function(self) self:SetEnabled(IsValid(choice.entity) and choice.entity:Alive()) end
    end
    local expires=RealTime()+15
    frame.Think=function()
        if E.SummonFrame~=frame then return end
        if RealTime()>=expires or UI.ActivePage~="summon_card" or not E:IsActive(LocalPlayer())
            or LocalPlayer():GetNW2String("LOD_ThrowableItem","")~="summon_card" then E:CloseSummonCard(true) end
    end
end)
