-- Small session shell: authority, answer selection and settlement stay server-side.
LOD.Minigame = LOD.Minigame or {LastSession=0,RetiredSession=0}
local M, UI = LOD.Minigame, LOD.UI
local C = UI.Colors
local phases={offer=1,playing=2,pending=3,result=4,close=5}
function M:IsLocked()
    return self.State and self.State.phase=='playing' or false
end
function M:CloseSensitivePanels()
    for _,name in ipairs({'Equipment','CharacterSheet','Wallet','Spellbook','FieldManual'}) do
        local page=LOD[name]
        if page and page.Close then page:Close() end
    end
    if LOD.CombatRollFeed and IsValid(LOD.CombatRollFeed.HistoryFrame) then
        LOD.CombatRollFeed.HistoryFrame:Remove()
    end
    -- Derma confirmation windows (discard/sell) can contain an item name and
    -- outlive their parent page. Retire existing popups before displaying cards.
    local world=vgui.GetWorldPanel()
    if IsValid(world) then
        for _,panel in ipairs(world:GetChildren()) do
            if panel~=self.Frame and panel.GetClassName and panel:GetClassName()=='DFrame' then panel:Remove() end
        end
    end
    UI.ActivePage=nil
end
function M:RemoveFrame()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil
end
function M:Retire()
    self.RetiredSession=math.max(self.RetiredSession or 0,self.State and self.State.session or 0)
    self.State=nil;self.Sent=false;self:RemoveFrame()
end
function M:Send(action,choice)
    local state=self.State
    if not state or self.Sent then return false end
    if action==1 and state.phase~='offer' or action==2 and state.phase~='playing'
        or action==3 and state.phase~='pending' then return false end
    self.Sent=true
    net.Start('LOD_MinigameAction')
    net.WriteUInt(state.session,32);net.WriteUInt(action,3)
    if action==2 then net.WriteUInt(choice,2) end
    net.SendToServer()
    -- Keep restrictions through the authoritative acknowledgement. Closing the
    -- window locally never unlocks inventory or enables a second answer.
    if IsValid(self.Frame) then
        for _,button in ipairs(self.Buttons or {}) do if IsValid(button) then button:SetEnabled(false) end end
    end
    return true
end
local function label(parent,text,font)
    local panel=vgui.Create('DLabel',parent)
    panel:SetText(text);panel:SetTextColor(C.ink);panel:SetFont(font or 'LOD_SheetBody')
    panel:SetWrap(true);panel:SetAutoStretchVertical(true)
    panel:Dock(TOP);panel:DockMargin(0,0,0,12)
    return panel
end
function M:Render()
    self:RemoveFrame();self.Buttons={}
    local state=self.State
    if not state then return end
    local frame=vgui.Create('DFrame');self.Frame=frame
    frame:SetTitle('');frame:SetSize(math.min(940,ScrW()-32),math.min(640,ScrH()-32))
    frame:Center();frame:MakePopup();frame:ShowCloseButton(false)
    frame.Paint=function(_,w,h) UI:Paper(0,0,w,h,C.blue,255,8) end
    frame:DockPadding(24,22,24,22)
    label(frame,state.title or 'GAME MASTER — EQUIPMENT QUIZ','LOD_SheetHeading')
    local timerLabel=label(frame,'','LOD_SheetSmall')
    timerLabel.Think=function(panel)
        local remaining=math.max(0,math.ceil((tonumber(state.expiresAt) or 0)-CurTime()))
        panel:SetText((state.phase=='offer' or state.phase=='playing') and ('Time remaining: '..remaining..' seconds. Gameplay continues.') or 'Gameplay continues.')
    end
    local footer=vgui.Create('DPanel',frame);footer:Dock(BOTTOM);footer:SetTall(44);footer.Paint=function() end
    local function button(text,action,choice,parent)
        local btn=vgui.Create('DButton',parent or footer)
        btn:SetText(text);UI:Button(btn,C.blue)
        btn.DoClick=function() M:Send(action,choice) end
        M.Buttons[#M.Buttons+1]=btn
        return btn
    end
    local close=button(state.phase=='playing' and 'FORFEIT / ESC' or state.phase=='offer' and 'DECLINE / ESC' or 'CLOSE / ESC',0)
    close:Dock(RIGHT);close:SetWide(160)
    close.DoClick=function()
        if state.phase=='result' then M:Retire() else M:Send(0) end
    end
    frame.OnKeyCodePressed=function(_,key) if key==KEY_ESCAPE then close:DoClick() end end
    local scroll=vgui.Create('DScrollPanel',frame);scroll:Dock(FILL)
    label(scroll,state.message or '')
    if state.phase=='offer' then
        label(scroll,'One accepted attempt this dungeon. Identify one of your worn items from three cards. Correct: one DFT. Wrong: the real item is stolen. Equipment and Player Menu pages close while you answer. Cancelling or timing out forfeits the attempt without theft.')
        local accept=button('ACCEPT THE RISK',1);accept:Dock(LEFT);accept:SetWide(220)
    elseif state.phase=='playing' then
        label(scroll,'Which item are you wearing? Select one answer.','LOD_SheetSubheading')
        for index,card in ipairs(state.cards or {}) do
            local row=vgui.Create('DPanel',scroll);row:Dock(TOP);row:DockMargin(0,0,0,12)
            row:SetTall(118);row:DockPadding(12,10,12,10)
            row.Paint=function(_,w,h) draw.RoundedBox(1,0,0,w,h,C.light) end
            local choose=button('CHOOSE '..index,2,index,row);choose:Dock(RIGHT);choose:SetWide(112);choose:DockMargin(12,0,0,0)
            local text=vgui.Create('DScrollPanel',row);text:Dock(FILL)
            label(text,tostring(card.name or ''),'LOD_SheetSubheading')
            label(text,tostring(card.slot or ''),'LOD_SheetSmall')
            label(text,tostring(card.description or ''),'LOD_SheetSmall')
        end
    elseif state.phase=='pending' then
        label(scroll,'No reward has been confirmed. Your answer is locked; retry only attempts the same reward settlement.')
        local retry=button('RETRY REWARD',3);retry:Dock(LEFT);retry:SetWide(220)
    elseif state.phase=='result' then
        -- Never infer a win from an answer, a pending receipt or a local timeout.
        label(scroll,state.success==true and 'DFT awarded.' or 'Challenge ended.','LOD_SheetSubheading')
    end
end
function M:Receive(state)
    if type(state)~='table' or not phases[state.phase] then return false end
    local session=tonumber(state.session)
    if not session or session%1~=0 or session<=0 or session<=(self.RetiredSession or 0)
        or session<(self.LastSession or 0) then return false end
    if self.State and session==self.State.session then
        local previous=phases[self.State.phase]
        if phases[state.phase]<previous or (phases[state.phase]==previous and state.phase~='pending') then return false end
    end
    self.LastSession=session;self.State=state;self.Sent=false
    if state.phase=='close' then self:Retire();return true end
    if self:IsLocked() then self:CloseSensitivePanels() end
    self:Render();return true
end
net.Receive('LOD_MinigameState',function() M:Receive(net.ReadTable()) end)
hook.Add('PreCleanupMap','LOD_MinigameCleanup',function() M:Retire() end)
hook.Add('ShutDown','LOD_MinigameShutdown',function() M:Retire() end)
