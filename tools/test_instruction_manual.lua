-- Exercise the real shared navigation + portable reader without a spawned book.
local base="gamemodes/legend_of_deborah/gamemode/"
local function expect(ok,label) assert(ok,label) end
Color=function(...) return {...} end
surface={CreateFont=function() end}
draw={}
isstring=function(v) return type(v)=='string' end
util={Decompress=function(value) return value end}
KEY_ESCAPE,KEY_P,KEY_I,KEY_L=70,25,18,21
RealTime=function() return 20 end
local timers={};timer={Simple=function(_,callback) timers[#timers+1]=callback end}
ScrW=function() return 800 end;ScrH=function() return 600 end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
local saved={lod_manual_page=7,lod_manual_scroll=123,lod_manual_text_size=21}
cookie={GetNumber=function(k,d) return saved[k] or d end,Set=function(k,v) saved[k]=v end}
IsValid=function(p) return type(p)=="table" and not p.removed end
include=function(path) return assert(loadfile(base..path))() end
local receivers,started,requests,reads={},nil,0,nil
net={
    Receive=function(id,fn) receivers[id]=fn end,
    Start=function(id) started=id end,
    SendToServer=function()
        assert(started=='LOD_RequestInstructionManual','reader requests canonical server payload')
        requests=requests+1;started=nil
    end,
    ReadString=function() local v=table.remove(reads,1);return v end,
    ReadUInt=function() local v=table.remove(reads,1);return v end,
    ReadData=function() local v=table.remove(reads,1);return v end
}
local panels={}
local Panel={}
function Panel:SetSize(w,h) self.w,self.h=w,h end
function Panel:GetWide() return self.w end
function Panel:GetTall() return self.h end
function Panel:SetPos(x,y) self.x,self.y=x,y end
function Panel:SetText(t) self.text=t end
function Panel:Remove() self.removed=true end
function Panel:MakePopup() self.popup=true end
function Panel:SetHTML(s)
    self.html=s;self.documentLoaded=true
    if self.OnDocumentReady then self:OnDocumentReady('asset://garrysmod/html/lod_manual') end
end
function Panel:SetAllowLua(b) self.allowLua=b end
function Panel:AddFunction(ns,name,fn)
    assert(self.documentLoaded,'DHTML:AddFunction called before document ready')
    self.callbacks[ns..'.'..name]=fn
end
function Panel:QueueJavascript(s) self.js=s end
for _,k in ipairs({'SetFont','SetTextColor','SetContentAlignment','SetWrap','SetMouseInputEnabled',
    'ShowCloseButton','Center','SetTitle','SetDraggable','SetDeleteOnClose'}) do Panel[k]=function() end end
vgui={Create=function(kind,parent)
    local p=setmetatable({kind=kind,parent=parent,callbacks={}},{__index=Panel});panels[#panels+1]=p;return p
end}
LOD={}
include('lod/cl_ui_theme.lua')
local UI=LOD.UI
local function other(name)
    local page={}
    function page:Close() self.closed=true end
    function page:Open() UI:SelectPage(name);self.opened=true end
    page.Toggle=page.Open;return page
end
LOD.CharacterSheet=other('sheet');LOD.Spellbook=other('book');LOD.Equipment=other('equipment');LOD.Wallet=other('wallet')
LOD.CombatRollFeed={OpenHistory=function() UI:SelectPage('history') end,ToggleHistory=function() UI:SelectPage('history') end}
include('lod/cl_instruction_manual.lua')
local M=LOD.FieldManual
expect(ENT==nil,'portable reader has no physical-entity dependency')
local parent=vgui.Create('DFrame');parent:SetSize(776,576)
UI:PageLinks(parent,'sheet',76)
local manualButton
for _,p in ipairs(panels) do if p.text=='MANUAL' then manualButton=p end end
expect(manualButton,'P menu has Manual tab');manualButton.DoClick()
expect(UI.ActivePage=='manual' and IsValid(M.Frame),'tab opens canonical reader')
expect(requests==1 and M.Browser.html==nil,'visible reader requests payload instead of client-only files')
local payload='<!doctype html><html><body>TIME OVER</body></html>'
reads={'manual-test',124,1,1,1,#payload,#payload,payload}
receivers.LOD_InstructionManualPayload()
expect(M.Frame:GetWide()<=ScrW() and M.Frame:GetTall()<=ScrH(),'small-screen frame fits')
expect(not M.Browser.allowLua,'arbitrary Lua disabled')
expect(M.Browser.html:find('TIME OVER',1,true),'complete generated document loaded')
expect(M.Browser.callbacks['lod.position'] and M.Browser.callbacks['lod.close'] and M.Browser.callbacks['lod.tab'],
    'document-ready event installs the bounded bridge')
expect(M.Browser.js:find('restore(7,123.0,21)',1,true),'document-ready event restores bookmark')
local original=M.Frame;receivers.LOD_OpenFieldManual()
expect(M.Frame==original,'staging E reuses already-open reader')
M.Browser.callbacks['lod.position'](16,251,23)
local oldBrowser=M.Browser
oldBrowser.callbacks['lod.tab'](80)
expect(UI.ActivePage=='sheet' and not IsValid(M.Frame),'P from DHTML switches to sheet')
expect(saved.lod_manual_page==16 and saved.lod_manual_scroll==251,'tab switch saves bookmark')
receivers.LOD_OpenFieldManual()
expect(M.Browser.js:find('restore(16,251.0,23)',1,true),'E resumes same bookmark')
oldBrowser.callbacks['lod.position'](0,0,18)
expect(M.Page==16,'stale browser callback cannot overwrite new reader')
M.Browser.callbacks['lod.position'](0/0,0,18)
expect(M.Page==16,'reject nonfinite callback')
M.Browser.callbacks['lod.close']()
expect(UI.ActivePage==nil and not IsValid(M.Frame),'Escape bridge closes reader')
M:Open();UI:SelectPage(nil)
expect(not IsValid(M.Frame),'terminal transition closes reader through shared menu')
M.HTML=nil;M:Open();expect(requests==2 and IsValid(M.LoadingLabel),'missing payload still opens visible reader')
timers[#timers]();expect(M.LoadingLabel.text:find('DID NOT RESPOND',1,true),'no-response timeout exposes retry')
M.LoadingLabel.DoClick();expect(requests==3,'visible retry requests payload again')
-- No player, alive, staging, deployment, or role stubs were supplied. Opening
-- therefore demonstrably does not depend on those world-state authorities.
print('PASS: one reader, both entry points, portable access, bookmark, navigation, stale callback isolation')
