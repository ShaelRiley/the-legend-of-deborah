-- Actual client menu, theme, key/command and HUD handlers; only VGUI/engine doubles.
SERVER=false;CLIENT=true;TOP=1;FILL=2;KEY_F3=3;KEY_ESCAPE=4;TEXT_ALIGN_CENTER=1
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT15_UI: '..msg) end
local noop=function() end
local nodes,hooks,commands,sent,texts={},{},{},{},{}
local width,height=1280,720
ScrW=function() return width end;ScrH=function() return height end
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
IsValid=function(v) return type(v)=='table' and v.valid==true end
local P={};P.__index=P
function P:SetPos(x,y) self.x=x;self.y=y end
function P:SetSize(w,h) self.w=w;self.h=h end
function P:SetTall(h) self.h=h end
function P:GetWide() return self.w or (self.parent and self.parent:GetWide()) or 0 end
function P:GetTall() return self.h or 0 end
function P:SetText(text) self.text=text end
function P:SetTextColor(c) self.color=c end
function P:SetFont(f) self.font=f end
function P:GetClassName() return self.class end
function P:Dock(mode) self.dock=mode end
function P:Remove() self.valid=false;for _,c in ipairs(self.children) do c:Remove() end end
P.SetTitle=noop;P.Center=noop;P.SetDraggable=noop;P.MakePopup=noop;P.DockMargin=noop
P.SetWrap=noop;P.SetContentAlignment=noop;P.ShowCloseButton=noop;P.IsHovered=function() return false end
P.IsEnabled=function() return true end
local focus
vgui={GetKeyboardFocus=function() return focus end,Create=function(class,parent)
 local v=setmetatable({valid=true,class=class,parent=parent,children={}},P)
 nodes[#nodes+1]=v;if parent then parent.children[#parent.children+1]=v end;return v
end}
local down,console,pause,quiz,cinematic=false,false,false,false,false
input={IsKeyDown=function(k) check(k==KEY_F3,'only requested function key polled');return down end}
gui={IsConsoleVisible=function() return console end,IsGameUIVisible=function() return pause end}
surface={CreateFont=noop,SetDrawColor=noop,DrawRect=noop,DrawOutlinedRect=noop}
draw={RoundedBox=noop,SimpleTextOutlined=function(text,...) texts[#texts+1]=text end}
hook={Add=function(_,id,fn) hooks[id]=fn end}
concommand={Add=function(id,fn) commands[id]=fn end}
RunConsoleCommand=function(...) sent[#sent+1]={...} end
Derma_Query=function(_,_,_,confirm) local v=vgui.Create('DFrame');v.accept=confirm;return v end
local ply={valid=true,nw={}}
function ply:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
function ply:GetNW2String(k,d) return self.nw[k] or d end
LocalPlayer=function() return ply end
LOD={ClientState={},Minigame={IsLocked=function() return quiz end},CampaignTimeout={IsCinematic=function() return cinematic end}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'cl_ui_theme.lua');dofile(root..'cl_soldier_queue_ui.lua')
local UI=LOD.SoldierQueueUI
local function reset(mode,context)
 UI:Close();UI.lastMode=nil;UI.pending=nil;UI.f3Down=nil;UI.chatOpen=false
 nodes={};sent={};texts={};down=false;console=false;pause=false;quiz=false;cinematic=false;focus=nil
 LOD.ClientState={};ply.valid=true
 ply.nw={LOD_TeamMenuContext=context or '1:1:1:'..mode,LOD_HeroQueue=mode=='spectator' and 'spectator' or 'hero',
  LOD_IsSoldier=mode=='soldier',LOD_SoldierWaiting=mode=='waiting',LOD_Eliminated=mode=='eliminated' or mode=='waiting'}
end
local function buttons()
 local a={};for _,v in ipairs(nodes) do if IsValid(v) and v.class=='DButton' then a[#a+1]=v end end;return a
end
local function think() hooks.LOD_SoldierQueueUIThink() end
local function key() down=false;think();down=true;think() end
for _,mode in ipairs({'soldier','waiting'}) do
 for _,size in ipairs({{640,360},{1280,720},{1920,1080}}) do
  width,height=size[1],size[2];reset(mode);think()
  check(not IsValid(UI.Panel),'Soldier never forced into modal')
  hooks.LOD_SoldierQueueHint();check(texts[#texts]:find('F3',1,true),'visible Soldier F3 hint')
  key();check(IsValid(UI.Panel),'F3 opens live/waiting Soldier')
  local frame=UI.Panel;local b=buttons()
  check(#b==2 and b[1].text=='RETURN TO HERO QUEUE' and b[2].text=='SPECTATE ONLY','Soldier has exactly two role choices')
  check(frame:GetWide()<=width-32 and frame:GetTall()<=height-32,'frame inside viewport')
  local scroll=false
  for _,v in ipairs(nodes) do
   if v.class=='DScrollPanel' then scroll=true;check(v:GetTall()>0,'scroll body has usable height') end
   if v.class=='DLabel' then check(v.color==LOD.UI.Colors.ink,'readable paper ink') end
  end
  check(scroll,'short screens scroll choices')
  b[1].DoClick();check(#sent==1 and sent[1][1]=='lod_return_to_hero_queue' and sent[1][2]==ply.nw.LOD_TeamMenuContext,'queue action binds exact context')
  check(not IsValid(UI.Panel),'successful request closes menu')
  think();think();check(not IsValid(UI.Panel),'held F3 does not reopen dismissed frame')
  key();b=buttons();b[2].DoClick();check(sent[2][1]=='lod_spectate_only','spectate-only has distinct server command')
 end
end
reset('spectator');key();local b=buttons();check(#b==1 and b[1].text=='RETURN TO HERO QUEUE','spectator can requeue')
UI:Close();hooks.LOD_SoldierQueueHint();check(texts[#texts]:find('SPECTATING ONLY',1,true),'explicit spectator hint')
reset('hero');think();key();check(not IsValid(UI.Panel),'ordinary Hero F3 does not gain role choices')
reset('eliminated');think();b=buttons()
check(#b==3 and b[1].text=='WAIT FOR RESURRECTION' and b[2].text=='BEGIN A NEW HERO' and b[3].text=='JOIN THE SOLDIERS','ordinary eliminated Hero trio preserved')
UI:Close();think();check(not IsValid(UI.Panel),'ordinary choices auto-open once, not every tick')
-- Context-less initialization does not lose the normal elimination prompt.
reset('eliminated','');think();check(not IsValid(UI.Panel),'wait for authoritative context')
ply.nw.LOD_TeamMenuContext='2:3:4:eliminated';think();check(IsValid(UI.Panel),'initial snapshot later opens pending choice')
for _,block in ipairs({'console','chat','text','binder','pause','quiz','tetris','failed','clear','cinematic'}) do
 reset('soldier')
 if block=='console' then console=true elseif block=='chat' then hooks.LOD_SoldierQueueChat();UI.chatOpen=true
 elseif block=='text' or block=='binder' then focus=vgui.Create(block=='text' and 'DTextEntry' or 'DBinder')
 elseif block=='pause' then pause=true elseif block=='quiz' then quiz=true elseif block=='tetris' then ply.nw.LOD_DeathTetrisActive=true
 elseif block=='failed' then LOD.ClientState.failed=true elseif block=='clear' then LOD.ClientState.levelCleared=true
 else cinematic=true end
 key();commands.lod_hero_choices();check(not IsValid(UI.Panel),'key/direct open honors '..block)
 console=false;UI.chatOpen=false;focus=nil;pause=false;quiz=false;ply.nw.LOD_DeathTetrisActive=false
 LOD.ClientState={};cinematic=false;think();check(not IsValid(UI.Panel),'blocked held press never activates later '..block)
end
for _,change in ipairs({'campaign','hero','life','role'}) do
 reset('soldier');key();local frame=UI.Panel;local action=buttons()[2]
 ply.nw.LOD_TeamMenuContext='changed:'..change;think()
 check(not IsValid(frame),'stale '..change..' frame retired')
 commands.lod_hero_choices();local fresh=UI.Panel;action.DoClick()
 check(#sent==0 and UI.Panel==fresh and IsValid(fresh),'stale callback cannot act or close replacement view')
end
reset('soldier');key();ply.nw.LOD_IsSoldier=false;ply.nw.LOD_HeroQueue='spectator';think()
check(not IsValid(UI.Panel),'role projection change closes old menu before context packet arrives')
reset('eliminated');think();b=buttons();b[2].DoClick();local confirm=UI.Confirm
check(IsValid(confirm) and #sent==0,'new Hero requires existing confirmation')
ply.nw.LOD_TeamMenuContext='new-life';think();confirm.accept()
check(#sent==0 and not IsValid(confirm),'stale new-Hero confirmation cannot discard replacement')
reset('eliminated');think();b=buttons();b[2].DoClick();UI.Confirm.accept()
check(#sent==1 and sent[1][1]=='lod_begin_new_hero','valid new-Hero confirmation retained')
reset('eliminated');think();buttons()[3].DoClick();check(sent[1][1]=='lod_join_human_soldier','ordinary join option retained')
reset('soldier');commands.lod_ui_return_to_hero_queue();check(sent[1][1]=='lod_return_to_hero_queue','legacy UI return uses same contextual path')
reset('soldier');key();quiz=true;think();hooks.LOD_SoldierQueueHint()
check(not IsValid(UI.Panel) and #texts==0,'minigame closes existing menu and suppresses hint')
print('SPOT15_UI_PASS '..checks..' actual-production assertions')
