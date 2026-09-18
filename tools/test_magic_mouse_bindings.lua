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
-- Native startup installs the Wizard feedback wrapper after the network receiver
-- and Forms dispatcher. Exercise that complete chain, including non-Wizards.
local serverReceivers={}
net.Receive=function(name,fn) serverReceivers[name]=fn end
dofile(root..'sv_magic.lua')
dofile(root..'sv_magic_forms.lua')
dofile(root..'sv_rpg_wizard_feedback.lua')
local W,M=LOD.RPGWizardOffense,LOD.Magic
assert(W:Install(),'Install the same cast wrapper used by the live server')
local requestButton,dispatched,raiseCast
net.ReadUInt=function(bits) assert(bits==3);return requestButton end
local receive=assert(serverReceivers.LOD_MagicCastRequest)
-- Only terminal world effects/placement are doubled; selection, wrapper,
-- ownership, cost, cooldown, context sealing and cast transaction remain real.
local endpoints={_CastWall='wall',_CastCone='cone',_CastBlast='blast',_CastBeam='beam',
 _CastSummon='summon',_SpawnProjectile='projectile'}
for method,kind in pairs(endpoints) do
 F[method]=function(_,ply,form,content,context)
  if raiseCast then error('mouse binding cast error') end
  dispatched={form=form.id,kind=kind,context=context,bonus=W:AttackSnapshotBonus(ply)}
  return true
 end
end
F.CanPlaceWall=function() return true end
F._SummonCount=function() return 0 end
F._SummonPlacement=function() return Vector() end
local allForms={};for id in pairs(LOD.RPG.MagicForms) do allForms[#allForms+1]=id end;table.sort(allForms)
local cases=0
for _,class in ipairs({'fighter','rogue','wizard'}) do
 state.classId=class;state.magicFormIds=table.Copy(allForms);state.contentIds={};state.selectedMagicContentId=nil
 state.derivedStats={intMod=3,wisMod=0};state.featIds={}
 state.selectedMagicFormId='bolt';state.magicBindings=nil;P:EnsureState(state)
 for _,id in ipairs(allForms) do
  if P:FormAllowed(state,id) then
   for button=3,5 do
    state.selectedMagicFormId=id=='bolt' and 'beam' or 'bolt';state.magicBindings=nil;P:EnsureState(state)
    assert(P:BindForm(state,id,button))
    owner.ps.magic=100;M.NextCast[owner]=0;dispatched=nil;requestButton=button
    receive(3,owner)
    assert(dispatched and dispatched.form==id,class..' M'..button..' must cast '..id..', not RMB')
    assert(dispatched.context.formId==id and dispatched.bonus==(class=='wizard' and 3 or 0))
    local cost=LOD.RPGAbilityRules:OffensiveMagicCost(owner,F:TotalBaseCost(LOD.RPG.MagicForms[id]))
    assert(owner.ps.magic==100-cost,'Charge the assigned Form cost')
    assert(W.ActiveFullMagicSnapshots[owner]==nil,'No leaked Wizard snapshot')
    dispatched=nil;receive(3,owner);assert(not dispatched,'Shared cooldown still rejects repeats')
    M.NextCast[owner]=0;owner.ps.magic=0;receive(3,owner);assert(not dispatched,'Insufficient Magic still rejects')
    cases=cases+1
   end
  end
 end
end
state.classId='wizard';state.magicFormIds=table.Copy(allForms);state.selectedMagicFormId='bolt';state.magicBindings=nil;P:EnsureState(state)
owner.ps.magic=100;M.NextCast[owner]=0;dispatched=nil;requestButton=5
receive(3,owner);assert(not dispatched and owner.ps.magic==100,'Unbound M5 cannot fall back through the wrapper')
for _,button in ipairs({0,1,6,7}) do requestButton=button;receive(3,owner);assert(not dispatched) end
requestButton=2;receive(9,owner);assert(not dispatched,'Oversized request rejected')
receive(3,owner);assert(dispatched.form=='bolt','Explicit RMB still casts its binding')
M.NextCast[owner]=0;owner.ps.magic=100;dispatched=nil
receive(0,owner);assert(dispatched.form=='bolt','Legacy request still defaults to RMB')
M.NextCast[owner]=0;owner.ps.magic=100;dispatched=nil
assert(M:CastForceShout(owner) and dispatched.form=='bolt','Buttonless developer calls retain selected Form')
M.NextCast[owner]=0;owner.ps.magic=100
local previous={marker=true};W.ActiveFullMagicSnapshots[owner]=previous;raiseCast=true
local ok,err=pcall(function() M:CastForceShout(owner,2) end)
assert(not ok and tostring(err):find('mouse binding cast error',1,true))
assert(W.ActiveFullMagicSnapshots[owner]==previous,'Error unwinding restores the preceding snapshot')
W.ActiveFullMagicSnapshots[owner]=nil;raiseCast=false
assert(M:CastForceShout({valid=false},5)==false,'Invalid caster still rejected')
print('MAGIC_MOUSE_SERVER_DISPATCH_PASS: '..cases..' class/Form/button casts through receiver and installed Wizard wrapper')
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
for n,key in ipairs({MOUSE_MIDDLE,MOUSE_4}) do held[key]=true;inputTick(cmd);assert(sent[#sent].button==n+2) end
held[MOUSE_5]=true;inputTick(cmd);assert(#sent==3 and LOD.MagicFX:WallAimActive()==5,'Wall press only arms its aiming guide')
inputTick(cmd);assert(#sent==3,'Holding never casts Wall')
held={};cmd.down=false;inputTick(cmd);assert(#sent==4 and sent[4].button==5 and not LOD.MagicFX:WallAimActive(),'Release casts once and hides guide')
inputTick(cmd);assert(#sent==4,'Release does not repeat')
covered=true;held[MOUSE_MIDDLE]=true;cmd.down=true;inputTick(cmd);covered=false;inputTick(cmd)
assert(#sent==4,'A menu click cannot leak into casting when the menu closes')
held={};cmd.down=false;inputTick(cmd);throwable=true;held[MOUSE_4]=true;cmd.down=true;inputTick(cmd)
assert(#sent==4,'Throwable priority covers every magic binding')
throwable=false;held={};cmd.down=false;inputTick(cmd);focus={valid=true};cmd.down=true;inputTick(cmd);assert(#sent==4,'Text entry blocks casting')
assert(hooks.LOD_MagicAuxiliaryBindings(owner,'+zoom',true,MOUSE_4)==true)
focus=nil;cmd.down=false;inputTick(cmd)
-- Repeat hold/release for every binding, and cancel every disruptive transition.
local keys={[3]=MOUSE_MIDDLE,[4]=MOUSE_4,[5]=MOUSE_5}
local function setDown(button,value) if button==2 then cmd.down=value else held[keys[button]]=value end end
for button=2,5 do
    LOD.Spellbook.Snapshot.bindings={[tostring(button)]='wall'}
    local before=#sent
    setDown(button,true);inputTick(cmd);assert(#sent==before and LOD.MagicFX:WallAimActive()==button)
    setDown(button,false);inputTick(cmd);assert(#sent==before+1 and sent[#sent].button==button and not LOD.MagicFX:WallAimActive())
    for _,cancel in ipairs({'menu','text','throwable','death','rebind','cleanup'}) do
        before=#sent;setDown(button,true);inputTick(cmd);assert(LOD.MagicFX:WallAimActive()==button)
        if cancel=='menu' then covered=true
        elseif cancel=='text' then focus={valid=true}
        elseif cancel=='throwable' then throwable=true
        elseif cancel=='death' then owner.hp=0
        elseif cancel=='rebind' then LOD.Spellbook.Snapshot.bindings[tostring(button)]='beam'
        else hooks.LOD_WallAimCancel() end
        inputTick(cmd);assert(not LOD.MagicFX:WallAimActive())
        covered=false;focus=nil;throwable=false;owner.hp=100
        LOD.Spellbook.Snapshot.bindings[tostring(button)]='wall'
        inputTick(cmd);setDown(button,false);inputTick(cmd);assert(#sent==before,'Cancelled gesture must not cast on release: '..cancel)
    end
end
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
