-- Real Wallet renderer/navigation, minimal VGUI/network boundary.
LOD={};TOP=1
istable=function(x) return type(x)=="table" end
Color=function(...) return {...} end
RealTime=function() return 1 end
IsValid=function(x) return type(x)=='table' and not x.removed end
ScrW=function() return 640 end;ScrH=function() return 480 end
local nodes,handlers,sent={}, {}, {}
local panel={}
function panel:SetSize(w,h) self.w=w;self.h=h end
function panel:SetPos(x,y) self.x=x;self.y=y end
function panel:GetWide() return self.w end
function panel:GetTall() return self.h end
function panel:SetTall(h) self.h=h end
function panel:SetText(t) self.text=t end
function panel:SetEnabled(x) self.enabled=x end
function panel:Remove() self.removed=true;for _,child in ipairs(nodes) do if child.parent==self then child:Remove() end end end
for _,name in ipairs({'SetFont','SetTextColor','SetWrap','SetTitle','Center','MakePopup','Dock','ShowCloseButton'}) do panel[name]=function() end end
vgui={Create=function(kind,parent) local p=setmetatable({kind=kind,parent=parent},{__index=panel});nodes[#nodes+1]=p;return p end}
surface={CreateFont=function() end,SetFont=function() end,GetTextSize=function(s) return #s*7,16 end}
hook={Add=function() end}
net={Receive=function(n,f) handlers[n]=f end,Start=function(n) sent[#sent+1]={channel=n} end,
    WriteString=function(s) table.insert(sent[#sent],s) end,SendToServer=function() end}
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
local frame=W.Frame
for _,p in ipairs(nodes) do
    if not p.removed and p.parent==frame and p.y==76 then assert(p.x+p.w<=frame:GetWide()-24,'Navigation fits 640px viewport') end
end
UI:SelectPage('book');assert(frame.removed and not W.Frame and UI.ActivePage=='book')
local before=#nodes;handlers.LOD_WalletSnapshot();assert(#nodes==before and UI.ActivePage=='book','Delayed snapshot does not reopen/focus Wallet')
handlers.LOD_WalletOpen();assert(W.Frame and UI.ActivePage=='wallet')
W:Close();handlers.LOD_WalletSnapshot();assert(not W.Frame and not UI.ActivePage)
print('WALLET_UI_PASS: eight slots, frozen details, ID-only actions, confirmation, availability, 640px navigation and late snapshot isolation')
