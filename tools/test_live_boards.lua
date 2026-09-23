-- Exercise the actual client board renderer and Heroes snapshot receiver.
CLIENT=true;SERVER=false
local now=0
CurTime=function() return now end
local vectorMeta={}
vectorMeta.__add=function() return setmetatable({},vectorMeta) end
vectorMeta.__mul=vectorMeta.__add
Vector=function() return setmetatable({},vectorMeta) end
Angle=function() return {Up=Vector,Forward=Vector,RotateAroundAxis=function() end} end
Color=function() return {} end
TEXT_ALIGN_CENTER=1
include=function() end
surface={CreateFont=function() end,SetFont=function() end,GetTextSize=function(s) return #s*9 end}
cam={Start3D2D=function() end,End3D2D=function() end}
local drawn={}
draw={SimpleText=function(text,font,x,y) drawn[#drawn+1]={text=text,y=y} end}
LOD={UI={Colors={},Paper=function() end}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_heroes_of_legend.lua')
local receiver,packet
net={Receive=function(_,fn) receiver=fn end,ReadTable=function() return packet end}
dofile(root..'cl_heroes_of_legend.lua')
ENT={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_heroes_of_legend_board/cl_init.lua')
local board=setmetatable({stakeholders=true},{__index=ENT})
board.GetNW2Bool=function(self) return self.stakeholders end
board.GetPos=Vector;board.GetAngles=Angle
local function render(time)
    now=time;drawn={};board:Draw();return drawn
end
local function contains(text)
    for _,line in ipairs(drawn) do if line.text:find(text,1,true) then return true end end
end
LOD.Stakeholders={}
for i=1,23 do LOD.Stakeholders[i]={id=tostring(i),name='Holder '..i,value=1000-i} end
for page,count in ipairs({10,10,3}) do
    render((page-1)*12)
    assert(contains('PAGE '..page..' OF 3'))
    local ranks={}
    for _,line in ipairs(drawn) do
        local rank=tonumber(line.text:match('^(%d+)%. '))
        if rank then ranks[#ranks+1]=rank;assert(line.y<1270,'Holder stays above footer') end
    end
    assert(#ranks==count and ranks[1]==(page-1)*10+1 and ranks[#ranks]==(page-1)*10+count)
end
render(36);assert(contains('PAGE 1 OF 3'),'Pagination cycles through every holder')
LOD.Stakeholders={{id='new',name=string.rep('X',300),value=9}}
render(24);assert(contains('PAGE 1 OF 1') and not contains('Holder 23'),'Shrinking snapshot discards old pages')
for _,line in ipairs(drawn) do
    if line.text:match('^1%. ') then assert(surface.GetTextSize(line.text)<576,'Long name stays on paper') end
end
LOD.Stakeholders={};render(0);assert(contains('PAGE 1 OF 1'),'Empty board has one safe page')

board.stakeholders=false;board.LODBoardEntries=nil
packet={{runId='current',rescueCount=3,highestLevel=4,cashRecovered=0,
    completionOrder=2,inProgress=true,partyMembers={'User as Hero'}}}
receiver();render(0);assert(contains('[IN PROGRESS]') and contains('Highest dungeon reached first'))
packet={{runId='current',rescueCount=3,highestLevel=4,cashRecovered=0,
    completionOrder=2,partyMembers={'User as Hero'}}}
receiver();render(0);assert(not contains('[IN PROGRESS]') and #LOD.HeroesOfLegend.Entries==1,
    'Completed packet replaces the live row and cached presentation')
local a={runId='a',rescueCount=3,completionOrder=1,partyMembers={'A'}}
local b={runId='b',rescueCount=3,completionOrder=1,partyMembers={'B'}}
assert(LOD.HeroesOfLegend:CompareEntries(a,b) and not LOD.HeroesOfLegend:CompareEntries(b,a),
    'Run identity breaks malformed legacy sequence ties deterministically')
print('LIVE_BOARDS_PASS: real client packets; 23 holders / 10 per page; rank continuity; shrink/empty/long names; live completion; deterministic ties')
