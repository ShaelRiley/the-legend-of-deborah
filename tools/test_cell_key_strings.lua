-- Exact coordinate-key contract through the production generator. Native LuaJIT
-- fast-path value/timing evidence is a separate Deck receipt, not headless FPS.
LOD={Config={Maze={}}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_maze_generator.lua')
local actual=LOD.MazeGenerator.CellKey
local function original(x,y,z)return x..":"..y..":"..z end
local checks=0
local function same(x,y,z)
    local ok,wanted=pcall(original,x,y,z)
    local got,value=pcall(actual,x,y,z)
    assert(ok==got and (not ok or wanted==value),'coordinate-key result/error contract changed')
    checks=checks+1
end
local values={-math.huge,-256,-1,-1/math.huge,0,0.0,.5,1,1.0,1.25,2,20,254,255,256,1e6,math.huge,0/0,'1','001','-0','room',false}
for _,x in ipairs(values)do for _,y in ipairs(values)do for _,z in ipairs(values)do same(x,y,z)end end end
same(nil,1,0);same(1,nil,0);same(1,1,nil);same(nil,nil,nil)
local special=setmetatable({}, {__concat=function(a,b)return tostring(a)..tostring(b)end,
    __tostring=function()return 'special'end})
same(special,1,0);same(1,special,0);same(1,1,special)
-- Repeated and changing coordinates must retain exact key spelling with no
-- campaign/config identity in the result, including values beyond the cache.
for z=-2,6 do for y=-1,40 do for x=-1,40 do same(x,y,z)end end end
LOD.Config.Maze={Width=256,Height=255,CellSize=768}
for _,x in ipairs({0,1,20,255,256,1.0})do same(x,255,0);same(x,256,-1)end
print('CELL_KEY_STRINGS_PASS '..checks..' exact value/error/representation/uncached/metamethod cases; native fast-path evidence separate')
