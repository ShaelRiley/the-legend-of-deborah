-- Real Wallet renderer/navigation, minimal VGUI/network boundary.
LOD={};TOP=1
istable=function(x) return type(x)=="table" end
Color=function(...) return {...} end
RealTime=function() return 1 end
IsValid=function(x) return type(x)=='table' and not x.removed end
ScrW=function() return 640 end;ScrH=function() return 480 end
local nodes,handlers,sent={}, {}, {}
local panel={}
function panel:GetCanvas() return self end
function panel:GetVBar()
    self.bar=self.bar or {value=0,GetScroll=function(b) return b.value end,SetScroll=function(b,v) b.value=v end}
    return self.bar
end
function panel:Receiver(_,fn) self.receiver=fn end
function panel:Droppable(name) self.drag=name end
function panel:SetTooltip(value) self.tooltip=value end
function panel:SetSize(w,h) self.w=w;self.h=h end
function panel:SetPos(x,y) self.x=x;self.y=y end
function panel:GetWide() return self.w end
function panel:GetTall() return self.h end
function panel:SetTall(h) self.h=h end
function panel:SetText(t) self.text=t end
function panel:SetEnabled(x) self.enabled=x end
function panel:Remove() self.removed=true;for _,child in ipairs(nodes) do if child.parent==self then child:Remove() end end end
for _,name in ipairs({'SetFont','SetTextColor','SetWrap','SetTitle','Center','MakePopup','Dock','ShowCloseButton','SetMouseInputEnabled','SetDoubleClickingEnabled','InvalidateLayout'}) do panel[name]=function() end end
vgui={Create=function(kind,parent) local p=setmetatable({kind=kind,parent=parent},{__index=panel});nodes[#nodes+1]=p;return p end}
surface={CreateFont=function() end,SetFont=function() end,GetTextSize=function(s) return #s*7,16 end,PlaySound=function() end}
hook={Add=function() end}
net={Receive=function(n,f) handlers[n]=f end,Start=function(n) sent[#sent+1]={channel=n} end,
    WriteUInt=function(n) table.insert(sent[#sent],n) end,WriteString=function(s) table.insert(sent[#sent],s) end,SendToServer=function() end}
LOD.Equipment={ItemName=function(_,i) return i.name end,Description=function() return 'Frozen attributes' end,Placement=function() return 'head',{} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_ui_theme.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_wallet.lua')
local W,UI=LOD.Wallet,LOD.UI
W:Open();assert(UI.ActivePage=='wallet' and sent[#sent][1]=='snapshot')
local state={balance=100,score=90,pool=100,pendingSoldier=0,ranked=true,atStatue=true,milestones={['1']=true},pending={},history={},tokens={}}
state.tokens[1]={id='server-token-1',item={name='Frozen Hat'},reason='Combat Level 1',depth=1,run='campaign:1',value=40,available=true}
net.ReadTable=function() return state end
handlers.LOD_WalletSnapshot()
local function find(text) for i=#nodes,1,-1 do local p=nodes[i];if not p.removed and p.text==text then return p end end end
assert(find('Sell Equipment'),'Equipment is the default statue screen')
assert(not find('RECREATE & EQUIP — FREE'),'Token services live on a separate clear page')
find('DFT Collection / Recreate').DoClick()
local slots=0
for _,p in ipairs(nodes) do if not p.removed and p.text and p.text:match('^SLOT ') then slots=slots+1 end end
assert(slots==8,'Wallet presents exactly eight slots')
local create=find('RECREATE & EQUIP — FREE');assert(create and create.enabled)
create.DoClick();assert(sent[#sent][1]=='recreate' and sent[#sent][2]=='server-token-1' and #sent[#sent]==2)
local confirmed
Derma_Query=function(_,_,_,yes) confirmed=yes end
local sell=find('SELL FOR 40 $DEB');local n=#sent;sell.DoClick();assert(#sent==n,'Sale requires explicit in-pane confirmation')
confirmed();assert(sent[#sent][1]=='sell' and sent[#sent][2]=='server-token-1')
state.atStatue=false;handlers.LOD_WalletSnapshot();assert(not find('RECREATE & EQUIP — FREE').enabled and not find('SELL FOR 40 $DEB').enabled)
state.atStatue=true;state.tokens[1].available=false;handlers.LOD_WalletSnapshot();assert(not find('ALREADY RECREATED THIS RUN').enabled)
-- Execute real pile receivers/actions: ID-only request, bounds, protected gear,
-- result correlation, deferred render while dragging, and authoritative refresh.
state.equipment={
    {id='hat',name='Fine Hat',value=40,equipped=true},
    {id='gun',name='Rare Pistol',value=80},
    {id='token-copy',name='Frozen Ring',value=200,reason='DFT-created equipment cannot be sold or fused.'}
}
for i=1,8 do state.equipment[#state.equipment+1]={id='extra'..i,name='Boots '..i,value=10} end
find('Sell Equipment').DoClick()
local function item(id)
    for i=#nodes,1,-1 do local p=nodes[i];if not p.removed and p.LODExchangeId==id then return p end end
end
assert(item('token-copy').enabled==false and not item('token-copy').drag)
assert(not W:SelectExchange('token-copy',true))
local n=#sent
assert(W.PilePanel.receiver(nil,{item('hat')},false) and #sent==n and not W.Pile.hat)
assert(not W.PilePanel.receiver(nil,{{LODExchangeId='hat'}},true),'Foreign drag is rejected')
assert(W.PilePanel.receiver(nil,{item('hat')},true));W.Frame.Think()
assert(W.Pile.hat and W.ConfirmButton.enabled)
assert(W.SourcePanel.receiver(nil,{item('hat')},true));W.Frame.Think();assert(not W.Pile.hat)
W.Scroll:GetVBar():SetScroll(120);W.SourceScroll:GetVBar():SetScroll(60)
item('hat').DoClick();W.Frame.Think();assert(W.Scroll:GetVBar():GetScroll()==120 and W.SourceScroll:GetVBar():GetScroll()==60);item('gun').DoClick();W.Frame.Think()
for i=1,6 do assert(W:SelectExchange('extra'..i,true)) end
assert(not W:SelectExchange('extra7',true),'Pile never exceeds eight')
for i=1,6 do W:SelectExchange('extra'..i,false) end
W.Frame.Think();find('Fuse Equipment').DoClick();W.Frame.Think();item('hat').DoClick();item('gun').DoClick();W.Frame.Think()
W.ConfirmButton.DoClick()
local request=sent[#sent];assert(request.channel=='LOD_JunkExchange' and request[1]=='fuse_items' and request[2]==2)
assert(request[3]=='gun' and request[4]=='hat' and type(request[5])=='number' and #request==5)
W:ConfirmExchange();assert(sent[#sent]==request,'No duplicate confirmation while pending')
assert(not W:SelectExchange('extra1',true))
net.ReadTable=function() return {request=request[5]+1,ok=true} end
handlers.LOD_JunkResult();assert(W.ExchangePending,'An unrelated response cannot release this request')
net.ReadTable=function() return {request=request[5],ok=false,message='Inventory changed.'} end
handlers.LOD_JunkResult();W.Frame.Think();assert(not W.ExchangePending and W.Pile.hat and W.ExchangeMessage=='Inventory changed.')
W:ConfirmExchange();request=sent[#sent]
net.ReadTable=function() return {request=request[5],ok=true,message='Fusion complete.'} end
handlers.LOD_JunkResult();assert(not next(W.Pile) and not W.ExchangePending)
state.equipment={{id='fused',name='Fused Gloves',value=115}}
net.ReadTable=function() return state end
local pressed=item('hat');dragndrop={IsDragging=function() return false end,m_DragWatch=pressed}
handlers.LOD_WalletSnapshot();assert(not pressed.removed,'Incoming snapshots preserve a pressed/dragged panel')
dragndrop.m_DragWatch=nil;W.Frame.Think();assert(pressed.removed and item('fused') and not item('hat'))
W:SelectExchange('fused',true);W.ExchangeAction='sell_items';W:ConfirmExchange()
request=sent[#sent];assert(request[1]=='sell_items' and request[2]==1)
net.ReadTable=function() return {request=request[4],ok=true,message='Sold for 115 $DEB.'} end
handlers.LOD_JunkResult();assert(W.ExchangeMessage=='Sold for 115 $DEB.')
net.ReadTable=function() return state end
local frame=W.Frame
for _,p in ipairs(nodes) do
    if not p.removed and p.parent==frame and p.y==76 then assert(p.x+p.w<=frame:GetWide()-24,'Navigation fits 640px viewport') end
end
-- Both DFT actions share actual drag/drop/confirm; cancel holds no server items.
state.tokens[2]={id='server-token-2',item={name='Frozen Boots'},value=60,available=true}
find('Fuse DFTs').DoClick()
assert(item('server-token-1') and item('server-token-2'))
W.PilePanel.receiver(nil,{item('server-token-1')},true);W.PilePanel.receiver(nil,{item('server-token-2')},true);W.Frame.Think()
W:ConfirmExchange();request=sent[#sent];assert(request[1]=='fuse_tokens' and request[2]==2)
net.ReadTable=function() return {request=request[5],ok=false,message='Invalid fusion'} end
handlers.LOD_JunkResult();W.Frame.Think();assert(W.Pile['server-token-1'])
find('Sell DFTs').DoClick();assert(not next(W.Pile),'Changing action clears staging safely')
item('server-token-1').DoClick();W.Frame.Think();W:ConfirmExchange();request=sent[#sent];assert(request[1]=='sell_tokens' and request[2]==1)
net.ReadTable=function() return {request=request[4],ok=true,message='Sold'} end
handlers.LOD_JunkResult();assert(not W.ExchangePending and not next(W.Pile))
net.ReadTable=function() return state end
item('server-token-2').DoClick();local messages=#sent
UI:SelectPage('book');assert(frame.removed and not W.Frame and UI.ActivePage=='book')
assert(not next(W.Pile) and #sent==messages,'Cancel never consumes or sends staged items')
local before=#nodes;handlers.LOD_WalletSnapshot();assert(#nodes==before and UI.ActivePage=='book','Delayed snapshot does not reopen/focus Wallet')
handlers.LOD_WalletOpen();assert(W.Frame and UI.ActivePage=='wallet')
W:Close();handlers.LOD_WalletSnapshot();assert(not W.Frame and not UI.ActivePage)
print('WALLET_UI_PASS: separate equipment/DFT pages, eight token slots, real drag/click piles, return drops, cap/eligibility, ID-only confirmation, response correlation, scroll/drag preservation, availability and late snapshot isolation')

ScrW=function() return 1280 end;ScrH=function() return 800 end
W.Section='equipment';W:Open()
assert(W.ConfirmButton.y+W.ConfirmButton.h<=W.Scroll:GetTall(),'Normal viewport keeps confirmation in view')
assert(W.SourcePanel.h>=120 and W.PilePanel.h==W.SourcePanel.h)
W:Close()
print('WALLET_LAYOUT_PASS: narrow scrolling fallback and normal-screen visible confirmation')
