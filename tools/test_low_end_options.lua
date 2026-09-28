-- Execute the real Options UI with VGUI/convar boundaries doubled; no new
-- preference authority or engine graphics settings may be created/overwritten.
local panels,settings,locked={}, {lod_music_enabled=0,lod_reduced_effects=1},false
local width,height=1280,800
function ScrW() return width end;function ScrH() return height end
function IsValid(p) return type(p)=='table' and not p.removed end
input={LookupBinding=function(k) assert(k=='+speed');return 'lshift' end}
function GetConVar(k) return {GetBool=function() return settings[k]~=0 end} end
function CreateClientConVar() error('Options created another preference') end
function RunConsoleCommand() error('Opening Options overwrote a setting') end
LOD={PlayerOptions={},UI={Colors={ink={}}}}
local UI=LOD.UI
function UI:IsMinigameLocked() return locked end
function UI:SelectPage() end;function UI:Paper() end;function UI:CloseButton() end;function UI:PageLinks() end
vgui={Create=function(class,parent)
 local p={class=class,parent=parent,w=100,h=20,Label={SetTextColor=function() end}}
 function p:SetSize(w,h) self.w=w;self.h=h end
 function p:GetWide() return self.w end;function p:GetTall() return self.h end
 function p:SetPos(x,y) self.x=x;self.y=y end
 function p:SetText(t) self.text=t end;function p:SetConVar(c) self.convar=c end
 function p:Remove() self.removed=true;if self.OnRemove then self.OnRemove() end end
 for _,k in ipairs({'Center','SetTitle','MakePopup','SetFont','SetTextColor','SizeToContents','SetMinMax','SetDecimals'}) do p[k]=function() end end
 panels[#panels+1]=p;return p
end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_player_options.lua')
local O=LOD.PlayerOptions
for _,size in ipairs({{1280,800},{640,480}}) do
 width,height=size[1],size[2];panels={};O:Open();local frame=O.Frame
 assert(UI.ActivePage=='options' and frame.w<=width-32 and frame.h<=height-32)
 local counts={}
 for _,p in ipairs(panels) do
  if p.convar then counts[p.convar]=(counts[p.convar] or 0)+1 end
  if p.parent==frame and p.y then assert(p.y+p.h<=frame.h,'control clipped below frame') end
  if p.Think then p:Think();assert(p.text:find('Disabled by server',1,true));settings.lod_music_enabled=1;p:Think();assert(p.text:find('Music follows',1,true));settings.lod_music_enabled=0 end
 end
 for _,k in ipairs({'lod_music','lod_music_volume','lod_always_run','lod_reduced_effects'}) do assert(counts[k]==1,'missing/duplicate option '..k) end
 assert(settings.lod_reduced_effects==1,'saved reduced-effects preference changed')
 O:Close();assert(O.Frame==nil and UI.ActivePage==nil)
end
locked=true;panels={};O:Open();assert(#panels==0,'minigame UI lock bypassed')
print('LOW_END_OPTIONS_PASS: existing saved Reduced Effects binding; music/volume/run intact; 1280x800 and 640x480 bounds; no new settings or writes; minigame lock')
