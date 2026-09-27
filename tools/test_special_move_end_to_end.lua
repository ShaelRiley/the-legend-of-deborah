-- Real keyboard adapter -> queued wire tokens -> real receiver -> owned attacks.
-- Only native UI/input/net/physics boundaries are doubled; no private matcher.
local env=dofile('tools/test_fighting_streets.lua')
local E,p=LOD.Equipment,env.player
local receive,token
net.Receive=function(name,fn) if name=='LOD_SpecialMoveToken' then receive=fn end end
net.ReadUInt=function(bits) assert(bits==3);return token end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_equipment_moves.lua')
assert(receive)
local keys,queue,callbacks,vars={},{},{},{}
local busy=false
local client=setmetatable({
    KEY_0=1,KEY_LAST=106,KEY_UP=88,KEY_DOWN=90,KEY_LEFT=89,KEY_RIGHT=91,
    KEY_LBRACKET=53,KEY_COMMA=58,KEY_SEMICOLON=55,KEY_BACKSLASH=61,
    LocalPlayer=function() return p end,
    gui={IsGameUIVisible=function() return busy end,IsConsoleVisible=function() return false end},
    vgui={CursorVisible=function() return false end,GetKeyboardFocus=function() end},
    chat={IsTyping=function() return false end},input={IsKeyDown=function(k) return keys[k]==true end},
    hook={Add=function(_,id,fn) callbacks[id]=fn end},
    net={Start=function(name) assert(name=='LOD_SpecialMoveToken') end,
        WriteUInt=function(v,bits) assert(bits==3);queue[#queue+1]=v end,
        SendToServer=function() end,Receive=function() end},
    CreateClientConVar=function(name,default)
        vars[name]=tonumber(default);return {GetInt=function() return vars[name] end}
    end,
}, {__index=_G})
LOD.UI={Colors={}}
assert(loadfile('gamemodes/legend_of_deborah/gamemode/lod/cl_equipment_moves.lua','t',client))()
local poll=assert(callbacks.LOD_SpecialMoveKeyboard)
local function tap(key) keys[key]=true;poll();poll();keys[key]=nil;poll() end
local function flush()
    for _,v in ipairs(queue) do token=v;receive(3,p) end
    queue={}
end
local function reset() env.reset();keys={};poll();flush() end
-- Every event reaches the server at the same CurTime, including release/repress.
reset();tap(client.KEY_LEFT);tap(client.KEY_DOWN);tap(client.KEY_RIGHT)
assert(#queue==3,'Real edge detection must emit one token per press, not per held frame')
flush();local projectile=env.projectile()
assert(IsValid(projectile) and p.ps.magic==88,'Keyboard recipe must spawn the real paid Ember Fist projectile')
env.hit(env.enemy);env.advance(.05);projectile:Think()
assert(not IsValid(projectile) and env.enemy.hp<100 and env.ally.hp==100,'Real shared projectile impact, faction and damage')
reset();tap(client.KEY_RIGHT);tap(client.KEY_DOWN);tap(client.KEY_RIGHT);flush()
assert(p.ps.magic==82 and env.enemy.hp<100,'Cinder Rise from repeated RIGHT edges must reach shared area damage')
-- Mirrors are the same logical stream, not a second spell dispatcher.
reset();tap(client.KEY_SEMICOLON);tap(client.KEY_COMMA);tap(client.KEY_BACKSLASH);flush()
assert(IsValid(env.projectile()) and p.ps.magic==88,'Keyboard mirrors retain the attack path')
reset();tap(client.KEY_LEFT);busy=true;poll();tap(client.KEY_DOWN);busy=false;poll();tap(client.KEY_RIGHT);flush()
assert(p.ps.magic==100 and not IsValid(env.projectile()),'UI reset separates pre/post-menu inputs')
reset();tap(client.KEY_LEFT);tap(client.KEY_DOWN);tap(client.KEY_RIGHT)
E:UnequipItem(env.state,env.item.id);flush()
assert(p.ps.magic==100 and not IsValid(env.projectile()),'Queued client input cannot retain unequipped capability')
print('SPECIAL_MOVE_END_TO_END_PASS: real keyboard and mirrors, ordered coalesced wire delivery, actual paired-glove projectile/strike damage, one payment, menu and ownership cancellation')
