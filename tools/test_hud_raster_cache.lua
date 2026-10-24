-- Real UI/feed with native drawing doubles. This checks command/state parity,
-- invalidation, bounded ownership and error cleanup, never native FPS or pixels.
local root="gamemodes/legend_of_deborah/gamemode/lod/"
local frame,font,tx,ty=1,"?",0,0
local color={r=1,g=2,b=3,a=4}
local screen,target,stack,material={},nil,{},nil
local depth,clipped,blend,alphaWrite=0,false,false,false
local textures,uniqueTextures,draws,scale={},0,0,1
local failText=false
LOD={CombatRollFeed={entries={}}}
TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT=0,1,2
TEXT_ALIGN_TOP,TEXT_ALIGN_BOTTOM=3,4
RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,IMAGE_FORMAT_RGBA8888=0,0,0
BLEND_ZERO,BLEND_ONE,BLEND_SRC_ALPHA,BLEND_ONE_MINUS_SRC_ALPHA,BLENDFUNC_ADD=0,1,2,3,4
bit={bor=function()return 13 end}
function Color(r,g,b,a)return {r=math.min(tonumber(r),255),g=math.min(tonumber(g),255),b=math.min(tonumber(b),255),a=math.min(tonumber(a or 255),255)}end
function CurTime()return 100 end
function FrameNumber()return frame end
function ScrW()return 1280 end
function ScrH()return 800 end
function math.Clamp(n,lo,hi)return math.max(lo,math.min(hi,n))end
local hooks={}
hook={Add=function(event,id,fn)hooks[event]=hooks[event]or{};hooks[event][id]=fn end}
concommand={Add=function()end}
function DisableClipping(value)local old=clipped;clipped=value;return old end
local function width(text)
    local n=0;for _ in text:gmatch("[%z\1-\127\194-\244][\128-\191]*")do n=n+7 end
    local _,av=text:gsub("AV","");return (n-av*2)*scale,17*scale
end
surface={CreateFont=function()end,SetFont=function(value)font=value end,
    GetTextSize=width,SetTextPos=function(x,y)tx,ty=x,y end,
    GetTextPos=function()return tx,ty end,
    SetTextColor=function(r,g,b,a)color={r=r,g=g,b=b,a=a or 255}end,
    GetTextColor=function()return color end,
    SetDrawColor=function()end,DrawRect=function()end,SetMaterial=function(value)material=value end,
    DrawCircle=function()end,DrawLine=function()end}
function surface.DrawText(text)
    if failText then error("native text failure")end
    draws=draws+1
    local events=target and target.events or screen
    events[#events+1]={text,font,tx,ty,color.r,color.g,color.b,color.a}
    tx=tx+width(text)
end
function surface.DrawTexturedRectUV(x,y,w,h)
    assert(w<=1024 and h<=256,"oversized raster submitted")
    for _,event in ipairs(material.texture.events)do
        local row={};for i,v in ipairs(event)do row[i]=v end
        row[3],row[4]=row[3]+x,row[4]+y;screen[#screen+1]=row
    end
end
function GetRenderTargetEx(name,w,h)
    if not textures[name]then
        uniqueTextures=uniqueTextures+1
        textures[name]={name=name,events={},GetName=function(self)return self.name end,
            Width=function()return w end,Height=function()return h end}
    end
    return textures[name]
end
function CreateMaterial(_,_,params)return {texture=textures[params["$basetexture"]]}end
render={PushRenderTarget=function(value)stack[#stack+1]=target or false;target=value end,
    PopRenderTarget=function()target=table.remove(stack);if target==false then target=nil end end,
    Clear=function()target.events={}end,
    OverrideBlend=function(value)blend=value end,
    OverrideAlphaWriteEnable=function(value)alphaWrite=value end}
cam={Start2D=function()depth=depth+1 end,End2D=function()depth=depth-1 end}
draw={SimpleText=function()error("non-HUD drawing unexpected in raster test")end}
dofile(root.."cl_ui_theme.lua")
dofile(root.."cl_combat_roll_feed_semantics.lua")
local feed,cache=LOD.CombatRollFeed,LOD.CombatRollFeed.HUDRasterCache
local function fire(event)for _,fn in pairs(hooks[event]or{})do fn()end end
local function equal(a,b,label)
    if type(a)~="table"or type(b)~="table"then assert(a==b,label);return end
    for k,v in pairs(a)do equal(v,b[k],label.."/"..tostring(k))end
    for k in pairs(b)do assert(a[k]~=nil,label.."/extra")end
end
local cases=0
local function compare(lines,x,y,alpha,first,last)
    screen={};feed:DrawLines(lines,x,y,alpha,first,last,true)
    local expected=screen
    local expectedState={font,tx,ty,color.r,color.g,color.b,color.a}
    screen={};frame=frame+1;local before=draws
    cache:Draw(lines,x,y,alpha,first,last)
    equal(screen,expected,"raster commands")
    equal({font,tx,ty,color.r,color.g,color.b,color.a},expectedState,"native text end state")
    assert(not target and #stack==0 and depth==0 and not blend and not alphaWrite and not clipped,"render state leaked")
    cases=cases+1;return draws-before
end
local lines={{{text="AV café → 龍 ",role="identity"},{text="27 DAMAGE",role="damage"}},{{text="+15 HP",role="resource"}}}
fire("InitPostEntity");assert(uniqueTextures==6)
assert(compare(lines,19.8,21.4,255,1,2)>0)
assert(compare(lines,19.8,21.4,255,1,2)==0,"warm cache submitted native glyphs")
for _,alpha in ipairs({0,.5,127.75,254,256})do assert(compare(lines,19.8,21.4,alpha,1,2)>0)end
local beforeReentry=cache.builds
frame=frame+1;cache:Draw(lines,19.8,21.4,255,1,2)
assert(cache.builds==beforeReentry+1,"fade reentry did not refresh metadata")
assert(compare(lines,19.8,21.4,255,1,2)==0)
lines[1][1].text="Immediate replacement → "
assert(compare(lines,19.8,21.4,255,1,2)>0)
LOD.UI.HUDRoles.identity.r=90
assert(compare(lines,19.8,21.4,255,1,2)>0)
lines[1][1].role="magic";assert(compare(lines,19.8,21.4,255,1,2)>0)
compare(lines,20,22,255,1,1);compare(lines,20.001,22.999,255,1,2)
assert(compare(lines,-1,22,255,1,2)>0)
local wide={{{text=string.rep("W",400),role="prose"}}}
assert(compare(wide,20,22,255,1,1)>0)
scale=20;fire("OnReloaded");assert(compare(lines,20,22,255,1,2)>0);scale=1;fire("OnReloaded")
for _,event in ipairs({"OnReloaded","OnScreenSizeChanged","PostCleanupMap"})do
    fire(event);assert(compare(lines,19.8,21.4,255,1,2)>0,event.." retained stale raster")
end
local native=feed.DrawLines;local calls=0
feed.DrawLines=function(self,...)calls=calls+1;return native(self,...)end
assert(compare(lines,19.8,21.4,255,1,2)>0 and calls==2,"foreign DrawLines bypassed")
feed.DrawLines=native
local nativeHUD=LOD.UI.HUDText;calls=0
LOD.UI.HUDText=function(self,...)calls=calls+1;return nativeHUD(self,...)end
assert(compare(lines,19.8,21.4,255,1,2)>0 and calls==6,"foreign HUDText bypassed")
LOD.UI.HUDText=nativeHUD
cache:Invalidate();failText=true
local ok,err=pcall(cache.Draw,cache,lines,20,22,255,1,2)
failText=false
assert(not ok and tostring(err):find("native text failure",1,true),"native error was swallowed")
assert(not target and #stack==0 and depth==0 and not clipped and not blend and not alphaWrite,"error leaked render state")
assert(compare(lines,19.8,21.4,255,1,2)>0)
cache:Invalidate();frame=frame+1
local beforeFull=cache.fallbacks
for i=1,7 do cache:Draw({{{text="same-frame "..i,role="prose"}}},10,20,255,1,1) end
assert(cache.fallbacks==beforeFull+1 and uniqueTextures==6,"pool exhaustion overwrote an in-flight texture")
frame=frame+1;cache:Draw(lines,19.8,21.4,255,1,2)
local beforeView=cache.builds
cache:Draw(lines,20.7,23.1,255,1,2)
assert(cache.builds==beforeView,"second view overwrote a submitted texture")
local nativeDraw=surface.DrawText;calls=0
surface.DrawText=function(...)calls=calls+1;return nativeDraw(...)end
assert(compare(lines,19.8,21.4,255,1,2)>0 and calls>0,"foreign native drawing provider bypassed")
surface.DrawText=nativeDraw
local transient={{{text="bounded owner",role="prose"}}}
compare(transient,10,20,255,1,1)
local weak=setmetatable({transient},{__mode="v"});transient=nil
collectgarbage();assert(weak[1],"fixture not owned by cache")
cache:Invalidate();collectgarbage();collectgarbage();assert(not weak[1],"cleanup retained old layout")
assert(uniqueTextures==6,"invalidation grew render-target resource pool")
dofile(root.."cl_combat_roll_feed_semantics.lua")
assert(LOD.CombatRollFeed.HUDRasterCache~=cache)
fire("InitPostEntity")
assert(uniqueTextures==6,"Lua reload grew engine texture ownership")
print("HUD_RASTER_CACHE_PASS cases="..cases.." fixed_textures="..uniqueTextures.."; command/text-state parity, warm reuse, fades, live text/role/palette, bounds, reload/cleanup, foreign providers and native-error cleanup; no FPS/pixel inference")
