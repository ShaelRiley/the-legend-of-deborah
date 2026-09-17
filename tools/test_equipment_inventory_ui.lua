-- Actual inventory/equipment authorities with only VGUI/net/input boundaries doubled.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local E=LOD.Equipment;local root='gamemodes/legend_of_deborah/gamemode/lod/'
KEY_O=25;CreateClientConVar=function() return {GetInt=function() return KEY_O end} end
local now=10;RealTime=function() return now end
unpack=table.unpack
local nodes,receivers,requests={}, {}, {}
local panel={};panel.__index=panel
local create
function panel:SetPos(x,y) self.x=x;self.y=y end
function panel:GetX() return self.x or 0 end;function panel:GetY() return self.y or 0 end
function panel:SetSize(w,h) self.w=w;self.h=h end
function panel:GetWide() return self.w end;function panel:GetTall() return self.h end
function panel:SetText(t) self.text=t end
function panel:SetTooltip(t) self.tooltip=t end
function panel:SetContentAlignment() return self end
function panel:Droppable(name) self.drag=name end
function panel:SetDoubleClickingEnabled(v) self.doubleClick=v end
function panel:OnMousePressed() dragndrop.m_DragWatch=self end
function panel:Receiver(name,fn) self.receiver=fn end
function panel:GetCanvas() if not self.canvas then self.canvas=create('DPanel',self) end return self.canvas end
function panel:GetVBar()
    if not self.bar then self.bar={scroll=0,GetScroll=function(b) return b.scroll end,SetScroll=function(b,v) b.scroll=v end} end
    return self.bar
end
function panel:Clear() for _,p in ipairs(self.children) do p:Remove() end;self.children={} end
function panel:Remove() self:Clear();self.valid=false end
for _,name in ipairs({'SetFont','SetTextColor','SetWrap','SetEnabled'}) do panel[name]=function() end end
create=function(kind,parent)
    local p=setmetatable({valid=true,kind=kind,parent=parent,children={},x=0,y=0,w=100,h=100},panel)
    nodes[#nodes+1]=p;if parent then parent.children[#parent.children+1]=p end;return p
end
vgui={Create=create}
LOD.UI={Colors={ink={},blue={},red={},green={},rule={},peach={},light={}},Button=function() end}
surface={SetFont=function() end,GetTextSize=function(s) return #s*7,14 end}
local drawing=false;dragndrop={IsDragging=function() return drawing end}
net.Receive=function(n,f) receivers[n]=f end
local pending
net.Start=function(n) pending={name=n} end
net.WriteString=function(s) pending[#pending+1]=s end
net.SendToServer=function() requests[#requests+1]=pending end
local ply=fixture.actor('ui-owner');LocalPlayer=function() return ply end
local closed=0;LOD.Spellbook={Close=function() error("Equipment must not close the Spellbook") end}
input={SelectWeapon=function(w) ply.selected=w end}
dofile(root..'cl_equipment.lua');dofile(root..'cl_equipment_icons.lua');dofile(root..'cl_equipment_inventory.lua')
local realClose=E.Close;E.Close=function() closed=closed+1 end
local state={items={},slots={},activeWeaponClass='weapon_pistol'}
for i,family in ipairs({'headwear','vest','trousers','boots','ring','ring','gloves','shield','weapon_pistol','weapon_smg1'}) do
    local item=E:Generate(100+i,5,family,'i'..i);item.id='i'..i;state.items[item.id]=item
end
E:AddConsumable(state,'healing_potion',3);E:AddConsumable(state,'stink_bomb',2)
E:Equip(state,'i5','left_hand');E:Equip(state,'i9','weapon_pistol');E:Equip(state,'i10','weapon_smg1')
E.Snapshot=table.Copy(state);E.HasSnapshot=true
local frame=create('DFrame');frame:SetSize(608,448);LOD.Spellbook.Frame=frame
E:BuildPanel(frame);local view=E.InventoryView
assert(#view.SlotTiles==9)
for _,p in ipairs(view.SlotTiles) do assert(p:GetX()>=0 and p:GetX()+p.w<=view.LeftWidth) end
assert(view.DetailScroll:GetTall()>0 and view.BagScroll:GetTall()>0)
local function bag(id)
    for _,p in ipairs(view.Bag.children) do if p.LODItemId==id and IsValid(p) then return p end end
end
local function slot(name) for _,p in ipairs(view.SlotTiles) do if p.LODOriginSlot==name then return p end end end
assert(bag('healing_potion') and bag('stink_bomb') and not bag('i9') and bag('i10'))
assert(bag('healing_potion').tooltip:find('Healing',1,true))
-- Hover is cosmetic; wrong slots and foreign drag panels send nothing.
local count=#requests
slot('head').receiver(nil,{bag('i1')},false);assert(#requests==count)
assert(not slot('feet').receiver(nil,{bag('i1')},true) and #requests==count)
assert(not E:InventoryReceive('head',{{valid=true,LODItemId='i1'}},true))
assert(slot('head').receiver(nil,{bag('i1')},true))
assert(requests[#requests][1]=='equip' and requests[#requests][2]=='i1' and requests[#requests][3]=='head')
assert(not E.Snapshot.slots.head,'Do not optimistically equip')
-- Simulate authoritative equip and transport without closing/reopening window.
assert(E:Equip(state,'i1','head'))
net.ReadTable=function() return table.Copy(state) end
receivers.LOD_EquipmentSnapshot();assert(E.InventoryView==view and closed==0)
assert(slot('head').LODItemId=='i1')
view.BagScroll:GetVBar():SetScroll(80);view.DetailScroll:GetVBar():SetScroll(40)
-- Defer render refresh while dragging, retain actual updated authoritative state.
drawing=true;local oldTile=slot('head')
E:Equip(state,'i7','left_hand');receivers.LOD_EquipmentSnapshot()
assert(slot('head')==oldTile and E.Snapshot.slots.right_hand=='i7')
drawing=false;view.Think();assert(slot('right_hand').LODItemId=='i7' and slot('left_hand').LODItemId=='i7')
assert(view.BagScroll:GetVBar():GetScroll()==80 and view.DetailScroll:GetVBar():GetScroll()==40)
-- Native DLabel arms a drag-watch before crossing the 20-pixel threshold.
local pressed=slot('head');assert(pressed.doubleClick==false)
pressed:OnMousePressed(1)
local previous=E.Snapshot;E.Snapshot=table.Copy(previous)
E:RefreshInventory();assert(IsValid(pressed) and slot('head')==pressed,'Mouse-down tile survives incoming snapshot')
dragndrop.m_DragWatch=nil;view.Think()
-- Paired glove removal and ring displacement use canonical shared occupancy.
now=now+1;assert(E:InventoryMove('i7','inventory','right_hand'))
assert(requests[#requests][1]=='unequip' and requests[#requests][2]=='i7')
assert(E:Unequip(state,'right_hand') and not state.slots.left_hand and not state.slots.right_hand)
assert(E:Equip(state,'i5','left_hand') and E:Equip(state,'i6','right_hand'))
assert(E:Equip(state,'i7','right_hand') and state.items.i5 and state.items.i6)
assert(E:Equip(state,'i5','left_hand') and not state.slots.right_hand and state.items.i7)
-- Native gun selection is separate from wearing clothing; no gun ownership loss.
ply:Give('weapon_smg1');now=now+1
assert(E:InventoryMove('i10','weapon') and requests[#requests][1]=='select_weapon' and closed==0)
now=now+1;assert(E:InventoryMove('i9','inventory','weapon'))
assert(requests[#requests][1]=='stow_weapon')
now=now+1;assert(not E:InventoryMove('i10','inventory','weapon'))
local empty=0;for _,p in ipairs(view.Bag.children) do if p.kind=='DButton' and not p.LODItemId then empty=empty+1 end end
assert(empty>=2,'Visible empty inventory destinations remain available')
-- Every potion fits only Throwable. Keyboard/click fallback uses same request.
now=now+1;assert(E:InventoryMove('stink_bomb','throwable'))
assert(not E:InventoryCompatible('stink_bomb','weapon') and not E:InventoryCompatible('healing_potion','body'))
assert(E:InventoryCompatible('i5','right_hand') and E:InventoryCompatible('i7','left_hand'))
-- A late item removal invalidates the stale tile instead of equipping it.
local stale=bag('i8');state.items.i8=nil;receivers.LOD_EquipmentSnapshot();now=now+1
assert(not E:InventoryReceive('left_arm',{stale},true))
-- Select then click an occupied destination sends requested hand, keeps record IDs.
E.InventorySelectedId='i6';now=now+1;slot('left_hand').DoClick(slot('left_hand'))
assert(requests[#requests][2]=='i6' and requests[#requests][3]=='left_hand')
-- Large viewport and all family icons are covered without 3D icon entities.
frame:SetSize(1120,740);view:Remove();E:BuildPanel(frame)
assert(E.InventoryView.RightWidth>E.InventoryView.LeftWidth)
local drawCalls=0
surface.SetDrawColor=function() end;surface.DrawPoly=function(points) assert(#points>=3);drawCalls=drawCalls+1 end
surface.DrawCircle=function() end;surface.DrawRect=function() end
draw={NoTexture=function() end,SimpleText=function() end}
for _,item in pairs(state.items) do E:DrawItemIcon(item,0,0,56,{r=0,g=0,b=0,a=255}) end
assert(drawCalls>=11)
print('EQUIPMENT_INVENTORY_UI_PASS: body/grid layout, owned icons/stacks, correct/invalid/stale drops, paired hands, native weapon selection, server-only mutation, retained/deferred snapshot UI and scroll')

-- Real sibling-page lifecycle: no Spellbook snapshot dependency or delayed focus theft.
E.Close=realClose;LOD.Spellbook=nil
for _,name in ipairs({'SetTitle','Center','MakePopup','ShowCloseButton'}) do panel[name]=function() end end
surface.CreateFont=function() end
ScrW=function() return 640 end;ScrH=function() return 480 end
LOD.UI.Colors={};dofile(root..'cl_ui_theme.lua')
gui={IsConsoleVisible=function() return false end};chat={IsTyping=function() return false end}
dofile(root..'cl_spellbook.lua')
LOD.Spellbook:Open();assert(LOD.Spellbook.PendingOpen)
E:Open();assert(LOD.UI.ActivePage=='equipment' and E.Frame and not LOD.Spellbook.PendingOpen)
local ownedFrame=E.Frame
net.ReadTable=function() return {forms={},contents={}} end
receivers.LOD_MagicSpellbookSnapshot()
assert(E.Frame==ownedFrame and LOD.UI.ActivePage=='equipment' and not IsValid(LOD.Spellbook.Frame))
local equipmentTab
for _,p in ipairs(ownedFrame.children) do if p.text=='EQUIPMENT' then equipmentTab=p end end
assert(equipmentTab,'Equipment has its own first-class tab')
LOD.Spellbook:Open();assert(ownedFrame.valid==false and not E.Frame and LOD.UI.ActivePage=='book')
net.ReadTable=function() return table.Copy(state) end
receivers.LOD_EquipmentSnapshot();assert(not E.Frame and LOD.UI.ActivePage=='book')
E:Open();assert(not IsValid(LOD.Spellbook.Frame) and LOD.UI.ActivePage=='equipment')
E:Close();receivers.LOD_EquipmentSnapshot();assert(not E.Frame and not LOD.UI.ActivePage)
print('EQUIPMENT_PAGE_PASS: independent frame, direct sibling tab, pending request cancellation, late snapshot isolation')
