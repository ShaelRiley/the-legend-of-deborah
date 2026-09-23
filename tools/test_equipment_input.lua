-- Execute the real client keyboard adapter with input/UI boundary doubles.
KEY_0,KEY_LAST=1,106
KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT=88,90,89,91
KEY_LBRACKET,KEY_COMMA,KEY_SEMICOLON,KEY_BACKSLASH=53,58,55,61
local held={}
local callbacks,convars,sent={}, {}, {}
function IsValid(x) return type(x)=='table' end
function CreateClientConVar(name,default)
    local cv={value=tonumber(default),GetInt=function(self) return self.value end};convars[name]=cv;return cv
end
local ply={Alive=function() return true end}
function LocalPlayer() return ply end
local menu,typing,focus,throwable=false,false,false,false
LOD={UI={Colors={}},Equipment={IsActive=function() return throwable end}}
gui={IsGameUIVisible=function() return menu end,IsConsoleVisible=function() return false end}
vgui={CursorVisible=function() return false end,GetKeyboardFocus=function() return focus and {} end}
chat={IsTyping=function() return typing end}
input={IsKeyDown=function(key) return held[key] or false end}
net={Start=function() end,WriteUInt=function(value) sent[#sent+1]=value end,SendToServer=function() end,Receive=function() end}
hook={Add=function(event,id,callback) callbacks[id]=callback end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_equipment_moves.lua')
local poll=callbacks.LOD_SpecialMoveKeyboard
poll();held[KEY_UP]=true;poll();poll();assert(#sent==1 and sent[1]==1,'Holding is not repetition')
held[KEY_UP]=nil;poll();held[KEY_LBRACKET]=true;poll();assert(sent[#sent]==1)
menu=true;poll();assert(sent[#sent]==0,'UI opening resets server recipe')
local n=#sent;held[KEY_LBRACKET]=nil;held[KEY_RIGHT]=true;poll();assert(#sent==n)
menu=false;poll();assert(#sent==n,'Held menu key must be released before reuse')
held={};poll();held[KEY_RIGHT]=true;poll();assert(sent[#sent]==4)
for _,mode in ipairs({'chat','focus','throwable'}) do
    typing,focus,throwable=mode=='chat',mode=='focus',mode=='throwable'
    poll();local before=#sent;held={};poll();held[KEY_DOWN]=true;poll();assert(#sent==before)
    typing,focus,throwable=false,false,false
end
held={};poll();held[150]=true;poll();local before=#sent
poll();assert(#sent==before,'Controller codes never enter logical stream')
held={};poll();held[KEY_DOWN],held[KEY_LEFT]=true,true;poll();assert(sent[#sent]==0,'Ambiguous simultaneous directions reset')
held={};poll();convars.lod_special_key_up.value=42;held[42]=true;poll();assert(sent[#sent]==1,'Rebinding feeds same stream')
print('EQUIPMENT_INPUT_PASS: real client edge detection, keyboard mirror/rebinding, menu/chat/focus/Throwable suppression, no controller tokens')

local deadline=12;CurTime=function() return 1 end
ply.GetNW2Float=function() return deadline end
ply.GetActiveWeapon=function() return nil end
assert(callbacks.LOD_VeilBody(ply)==true,'ordinary observer cannot draw cloaked body')
halo={RenderedEntity=function() return ply end}
assert(callbacks.LOD_VeilBody(ply)==nil,'authorized Sixth Sense halo mask remains drawable')
halo=nil;deadline=0
assert(callbacks.LOD_VeilBody(ply)==nil,'reveal restores normal body drawing')
print('VEIL_CLIENT_PASS: deadline concealment, authorized halo pass, normal draw restoration')
