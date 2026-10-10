-- Actual server snapshots -> shipped Spellbook Open/Paint/callbacks. Only
-- Source entities, net transport, font measurement and Derma/draw are adapters.
-- This is headless production evidence, not native visual/co-op acceptance.
dofile('tools/test_checkpoint_d_closure.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local M,CPS=LOD.MagicProgression,LOD.CharacterProgressionSystem
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT12: '..msg) end
local now,screenW,screenH=100,1280,800
CurTime=function() return now end;RealTime=CurTime
ScrW=function() return screenW end;ScrH=function() return screenH end
TEXT_ALIGN_CENTER=1;TEXT_ALIGN_LEFT=0;TEXT_ALIGN_TOP=0
MOUSE_LEFT=107;MOUSE_RIGHT=108;MOUSE_MIDDLE=109;MOUSE_4=110;MOUSE_5=111
KEY_I=19;KEY_P=26;KEY_ESCAPE=70
local allocations=0
Color=function(r,g,b,a) allocations=allocations+1;return {r=r,g=g,b=b,a=a or 255} end
local owner={valid=true,alive=true,nw={}}
function owner:Alive() return self.alive end
function owner:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
owner.GetNW2Float=owner.GetNW2Bool;owner.GetNW2Int=owner.GetNW2Bool
local localPlayer=owner
LocalPlayer=function() return localPlayer end
IsValid=function(v) return type(v)=='table' and v.valid==true end
local throwing=false
LOD.Equipment={IsActive=function() return throwing end}
LOD.CharacterSheet=nil;LOD.Wallet=nil;LOD.Minigame=nil
LOD.Audio={Play=function() end};LOD.UI={}
local hooks,receivers={},{}
hook={Add=function(_,id,fn) hooks[id]=fn end}
concommand={Add=function() end};gui={IsConsoleVisible=function() return false end}
chat={IsTyping=function() return false end};input={IsKeyDown=function() return false end}
local fonts={DermaDefault={size=13}},font
local drawColor,paint
surface={CreateFont=function(id,def) fonts[id]=def end,
    SetFont=function(id) font=id end,
    GetTextSize=function(text) local size=(fonts[font] or {}).size or 14;return #text*size*0.52,size end,
    SetDrawColor=function(c) drawColor=c end,
    DrawOutlinedRect=function(x,y,w,h,t) paint.outlines[#paint.outlines+1]={x=x,y=y,w=w,h=h,t=t,color=drawColor} end,
    DrawRect=function(x,y,w,h) paint.rects[#paint.rects+1]={x=x,y=y,w=w,h=h,color=drawColor} end}
draw={RoundedBox=function(_,x,y,w,h,c) paint.fills[#paint.fills+1]={x=x,y=y,w=w,h=h,color=c} end,
    SimpleText=function(text,fn,x,y,c)
        surface.SetFont(fn);local tw,th=surface.GetTextSize(text)
        paint.texts[#paint.texts+1]={text=text,font=fn,x=x,y=y,color=c,w=tw,h=th}
    end}
local all={}
vgui={Create=function(kind,parent)
    local p={valid=true,kind=kind,parent=parent,children={},enabled=true,hover=false,text=''}
    if parent then parent.children[#parent.children+1]=p end
    all[#all+1]=p
    function p:SetTitle(v) self.title=v end
    function p:SetText(v) self.text=v end
    function p:SetFont(v) self.font=v end
    function p:SetTextColor(v) self.textColor=v end
    function p:SetPos(x,y) self.x=x;self.y=y end
    function p:SetSize(w,h) self.w=w;self.h=h end
    function p:GetWide() return self.w end
    function p:GetTall() return self.h end
    function p:SetEnabled(v) self.enabled=v end
    function p:IsEnabled() return self.enabled end
    function p:IsHovered() return self.hover end
    function p:Center() self.centered=true end
    function p:MakePopup() self.popup=true end
    function p:ShowCloseButton(v) self.closeButton=v end
    function p:Remove() self.valid=false;for _,c in ipairs(self.children) do c:Remove() end end
    return p
end}
local sent,current,incoming={}
net={Receive=function(name,fn) receivers[name]=fn end,
    ReadTable=function() return incoming end,
    Start=function(name) current={name=name,strings={},uints={}} end,
    WriteString=function(value) current.strings[#current.strings+1]=value end,
    WriteUInt=function(value,bits) current.uints[#current.uints+1]={value,bits} end,
    SendToServer=function() sent[#sent+1]=current end}
dofile(root..'cl_ui_theme.lua')
dofile(root..'cl_spellbook.lua')
local B,C=LOD.Spellbook,LOD.UI.Colors
local function makeState(class)
    local state=CPS:NewProgressionState('spot12-'..(class or 'wizard'),'hero','hero')
    state.classId=class or 'wizard';state.magicFormIds=table.Copy(M.FormOrder)
    state.contentIds=table.Copy(M.ContentOrder)
    state.selectedMagicFormId='bolt';state.selectedMagicContentId='fire'
    state.magicBindings={['2']='bolt',['3']='wall',['4']='watermelon',['5']='super_ball'}
    state.derivedStats={quantumCostMultiplier=1}
    return state
end
local state=makeState()
local function resetBody()
    localPlayer=owner;owner.alive=true;owner.nw={LOD_Magic=100};throwing=false;now=100
end
local function deliver(s)
    incoming=M:Snapshot(s);receivers.LOD_MagicSpellbookSnapshot()
end
local function open(s)
    B:Close();incoming=M:Snapshot(s);B.Snapshot=incoming;B:Open()
end
local function cards()
    local result={}
    for _,p in ipairs(B.Frame.children) do if p.text=='' and p.h~=26 then result[#result+1]=p end end
    return result
end
local function findCard(id,kind)
    local entries=kind=='content' and B.Snapshot.contents or B.Snapshot.forms
    local offset=kind=='content' and #B.Snapshot.forms or 0
    for i,e in ipairs(entries) do if e.id==id then return cards()[offset+i],e end end
    error('Missing production card '..id)
end
local function render(p)
    paint={fills={},outlines={},rects={},texts={}}
    p:Paint(p.w,p.h)
    return paint
end
local function same(a,b) return a.r==b.r and a.g==b.g and a.b==b.b and a.a==b.a end
local function luminance(c)
    local function channel(v) v=v/255;return v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4 end
    return .2126*channel(c.r)+.7152*channel(c.g)+.0722*channel(c.b)
end
local function contrast(a,b)
    local x,y=luminance(a),luminance(b);return (math.max(x,y)+.05)/(math.min(x,y)+.05)
end
-- These frozen values are the live GDD's cosmetic mix, not another state resolver.
local colors={
    blue={fill={r=208,g=213,b=214,a=255},ink={r=48,g=73,b=110,a=255}},
    red={fill={r=233,g=206,b=193,a=255},ink={r=129,g=52,b=44,a=255}},
    gold={fill={r=228,g=216,b=188,a=255},ink={r=111,g=82,b=29,a=255}},
    muted={fill={r=220,g=216,b=202,a=255},ink={r=88,g=82,b=72,a=255}},
}
local minContrast=math.huge
local function expect(id,kind,label,role,selected)
    local p,e=findCard(id,kind);local out=render(p)
    check(#out.fills==1 and out.fills[1].x==0 and out.fills[1].y==0 and out.fills[1].w==p.w and out.fills[1].h==p.h,'whole card covered')
    check(same(out.fills[1].color,colors[role].fill),label..' backdrop is '..role)
    check(out.texts[2].text==label,'literal availability reason '..label)
    check(same(out.texts[1].color,colors[role].ink) and same(out.texts[2].color,colors[role].ink),'readable semantic title/status ink')
    check(out.outlines[1].color==C[role] and out.outlines[1].t==1,'state border preserved')
    check(#out.outlines==(selected and 2 or 1),'selection geometry independent of availability')
    if selected then
        local r=out.outlines[2]
        check(r.color==C.ink and r.t==2 and r.x==3 and r.y==3 and r.w==p.w-6 and r.h==p.h-6,'selected inset dark outline')
    end
    check(p.enabled==(e.owned==true),'only ownership determines configuration access')
    check(out.texts[3].color==C.ink and out.texts[4].color==C.ink,'cost/description remain body ink')
    for _,t in ipairs(out.texts) do
        local ratio=contrast(t.color,out.fills[1].color);minContrast=math.min(minContrast,ratio)
        check(ratio>=4.5,'all text contrasts against actual card fill')
        check(t.y>=5 and t.y+t.h<p.h-6,'text vertically clears card borders and hover stripe')
    end
    local before=out.fills[1].color;p.hover=true;local hovered=render(p);p.hover=false
    check(same(before,hovered.fills[1].color),'hover cannot erase state fill')
    check(#hovered.rects==(e.owned and 1 or 0),'only owned card gets hover underline')
    if e.owned then check(hovered.rects[1].color==C[role],'hover cannot falsely imply blue ready') end
    return p,e,out
end
resetBody();open(state)
check(#B.Snapshot.forms==10 and #B.Snapshot.contents==7,'actual server catalog, no fabricated reduced fixture')
expect('bolt','form','READY / SELECTED','blue',true)
expect('beam','form','AVAILABLE','blue',false)
expect('fire','content','READY / SELECTED','blue',true)
expect('raw','content','AVAILABLE','blue',false)
-- Repaint existing panels while only networked body state changes; no new snapshot.
local originalFrame=B.Frame
owner.nw.LOD_Magic=0
expect('bolt','form','NEED MAGIC','red',true);expect('earth','content','NEED MAGIC','red',false)
owner.nw.LOD_MagicNextCast=101
expect('bolt','form','COOLDOWN','gold',true)
owner.nw.LOD_StatusMuted=true
expect('bolt','form','BLOCKED','red',true)
owner.nw.LOD_StatusMuted=false;owner.nw.LOD_StatusIntimidated=true
expect('fire','content','BLOCKED','red',true)
owner.alive=false
expect('bolt','form','UNAVAILABLE','muted',true)
owner.alive=true;localPlayer=nil
expect('beam','form','UNAVAILABLE','muted',false)
resetBody();owner.nw.LOD_StatusHeld=true
expect('bolt','form','READY / SELECTED','blue',true)
owner.nw.LOD_ThrowableCount=1;throwing=true
expect('bolt','form','BLOCKED','red',true)
throwing=false
expect('bolt','form','READY / SELECTED','blue',true)
throwing=true;owner.nw.LOD_ThrowableCount=0
expect('bolt','form','READY / SELECTED','blue',true)
resetBody();owner.nw.LOD_SuperBallRemaining=0;owner.nw.LOD_WallRemaining=0
expect('super_ball','form','BALL LIMIT','gold',false);expect('wall','form','WALL LIMIT','gold',false)
expect('fire','content','READY / SELECTED','blue',true)
owner.nw.LOD_Magic=0
expect('wall','form','WALL LIMIT','gold',false)
owner.nw.LOD_MagicNextCast=100.01
expect('wall','form','COOLDOWN','gold',false)
now=100.01;owner.nw.LOD_WallRemaining=1
expect('wall','form','NEED MAGIC','red',false)
check(B.Frame==originalFrame,'body state transitions need no reconstruction or extra timer')
-- Selected limited Forms keep their warning backdrop and independent selection mark.
resetBody();state.selectedMagicFormId='wall';deliver(state);owner.nw.LOD_WallRemaining=0
expect('wall','form','WALL LIMIT','gold',true)
state.selectedMagicFormId='super_ball';deliver(state);owner.nw.LOD_SuperBallRemaining=0
expect('super_ball','form','BALL LIMIT','gold',true)
-- Snapshot cost multiplier, selected opposite component, exact affordability/ceil.
resetBody();state=makeState();state.magicBindings={['2']='bolt'};state.derivedStats.quantumCostMultiplier=.5;deliver(state)
owner.nw.LOD_Magic=4
expect('bolt','form','READY / SELECTED','blue',true)
expect('fire','content','READY / SELECTED','blue',true)
owner.nw.LOD_Magic=3.99
expect('bolt','form','NEED MAGIC','red',true)
owner.nw.LOD_Magic=2.5
expect('beam','form','NEED MAGIC','red',false)
owner.nw.LOD_Magic=3
expect('beam','form','AVAILABLE','blue',false)
state.selectedMagicContentId=nil;state.magicContentBindings=nil;deliver(state);owner.nw.LOD_Magic=2
expect('bolt','form','READY / SELECTED','blue',true)
expect('raw','content','READY / SELECTED','blue',true)
expect('fire','content','NEED MAGIC','red',false)
state.selectedMagicFormId='cone';deliver(state)
expect('raw','content','NEED MAGIC','red',true)
-- Production class/ownership repair -> UI locks, not invented client permissions.
resetBody();state=makeState('fighter');state.magicFormIds={'bolt','wall','summon'}
state.contentIds={'fire'};state.selectedMagicFormId='wall';deliver(state)
expect('wall','form','WIZARD / LOCKED','muted',false)
expect('summon','form','WIZARD / LOCKED','muted',false)
expect('earth','content','LOCKED','muted',false)
owner.alive=false;owner.nw.LOD_StatusMuted=true
expect('wall','form','WIZARD / LOCKED','muted',false)
expect('earth','content','LOCKED','muted',false)
-- Configuration uses the actual callbacks/packet shapes even when casting blocked.
resetBody();state=makeState();deliver(state);owner.nw.LOD_StatusMuted=true
local p=findCard('beam','form');local before=#sent
p:DoClick();p:DoRightClick();p:OnMousePressed(MOUSE_MIDDLE);p:OnMousePressed(MOUSE_4);p:OnMousePressed(MOUSE_5)
for i,button in ipairs({2,2,3,4,5}) do
    local msg=sent[before+i]
    check(msg.name=='LOD_MagicBindForm' and msg.strings[1]=='beam' and msg.uints[1][1]==button and msg.uints[1][2]==3,'form configuration packet unchanged')
end
check(B.Snapshot.selectedFormId=='bolt','client click cannot change authoritative selection locally')
p=findCard('earth','content');before=#sent
p:DoClick();p:DoRightClick();p:OnMousePressed(MOUSE_MIDDLE);p:OnMousePressed(MOUSE_4);p:OnMousePressed(MOUSE_5)
for i,button in ipairs({2,2,3,4,5}) do
    local msg=sent[before+i]
    check(msg.name=='LOD_MagicBindContent' and msg.strings[1]=='earth' and msg.uints[1][1]==button and msg.uints[1][2]==3,'button-specific content configuration packet')
end
-- Bound Forms use their own Content price; Content availability uses the
-- cheapest actual matching binding, and every active Content has its label.
resetBody();state=makeState();state.selectedMagicFormId='beam';state.selectedMagicContentId='fire'
state.magicBindings={['2']='beam',['3']='bolt',['4']='wall',['5']='super_ball'}
state.magicContentBindings={['2']='fire',['3']='ice',['4']='raw',['5']='fire'}
deliver(state);owner.nw.LOD_Magic=4
expect('beam','form','NEED MAGIC','red',true)
expect('super_ball','form','AVAILABLE','blue',false)
expect('fire','content','READY / SELECTED','blue',true)
expect('ice','content','NEED MAGIC','red',true)
expect('raw','content','NEED MAGIC','red',true)
local fire=findCard('fire','content');local out=render(fire)
check(out.texts[5].text=='RMB/M5','multiple matching Content labels are stable and separate')
owner.nw.LOD_Magic=6;expect('ice','content','READY / SELECTED','blue',true)
state.contentIds={'fire'};deliver(state);p=findCard('earth','content');before=#sent
p:DoClick();p:DoRightClick();p:OnMousePressed(MOUSE_5)
check(#sent==before,'locked callbacks send nothing even when invoked directly')
-- Latest snapshot replaces cards without preserving stale ownership/selection.
local retiredFrame=B.Frame;state=makeState();state.selectedMagicFormId='wall';deliver(state)
check(not retiredFrame.valid and B.Frame~=retiredFrame,'old card tree retired on replacement')
resetBody();expect('wall','form','READY / SELECTED','blue',true)
expect('bolt','form','AVAILABLE','blue',false)
-- All cards use actual production layout and literal copy at tested viewports.
for _,size in ipairs({{960,600},{1280,800},{1920,1080}}) do
    screenW,screenH=size[1],size[2];open(state);local list=cards()
    check(#list==17,'all Form and RAW/Content cards present')
    for i,a in ipairs(list) do
        check(a.x>=24 and a.x+a.w<=B.Frame.w-24 and a.y>=100 and a.y+a.h<B.Frame.h-96,'card bounded above navigation')
        for j=i+1,#list do
            local b=list[j]
            check(a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y,'card rectangles do not overlap')
        end
        local out=render(a)
        for _,t in ipairs(out.texts) do check(t.w<=a.w-8,'measured text fits at '..screenW..': '..t.text) end
    end
end
-- Warm all roles, then prove repeated paints reuse Colors and emit no packets.
resetBody();open(makeState());local p=findCard('bolt','form')
render(p);owner.nw.LOD_Magic=0;render(p);owner.nw.LOD_MagicNextCast=200;render(p);owner.alive=false;render(p)
local allocated,packetCount=allocations,#sent
for i=1,40 do
    resetBody();render(p);owner.nw.LOD_Magic=0;render(p)
    owner.nw.LOD_MagicNextCast=200;render(p);owner.alive=false;render(p)
end
check(allocations==allocated,'no per-repaint Color allocations after four cached treatments')
check(#sent==packetCount,'rendering never sends a gameplay/configuration message')
-- Existing pending-open, close, invalid snapshot and minigame seams.
B:Close();B.Snapshot=nil;B:Open()
check(B.PendingOpen and B.Frame==nil and sent[#sent].name=='LOD_RPG_RequestSheet','missing snapshot requests authoritative data')
deliver(makeState());check(IsValid(B.Frame) and not B.PendingOpen,'pending opens on actual snapshot delivery')
local retained=B.Snapshot;incoming=false;receivers.LOD_MagicSpellbookSnapshot()
check(B.Snapshot==retained,'malformed non-table snapshot ignored')
B:Close();deliver(makeState());check(not IsValid(B.Frame),'late snapshot does not reopen closed page')
LOD.Minigame={IsLocked=function() return true end};check(B:Open()==false and not IsValid(B.Frame),'minigame lock preserved')
print(string.format('SPOT12_SPELLBOOK_PASS: %d production snapshot/paint/layout/state/callback assertions; minimum text contrast %.3f:1. Native appearance/font/co-op acceptance remains open.',checks,minContrast))
