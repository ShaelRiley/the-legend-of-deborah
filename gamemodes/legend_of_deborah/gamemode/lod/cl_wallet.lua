LOD.Wallet={}
local W,UI,E=LOD.Wallet,LOD.UI,LOD.Equipment
local C=UI.Colors
function W:Request(action,id)
    net.Start('LOD_WalletRequest');net.WriteString(action);net.WriteString(id or '');net.SendToServer()
end
function W:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil
    if UI.ActivePage=='wallet' then UI.ActivePage=nil end
end
function W:Render()
    local frame=self.Frame
    if not IsValid(frame) then return end
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
        label('RECENT TRANSACTIONS','LOD_SheetSubheading')
        for _,row in ipairs(state.history or {}) do
            local b=row.body
            label(row.kind..(b.amount and (' · '..b.amount..' $DEB') or '')..(b.name and (' · '..b.name) or '')
                ..(b.level and (' · Combat Level '..b.level) or ''))
        end
    end
    content:SetTall(y+16)
end
function W:Open()
    self:Close();UI:SelectPage('wallet')
    local frame=vgui.Create('DFrame');self.Frame=frame
    frame:SetTitle('');frame:SetSize(math.min(ScrW()-32,1040),math.min(ScrH()-32,740));frame:Center();frame:MakePopup()
    UI:CloseButton(frame,function() W:Close() end)
    frame.Paint=function(_,w,h) UI:Paper(0,0,w,h,C.gold);draw.SimpleText('WALLET','LOD_SheetHeading',24,20,C.gold) end
    UI:PageLinks(frame,'wallet',76)
    self:Render();self:Request('snapshot')
end
net.Receive('LOD_WalletSnapshot',function()
    local state=net.ReadTable()
    if not istable(state) then return end
    W.Snapshot=state
    if UI.ActivePage=='wallet' and IsValid(W.Frame) then W:Render() end
end)
net.Receive('LOD_WalletOpen',function() W:Open() end)
