-- Actual producers, SnapshotDelivery, full/delta receivers and all three page
-- builders. Source/Derma/net/font adapters are boundaries, not gameplay doubles.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local Run,CPS,M,E=fixture.Run,LOD.CharacterProgressionSystem,LOD.MagicProgression,LOD.Equipment
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,debug.traceback('SPOT13 # '..checks..': '..msg,2)) end
local p=fixture.actor('spot13-reader')
local character=LOD.Config.Models.Characters[1]
Run.State.Level,Run.State.RosterSeed=1,1729
p.ps.progressionState=nil;p.ps.model,p.ps.characterName,p.ps.lives=character.model,character.name,3
local hero=CPS:InitializeHero(Run,p.ps,character);p.LODProgressionState=hero
check(CPS:CommitClass(p,'wizard'),'real class commit')
local hand=CPS:BuildClientSnapshot(p).featDraft
check(CPS:CommitFeat(p,hand.offers[1].featId,1),'real starting feat commit')
E:Ensure(p.ps)
local equipment=p.ps.equipment
local now,sw,sh=100,1280,800
CurTime=function() return now end;RealTime=CurTime
ScrW=function() return sw end;ScrH=function() return sh end
LocalPlayer=function() return p end
p.GetNW2Int=p.GetNW2Float
local timers,hooks,receivers,packets,requests={},{},{},{},{}
hook.Add=function(_,id,fn) hooks[id]=fn end;hook.Remove=function(_,id) hooks[id]=nil end
hook.Run=function() end
local timerCount=0
timer.Simple=function(_,fn) timerCount=timerCount+1;timers[#timers+1]=fn end
local function flush()
    now=now+1
    local work=timers;timers={}
    for _,fn in ipairs(work) do fn() end
end
local current,incoming
net.Receive=function(name,fn) receivers[name]=fn end
net.Start=function(name) current={name=name} end
net.WriteTable=function(data) current.data=table.Copy(data) end
net.WriteString=function(value) current[#current+1]=value end
net.WriteUInt=function(value) current[#current+1]=value end
net.ReadTable=function() return incoming end
net.Send=function(who) current.player=who;packets[#packets+1]=current end
net.SendToServer=function() requests[#requests+1]=current end
net.BytesWritten=function() return 0 end
ErrorNoHalt=function(message) error(message) end
LOD.RPGTestLog=nil
dofile(root..'sv_snapshot_delivery.lua')
local D=LOD.SnapshotDelivery
local function sendAll()
    D:Queue(p,'LOD_RPG_Snapshot',function(who) return CPS:BuildClientSnapshot(who) end)
    M:SendSnapshot(p);E:Sync(p);flush()
end
local function latest(name)
    for i=#packets,1,-1 do if packets[i].name==name then return packets[i] end end
end
local function receive(packet)
    incoming=table.Copy(packet.data);receivers[packet.name]()
end
local function deliverAll()
    local work=packets;packets={}
    for _,packet in ipairs(work) do receive(packet) end
    return work
end
local function meta(packet)
    return (packet.data.equipmentDelta and packet.data.state or packet.data)._pageUpdate
end

-- Complete VGUI tree adapter: actual Paint -> children -> PaintOver order.
local panel={};panel.__index=panel
local nodes={}
local create
function panel:SetPos(x,y) self.x,self.y=x,y end
function panel:GetX() return self.x end;function panel:GetY() return self.y end
function panel:SetSize(w,h) self.w,self.h=w,h end
function panel:SetWide(w) self.w=w end;function panel:SetTall(h) self.h=h end
function panel:GetWide() return self.w end;function panel:GetTall() return self.h end
function panel:SetText(v) self.text=v end;function panel:GetText() return self.text end
function panel:SetFont(v) self.font=v end;function panel:GetFont() return self.font end
function panel:SetTooltip(v) self.tooltip=v end
function panel:SetEnabled(v) self.enabled=v end;function panel:IsEnabled() return self.enabled~=false end
function panel:IsHovered() return false end
function panel:IsVisible() return self.visible~=false and (not self.parent or self.parent:IsVisible()) end
function panel:SetVisible(v) self.visible=v end
function panel:GetCanvas()
    if not self.canvas then self.canvas=create('DPanel',self);self.canvas.w=self.w-18 end
    return self.canvas
end
function panel:GetVBar()
    if not self.bar then self.bar={scroll=0,GetScroll=function(b) return b.scroll end,SetScroll=function(b,v) b.scroll=v end} end
    return self.bar
end
function panel:Clear() for _,child in ipairs(self.children) do child:Remove() end;self.children={} end
function panel:Remove() self.valid=false;self:Clear() end
function panel:Receiver(_,fn) self.receiver=fn end
function panel:OnMousePressed() dragndrop.m_DragWatch=self end
for _,name in ipairs({'SetTextColor','SetContentAlignment','SetWrap','Center','SetTitle','ShowCloseButton',
    'SetDraggable','MakePopup','InvalidateLayout','Droppable','SetDoubleClickingEnabled'}) do panel[name]=function() end end
create=function(kind,parent)
    local n=setmetatable({valid=true,kind=kind,parent=parent,children={},x=0,y=0,w=100,h=100},panel)
    nodes[#nodes+1]=n;if parent then parent.children[#parent.children+1]=n end;return n
end
vgui={Create=create,GetKeyboardFocus=function() return nil end}
local fonts,font={},nil
local drawColor,drawLog,painted={}, {}, {}
surface={CreateFont=function(name,data) fonts[name]=data end,SetFont=function(name) font=name end,
    GetTextSize=function(text) local size=(fonts[font] or {}).size or 13;return (utf8.len(text) or #text)*size*.52,size end,
    SetDrawColor=function(c) drawColor=c end,
    DrawRect=function(x,y,w,h) drawLog[#drawLog+1]={kind='rect',x=x,y=y,w=w,h=h,color=drawColor} end,
    DrawOutlinedRect=function() end,DrawPoly=function() end,DrawCircle=function() end}
draw={RoundedBox=function() end,NoTexture=function() end,
    SimpleText=function(text,fn,x,y,color) drawLog[#drawLog+1]={kind='text',text=text,font=fn,x=x,y=y,color=color} end}
TEXT_ALIGN_CENTER=1;TEXT_ALIGN_LEFT=0;TEXT_ALIGN_TOP=0
KEY_P=26;KEY_I=19;KEY_L=22;KEY_O=25;KEY_ESCAPE=70
MOUSE_LEFT=107;MOUSE_RIGHT=108;MOUSE_MIDDLE=109;MOUSE_4=110;MOUSE_5=111
unpack=table.unpack
concommand={Add=function() end};gui={IsConsoleVisible=function() return false end};chat={IsTyping=function() return false end}
input={IsKeyDown=function() return false end,GetKeyName=function() return 'o' end}
CreateClientConVar=function() return {GetInt=function() return KEY_O end} end
local dragging=false;dragndrop={IsDragging=function() return dragging end}
LOD.Audio={Play=function() end};LOD.Wallet=nil;LOD.Minigame=nil
LOD.CharacterPortrait={Create=function(_,parent) local n=create('Portrait',parent);n.Paint=function() end;return n end}
LOD.UI={};dofile(root..'cl_ui_theme.lua');dofile(root..'cl_ui_unread.lua')
dofile(root..'cl_character_sheet.lua');dofile(root..'cl_spellbook.lua')
dofile(root..'cl_equipment.lua');dofile(root..'cl_equipment_icons.lua');dofile(root..'cl_equipment_inventory.lua')
local UI,S,B=LOD.UI,LOD.CharacterSheet,LOD.Spellbook
local function paint(n)
    if not IsValid(n) or not n:IsVisible() then return end
    if n.Paint then n:Paint(n.w,n.h) end
    for _,child in ipairs(n.children) do paint(child) end
    painted[n]=true
    if n.PaintOver then n:PaintOver(n.w,n.h) end
end
local function unread(a,b,c)
    check(UI:IsPageUnread('sheet')==a,'Character unread expected '..tostring(a))
    check(UI:IsPageUnread('book')==b,'Spellbook unread expected '..tostring(b))
    check(UI:IsPageUnread('equipment')==c,'Inventory unread expected '..tostring(c))
end
local function markAll()
    hero.baseAbilities.str=(hero.baseAbilities.str or 0)+1;CPS:_RecomputeProgressionState(hero)
    local contents=hero.contentIds
    if #contents==0 then contents[1]='fire' else table.remove(contents) end
    local item=E:NewItem(p,'boots','unread-'..now);equipment.items[item.id]=item
    sendAll();deliverAll();unread(true,true,true)
end

-- First complete sync is quiet; the live payloads remain untouched by metadata.
sendAll();check(#packets==3,'three relevant initial real channels')
local initial=table.Copy(packets)
local epoch=meta(packets[1]).epoch
for _,packet in ipairs(packets) do
    check(meta(packet).epoch==epoch and meta(packet).revision==1,'shared epoch, per-page first revision')
end
check(equipment._pageUpdate==nil and hero._pageUpdate==nil,'metadata never mutates profiles/items')
deliverAll();unread(false,false,false)
check(B.Snapshot.forms[1].displayName~=nil and S.Snapshot.identityTraits[1]~=nil,'real server authored DTOs')
local requested=timerCount;sendAll();check(#packets==0,'identical polls deduplicated before metadata')
check(timerCount==requested+1 and not D.Players[p].scheduled,'one existing flush, no idle recurring job')
D:Invalidate(p);sendAll();check(#packets==3,'explicit full resync')
for _,packet in ipairs(packets) do check(meta(packet).epoch==epoch and meta(packet).revision==2,'resync keeps epoch and raises revision') end
deliverAll();unread(false,false,false)

-- Genuine level/draft/Form grants, then a chosen result, are meaningful. The
-- first synchronised state was quiet; this later change must not be mistaken
-- for initialization just because the page has never been opened.
check(CPS:AdvanceHeroToLevel(p,2),'real Level-2 advancement')
sendAll();deliverAll();unread(true,true,false)
S:Open(false);paint(S.Frame);B:Open();paint(B.Frame);B:Close()
local nextDraft=CPS:BuildClientSnapshot(p).featDraft
if nextDraft and not nextDraft.resolved and #nextDraft.offers>0 then
    check(CPS:CommitFeat(p,nextDraft.offers[1].featId,nextDraft.earnedAtLevel),'real next feat commitment')
    sendAll();deliverAll();check(UI:IsPageUnread('sheet'),'owned feat/choice completion is unread')
    S:Open(false);paint(S.Frame);S:Close()
end
-- Stack amounts, removals and capacity are inventory content, not ammo noise.
check(E:AddConsumable(equipment,'healing_potion',1),'real consumable stack acquisition')
sendAll();deliverAll();unread(false,false,true)
E:Open();paint(E.Frame);E:Close()
check(E:AddConsumable(equipment,'healing_potion',1),'real stack increment')
sendAll();deliverAll();unread(false,false,true)
E:Open();paint(E.Frame);E:Close()
equipment.capacityBonus=2;sendAll();deliverAll();unread(false,false,true)
E:Open();paint(E.Frame);E:Close()
check(E:Consume(equipment,'healing_potion') and E:Consume(equipment,'healing_potion'),'canonical stack depletion clears its slot')
sendAll();deliverAll();unread(false,false,true)
E:Open();paint(E.Frame);E:Close();unread(false,false,false)

-- Real ownership/progression changes while closed: coalesce; no sibling clears.
markAll()
local oldBook=B.Snapshot
B:Open();unread(true,true,true)
local replaced=B.Frame
hero.contentIds={'ice','fire'};sendAll();deliverAll()
check(not IsValid(replaced) and B.Frame~=replaced,'updated Book rebuilds instead of displaying old cards')
replaced:PaintOver(replaced.w,replaced.h);unread(true,true,true)
B.Frame:SetVisible(false);B.Frame:PaintOver(B.Frame.w,B.Frame.h);unread(true,true,true)
B.Frame:SetVisible(true);paint(B.Frame);unread(true,false,true)
check(painted[B.Frame.children[2]],'children are painted before page acknowledgement')
S:Open(false);unread(true,false,true);paint(S.Frame);unread(false,false,true)
E:Open();unread(false,false,true);paint(E.Frame);unread(false,false,false)

-- Transient resources, bindings, stow/equip and current effective stats are quiet.
E:Close();S:Close();B:Close()
for i=1,12 do
    hero.xp=hero.xp+1;p.hp=80+i;Run.State.Level=1+i
    p.nw.LOD_Magic=i;hero.selectedMagicContentId=i%2==0 and 'ice' or 'fire'
    equipment.activeWeaponClass=i%2==0 and 'weapon_smg1' or 'weapon_pistol'
    equipment.blockChance=i/100
    sendAll();deliverAll();unread(false,false,false)
end
local wand=E:NewItem(p,'weapon_lod_wand','unread-wand');check(wand~=nil,'real wand record')
equipment.items[wand.id]=wand;sendAll();deliverAll();unread(false,false,true)
E:Open();paint(E.Frame);E:Close()
wand.charges=wand.charges-1;sendAll();deliverAll();unread(false,false,false)

-- Duplicate/older deliveries cannot overwrite either data or unread state.
markAll();local latestSheet=S.Snapshot
for _,packet in ipairs(initial) do receive(packet) end
check(S.Snapshot==latestSheet and B.Snapshot~=oldBook,'stale same-epoch snapshots ignored')
unread(true,true,true)
local full={name='LOD_RPG_Snapshot',data=table.Copy(latestSheet)}
receive(full);check(S.Snapshot==latestSheet,'duplicate revision ignored')
D:Invalidate(p);sendAll();deliverAll();unread(true,true,true)

-- A drag starts on mouse-down, before native IsDragging: neither path may ack
-- an updated bag before its new item tiles have actually been painted.
E:Open();paint(E.Frame);unread(true,true,false)
local view=E.InventoryView
for _,watch in ipairs({true,false}) do
    local old=view.CurrentSnapshot
    if watch then dragndrop.m_DragWatch=view.SlotTiles[1] else dragging=true end
    local item=E:NewItem(p,'boots','drag-'..now);equipment.items[item.id]=item
    sendAll();deliverAll();check(E.InventoryView==view and view.CurrentSnapshot==old,'drag defers real rebuild')
    paint(E.Frame);unread(true,true,true)
    dragndrop.m_DragWatch=nil;dragging=false;view.Think()
    check(view.CurrentSnapshot==E.Snapshot,'release binds rebuilt latest snapshot')
    unread(true,true,true);paint(E.Frame);unread(true,true,false)
end

-- Deliberately drop one reliable packet in the adapter to exercise explicit
-- recovery. A delta may never splice into a stale or missing baseline.
E:Close()
local first=E:NewItem(p,'boots','gap-first');equipment.items[first.id]=first
sendAll();local lost=assert(latest('LOD_EquipmentSnapshot'));check(lost.data.equipmentDelta,'real delta serialization')
packets={}
local second=E:NewItem(p,'boots','gap-second');equipment.items[second.id]=second
sendAll();local gap=assert(latest('LOD_EquipmentSnapshot'));packets={}
local count=#requests;local previous=E.Snapshot
receive(gap)
check(E.Snapshot==previous and #requests==count+1 and requests[#requests][1]=='snapshot','missing exact baseline requests full recovery')
receive(lost);check(E.Snapshot.items[first.id]~=nil and E.Snapshot.items[second.id]==nil,'the actual preceding delta applies')
receive(gap);check(E.Snapshot.items[second.id]~=nil,'exact-baseline next delta applies')
unread(true,true,true)
receive(lost);check(E.Snapshot.items[second.id]~=nil,'late older delta cannot roll back newer cache')
D:Invalidate(p,'LOD_EquipmentSnapshot');sendAll();deliverAll();unread(true,true,true)

-- Locked access, loading frames and sibling navigation do not consume markers.
local locked=true;LOD.Minigame={IsLocked=function() return locked end}
check(S:Open(false)==false and B:Open()==false and E:Open()==false,'all three access guards')
unread(true,true,true);locked=false
S:Open(false);local stale=S.Frame;locked=true;paint(stale);unread(true,true,true)
locked=false;S:Close();stale:PaintOver(stale.w,stale.h);unread(true,true,true)
local saved=S.Snapshot;S.Snapshot=nil;S:Open(false);paint(S.Frame);unread(true,true,true)
S.Snapshot=saved;S:Close();LOD.Minigame=nil

-- Markers are above only the requested existing navigation buttons; complete
-- page rendering removes only its own marker. Test native-sized bounds with
-- deterministic fonts, not a claim about native Source fonts or screenshots.
for _,size in ipairs({{960,600},{1280,800},{1920,1080}}) do
    sw,sh=size[1],size[2]
    S:Open(false);drawLog={};S.Frame:PaintOver(S.Frame.w,S.Frame.h)
    local marks={}
    for _,entry in ipairs(drawLog) do if entry.text=='!' then marks[#marks+1]=entry end end
    check(#marks==3,'exactly three markers before this frame acknowledgement')
    for i,entry in ipairs(marks) do
        local button=S.Frame.children[i+1] -- close is first, then nav links
        check(entry.x==button.x+button.w/2 and entry.y==button.y-9,'marker centered directly above correct tab')
        check(entry.y>=0 and entry.y<button.y,'18px marker band inside frame')
        check(entry.color==UI.Colors.red and entry.font=='LOD_SheetKey','existing vermilion/key font')
        for _,child in ipairs(S.Frame.children) do
            if child.kind=='DLabel' then
                check(entry.x+8<=child.x or child.x+child.w<=entry.x-8 or
                    entry.y+9<=child.y or child.y+child.h<=entry.y-9,'marker band never overlaps a header label')
            end
        end
    end
    unread(false,true,true)
    -- New actual stat progression recreates only the Character marker.
    S:Close();hero.baseAbilities.str=hero.baseAbilities.str+1;CPS:_RecomputeProgressionState(hero)
    sendAll();deliverAll();unread(true,true,true)
end

-- The same three badges remain visible while reading another page. Exercise
-- the actual Die-Logger header, whose subtitle also needs reserved space.
LOD.CombatRollFeed=LOD.CombatRollFeed or {}
LOD.CombatRollFeed.historyLoaded=true;LOD.CombatRollFeed.history={}
dofile(root..'cl_feedback_language.lua')
local history=LOD.CombatRollFeed:OpenHistory();drawLog={};paint(history)
local marks=0
for _,entry in ipairs(drawLog) do if entry.text=='!' then
    marks=marks+1
    for _,child in ipairs(history.children) do if child.kind=='DLabel' then
        check(entry.x+8<=child.x or child.x+child.w<=entry.x-8 or
            entry.y+9<=child.y or child.y+child.h<=entry.y-9,'history marker avoids title/subtitle/legend')
    end end
end end
check(marks==3,'reading Die-Logger displays only the three requested badges');unread(true,true,true)
UI:SelectPage(nil)

-- Cache cleanup/floor-only transitions preserve unread state and revisions.
local beforeEpoch=UI.PageEpoch
Run.State.Level=Run.State.Level+1;Run.State.LevelSeed=98765
p.LODRunSpawnSerial=(p.LODRunSpawnSerial or 0)+1
hooks.LOD_SnapshotDeliveryCleanup();sendAll();deliverAll()
check(UI.PageEpoch==beforeEpoch,'floor/deployment/map cache cleanup is not a life reset');unread(true,true,true)

-- Death is explicit even when death and respawn happen between two dispatches.
S:Open(false);local oldFrame=S.Frame
hooks.LOD_SnapshotDeliveryLife(p);sendAll();local deadEpoch=meta(packets[1]).epoch
deliverAll();check(deadEpoch>beforeEpoch and not IsValid(oldFrame),'death retires old views')
unread(false,false,false)
oldFrame:PaintOver(oldFrame.w,oldFrame.h);unread(false,false,false)
-- Older cross-epoch full/delta traffic never reclaims the new actor UI.
receive(gap);receive(full);check(UI.PageEpoch==deadEpoch,'retired actor packets rejected');unread(false,false,false)

-- Campaign/profile replacement with equal-valued data is a quiet new baseline.
markAll();Run.State=table.Copy(Run.State);sendAll();deliverAll()
check(UI.PageEpoch>deadEpoch,'new campaign epoch');unread(false,false,false)
markAll();p.ps=table.Copy(p.ps);hero=p.ps.progressionState;equipment=p.ps.equipment
sendAll();deliverAll();unread(false,false,false)
markAll();hero=table.Copy(hero);p.ps.progressionState=hero;p.LODProgressionState=hero
sendAll();deliverAll();unread(false,false,false)

-- Real Soldier state identity changes retire Hero markers, and a new Soldier
-- with equal values is still a new incarnation. No saved-Hero unread leakage.
markAll()
local soldier=LOD.SoldierProgression:Attach(p,88241,35,1);check(soldier~=nil,'real Soldier incarnation')
p.soldier=true;sendAll();deliverAll();unread(false,false,false)
check(S.Snapshot.isSoldier and S.Snapshot.readOnly,'actual read-only Soldier sheet')
LOD.SoldierProgression:Retire(p);LOD.SoldierProgression:Attach(p,88241,35,1)
sendAll();deliverAll();unread(false,false,false)
LOD.SoldierProgression:Retire(p);p.soldier=false
sendAll();deliverAll();unread(false,false,false)

-- Fresh connection revokes pending old server work; another recipient has an
-- independent epoch and cannot inherit this client's delivery baselines.
markAll();beforeEpoch=UI.PageEpoch
hooks.LOD_SnapshotDeliveryDisconnect(p);sendAll();deliverAll()
check(UI.PageEpoch>beforeEpoch,'reconnect establishes fresh baseline');unread(false,false,false)
local other=fixture.actor('other')
D:Queue(other,'LOD_RPG_Snapshot',function() return {level=1} end);flush()
check(#packets==1 and packets[1].player==other and meta(packets[1]).epoch~=UI.PageEpoch,'recipient isolation')
packets={}
local buildCount=0
D:Queue(other,'LOD_RPG_Snapshot',function(who)
    buildCount=buildCount+1
    if buildCount==1 then who.ps=table.Copy(who.ps);return {level=99} end
    return {level=1}
end)
flush();check(#packets==0,'in-build profile retirement cannot dispatch its stale result')
flush();check(#packets==1 and packets[1].data.level==1 and buildCount==2,'retired producer retries via existing queue')
packets={}
check(next(D.Players[p].pending)==nil and not D.Players[p].scheduled,'no per-frame network work')
for _,page in ipairs({'history','manual','wallet','inventory'}) do check(not UI:IsPageUnread(page),'no unrelated or duplicate Inventory tab') end
local f=assert(io.open('gamemodes/legend_of_deborah/gamemode/shared.lua'));local loader=f:read('*a');f:close()
check(loader:find('AddCSLuaFile("lod/cl_ui_unread.lua")',1,true) and loader:find('include("lod/cl_ui_unread.lua")',1,true),'shipped client loader wiring')
print('SPOT13_UNREAD_PASS: '..checks..' production producer/transport/delta/UI/paint/lifecycle assertions; native appearance/co-op acceptance remains open.')
