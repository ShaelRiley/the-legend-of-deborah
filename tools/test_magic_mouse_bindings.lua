-- Production progression, cast resolver, selector and client input boundaries.
local fx=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local P,F=LOD.MagicProgression,LOD.MagicForms
local owner=fx.actor('mouse-hero');local state=owner.ps.progressionState
state.classId='wizard';state.magicFormIds={'bolt','beam','bomb','wall'};state.selectedMagicFormId='bolt'
state.magicBindings=nil
P:EnsureState(state);assert(state.magicBindings['2']=='bolt')
assert(P:BindForm(state,'beam',3) and P:BindForm(state,'bomb',4) and P:BindForm(state,'wall',5))
for key,id in pairs({['2']='bolt',['3']='beam',['4']='bomb',['5']='wall'}) do
 assert(state.magicBindings[key]==id)
 local _,form=F:SelectedCastState(owner,tonumber(key));assert(form.id==id)
end
assert(not P:BindForm(state,'missing',3) and not P:BindForm(state,'bolt',1))
assert(P:BindForm(state,'beam',2));assert(state.magicBindings['2']=='beam' and state.magicBindings['3']=='bolt','Rebind swaps occupied bindings')
assert(P:BindForm(state,'beam',4));assert(state.magicBindings['4']=='beam' and state.magicBindings['2']=='bomb')
local saved=table.Copy(state);P:EnsureState(saved)
assert(P:Snapshot(saved).bindings['5']=='wall' and saved.magicBindings['2']=='bomb','Character snapshot/reconnect retains bindings')
state.classId='fighter';P:EnsureState(state);assert(not state.magicBindings['5'],'Restricted forms lose bindings')
state.magicFormIds={'bolt'};state.selectedMagicFormId='bolt';P:EnsureState(state)
assert(P:BindForm(state,'bolt',5) and state.magicBindings['2']=='bolt' and not state.magicBindings['5'],'Single form always uses RMB')
local _,none=F:SelectedCastState(owner,5);assert(not none,'Unbound auxiliary button never falls back to RMB')
-- Real client input path: all four buttons, menu/chat/throwable and release latch.
MOUSE_LEFT,MOUSE_RIGHT,MOUSE_MIDDLE,MOUSE_4,MOUSE_5=107,108,109,110,111
IN_ATTACK,IN_ATTACK2=1,2
local hooks,receivers={},{};hook.Add=function(_,id,fn) hooks[id]=fn end
net.Receive=function(id,fn) receivers[id]=fn end
local sent={}
net.Start=function(channel) sent[#sent+1]={channel=channel} end
net.WriteUInt=function(value) sent[#sent].button=value end
net.SendToServer=function() end
Material=function() return {} end
LOD.MagicArea={Material={}};LocalPlayer=function() return owner end
owner.nw.LOD_PlayedIdentity=true
local held,covered,focus,throwable={},false,nil,false
input={IsMouseDown=function(key) return held[key] end}
gui={IsGameUIVisible=function() return false end,IsConsoleVisible=function() return false end}
vgui={CursorVisible=function() return covered end,GetKeyboardFocus=function() return focus end}
LOD.UI={};LOD.Spellbook={Snapshot={bindings={['2']='bolt',['3']='beam',['4']='bomb',['5']='wall'}}}
LOD.Equipment.IsActive=function() return throwable end
local cmd={down=false,KeyDown=function(self,key) return key==IN_ATTACK2 and self.down end,RemoveKey=function() end}
dofile(root..'cl_magic.lua')
local inputTick=hooks.LOD_MagicPredictedInput
inputTick(cmd);cmd.down=true;inputTick(cmd);inputTick(cmd);assert(#sent==1 and sent[1].button==2)
for n,key in ipairs({MOUSE_MIDDLE,MOUSE_4,MOUSE_5}) do held[key]=true;inputTick(cmd);assert(sent[#sent].button==n+2) end
assert(#sent==4);inputTick(cmd);assert(#sent==4,'Held keys do not repeat')
held={};cmd.down=false;inputTick(cmd);covered=true
held[MOUSE_MIDDLE]=true;cmd.down=true;inputTick(cmd);covered=false;inputTick(cmd)
assert(#sent==4,'A menu click cannot leak into casting when the menu closes')
held={};cmd.down=false;inputTick(cmd);throwable=true;held[MOUSE_4]=true;cmd.down=true;inputTick(cmd)
assert(#sent==4,'Throwable priority covers every magic binding')
throwable=false;held={};cmd.down=false;inputTick(cmd);focus={valid=true};cmd.down=true;inputTick(cmd);assert(#sent==4,'Text entry blocks casting')
assert(hooks.LOD_MagicAuxiliaryBindings(owner,'+zoom',true,MOUSE_4)==true)
-- Real selection buttons, including RMB and extra-button presses.
focus=nil;LOD.UI.Colors={};LOD.UI.CloseButton=function() end;LOD.UI.PageLinks=function() end
LOD.UI.SelectPage=function(self,page) self.ActivePage=page end
ScrW=function() return 1280 end;ScrH=function() return 800 end
surface={PlaySound=function() end};RealTime=CurTime
local nodes={};local panel={}
for _,name in ipairs({'SetPos','SetSize','SetText','SetEnabled','SetTitle','Center','MakePopup'}) do panel[name]=function() end end
panel.GetTall=function() return 590 end;panel.GetWide=function() return 1120 end
panel.Remove=function(self) self.valid=false end
vgui.Create=function(kind) local p=setmetatable({valid=true,kind=kind},{__index=panel});nodes[#nodes+1]=p;return p end
concommand={Add=function() end}
net.WriteString=function(value) sent[#sent].id=value end
dofile(root..'cl_spellbook.lua')
LOD.Spellbook.Snapshot={forms={{id='bolt',owned=true}},contents={},bindings={}}
LOD.Spellbook:Open();local button=nodes[#nodes]
button.DoClick();assert(sent[#sent].button==2)
button.DoRightClick();assert(sent[#sent].button==2)
for n,key in ipairs({MOUSE_MIDDLE,MOUSE_4,MOUSE_5}) do button:OnMousePressed(key);assert(sent[#sent].button==n+2 and sent[#sent].id=='bolt') end
print('MAGIC_MOUSE_BINDINGS_PASS: four authorities, rebind/swap/migration, ownership/class/one-form, snapshot roundtrip, button-specific cast state, actual selector and input suppression/release')
