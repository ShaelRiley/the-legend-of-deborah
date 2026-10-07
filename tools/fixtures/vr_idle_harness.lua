-- Exercise the installed overlay and real pinned addon lifecycle bodies.
-- Engine dispatch/timers/native module calls are doubled, never native FPS.
unpack=table.unpack
local addon=assert(arg[1])
local mode=assert(arg[2])
SERVER=mode=='server';CLIENT=not SERVER
local now,scans,nativeLoads,work=100,0,0,0
local hooks,timers,commands,receivers,settings={},{},{},{},{}
local noop=function() end
function isfunction(v) return type(v)=='function' end
function istable(v) return type(v)=='table' end
function isstring(v) return type(v)=='string' end
function IsValid(v) return type(v)=='table' and v.valid~=false end
function Color(...) return {...} end
color_white=Color(255,255,255)
FCVAR_ARCHIVE=1;FCVAR_REPLICATED=2;FCVAR_NOTIFY=4
SysTime=function() return now end;CurTime=SysTime
function tobool(v) return v=='1' or v==true end
local vectorMeta={}
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vectorMeta) end
vectorMeta.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vectorMeta.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
Angle=Vector
WorldToLocal=function(pos,ang,origin) return pos-origin,ang end
hook={GetTable=function() return hooks end,
    Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
    Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end}
function hook.Run(event,...)
    local copy={};for id,fn in pairs(hooks[event] or {}) do copy[#copy+1]={id,fn} end
    for _,entry in ipairs(copy) do
        if hooks[event][entry[1]]==entry[2] then
            local result=table.pack(entry[2](...))
            if result[1]~=nil then return unpack(result,1,result.n) end
        end
    end
end
hook.Call=function(event,gm,...) return hook.Run(event,...) end
timer={Create=function(id,delay,reps,fn) timers[id]={delay=delay,reps=reps,fn=fn,next=now+delay} end,
    Remove=function(id) timers[id]=nil end,Exists=function(id) return timers[id]~=nil end}
local function step(frames)
    for _=1,frames do
        now=now+0.025
        for _,event in ipairs({'Think','Tick','PreRender','RenderScene','HUDPaint',
                              'PrePlayerDraw','PlayerCanPickupItem'}) do
            -- Pickup callbacks require arguments and are tested separately.
            if event~='PlayerCanPickupItem' then hook.Run(event) end
        end
        local copy={};for id,t in pairs(timers) do copy[#copy+1]={id,t} end
        for _,entry in ipairs(copy) do
            local id,t=entry[1],entry[2]
            if timers[id]==t and now>=t.next then
                if t.reps>0 then t.reps=t.reps-1;if t.reps==0 then timers[id]=nil end end
                t.next=now+t.delay;t.fn()
            end
        end
    end
end
function CreateConVar(name,default)
    default=tostring(default)
    if settings[name] then return settings[name] end
    local cv={value=default,default=default}
    function cv:GetString() return self.value end
    function cv:GetBool() return self.value=='1' end
    function cv:GetInt() return tonumber(self.value) or 0 end
    function cv:GetDefault() return self.default end
    function cv:SetBool(v) self.value=v and '1' or '0' end
    function cv:SetString(v) self.value=v end
    function cv:Revert() self.value=self.default end
    settings[name]=cv;return cv
end
CreateClientConVar=CreateConVar;GetConVar=function(name) return settings[name] end
cvars={AddChangeCallback=noop,RemoveChangeCallback=noop}
system={IsLinux=function() return true end,IsWindows=function() return false end}
file={Exists=function() return false end,CreateDir=noop,Append=noop,Write=noop}
concommand={Add=function(name,fn) commands[name]=fn end}
local sent,readBooleans={},{}
net={Receive=function(name,fn) receivers[name]=fn end,ReadBool=function() return table.remove(readBooleans,1) end,
    Start=function(name) sent[#sent+1]=name end,WriteEntity=noop,WriteBool=noop,WriteString=noop,
    SendOmit=noop,Broadcast=noop,Send=noop,SendToServer=noop}
util={AddNetworkString=noop};engine={TickInterval=function() return 0.015 end}
game={SinglePlayer=function() return false end,GetMap=function() return 'gm_flatgrass' end}
local entityMeta={SetModel=noop}
local playerMeta={GetAimVector=function() return 'desktop-aim' end}
function FindMetaTable(name) return name=='Entity' and entityMeta or name=='Player' and playerMeta end
local function playerFixture(sid,id)
    local p={valid=true,sid=sid,id=id,nw={},alive=true}
    function p:SteamID() return self.sid end
    function p:EntIndex() return self.id end
    function p:IsPlayer() return true end
    function p:Alive() return self.alive end
    function p:GetNWBool(n) return self.nw[n] or false end
    function p:SetNWBool(n,v) self.nw[n]=v end
    p.DrawShadow=noop;p.GetViewOffset=function() return Vector() end
    p.SetViewOffset=noop;p.SetCurrentViewOffset=noop;p.Give=noop;p.SelectWeapon=noop
    p.GetModel=function() return 'models/player/kleiner.mdl' end
    p.GetActiveWeapon=function() return nil end;p.InVehicle=function() return false end
    return p
end
local p1,p2,desktop=playerFixture('STEAM_0:1:101',1),playerFixture('STEAM_0:0:102',2),playerFixture('STEAM_0:1:103',3)
player={GetAll=function() scans=scans+1;return {p1,p2,desktop} end,
    GetBySteamID=function(sid) for _,p in ipairs({p1,p2,desktop}) do if p.sid==sid then return p end end end}
LocalPlayer=function() return p1 end
gui={IsGameUIVisible=function() return false end};vgui={CursorVisible=function() return false end}
render={RenderView=noop};surface={};MsgC=noop
RunConsoleCommand=noop
local function include(path) return dofile(addon..'/lua/'..path) end
_G.include=include
AddCSLuaFile=noop
vrmod={status={}}
include('vrmod/lod_idle.lua')
local idle=vrmod.LODIdle
local originalHookAdd,originalHookRemove=hook.Add,hook.Remove
include('vrmod/api/sh_api.lua')
assert(hook.Add==originalHookAdd and hook.Remove==originalHookRemove,'addon translations must not wrap global hook registration')
include('vrmod/logger.lua')
include('vrmod/core/sh_startup.lua')
include('vrmod/player/sh_pmchange.lua')
if SERVER then
    include('vrmod/api/sv_api.lua')
    include('vrmod/pickup/sh_manualpickup.lua')
    -- Server half is byte-exact production code; unused GLua client continue
    -- syntax is excluded by the Python driver, not substituted in executed code.
    dofile(addon..'/server_network.lua')
    idle:FinishLoad();hook.Run('Initialize');hook.Run('InitPostEntity')
    local function join(p)
        readBooleans={false,false};receivers.vrutil_net_join(2,p)
    end
    local function exit(p) receivers.vrutil_net_exit(0,p) end
    assert(idle:Snapshot().idle and not timers.vrmod_logger_flush)
    assert(playerMeta.GetAimVector(p1)=='desktop-aim' and entityMeta.SetModel==noop)
    local baseline=scans
    step(2400);assert(scans==baseline,'idle server performed unused player scans')
    assert(not next(hooks.Think or {}),'idle server still dispatched a VR Think callback')
    join(p1);assert(idle.active and idle:PlayerCount()==1 and timers.vrmod_logger_flush)
    assert(hooks.Think.VRSwitchToEmptyWeapon and timers.VRModManualPickup_RespawnFixTimer)
    assert(entityMeta.SetModel~=noop,'first join restores model compatibility')
    step(120);assert(scans>baseline,'live VR must retain real server work')
    local item={GetClass=function() return 'item_healthkit' end}
    assert(hook.Run('PlayerCanPickupItem',p1,item)==false,'live VR pickup guard retained')
    assert(hook.Run('PlayerCanPickupItem',desktop,item)==true,'desktop teammate pickup retained')
    join(p2);join(p2);assert(idle:PlayerCount()==2,'duplicate join inflated presence')
    exit(p1);assert(idle.active and idle:PlayerCount()==1,'one exit suspended the remaining VR player')
    p2.valid=false;hook.Run('PlayerDisconnected',p2)
    assert(idle:Snapshot().idle and idle:PlayerCount()==0 and entityMeta.SetModel==noop)
    baseline=scans;step(2400);assert(scans==baseline and idle:Snapshot().idle,'disconnect left VR work running')
    p2.valid=true;join(p2);exit(p2);assert(idle:Snapshot().idle,'resume/last-exit did not return to idle')
    -- The real proxy lifecycle must retire native physics entities even if the
    -- disconnected player has already become invalid. No pose-loop trap runs.
    function __GLUA_CONTINUE_NOT_EXECUTED() error('unexpected GLua pose-loop execution') end
    dofile(addon..'/proxies_lua54.lua')
    local proxies={}
    ents={Create=function()
        local e={valid=true};proxies[#proxies+1]=e
        setmetatable(e,{__index=function() return noop end})
        function e:GetPhysicsObject() return nil end
        function e:Remove() self.valid=false end
        return e
    end}
    p2.GetMoveType=function() return 0 end;p2.GetPos=function() return Vector() end
    p2.Nick=function() return 'fixture' end
    join(p2)
    local queued={};for _,t in pairs(timers) do if t.delay==0 then queued[#queued+1]=t.fn end end
    for _,fn in ipairs(queued) do fn() end
    assert(#proxies==3,'actual VR proxy creation must remain available')
    assert(idle:Snapshot().resource_counts.physics_proxies==3,'native proxy ownership missing from diagnostics')
    p2.valid=false;hook.Run('PlayerDisconnected',p2)
    for _,proxy in ipairs(proxies) do assert(not proxy.valid,'disconnected VR owner left a native physics proxy') end
    step(40);assert(idle:Snapshot().idle,'proxy disconnect left deferred work')
    p2.valid=true;join(p2);exit(p2)
    queued={};for _,t in pairs(timers) do if t.delay==0 then queued[#queued+1]=t.fn end end
    for _,fn in ipairs(queued) do fn() end
    assert(#proxies==3,'queued proxy spawn recreated resources after the last exit')
    -- Actual pickup registration/drop/controller bodies, with only native entity
    -- and spatial-transform operations doubled. Dropped world props survive.
    settings.vrmod_collison_proxy:SetBool(false)
    scripted_ents={Register=noop}
    include('vrmod/utils/sh_pickup.lua')
    dofile(addon..'/server_pickup.lua')
    local controller,stopped,removed,attached=nil,0,0,{}
    ents.Create=function(class)
        assert(class=='vrmod_pickup')
        controller={valid=true,StartMotionController=noop}
        function controller:StopMotionController() stopped=stopped+1 end
        function controller:Remove() removed=removed+1;self.valid=false end
        function controller:AddToMotionController(phys) attached[phys]=true end
        function controller:RemoveFromMotionController(phys) attached[phys]=nil end
        return controller
    end
    local function hold(p,left,ragdoll)
        local ent={valid=true,picked=true,pos=Vector(),ang=Angle()}
        local phys={valid=true,Wake=noop,SetPos=noop,SetAngles=noop,SetVelocity=noop,SetAngleVelocity=noop}
        ent.GetClass=function() return ragdoll and 'prop_ragdoll' or 'prop_physics' end
        if ragdoll then ent.original_npc={valid=true} end
        ent.Remove=function(self) self.valid=false end
        ent.GetPhysicsObject=function() return phys end
        ent.GetCollisionGroup=function() return 0 end
        ent.GetPos=function(self) return self.pos end;ent.GetAngles=function(self) return self.ang end
        ent.SetPos=function(self,v) self.pos=v end;ent.SetAngles=function(self,v) self.ang=v end
        ent.NearestPoint=function(self) return self.pos end
        local activeController=vrmod.utils.InitPickupController()
        local info=vrmod.utils.CreatePickupInfo(p,left,ent,Vector(1,2,3),Angle())
        vrmod.utils.AttachPhysicsToController(info,activeController)
        return ent,phys
    end
    join(p1);join(p2)
    local left,lphys=hold(p1,true)
    local right,rphys=hold(p1,false)
    local remaining,lastphys=hold(p2,true)
    local state=idle:Snapshot()
    assert(state.resource_counts.held_props==3 and state.resource_counts.motion_controllers==1)
    exit(p1)
    assert(not attached[lphys] and not attached[rphys] and attached[lastphys])
    assert(not left.picked and not right.picked and left.valid and right.valid,'exit destroyed ordinary dropped props')
    assert(controller.valid and stopped==0 and idle:PlayerCount()==1,'one exit retired another player\'s held physics')
    -- The engine lookup may no longer find an invalid disconnect entity. Run the
    -- actual upstream callback first to prove both disconnect callback orders.
    local lookup=player.GetBySteamID
    p2.valid=false;player.GetBySteamID=function(sid) if sid~=p2.sid then return lookup(sid) end end
    hooks.PlayerDisconnected.vrutil_hook_playerdisconnected(p2)
    hook.Run('PlayerDisconnected',p2);player.GetBySteamID=lookup
    assert(stopped==1 and removed==1 and not controller.valid and not next(attached))
    assert(remaining.valid and not remaining.picked,'disconnect destroyed a dropped world prop')
    state=idle:Snapshot()
    assert(state.native_resources==0 and state.idle,'last exit left a native VR motion controller')
    local idleScans=scans;step(80);assert(scans==idleScans and idle:Snapshot().idle)
    p2.valid=true
    -- Native ragdoll bone operations are an engine boundary. Its real drop body
    -- owns a finite world-object deletion that must survive an intervening join.
    vrmod.utils.CacheBoneMasses=noop;vrmod.utils.SetBoneMass=noop
    vrmod.utils.IsRagdollDead=function() return false end
    join(p1);local rag=hold(p1,true,true);exit(p1)
    assert(rag.valid and idle:Snapshot().pending_once>0 and not idle:Snapshot().idle)
    join(p2);exit(p2)
    assert(rag.valid and idle:Snapshot().pending_once==1,'new VR lifetime cancelled dropped NPC cleanup')
    step(160);assert(not rag.valid and idle:Snapshot().idle,'finite dropped NPC cleanup did not finish')
    print('VR_IDLE_SERVER_PASS 4800 idle frames: zero player scans; real join/rejoin/mixed pickup/invalid disconnect/reactivation; all proxies and held motion controllers retired')
else
    -- SWEP registration uses the same scoped gate, without a global draw hook.
    SWEP={Primary={},Secondary={}}
    include('weapons/weapon_vrmod_empty.lua')
    assert(not (hooks.PrePlayerDraw and hooks.PrePlayerDraw.LockMyPlayerColor))
    include('vrmod/utils/sh_system.lua')
    assert(idle:Snapshot().idle)
    local original={fn=function() return 'desktop' end}
    local plain=original.fn
    local vrfn=function() work=work+1 end
    idle:Binding(original,'fn',plain,vrfn)
    assert(original.fn==plain)
    idle.Hook.Add('Think','vr_fixture',vrfn)
    idle.Timer.Simple(0,function() work=work+1 end)
    local startCalls,shutdowns=0,0
    VRUtilClientStart=function() startCalls=startCalls+1;g_VR.active=true;return nil,'started',nil end
    VRUtilClientExit=function() shutdowns=shutdowns+1;g_VR.active=false;return false,'stopped',nil end
    idle:FinishLoad()
    local before=work;step(2400);assert(work==before and idle:Snapshot().idle)
    g_VR.net={[p2.sid]={}}
    idle.Hook.Run('VRMod_Start',p2);assert(idle.active and nativeLoads==0 and original.fn==vrfn)
    step(20);assert(work>before,'remote avatar support must resume on presence')
    g_VR.net[p2.sid]=nil;idle.Hook.Run('VRMod_Exit',p2,p2.sid)
    before=work;step(2400);assert(work==before and idle:Snapshot().idle and original.fn==plain)
    local result=table.pack(VRUtilClientStart())
    assert(result.n==3 and result[1]==nil and result[2]=='started' and result[3]==nil)
    g_VR.net[p1.sid]={};g_VR.net[p1.sid]=nil
    idle.Hook.Run('VRMod_Exit',p1,p1.sid)
    assert(idle.active,'death/respawn registration gap must not disable local tracking or Tetris')
    result=table.pack(VRUtilClientExit())
    assert(result.n==3 and result[1]==false and result[2]=='stopped' and result[3]==nil)
    assert(idle:Snapshot().idle and startCalls==1 and shutdowns==1)
    -- Real native core: no eager load; explicit failed startup must settle idle.
    vrmod.LoadNativeModule=function() nativeLoads=nativeLoads+1;return false end
    function __GLUA_CONTINUE_NOT_EXECUTED() error('unexpected GLua pose-loop execution') end
    dofile(addon..'/core_lua54.lua')
    vrmod.GetStartupError=function() return 'headset unavailable fixture' end
    idle:FinishLoad()
    assert(nativeLoads==0,'ordinary client loaded a headset native module')
    VRUtilClientStart();assert(nativeLoads==1 and idle:Snapshot().idle,'failed native startup left background work')
    commands.vrmod_start(nil,nil,{})
    assert(timers.vrmod_start and timers.vrmod_start.reps==1,'start cursor wait must be finite')
    commands.vrmod_exit();assert(not timers.vrmod_start and idle:Snapshot().idle,'cancelled pending start leaked activation')
    -- A newer owner must survive suspension of a shared method.
    g_VR.net[p2.sid]={};idle.Hook.Run('VRMod_Start',p2)
    local newer=function() return 'newer' end;original.fn=newer
    g_VR.net[p2.sid]=nil;idle.Hook.Run('VRMod_Exit',p2)
    assert(original.fn==newer and idle:Snapshot().idle)
    -- Temporary third-party-hook suppression restores the exact original owner.
    local stock=function() return 'stock-halos' end
    hook.Add('PostDrawEffects','RenderHalos',stock)
    g_VR.net[p2.sid]={};idle.Hook.Run('VRMod_Start',p2)
    idle.Hook.Remove('PostDrawEffects','RenderHalos')
    assert(not hooks.PostDrawEffects.RenderHalos)
    g_VR.net[p2.sid]=nil;idle.Hook.Run('VRMod_Exit',p2)
    assert(hooks.PostDrawEffects.RenderHalos==stock)
    local cleanups=0
    idle.Hook.Add('VRMod_Exit','VRRestoreFixture',function()
        idle.Timer.Simple(0.1,function() cleanups=cleanups+1 end)
    end)
    g_VR.net[p2.sid]={};idle.Hook.Run('VRMod_Start',p2)
    g_VR.net[p2.sid]=nil;idle.Hook.Run('VRMod_Exit',p2)
    assert(not idle:Snapshot().idle and idle:Snapshot().pending_once==1,'finite teardown must remain visible until settled')
    step(20);assert(cleanups==1 and idle:Snapshot().idle)
    g_VR.net[p2.sid]={};idle.Hook.Run('VRMod_Start',p2)
    g_VR.net[p2.sid]=nil;idle.Hook.Run('VRMod_Exit',p2)
    g_VR.net[p2.sid]={};idle.Hook.Run('VRMod_Start',p2);step(20)
    assert(cleanups==1,'stale exit cleanup ran in a new VR lifetime')
    print('VR_IDLE_CLIENT_PASS 4800 idle frames: zero VR callbacks/timers; remote presence, local tracking gap, return parity, native deferral, failed/cancelled starts')
end
