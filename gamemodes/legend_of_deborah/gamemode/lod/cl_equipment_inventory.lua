-- LOD-UI-008: body map and inventory tiles. Server snapshots own all mutations.
local E,UI=LOD.Equipment,LOD.UI
local C=UI.Colors
local DRAG='LOD_OwnedEquipment'
local positions={
    {'head','HEAD',1,0,'headwear'}, {'left_arm','SHIELD',0,1,'shield'},
    {'body','BODY',1,1,'vest'}, {'weapon','WEAPON',2,1,'gun'},
    {'left_hand','LEFT HAND',0,2,'gloves'}, {'legs','LEGS',1,2,'trousers'},
    {'right_hand','RIGHT HAND',2,2,'ring'}, {'feet','FEET',1,3,'boots'},
    {'throwable','THROWABLE',2,3,'bottle'}
}
E.BodyPositions=positions
local function dragging() return dragndrop and dragndrop.IsDragging() end
local function label(parent,text,x,y,w,h,font)
    local p=vgui.Create('DLabel',parent);p:SetPos(x,y);p:SetSize(w,h)
    p:SetFont(font or 'LOD_SheetSmall');p:SetTextColor(C.ink);p:SetText(text);p:SetWrap(true)
    return p
end
local function textHeight(text,width,font)
    surface.SetFont(font or 'LOD_SheetSmall')
    local lines=0
    for paragraph in (text..'\n'):gmatch('(.-)\n') do
        lines=lines+1;local line=''
        for word in paragraph:gmatch('%S+') do
            local candidate=line=='' and word or line..' '..word
            if line~='' and surface.GetTextSize(candidate)>width then lines=lines+1;line=word else line=candidate end
        end
    end
    local _,height=surface.GetTextSize('Ag');return lines*height+6
end
function E:InventorySlot(id)
    for _,slot in ipairs(self.SlotOrder) do if self.Snapshot.slots[slot]==id then return slot end end
end
function E:InventoryCompatible(id,slot)
    local item=self.Snapshot.items[id];local def=self:Definition(item)
    if not def then return false end
    if slot=='weapon' then return def.weapon==true end
    return self:Placement(self.Snapshot,item,slot)~=nil
end
function E:InventoryMessage(text)
    local view=self.InventoryView
    if IsValid(view) then view.Message:SetText(text) end
end
function E:InventoryMove(id,target,origin)
    local item=self.Snapshot.items[id];local def=self:Definition(item)
    if not def then self:InventoryMessage('That item is no longer available.');return false end
    if RealTime()<(self.InventoryNextAction or 0) then return false end
    if target=='inventory' then
        if not origin or self.Snapshot.slots[origin]~=id or def.weapon then
            self:InventoryMessage('Weapons stay owned; choose one in the weapon slot.');return false
        end
        self:Request('unequip',id,origin)
    elseif not self:InventoryCompatible(id,target) then
        self:InventoryMessage('That item does not fit this slot.');return false
    elseif target=='weapon' then
        local weapon=LocalPlayer():GetWeapon(def.weaponClass)
        if not IsValid(weapon) then self:InventoryMessage('Weapon unavailable.');return false end
        input.SelectWeapon(weapon);E:Close();return true
    else self:Request('equip',id,target) end
    self.InventoryNextAction=RealTime()+.12
    self:InventoryMessage('Equipment change requested.')
    return true
end
function E:InventoryReceive(target,panels,dropped)
    local tile=panels and panels[1]
    if not IsValid(tile) or not tile.LODItemId or tile.LODInventoryView~=self.InventoryView then return false end
    if not dropped and self.InventorySelectedId~=tile.LODItemId then
        self.InventorySelectedId=tile.LODItemId;self:InventoryDetails()
    end
    if dropped then return self:InventoryMove(tile.LODItemId,target,tile.LODOriginSlot) end
    return target=='inventory' or self:InventoryCompatible(tile.LODItemId,target)
end
local function tile(parent,id,slot,title,size)
    local p=vgui.Create('DButton',parent);p:SetSize(size,size);p:SetText('')
    p.LODItemId=id;p.LODOriginSlot=slot;p.LODInventoryView=E.InventoryView
    if id then
        p:Droppable(DRAG)
        local item=E.Snapshot.items[id]
        p:SetTooltip(E:ItemName(item)..'\n'..E:Description(item)..'\n'..(E:Definition(item).name or ''))
    end
    p.Paint=function(self,w,h)
        local item=E.Snapshot.items[self.LODItemId];local selected=E.InventorySelectedId==self.LODItemId and item
        draw.RoundedBox(2,0,0,w,h,selected and C.peach or C.light)
        local equipped=self.LODItemId and E:InventorySlot(self.LODItemId)
        local compatible=slot and E.InventorySelectedId and E:InventoryCompatible(E.InventorySelectedId,slot)
        surface.SetDrawColor(compatible and C.green or selected and C.red or equipped and C.blue or C.rule)
        surface.DrawOutlinedRect(0,0,w,h,selected and 3 or 1)
        if item then
            E:DrawItemIcon(item,6,4,math.min(w-12,h-17),C.blue)
            local def=E:Definition(item)
            local tag=def.throwable and ('x'..item.count) or (equipped and 'WORN' or '')
            if def.weapon then tag=E.Snapshot.activeWeaponClass==def.weaponClass and 'ACTIVE' or 'READY' end
            draw.SimpleText(tag,'DermaDefault',w*.5,h-14,C.ink,TEXT_ALIGN_CENTER)
        elseif self.LODIcon then E:DrawItemIcon(nil,8,6,math.min(w-16,h-12),C.rule,self.LODIcon) end
    end
    local press=p.OnMousePressed
    p.OnMousePressed=function(self,key)
        if self.LODItemId and (not slot or not E.InventorySelectedId or E.InventorySelectedId==self.LODItemId) then
            E.InventorySelectedId=self.LODItemId;E:InventoryDetails()
        end
        if press then return press(self,key) end
    end
    p.DoClick=function(self)
        if slot and E.InventorySelectedId and E.InventorySelectedId~=self.LODItemId then
            E:InventoryMove(E.InventorySelectedId,slot)
        elseif self.LODItemId then E.InventorySelectedId=self.LODItemId;E:InventoryDetails() end
    end
    p.DoRightClick=function(self)
        if slot and self.LODItemId then E:InventoryMove(self.LODItemId,'inventory',slot) end
    end
    p:Receiver(DRAG,function(_,panels,dropped) return E:InventoryReceive(slot or 'inventory',panels,dropped) end)
    return p
end
function E:InventoryDetails()
    local view=self.InventoryView;if not IsValid(view) then return end
    view.Details:Clear()
    local width=view.RightWidth-22;local y=0
    local function text(s,font)
        local height=textHeight(s,width,font)
        local p=label(view.Details,s,0,y,width,height,font);y=y+height+4;return p
    end
    local id=self.InventorySelectedId;local item=self.Snapshot.items[id]
    if not item then text('Select an item to inspect its properties. Drag it onto a body slot to equip.');return end
    local def=self:Definition(item);local slot=self:InventorySlot(id)
    text(self:ItemName(item),'LOD_SheetSubheading')
    text(self:Description(item))
    text(def.throwable and ('Quantity: '..item.count..' / '..def.maxStack) or ('Value: '..self:Value(item)))
    local names={};for _,s in ipairs(def.occupancy or def.slots) do names[#names+1]=self.SlotLabels[s] end
    text('Fits: '..table.concat(names,', ')..(def.occupancy and ' (both together)' or ''))
    local _,displaced=self:Placement(self.Snapshot,item)
    local old={};for _,other in ipairs(displaced or {}) do if other~=id then old[#old+1]=self:ItemName(self.Snapshot.items[other]) end end
    if #old>0 then text('Equipping replaces: '..table.concat(old,', ')..'. Displaced clothing remains in your inventory.') end
    local function button(title,action)
        local b=vgui.Create('DButton',view.Details);b:SetPos(0,y);b:SetSize(width,28);b:SetText(title);UI:Button(b,C.blue)
        b.DoClick=action;y=y+34
    end
    if def.weapon then button('SELECT WEAPON',function() E:InventoryMove(id,'weapon') end)
    else
        if slot then
            button('UNEQUIP',function() E:InventoryMove(id,'inventory',slot) end)
            if def.throwable then button('HOLD THROWABLE',function() E:Request('activate',id,'throwable');E:Close() end) end
        else button('EQUIP',function() E:InventoryMove(id,E:Placement(E.Snapshot,item)) end) end
        if item.definitionId=='ring' then
            button('EQUIP LEFT HAND',function() E:InventoryMove(id,'left_hand') end)
            button('EQUIP RIGHT HAND',function() E:InventoryMove(id,'right_hand') end)
        end
        if def.wearable and not slot then button('DISCARD',function()
            Derma_Query('Permanently discard '..E:ItemName(item)..'?','Discard equipment','Discard',function()
                E:Request('discard',id,'')
            end,'Keep')
        end) end
    end
end
function E:RefreshInventory()
    local view=self.InventoryView;if not IsValid(view) or dragging() then return end
    view.CurrentSnapshot=self.Snapshot
    for _,p in ipairs(view.SlotTiles or {}) do p:Remove() end
    view.SlotTiles={}
    local bagScroll=view.BagScroll:GetVBar():GetScroll()
    local detailScroll=view.DetailScroll:GetVBar():GetScroll()
    view.Bag:Clear()
    local size=view.TileSize
    for _,position in ipairs(positions) do
        local slot,title,col,row,icon=unpack(position)
        local actual=slot=='weapon' and self.Snapshot.activeWeaponClass or slot
        local id=self.Snapshot.slots[actual]
        local p=tile(view.Body,id,slot,title,size);p.LODIcon=icon
        p:SetPos((col+.5)*view.LeftWidth/3-size/2,28+row*view.RowHeight)
        view.SlotTiles[#view.SlotTiles+1]=p
    end
    local ids={};for id,item in pairs(self.Snapshot.items) do if self:Definition(item) then ids[#ids+1]=id end end
    table.sort(ids,function(a,b)
        local da,db=self:Definition(self.Snapshot.items[a]),self:Definition(self.Snapshot.items[b])
        if da.name==db.name then return a<b end;return da.name<db.name
    end)
    local columns=math.max(2,math.floor((view.RightWidth-20)/72));local cell=(view.RightWidth-20)/columns
    for i,id in ipairs(ids) do
        local p=tile(view.Bag,id,nil,'',math.min(64,cell-6))
        p:SetPos(((i-1)%columns)*cell,math.floor((i-1)/columns)*98)
        local name=self:Definition(self.Snapshot.items[id]).name
        label(view.Bag,name,p:GetX(),p:GetY()+p:GetTall()+2,cell-6,30,'DermaDefault')
    end
    if #ids==0 then label(view.Bag,'No owned equipment.',4,4,view.RightWidth-24,40) end
    self:InventoryDetails()
    view.BagScroll:GetVBar():SetScroll(bagScroll)
    view.DetailScroll:GetVBar():SetScroll(detailScroll)
    local _,moves,block=self:Contributions(self.Snapshot)
    local summary=string.format('Block: %.0f%% / 33%% cap',block*100)
    for _,id in ipairs(self.MoveOrder) do if moves[id] then
        local m=self.SpecialMoves[id];summary=summary..'\n'..m.name..' '..m.glyphs..' | '..m.magicCost..' Magic | '..m.cooldown..'s\n'..m.description
    end end
    view.Summary:SetText(summary)
    local height=textHeight(summary,view.LeftWidth-18)
    view.Summary:SetSize(view.LeftWidth-18,height)
    if view.Bindings then view.Bindings:SetPos(0,view.Summary:GetY()+height+4) end
end
function E:BuildPanel(frame)
    local view=vgui.Create('DPanel',frame);self.InventoryView=view
    view:SetPos(24,88);view:SetSize(frame:GetWide()-48,frame:GetTall()-200);view.Paint=function() end
    local w,h=view:GetWide(),view:GetTall()
    view.LeftWidth=math.floor(w*.43);view.RightWidth=w-view.LeftWidth-18
    local left=vgui.Create('DScrollPanel',view);left:SetPos(0,0);left:SetSize(view.LeftWidth,h)
    view.Body=left:GetCanvas();view.Body.Paint=function(_,bw,bh)
        E:DrawItemIcon(nil,bw*.37,52,math.min(250,bh-50),C.rule,'body')
    end
    view.RowHeight=math.min(88,math.max(52,(h-30)/4))
    view.TileSize=math.min(64,view.LeftWidth/3-12,view.RowHeight-20)
    label(view.Body,'EQUIPPED',0,0,view.LeftWidth,24,'LOD_SheetSubheading')
    for _,p in ipairs(positions) do
        label(view.Body,p[2],p[3]*view.LeftWidth/3,28+p[4]*view.RowHeight+view.TileSize,
            view.LeftWidth/3,20,'DermaDefault'):SetContentAlignment(8)
    end
    local y=30+4*view.RowHeight
    view.Summary=label(view.Body,'',0,y,view.LeftWidth-18,24)
    if self.BuildMoveBindings then
        view.Bindings=vgui.Create('DPanel',view.Body);view.Bindings.Paint=function() end
        view.Bindings:SetSize(view.LeftWidth-18,self:BuildMoveBindings(view.Bindings,0,view.LeftWidth-18))
    end
    local rx=view.LeftWidth+18
    view.Message=label(view,'Drag to equip. Right-click a worn slot to unequip.',rx,0,view.RightWidth,36)
    local bag=vgui.Create('DScrollPanel',view);view.BagScroll=bag
    bag:SetPos(rx,40);bag:SetSize(view.RightWidth,math.max(86,math.floor(h*.48)-40))
    view.Bag=bag:GetCanvas()
    view.Bag:Receiver(DRAG,function(_,panels,dropped) return E:InventoryReceive('inventory',panels,dropped) end)
    bag:Receiver(DRAG,function(_,panels,dropped) return E:InventoryReceive('inventory',panels,dropped) end)
    local dy=40+bag:GetTall()+12
    local detail=vgui.Create('DScrollPanel',view);view.DetailScroll=detail;detail:SetPos(rx,dy);detail:SetSize(view.RightWidth,h-dy)
    view.Details=detail:GetCanvas()
    self:RefreshInventory()
    view.Think=function()
        if view.CurrentSnapshot~=E.Snapshot and not dragging() then E:RefreshInventory() end
    end
end

-- A sibling Player Menu page, with its own frame and equipment snapshot lifecycle.
function E:Close()
    if UI.ActivePage=='equipment' then UI.ActivePage=nil end
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil;self.InventoryView=nil
end
function E:Open()
    self:Close();UI:SelectPage('equipment')
    local frame=vgui.Create('DFrame');self.Frame=frame
    frame:SetTitle('');frame:SetSize(math.min(ScrW()-32,1120),math.min(ScrH()-32,740))
    frame:Center();frame:MakePopup()
    UI:CloseButton(frame,function() E:Close() end)
    frame.Paint=function(_,w,h)
        UI:Paper(0,0,w,h,C.red,255,8)
        draw.SimpleText('EQUIPMENT','LOD_SheetHeading',24,20,C.red)
    end
    self:BuildPanel(frame)
    UI:PageLinks(frame,'equipment',frame:GetTall()-96)
    label(frame,'Drag onto a body slot, or select an item and click its slot.',24,frame:GetTall()-64,frame:GetWide()-48,36)
    label(frame,'Select an equipped potion → HOLD THROWABLE. Gameplay continues.',24,frame:GetTall()-34,frame:GetWide()-48,30,'DermaDefault')
    self:Request('snapshot')
end
concommand.Add('lod_equipment',function() E:Open() end)
hook.Add('ShutDown','LOD_EquipmentPageClose',function() E:Close() end)
