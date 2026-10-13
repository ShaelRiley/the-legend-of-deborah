-- Execute the production Derma construction and lifecycle. Pixel layout is native work.
local function noop() end
function IsValid(e) return type(e)=='table' and not e.removed end
function Color(...) return {...} end
function Vector(...) return {...} end
function Angle(...) return {...} end
TOP=1;KEY_E=2;KEY_ESCAPE=3;KEY_SPACE=4
local sw,sh=1280,800
function ScrW() return sw end
function ScrH() return sh end
surface={CreateFont=noop};hook={Add=noop}
local receivers={};net={Receive=function(id,fn) receivers[id]=fn end}
local guide={label='DUNGEON HERMIT',GetStageKind=function() return 1 end}
function guide:GetStageLabel() return self.label end
ents={FindByClass=function() return {guide} end}
local ply={alive=true,staged=true,deployed=false,Alive=function(self) return self.alive end}
function ply:GetNW2Bool(k) return k=='LOD_Staged' and self.staged or k=='LOD_Deployed' and self.deployed or false end
function LocalPlayer() return ply end
local panels={}
vgui={Create=function(kind,parent)
 local p={kind=kind,parent=parent,Entity={SetColor=noop,SetAngles=noop}}
 if parent then parent.children=parent.children or {};parent.children[#parent.children+1]=p end
 function p:SetSize(w,h) self.width=w;self.height=h end
 function p:SetPos(x,y) self.x=x;self.y=y end
 function p:SetText(v) self.text=v end
 function p:SetModel(v) self.model=v end
 function p:SetVisible(v) self.visible=v end
 function p:SetWrap(v) self.wrap=v end
 function p:SetAutoStretchVertical(v) self.autoStretch=v end
 function p:Dock(v) self.dock=v end
 p.SetTitle=noop;p.SetDraggable=noop;p.MakePopup=noop;p.SetFOV=noop;p.SetCamPos=noop
 p.SetLookAt=noop;p.SetFont=noop;p.SetTextColor=noop;p.DockMargin=noop
 function p:Remove() self.removed=true;if self.OnRemove then self.OnRemove() end end
 function p:Close() self:Remove() end
 panels[#panels+1]=p;return p
end}
LOD={Config={Models={Deborah='deborah-model'}}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_damsels.lua');dofile(root..'cl_damsels.lua')
local D=LOD.Damsels;D.ApplyAppearance=noop
local idleCalls=0
LOD.FriendlyIdle={Apply=function(_,ent,role,portrait)
 assert(ent and role=='hermit' and portrait==true);idleCalls=idleCalls+1
end}
for _,tail in ipairs({false,true}) do
 local queue={73,1,21};for _=1,20 do queue[#queue+1]=false end
 queue[#queue+1]=0;if tail then queue[#queue+1]=42 end
 local function read() assert(#queue>0);return table.remove(queue,1) end
 net.ReadUInt=read;net.ReadDouble=read;net.ReadBool=read
 net.BytesLeft=function() return #queue>0 and 4 or 0 end
 receivers.LOD_DamselState()
 assert(D.Campaign.epoch==(tail and 42 or 0) and #queue==0,'optional epoch tail packet handling')
end
D.Campaign={seed=73,epoch=1,level=1,rescued={}}
local body=string.rep('A long chapter with every control and clue. ',80)
local function show(level)
 panels={};D:ShowDialogue(level or 31,body,'separate actual receipt')
 local frame=D.DialogueFrame;local scroll,portrait,name
 for _,p in ipairs(panels) do
  if p.kind=='DScrollPanel' then scroll=p elseif p.kind=='DModelPanel' then portrait=p end
  if p.kind=='DLabel' and p.parent==frame then name=p end
 end
 assert(frame.width<=sw-32 and frame.height<=sh-32 and frame.x>=16 and frame.y>=16)
 assert(frame.x+frame.width<=sw-16 and frame.y+frame.height<=sh-16)
 assert(scroll and scroll.height>0 and #scroll.children==2)
 assert(scroll.children[1].text==body and scroll.children[1].wrap and scroll.children[1].autoStretch)
 assert(scroll.children[2].text=='separate actual receipt' and scroll.children[2].autoStretch)
 assert(scroll.children[1].height==nil,'long chapter forced into fixed label height')
 frame.Think();assert(not frame.removed)
 local before=idleCalls;portrait.LayoutEntity(portrait,portrait.Entity)
 assert(idleCalls==before+((level==nil or level==31 or level==30) and 1 or 0),'portrait idle admission changed')
 return frame,portrait,name
end
for _,screen in ipairs({{1280,800},{640,360},{480,320},{320,240}}) do
 sw,sh=screen[1],screen[2]
 local frame,portrait,name=show()
 assert(portrait.model=='models/player/monk.mdl' and name.text=='Dungeon Hermit')
 assert(portrait.visible==(sw-32>=560 and math.min(400,sh-32)>=270))
 frame.OnKeyCodePressed(frame,KEY_ESCAPE);assert(frame.removed and D.DialogueFrame==nil)
end
sw,sh=1280,800
local frame=show();D.Campaign.level=2;frame.Think();assert(frame.removed)
frame=show();D.Campaign.seed=74;frame.Think();assert(frame.removed)
frame=show();D.Campaign.epoch=2;frame.Think();assert(frame.removed,'same-seed campaign reset retained dialogue')
frame=show();ply.alive=false;frame.Think();assert(frame.removed);ply.alive=true
frame=show();ply.staged=false;frame.Think();assert(frame.removed);ply.staged=true
frame=show();ply.deployed=true;frame.Think();assert(frame.removed);ply.deployed=false
frame=show();guide.label='HECTOR THE DIRECTOR';frame.Think();assert(frame.removed,'pre-reveal guide remained open')
local portrait,name;frame,portrait,name=show(30);assert(name.text=='Hector the Director')
guide.removed=true;frame.Think();assert(frame.removed,'replaced guide retained its window');guide.removed=nil
frame,portrait,name=show(20);assert(name.text=='Deborah' and portrait.model=='deborah-model')
local old=frame;frame=show(0);assert(old.removed and D.DialogueFrame==frame)
-- Execute the real LayoutEntity -> FriendlyIdle path with a native client model
-- that has no scripted base_anim:SetAutomaticFrameAdvance method.
local _,nativePortrait=show()
local model=nativePortrait.Entity
function model:GetModel() return nativePortrait.model end
function model:EntIndex() return -1 end
function model:LookupSequence() return 7,2 end
function model:ResetSequence(id) self.sequence=id end
function model:GetSequence() return self.sequence end
function model:SetCycle(cycle) self.cycle=cycle end
function model:SetPlaybackRate(rate) self.rate=rate end
function model:LookupBone() return nil end
function model:GetFlexNum() return 0 end
local clock,frame=1,1
CurTime=function() return clock end;FrameNumber=function() return frame end
GetConVar=function() return nil end
angle_zero=Angle(0,0,0)
dofile(root..'cl_friendly_idle.lua')
assert(not model.SetAutomaticFrameAdvance)
nativePortrait.LayoutEntity(nativePortrait,model)
local first=model.cycle
clock=1.5;frame=2;nativePortrait.LayoutEntity(nativePortrait,model)
assert(model.AutomaticFrameAdvance==false and model.rate==0 and model.cycle~=first,
 'native client portrait failed to animate without scripted-only method')
print('STAGING_LORE_UI_PASS: complete scrolling and receipt; four screen bounds; speaker/model; Escape; lifecycle retirement; actual LayoutEntity -> FriendlyIdle client-model API and advancing cycle')
