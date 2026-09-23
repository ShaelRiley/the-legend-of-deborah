-- Execute real client shell and real canonical open routes. Only native GUI,
-- input and transport boundaries are doubled; no imaginary engine methods.
dofile('tools/test_equipment_inventory_ui.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,UI=LOD.Equipment,LOD.UI
local nodes,receivers,commands,hooks,requests={},{},{},{},{}
local panel={};panel.__index=panel
function panel:Remove() self.valid=false;for _,child in ipairs(self.children) do child:Remove() end end
function panel:GetChildren() return self.children end
function panel:GetClassName() return self.kind end
function panel:SetText(t) self.text=t end
function panel:SetEnabled(v) self.enabled=v end
function panel:SetSize(w,h) self.w,self.h=w,h end
function panel:SetWide(w) self.w=w end;function panel:SetTall(h) self.h=h end
function panel:GetWide() return self.w end;function panel:GetTall() return self.h end
for _,name in ipairs({'SetTitle','Center','MakePopup','ShowCloseButton','DockPadding','SetTextColor','SetFont','SetWrap','SetAutoStretchVertical','Dock','DockMargin'}) do
 panel[name]=function() end
end
local world=setmetatable({valid=true,kind='World',children={}},panel)
vgui.Create=function(kind,parent)
 local p=setmetatable({valid=true,kind=kind,children={},w=100,h=100},panel)
 parent=parent or world;parent.children[#parent.children+1]=p;nodes[#nodes+1]=p;return p
end
vgui.GetWorldPanel=function() return world end
TOP=1;BOTTOM=2;FILL=3;LEFT=4;RIGHT=5
net.Receive=function(n,f) receivers[n]=f end
local pending
net.Start=function(n) pending={name=n} end
net.WriteUInt=function(v,b) pending[#pending+1]={v,b} end
net.WriteString=function(v) pending[#pending+1]={v} end
net.SendToServer=function() requests[#requests+1]=pending end
concommand.Add=function(n,f) commands[n]=f end
hook.Add=function(_,n,f) hooks[n]=f end
cookie={GetNumber=function(_,default) return default end,Set=function() end}
LOD.CombatRollFeed={historyLoaded=true}
dofile(root..'cl_spellbook.lua')
dofile(root..'cl_character_sheet.lua')
dofile(root..'cl_wallet.lua')
dofile(root..'cl_instruction_manual.lua')
dofile(root..'cl_feedback_language.lua')
dofile(root..'cl_equipment_inventory.lua')
dofile(root..'cl_minigame.lua')
local M=LOD.Minigame
local function message(session,phase,extra)
 local s={session=session,phase=phase,title='GAME MASTER',message='server message',expiresAt=100}
 for k,v in pairs(extra or {}) do s[k]=v end
 return s
end
local cards={{name='Amber Ring',description='+1 WIS'},{name='Azure Ring',description='+1 STR'},{name='Ivory Ring',description='+1 CON'}}
local count=#requests
assert(M:Receive(message(1,'offer')) and not UI:IsMinigameLocked())
assert(M:Send(1) and not M:Send(1))
assert(#requests==count+1 and requests[#requests][1][1]==1 and requests[#requests][1][2]==32)
assert(requests[#requests][2][1]==1 and requests[#requests][2][2]==3)
local old=vgui.Create('DFrame');E.Frame=old
local query=vgui.Create('DFrame');query:SetText('Discard Amber Ring?')
assert(M:Receive(message(1,'playing',{cards=cards})))
assert(UI:IsMinigameLocked() and not IsValid(old) and not IsValid(query) and not E.Frame)
count=#requests
for _,name in ipairs({'Equipment','CharacterSheet','Wallet','Spellbook','FieldManual'}) do
 assert(LOD[name]:Open()==false,name..' direct open leaked')
end
assert(LOD.CombatRollFeed:OpenHistory()==false)
assert(E:BuildPanel(vgui.Create('DFrame'))==false)
assert(E:Request('snapshot')==false and E:PickupView({})==false)
assert(LOD.Wallet:Request('snapshot')==false)
assert(UI:SelectPage('equipment')==false and UI:PageKey(KEY_O)==false)
commands.lod_equipment()
assert(#requests==count and not E.Frame,'Supported console route leaked')
M.Frame:OnKeyCodePressed(KEY_ESCAPE)
assert(M.Sent and UI:IsMinigameLocked(),'Local cancel unlocked before server acknowledgement')
assert(requests[#requests][2][1]==0)
assert(M:Receive(message(1,'close')) and not UI:IsMinigameLocked())
assert(not M:Receive(message(1,'playing',{cards=cards})),'Retired packet reopened challenge')
assert(M:Receive(message(2,'playing',{cards=cards})))
assert(M:Send(2,3) and not M:Send(2,1),'Duplicate answer submitted')
assert(not M:Receive(message(2,'playing',{cards=cards})) and M.Sent,'Duplicate packet rearmed answer')
assert(not M:Receive(message(2,'offer')) and M:IsLocked(),'Regression unlocked inventory')
local wire=requests[#requests]
assert(#wire==3 and wire[1][1]==2 and wire[2][1]==2 and wire[3][1]==3 and wire[3][2]==2)
assert(M:Receive(message(2,'pending')) and not UI:IsMinigameLocked(),'Pending reward blocked equipment')
local function hasText(text)
 for _,node in ipairs(nodes) do if IsValid(node) and node.text==text then return true end end
 return false
end
assert(not hasText('DFT awarded.'))
assert(M:Send(3) and requests[#requests][2][1]==3)
assert(M:Receive(message(2,'result',{success=false})) and not hasText('DFT awarded.'))
assert(not M:Receive(message(2,'playing',{cards=cards})),'Result regressed to playable state')
M:Retire()
assert(M:Receive(message(3,'result',{success=true})) and hasText('DFT awarded.'))
assert(not M:Receive(message(2,'close')),'Old session retired new session')
assert(M:Receive(message(4,'playing',{cards=cards})))
hooks.LOD_MinigameCleanup()
assert(not M.State and not M.Frame and not UI:IsMinigameLocked())
assert(not M:Receive(message(4,'playing',{cards=cards})))
-- Exact recipient snapshot controls only this Game Master object's visibility.
ENT={};include=function() end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_dungeon_event/cl_init.lua')
local drawn,posed=0,0
local ent={GetNW2String=function() return 'equipment_quiz' end,GetEventID=function() return 'quiz' end,
 EntIndex=function() return 20 end,DrawModel=function() drawn=drawn+1 end}
LOD.ApplyHermitPose=function() posed=posed+1 end
LOD.DungeonEvents={events={{id='quiz',entityIndex=20,details={spent=true}}}}
ENT.Draw(ent);assert(drawn==0 and posed==0)
LOD.DungeonEvents.events[1].details.spent=false;ENT.Draw(ent);assert(drawn==1 and posed==1)
LOD.DungeonEvents.events[1].entityIndex=21;LOD.DungeonEvents.events[1].details.spent=true
ENT.Draw(ent);assert(drawn==2,'Old entity snapshot hid replacement')
print('MINIGAME_UI_PASS: actual modal, canonical menu/request/console guards, deferred unlock, wire shape, stale packets, pending failures, cleanup and recipient entity visibility')
