-- Execute production VR and desktop lifecycle paths with engine boundaries doubled.
CLIENT=true;SERVER=false
local root="gamemodes/legend_of_deborah/gamemode/lod/"
local hooks,receivers,commands,messages,settings,menus={},{},{},{},{},{}
local now,covered,focus=100,false,false
local serverReady,missingChannel,missingContent=true,nil,nil
function GetGlobalBool() return serverReady end
function GetGlobalString() return 'fixture-revision' end
function SetGlobalBool(_,v) serverReady=v end
function SetGlobalString() end
function isfunction(v) return type(v)=='function' end
local noop=function() end
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
    Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end,
    GetTable=function() return hooks end}
net={Receive=function(name,fn) receivers[name]=fn end,
    Start=function(name) messages[#messages+1]={name=name} end,
    WriteUInt=function(value,bits) local m=messages[#messages];m.value=value;m.bits=bits end,
    SendToServer=noop}
function Color() return {} end
surface={CreateFont=noop}
function IsValid(v) return type(v)=="table" and v.valid==true end
function CurTime() return now end
gui={IsGameUIVisible=function() return covered end,IsConsoleVisible=function() return false end}
vgui={CursorVisible=function() return false end,GetKeyboardFocus=function() return nil end}
input={IsKeyDown=function() return false end}
chat={IsTyping=function() return false end}
concommand={Add=function(name,fn) commands[name]=fn end}
util={NetworkStringToID=function(name) return name==missingChannel and 0 or 1 end}
file={Exists=function(name) return name~=missingContent end}
local downloads={}
resource={AddSingleFile=function(name) downloads[#downloads+1]=name end}
local nativeCommands={}
function RunConsoleCommand(name) nativeCommands[#nativeCommands+1]=name end
local ply={valid=true,alive=true,played=true,eliminated=false,interactive=true,remaining=20}
function ply:Alive() return self.alive end
function ply:GetNW2Bool(name)
    return ({LOD_PlayedIdentity=self.played,LOD_Eliminated=self.eliminated,
        LOD_DeathInteraction=self.interactive})[name]
end
function ply:GetNW2Float() return self.remaining end
function LocalPlayer() return ply end
function GetConVar(name) return settings[name] end
local function setting(value)
    return {value=value,GetString=function(self) return self.value end,
        SetString=function(self,v) self.value=v end}
end
settings.vrmod_hud=setting("0");settings.vrmod_hud_engine=setting("0")
LOD={UI={IsMinigameLocked=function() return false end},Tetris={}}
local toggles=0
LOD.CharacterSheet={Toggle=function() toggles=toggles+1 end}
local cinematic=false
LOD.CampaignTimeout={IsCinematic=function() return cinematic end,
    RequestRestart=function() return false end}
LOD.RequestCampaignRestart=function() return true end
dofile(root.."sh_vr.lua")
assert(not LOD.VR:IsActive(ply),"desktop works without VRMod installed")
dofile(root.."cl_tetris.lua");dofile(root.."cl_intermission_tetris.lua");dofile(root.."cl_vr.lua")
hooks.InitPostEntity.LOD_VRMenu()
local function vrInput(action,state)
    local fn=hooks.VRMod_Input and hooks.VRMod_Input.LOD_VRInput
    if fn then fn(action,state) end
end
local function stick(x,y)
    g_VR.input.vector2_walkdirection={x=x,y=y};hooks.Think.LOD_VRTetrisStick()
end
vrInput("boolean_menucontext",true);assert(toggles==0)
assert(not (hooks.Think and hooks.Think.LOD_VRTetrisStick),"no adapter Think dispatch while desktop-only")
assert(#menus==0,"VR quick menu is registered only on local activation")
vrmod={IsPlayerInVR=function(p) return p==ply end,
    AddInGameMenuItem=function(name,slot,pos,fn) menus[#menus+1]={name=name,fn=fn} end}
g_VR={active=true,input={},menuFocus=false}
hooks.VRMod_Start.LOD_VRStart(ply)
hooks.VRMod_Start.LOD_VRStart(ply)
local expectedMenus={['Deborah Player Menu']=true,['Deborah: Pay respects / Tetris']=true,
    ['Deborah Team Menu']=true,['Deborah Map']=true,['Deborah GPS']=true}
assert(#menus==5,"restarting VR must not duplicate the five retained quick-menu entries")
for _,entry in ipairs(menus) do
    assert(expectedMenus[entry.name],"retired Haste toggle or duplicate/unexpected quick-menu entry")
    expectedMenus[entry.name]=nil
end
assert(next(expectedMenus)==nil,"all retained quick-menu actions must remain available")
assert(settings.vrmod_hud.value=="1" and settings.vrmod_hud_engine.value=="1","gamemode HUD captured")
vrInput("boolean_menucontext",true);assert(toggles==1)
assert(hooks.VRMod_AllowDefaultAction.LOD_VRDefaultActions("boolean_menucontext")==false)
assert(hooks.VRMod_AllowDefaultAction.LOD_VRDefaultActions("boolean_primaryfire")==nil,
    "ordinary tracked weapons retain VRMod's input")
cinematic=true;vrInput("boolean_menucontext",true);assert(toggles==1);cinematic=false

ply.alive=false
vrInput("boolean_use",true)
assert(messages[#messages].name=="LOD_DeathTetrisAction" and messages[#messages].value==1)
local before=#messages
vrInput("boolean_primaryfire",true);assert(#messages==before,"mandatory wait cannot be bypassed")
local death=LOD.TetrisClient
death.active=true
stick(0,0);stick(-1,0);stick(-1,0)
assert(#messages==before+1 and messages[#messages].name=="LOD_TetrisInput" and messages[#messages].value==1)
stick(0,1);assert(#messages==before+1,"diagonal excursions are one press until centered")
stick(0,0);stick(0,1);assert(messages[#messages].value==3)
vrInput("boolean_jump",true);assert(messages[#messages].value==5)
before=#messages;covered=true;stick(0,0);stick(1,0);vrInput("boolean_jump",true)
covered=false;stick(1,0);assert(#messages==before,"closing UI while held does not issue a token")
stick(0,0);stick(1,0);assert(messages[#messages].value==2)
death.gameOver=true;before=#messages;stick(0,0);stick(0,-1);assert(#messages==before)
death.gameOver=false;ply.remaining=0
vrInput("boolean_use",true);assert(messages[#messages].value==2,"active Tetris uses contextual respawn")
death.active=false;before=#messages
vrInput("boolean_primaryfire",true);assert(#messages==before+1 and messages[#messages].value==2)
ply.eliminated=true;before=#messages;vrInput("boolean_use",true);vrInput("boolean_primaryfire",true)
assert(#messages==before,"eliminated Hero cannot respawn")
ply.eliminated=false;ply.alive=true
local victory=LOD.IntermissionTetrisClient
victory.available=true
vrInput("boolean_use",true);assert(messages[#messages].name=="LOD_IntermissionTetrisAction")
victory.active=true;stick(0,0);stick(0,-1)
assert(messages[#messages].name=="LOD_IntermissionTetrisInput" and messages[#messages].value==4)
before=#messages;vrInput("boolean_use",true);assert(#messages==before,"starting twice is suppressed")
LOD.UI.ActivePage="sheet";before=#messages;stick(0,0);stick(-1,0);vrInput("boolean_use",true)
assert(#messages==before);LOD.UI.ActivePage=nil
hooks.VRMod_Exit.LOD_VRExit(ply)
assert(settings.vrmod_hud.value=="0" and settings.vrmod_hud_engine.value=="0","saved HUD preferences restored")
g_VR.active=false;before=#messages;vrInput("boolean_use",true);assert(#messages==before)
assert(not hooks.Think.LOD_VRTetrisStick and not hooks.VRMod_Input.LOD_VRInput
    and not hooks.VRMod_AllowDefaultAction.LOD_VRDefaultActions,"exit removes all local adapter runtime hooks")
hooks.VRMod_Start.LOD_VRStart(ply)
assert(hooks.Think.LOD_VRTetrisStick and #menus==5,"restart restores adapter work without duplicate menus")
hooks.VRMod_Exit.LOD_VRExit(ply)

-- Mounted-byte proof is finite and cached; no idle polling/hash loop exists.
local readCount=0
local proof={'deborah-vr-idle-20261007 139'}
for i=1,139 do proof[#proof+1]=string.rep('a',64)..'  lua/vrmod/fixture'..i..'.lua' end
for _,name in ipairs({'sh_vr.lua','cl_vr.lua'}) do
    proof[#proof+1]='bridge '..string.rep('a',64)..'  '..root..name
end
local badByte=false
file.Read=function(path,realm)
    readCount=readCount+1
    if realm=='DATA' then return table.concat(proof,'\n')..'\n' end
    return badByte and path:find('fixture1.lua',1,true) and 'bad' or 'exact'
end
util.SHA256=function(bytes) return string.rep(bytes=='exact' and 'a' or 'b',64) end
vrmod.LODIdle={version=LOD.VR.IdleRevision,Snapshot=function()
    return {idle=true,players=0,runtime_hooks=0,recurring_timers=0,pending_once=0,method_overrides=0}
end}
local work=LOD.VR:WorkState()
assert(work.idle and work.source.verified and work.source.checked==139 and work.source.bridge_checked==2)
assert(readCount==142,'every mounted runtime and bridge byte must be checked exactly once')
LOD.VR:WorkState();assert(readCount==142,'status repeated source hashing')
badByte=true;LOD.VR.SourceIdentity=nil
assert(not LOD.VR:WorkState().source.verified,'mismatched mounted addon cannot certify idle source')
badByte=false;LOD.VR.SourceIdentity=nil

-- Client start refuses partial/server-missing setups and reports module errors
-- before making any native session request. A ready setup uses VRMod's real entry.
local loaded=0
vrmod.LoadNativeModule=function() loaded=loaded+1 end
vrmod.GetStartupError=function() return 'module load error fixture' end
missingChannel='vrutil_net_tick';commands.lod_vr_start();assert(loaded==0 and #nativeCommands==0)
missingChannel=nil;serverReady=false;commands.lod_vr_start();assert(loaded==0)
serverReady=true;commands.lod_vr_start();assert(loaded==1 and #nativeCommands==0)
vrmod.GetStartupError=function() return nil end
commands.lod_vr_start();assert(loaded==2 and nativeCommands[1]=='vrmod_start')
g_VR.active=true;commands.lod_vr_start();assert(loaded==2);g_VR.active=false

-- The exposed action seam preserves ordinary desktop binds and F semantics.
ply.alive=false;ply.remaining=0;victory.active=false
hooks.PlayerBindPress.LOD_DeathPlainRespawnInput(ply,"+attack",true)
assert(messages[#messages].name=="LOD_DeathTetrisAction" and messages[#messages].value==2)
ply.remaining=20;before=#messages
hooks.PlayerBindPress.LOD_DeathPlainRespawnInput(ply,"+attack",true);assert(#messages==before)
input.IsKeyDown=function() return true end
hooks.Think.LOD_DeathTetrisFInput();assert(messages[#messages].value==1)

-- Server detection/policy neither requires the addon nor affects non-VR clients.
CLIENT=false;SERVER=true;dofile(root.."sh_vr.lua")
assert(LOD.VR:IsActive(ply));assert(not LOD.VR:IsActive(nil))
local swap,tp=true,true
settings.vrmod_weapon_swap={SetBool=function(_,v) swap=v end}
settings.vrmod_allow_teleport={SetBool=function(_,v) tp=v end}
hooks.Initialize.LOD_VRGameplayPolicy();assert(not swap and not tp)
vrmod.NetReceiveLimited=noop;vrmod.GetHMDPose=noop;vrmod.GetLeftHandPose=noop;vrmod.GetRightHandPose=noop
vrmod.LODIdle={version=LOD.VR.IdleRevision}
swap=true;tp=true -- Late addon/config initialization must not undo the policy.
hooks.InitPostEntity.LOD_VRServerStartup()
assert(serverReady and #downloads==11,'server startup proves all channels/APIs/content and distributes every asset')
assert(not swap and not tp,'final map startup reapplies weapon/teleport policy after addon initialization')
missingChannel='vrutil_net_join';hooks.InitPostEntity.LOD_VRServerStartup()
assert(not serverReady and #downloads==11,'missing networking must not pass server readiness')
missingChannel=nil;missingContent='models/player/vr_hands.mdl'
hooks.InitPostEntity.LOD_VRServerStartup();assert(not serverReady)
missingContent=nil;vrmod.GetHMDPose=nil
assert(not LOD.VR:ServerReady(),'a pooled join string alone does not prove loaded server runtime')
vrmod=nil;assert(not LOD.VR:IsActive(ply))
print("PASS VR: server readiness/assets, client start guards, HUD, menus, controller Tetris, life guards and desktop regressions")
