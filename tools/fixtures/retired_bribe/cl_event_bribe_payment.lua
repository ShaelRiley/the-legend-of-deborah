-- A review is a quote from the server. The client sends item IDs, never prices.
local frame
local function decide(id,action,ids)
    net.Start('LOD_BribeDecision');net.WriteUInt(id,32);net.WriteUInt(action,2)
    if action==2 then
        net.WriteUInt(#ids,4)
        for _,itemId in ipairs(ids) do net.WriteString(itemId) end
    end
    net.SendToServer()
end
net.Receive('LOD_BribeReview',function()
    local review=net.ReadTable()
    if type(review)~='table' or type(review.items)~='table' or type(review.id)~='number' then return end
    if IsValid(frame) then frame.silent=true;frame:Close() end
    frame=vgui.Create('DFrame')
    local panel=frame
    panel:SetSize(math.min(660,ScrW()-40),math.min(550,ScrH()-40));panel:Center()
    panel:SetTitle('BRIBE BLOCKADE — '..review.price..' $DEB in item value');panel:MakePopup()
    function panel:OnClose() if not self.silent then decide(review.id,0) end end
    local intro=vgui.Create('DLabel',panel)
    intro:Dock(TOP);intro:SetTall(76);intro:DockMargin(10,4,10,8);intro:SetWrap(true)
    intro:SetText('Choose shared collateral or 1–8 of your unequipped wearables. Confirming permanently surrenders the entire selection; excess value gives no change. The passage opens for every Hero. Cancel spends nothing. Review expires in '..(review.seconds or 45)..' seconds.')
    local controls=vgui.Create('DPanel',panel);controls:Dock(BOTTOM);controls:SetTall(104)
    local total=vgui.Create('DLabel',controls);total:Dock(TOP);total:SetTall(26);total:SetText('Your selected item value: 0 / '..review.price..' $DEB')
    local collateral=vgui.Create('DButton',controls);collateral:Dock(TOP);collateral:SetTall(30)
    collateral:SetText(review.collateral and ('SURRENDER SHARED COLLATERAL — '..review.collateral.name..' ('..review.collateral.value..' $DEB)')
        or 'Recover the nearby lost-property ring to use shared collateral')
    collateral:SetEnabled(review.collateral~=nil)
    function collateral:DoClick() panel.silent=true;decide(review.id,1);panel:Close() end
    local confirm=vgui.Create('DButton',controls);confirm:Dock(LEFT);confirm:SetWide(math.floor((panel:GetWide()-24)*.72));confirm:DockMargin(0,8,8,0)
    confirm:SetText('CONFIRM SELECTED PAYMENT');confirm:SetEnabled(false)
    local cancel=vgui.Create('DButton',controls);cancel:Dock(FILL);cancel:DockMargin(0,8,0,0);cancel:SetText('CANCEL')
    function cancel:DoClick() panel:Close() end
    local list=vgui.Create('DListView',panel);list:Dock(FILL);list:SetMultiSelect(true)
    list:AddColumn('Unequipped wearable');list:AddColumn('$DEB value'):SetFixedWidth(100)
    for _,item in ipairs(review.items) do
        local line=list:AddLine(item.name,item.value);line.bribeItem=item
    end
    local function selection()
        local ids,value={},0
        for _,line in ipairs(list:GetSelected()) do
            ids[#ids+1]=line.bribeItem.id;value=value+line.bribeItem.value
        end
        return ids,value
    end
    function list:Think()
        local ids,value=selection()
        total:SetText('Your selected item value: '..value..' / '..review.price..' $DEB  ('..#ids..'/8 items; Ctrl-click to select several)')
        confirm:SetEnabled(#ids>=1 and #ids<=8 and value>=review.price)
    end
    function confirm:DoClick()
        local ids,value=selection()
        if #ids<1 or #ids>8 or value<review.price then return end
        panel.silent=true;decide(review.id,2,ids);panel:Close()
    end
end)
