LOD.Wallet={}
local W,UI,E=LOD.Wallet,LOD.UI,LOD.Equipment
local C=UI.Colors
local DRAG='LOD_DebbieEquipment'
local function wrappedHeight(value,width,font)
    surface.SetFont(font or 'LOD_SheetSmall')
    local lines=0
    for paragraph in (value..'\n'):gmatch('(.-)\n') do
        lines=lines+1;local line=''
        for word in paragraph:gmatch('%S+') do
            local nextLine=line=='' and word or line..' '..word
            if line~='' and surface.GetTextSize(nextLine)>width then lines=lines+1;line=word else line=nextLine end
        end
    end
    local _,height=surface.GetTextSize('Ag');return lines*height+8
end
local function dragging() return dragndrop and (dragndrop.IsDragging() or IsValid(dragndrop.m_DragWatch)) end
function W:SelectExchange(id,inPile)
    if self.ExchangePending then return false end
    local row=self.ExchangeItems and self.ExchangeItems[id]
    if not row or row.reason or (self.ExchangeAction=='sell_unequipped' and row.equipped) then return false end
    self.Pile=self.Pile or {}
    local count=0;for _ in pairs(self.Pile) do count=count+1 end
    local maximum=self.ExchangeAction=='sell_unequipped' and 256 or 8
    if inPile and not self.Pile[id] and count>=maximum then self.ExchangeMessage='Maximum '..maximum..' items per exchange.';self.RenderPending=true;return false end
    self.Pile[id]=inPile or nil;self.ExchangeMessage=nil;self.RenderPending=true
    return true
end
function W:ReceiveExchange(panels,dropped,inPile)
    local p=panels and panels[1]
    if not IsValid(p) or p.LODWalletFrame~=self.Frame then return false end
    local row=self.ExchangeItems and self.ExchangeItems[p.LODExchangeId]
    if not row or row.reason or self.ExchangePending then return false end
    if dropped then return self:SelectExchange(row.id,inPile) end
    return true
end
function W:ConfirmExchange()
    local state=self.Snapshot
    if self.ExchangePending or not state or not state.atStatue or not state.ranked then return end
    local ids={}
    for id in pairs(self.Pile or {}) do
        local row=self.ExchangeItems[id]
        if not row or row.reason or (self.ExchangeAction=='sell_unequipped' and row.equipped) then self.ExchangeMessage='Inventory changed. Review your pile.';self.RenderPending=true;return end
        ids[#ids+1]=id
    end
    local action=self.ExchangeAction or 'sell_items'
    if #ids<1 or #ids>(action=='sell_unequipped' and 256 or 8) or (action=='fuse_items' or action=='fuse_tokens') and #ids<2 then return end
    table.sort(ids)
    self.ExchangeSerial=((self.ExchangeSerial or 0)%65535)+1
    self.ExchangePending={request=self.ExchangeSerial,at=RealTime()}
    self.ExchangeMessage='Waiting for Debbie…';self.RenderPending=true
    net.Start('LOD_JunkExchange');net.WriteString(action);net.WriteUInt(#ids,9)
    for _,id in ipairs(ids) do net.WriteString(id) end
    net.WriteUInt(self.ExchangeSerial,16);net.SendToServer()
end
function W:BuildExchange(content,width,y)
    local state=self.Snapshot
    local tokens=self.Section=='token_exchange'
    local rows=state.equipment or state.junk or {}
    if tokens then
        rows={}
        for _,token in ipairs(state.tokens or {}) do rows[#rows+1]={id=token.id,name=E:ItemName(token.item),value=token.value,description=E:Description(token.item)} end
    end
    local sourceScroll=IsValid(self.SourceScroll) and self.SourceScroll:GetVBar():GetScroll() or self.SourceScrollPosition or 0
    local pileScroll=IsValid(self.PileScroll) and self.PileScroll:GetVBar():GetScroll() or self.PileScrollPosition or 0
    self.Pile=self.Pile or {};self.ExchangeItems={}
    for _,row in ipairs(rows) do self.ExchangeItems[row.id]=row end
    for id in pairs(self.Pile) do
        if not self.ExchangeItems[id] or self.ExchangeItems[id].reason then self.Pile[id]=nil end
    end
    local function text(parent,value,x,top,w,h,font)
        local p=vgui.Create('DLabel',parent);p:SetPos(x,top);p:SetSize(w,h);p:SetText(value)
        p:SetFont(font or 'LOD_SheetSmall');p:SetTextColor(C.ink);p:SetWrap(true);return p
    end
    local selling=self.ExchangeAction=='sell_items' or self.ExchangeAction=='sell_tokens' or self.ExchangeAction=='sell_unequipped'
    text(content,(selling and 'SELL ' or 'FUSE ')..(tokens and 'DFTs' or 'EQUIPMENT'),0,y,width,30,'LOD_SheetSubheading');y=y+34
    text(content,tokens and 'Drag tokens into the pile. Fusion returns one upgraded DFT; it inherits any recreation already used this run.' or 'Drag gear into the pile. Equipped gear changes only on success. DFT-created equipment is ineligible.',0,y,width,44,'DermaDefault');y=y+48
    if selling and not tokens then
        local all=vgui.Create('DButton',content);all:SetPos(0,y);all:SetSize(width,34)
        all:SetText('SELL ALL UNEQUIPPED — REVIEW PILE')
        all:SetEnabled(not self.ExchangePending)
        UI:Button(all,C.blue)
        all.DoClick=function()
            self.ExchangeAction='sell_unequipped';self.Pile={}
            for _,row in ipairs(rows) do
                if not row.equipped and not row.reason then self.Pile[row.id]=true end
            end
            self.ExchangeMessage='Review these items and total, then confirm. Equipped and protected gear are excluded.'
            self.RenderPending=true
        end
        y=y+42
    end
    local maximum=self.ExchangeAction=='sell_unequipped' and 256 or 8
    local half=math.floor((width-16)/2)
    local panelHeight=math.min(260,math.max(120,self.Frame:GetTall()-140-y-210))
    local source,pile=vgui.Create('DPanel',content),vgui.Create('DPanel',content)
    self.SourcePanel,self.PilePanel=source,pile
    source:SetPos(0,y);source:SetSize(half,panelHeight);pile:SetPos(half+16,y);pile:SetSize(half,panelHeight)
    local function paint(panel,inPile)
        panel.Paint=function(_,w,h)
            UI:Paper(0,0,w,h,inPile and C.gold or C.blue)
            draw.SimpleText(inPile and (selling and 'SALE PILE' or 'FUSION PILE') or (tokens and 'YOUR DFTs' or 'YOUR EQUIPMENT'),'LOD_SheetKey',10,10,C.ink)
        end
        panel:Receiver(DRAG,function(_,panels,dropped) return self:ReceiveExchange(panels,dropped,inPile) end)
    end
    paint(source,false);paint(pile,true)
    local function list(parent,inPile)
        local scroll=vgui.Create('DScrollPanel',parent);scroll:SetPos(8,38);scroll:SetSize(half-16,panelHeight-46)
        if inPile then self.PileScroll=scroll else self.SourceScroll=scroll end
        scroll:Receiver(DRAG,function(_,panels,dropped) return self:ReceiveExchange(panels,dropped,inPile) end)
        local canvas=scroll:GetCanvas();local rowY=0
        canvas:Receiver(DRAG,function(_,panels,dropped) return self:ReceiveExchange(panels,dropped,inPile) end)
        for _,row in ipairs(rows) do
            if (self.Pile[row.id]==true)==inPile then
                local b=vgui.Create('DButton',canvas);b:SetPos(0,rowY)
                local suffix=row.reason or ((row.equipped and 'EQUIPPED · ' or '')..row.value..' $DEB value'..((row.count or 1)>1 and (' · ×'..row.count) or ''))
                b:SetText('');b:SetTooltip(row.name..'\n'..suffix..'\n'..(row.description or ''))
                UI:Button(b,row.reason and C.rule or C.blue)
                local caption=row.name..'\n'..suffix
                local height=math.max(76,wrappedHeight(caption,half-52,'DermaDefault'))
                b:SetSize(half-36,height+8);b:SetDoubleClickingEnabled(false)
                local name=text(b,caption,8,4,half-52,height,'DermaDefault')
                name:SetMouseInputEnabled(false)
                b.LODExchangeId=row.id;b.LODWalletFrame=self.Frame
                b:Receiver(DRAG,function(_,panels,dropped) return self:ReceiveExchange(panels,dropped,inPile) end)
                if not row.reason then b:Droppable(DRAG) end
                b:SetEnabled(not self.ExchangePending and not row.reason)
                b.DoClick=function() self:SelectExchange(row.id,not inPile) end
                rowY=rowY+height+14
            end
        end
        if rowY==0 then text(canvas,inPile and 'DROP ITEMS HERE' or 'No more carried equipment.',8,12,half-40,80) end
        scroll:InvalidateLayout(true)
        scroll:GetVBar():SetScroll(inPile and pileScroll or sourceScroll)
    end
    list(source,false);list(pile,true);y=y+panelHeight+10
    local count,value=0,0
    for id in pairs(self.Pile) do count=count+1;value=value+self.ExchangeItems[id].value end

    text(content,selling and string.format('%d items · Receive %g $DEB',count,value)
        or string.format('%d / 8 items · New gear: %g–%g Value (85–100%%)',count,math.ceil(value*.85),value),0,y,width,32,'LOD_SheetSubheading');y=y+36
    text(content,tokens and 'Confirm consumes these tokens. Fusion returns one DFT with upgraded equipment; it does not reset a used recreation.' or (self.ExchangeAction=='sell_unequipped' and 'Confirm sells only the reviewed unequipped items. Equipped and protected gear cannot be sold here.' or selling and 'Confirm sells the reviewed pile, including any equipped items you selected.' or 'Confirm consumes the pile and returns one upgraded item to inventory.'),0,y,width,38,'DermaDefault');y=y+42
    local confirm=vgui.Create('DButton',content);confirm:SetPos(0,y);confirm:SetSize(width,38)
    confirm:SetText(selling and ('CONFIRM SALE — '..value..' $DEB') or (tokens and 'CONFIRM FUSION — RECEIVE UPGRADED DFT' or 'CONFIRM FUSION — RECEIVE NEW EQUIPMENT'))
    confirm:SetEnabled(not self.ExchangePending and state.atStatue and state.ranked and count>=(selling and 1 or 2) and count<=maximum)
    UI:Button(confirm,C.red);confirm.DoClick=function() self:ConfirmExchange() end;self.ConfirmButton=confirm;y=y+46
    local message=self.ExchangeMessage or (not state.ranked and 'Unranked run: persistent equipment exchanges are disabled.' or state.atStatue and 'Your wallet and inventory change only after Debbie accepts the exchange.' or 'Visit Debbie in staging to confirm an exchange.')
    local messageHeight=wrappedHeight(message,width)
    text(content,message,0,y,width,messageHeight)
    return y+messageHeight+10
end
function W:Request(action,id)
    net.Start('LOD_WalletRequest');net.WriteString(action);net.WriteString(id or '');net.SendToServer()
end
function W:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil;self.Pile={};self.RenderPending=nil;self.SourceScrollPosition=0;self.PileScrollPosition=0
    if UI.ActivePage=='wallet' then UI.ActivePage=nil end
end
function W:Render()
    local frame=self.Frame
    if not IsValid(frame) then return end
    if dragging() then self.RenderPending=true;return end
    self.RenderPending=nil
    local scrollPosition=IsValid(self.Scroll) and self.Scroll:GetVBar():GetScroll() or 0
    if IsValid(self.SourceScroll) then self.SourceScrollPosition=self.SourceScroll:GetVBar():GetScroll() end
    if IsValid(self.PileScroll) then self.PileScrollPosition=self.PileScroll:GetVBar():GetScroll() end
    if IsValid(self.Scroll) then self.Scroll:Remove() end
    local scroll=vgui.Create('DScrollPanel',frame);self.Scroll=scroll
    scroll:SetPos(24,116);scroll:SetSize(frame:GetWide()-48,frame:GetTall()-140)
    local content=vgui.Create('DPanel',scroll);content:Dock(TOP);content.Paint=function() end
    local width=frame:GetWide()-80;local y=0
    local function label(text,font)
        font=font or 'LOD_SheetSmall'
        surface.SetFont(font)
        local lines,line=1,''
        for word in text:gmatch('%S+') do
            local candidate=line=='' and word or line..' '..word
            if surface.GetTextSize(candidate)>width then lines=lines+1;line=word else line=candidate end
        end
        local _,h=surface.GetTextSize('Ag')
        local l=vgui.Create('DLabel',content);l:SetPos(0,y);l:SetSize(width,lines*h+4)
        l:SetFont(font);l:SetTextColor(C.ink);l:SetWrap(true);l:SetText(text)
        y=y+lines*h+12
    end
    local state=self.Snapshot
    if not state then label('Loading your wallet…')
    elseif state.error then label(state.error)
    else
        label(string.format('%g $DEB   |   Lifetime score: %g',state.balance,state.score),'LOD_SheetHeading')
        local servicesY=y;local wide=width>=700
        for i,entry in ipairs({{'equipment','fuse_items','Fuse Equipment'}, {'equipment','sell_items','Sell Equipment'},
            {'token_exchange','fuse_tokens','Fuse DFTs'}, {'token_exchange','sell_tokens','Sell DFTs'}, {'tokens',nil,'DFT Collection / Recreate'}}) do
            local page,action,title=entry[1],entry[2],entry[3]
            local button=vgui.Create('DButton',content)
            button:SetPos(wide and ((i-1)%2)*(width+12)/2 or 0,servicesY+(wide and math.floor((i-1)/2) or i-1)*46)
            button:SetSize(wide and (width-12)/2 or width,38);button:SetText(title)
            button:SetEnabled(not self.ExchangePending)
            UI:Button(button,self.ExchangeAction==action and self.Section==page and C.red or C.blue)
            button.DoClick=function()
                self.Section=page;self.ExchangeAction=action;self.Pile={};self.ExchangeMessage=nil
                self.Scroll:GetVBar():SetScroll(0);self:Render()
            end
        end
        y=servicesY+(wide and 3 or 5)*46
        if self.Section~='tokens' then
            y=self:BuildExchange(content,width,y)
        else
        label('Debbie Fund Tokens preserve equipment between runs. Each token can recreate its exact item once per run; the token remains yours.')
        label(state.ranked and ('Dungeon rescue pool: '..state.pool..' $DEB. Pending mercenary claim: '..state.pendingSoldier..' $DEB.')
            or 'Unranked run: persistent earnings, token sales and recreations are disabled.')
        label(state.atStatue and 'At the Debbie statue: recreate and equip a frozen item, or sell a token permanently.'
            or 'Visit the Debbie statue in staging to recreate or sell. Press your Use key there to refresh this wallet.')
        local milestones={}
        for _,level in ipairs({1,5,10,20}) do
            local key=tostring(level)
            local status=state.pending[key] and 'pending — collection full' or state.milestones[key] and 'earned' or 'not yet earned'
            milestones[#milestones+1]='Level '..level..': '..status
        end
        label(table.concat(milestones,'   |   '))
        for i=1,8 do
            local token=state.tokens[i]
            if token then
                label('SLOT '..i..' — '..E:ItemName(token.item),'LOD_SheetSubheading')
                label(E:Description(token.item))
                label(token.reason..' · Dungeon '..token.depth..' · '..token.run..' · Sale value '..token.value..' $DEB')
                local _,displaced=E:Placement(E.Snapshot or {items={},slots={}},token.item)
                local names={}
                for _,id in ipairs(displaced or {}) do names[#names+1]=E:ItemName(E.Snapshot.items[id]) end
                if #names>0 then label('Recreating equips this item and replaces: '..table.concat(names,', ')) end
                local create=vgui.Create('DButton',content);create:SetPos(0,y);create:SetSize(math.min(260,width*.52),30)
                create:SetText(token.available and 'RECREATE & EQUIP — FREE' or 'ALREADY RECREATED THIS RUN')
                create:SetEnabled(state.atStatue and state.ranked and token.available);UI:Button(create,C.blue)
                create.DoClick=function() create:SetEnabled(false);W:Request('recreate',token.id) end
                local sell=vgui.Create('DButton',content);sell:SetPos(math.min(270,width*.54),y);sell:SetSize(math.min(200,width*.44),30)
                sell:SetText('SELL FOR '..token.value..' $DEB');sell:SetEnabled(state.atStatue and state.ranked);UI:Button(sell,C.red)
                sell.DoClick=function()
                    Derma_Query('Permanently sell '..E:ItemName(token.item)..' for '..token.value..' $DEB?','Sell Debbie Fund Token',
                        'Sell',function() sell:SetEnabled(false);W:Request('sell',token.id) end,'Keep token')
                end
                y=y+46
            else label('SLOT '..i..' — EMPTY') end
        end
        end
        label('RECENT TRANSACTIONS','LOD_SheetSubheading')
        for _,row in ipairs(state.history or {}) do
            local b=row.body
            label(row.kind..(b.amount and (' · '..b.amount..' $DEB') or '')..(b.name and (' · '..b.name) or '')
                ..(b.level and (' · Combat Level '..b.level) or ''))
        end
    end
    content:SetTall(y+16)
    scroll:InvalidateLayout(true)
    scroll:GetVBar():SetScroll(scrollPosition)
end
function W:Open()
    self.Section=self.Section or 'equipment';self.ExchangeAction=self.ExchangeAction or 'sell_items'
    self:Close();UI:SelectPage('wallet')
    local frame=vgui.Create('DFrame');self.Frame=frame
    frame:SetTitle('');frame:SetSize(math.min(ScrW()-32,1040),math.min(ScrH()-32,740));frame:Center();frame:MakePopup()
    UI:CloseButton(frame,function() W:Close() end)
    frame.Paint=function(_,w,h) UI:Paper(0,0,w,h,C.gold);draw.SimpleText('WALLET','LOD_SheetHeading',24,20,C.gold) end
    UI:PageLinks(frame,'wallet',76)
    frame.Think=function()
        if W.ExchangePending and RealTime()-W.ExchangePending.at>8 then
            W.ExchangePending=nil;W.ExchangeMessage='Response delayed. Review the refreshed inventory before trying again.'
            W:Request('snapshot');W.RenderPending=true
        end
        if W.RenderPending and not dragging() then W:Render() end
    end
    self:Render();self:Request('snapshot')
end
net.Receive('LOD_WalletSnapshot',function()
    local state=net.ReadTable()
    if not istable(state) then return end
    W.Snapshot=state
    if UI.ActivePage=='wallet' and IsValid(W.Frame) then W:Render() end
end)
net.Receive('LOD_WalletOpen',function() W.Section='equipment';W.ExchangeAction='sell_items';W:Open() end)
net.Receive('LOD_JunkResult',function()
    local result=net.ReadTable()
    if not istable(result) or not W.ExchangePending or result.request~=W.ExchangePending.request then return end
    W.ExchangePending=nil;W.ExchangeMessage=result.message
    if result.ok then W.Pile={};LOD.Audio:Play('confirm') end
    W.RenderPending=true
end)

net.Receive("LOD_Stakeholders",function() LOD.Stakeholders=net.ReadTable() end)
