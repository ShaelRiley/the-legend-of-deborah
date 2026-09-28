local e=dofile('tools/music_test_fixture.lua');local M=LOD.Music;local check=e.check
local c=e.catalog();check(M.ValidateCatalog(c),'valid inherited catalog')
local p=assert(M.Plan(c,{set='all',post_victory='auto'},17,'run:1',4,1))
local q=assert(M.Plan(c,{set='all',post_victory='auto'},17,'run:1',4,1))
check(table.concat(p.floors)==table.concat(q.floors),'deterministic floor assignment')
local seen={};for _,id in ipairs(p.floors) do seen[id]=true end
check(table.Count(seen)==4,'no duplicates with enough blocks')
check(#M.Pool(c,'pair')==2,'sorted deduplicated sets')
local small=assert(M.Plan(c,{set='pair'},17,'run:2',8,1))
for _,id in ipairs(small.floors) do check(id=='alpha' or id=='beta','small set never broadens') end
check(not M.Pool(c,'missing'),'reject unknown sets')
check(M.Pool(c,'all')[1]=='alpha','themed membership does not remove full-catalog entries')
for _,role in ipairs(M.Roles) do
 local r=M.Candidates(c,c.blocks.alpha,role,{})
 check(#r==1 and r[1].source=='project-default','omitted '..role..' inherits exactly its role')
end
c.blocks.alpha.roles.BOSS=c.profiles.default.roles.BOSS
check(M.Candidates(c,c.blocks.alpha,'BOSS',{})[1].source=='custom','custom first')
check(M.Candidates(c,c.blocks.alpha,'BOSS',{universal_boss=true})[1].source=='project-default','override never falls back to custom')
c.blocks.alpha.title='Changed';c.assets[c.profiles.default.roles.T0].gain=.1
check(p.blocks.alpha.title=='alpha' and p.assets[c.profiles.default.roles.T0].gain==1,'frozen catalog/title/source versions')
local bad=table.Copy(c);bad.assets[bad.profiles.default.roles.T0].path='../bad.ogg';check(not M.ValidateCatalog(bad),'traversal rejected')
bad=table.Copy(c);bad.blocks.alpha.roles.VICTORY=bad.profiles.default.roles.T0;check(not M.ValidateCatalog(bad),'fanfare cannot inherit a loop')
bad=table.Copy(c);bad.assets[bad.profiles.default.roles.T1].bpm=121;check(not M.ValidateCatalog(bad),'default sibling grid mismatch rejected')
local pressure=M.Pressure(nil,{staging=true,hits=10,hp=.1,remaining=1},0)
check(pressure.value==0,'staging remains calm even with remote pressure')
pressure=M.Pressure(pressure,{hits=1,recent=true,hp=1,remaining=900},1)
check(pressure.value==0,'escalation smoothed')
pressure=M.Pressure(pressure,{hits=1,recent=true,hp=1,remaining=900},5)
check(pressure.value==1,'manageable combat alert')
pressure=M.Pressure(pressure,{hits=3,recent=true,hp=.3,remaining=900},6)
pressure=M.Pressure(pressure,{hits=3,recent=true,hp=.3,remaining=900},10)
check(pressure.value==2,'sustained damage danger')
pressure=M.Pressure(pressure,{hits=3,recent=true,hp=.1,remaining=900},10.1)
check(pressure.value==3,'urgent survival bypasses dwell')
pressure=M.Pressure(pressure,{hits=0,hp=1,remaining=900},11)
check(pressure.value==3,'no immediate relaxation after healing/time extension')
pressure=M.Pressure(pressure,{hits=0,hp=1,remaining=900},18)
check(pressure.value==0,'slower relaxation')
local a,b={x=1,y=1,z=0},{x=1,y=1,z=1}
local graph={Width=1,Height=1,Layers=2,Cells={['1:1:0']=a,['1:1:1']=b},VerticalEdges={{a=a,b=b,LODStairDirection='E'}}}
for _,fraction in ipairs({0,.25,.5,.75,1,.75,.25,0}) do
 local lo,hi,t=M.Floors(graph,Vector(-320+320*fraction,0,384*fraction),true,1)
 check(lo==1 and hi==2 and math.abs(t-fraction)<.0001,'ascent/descent/reversal follows actual flight')
end
local lo,hi=M.Floors(graph,Vector(100,100,240),false,1);check(lo==1 and hi==1,'jump/camera height cannot change floors')
lo,hi=M.Floors(graph,Vector(100,100,384),true,1);check(lo==2 and hi==2,'confirmed warp/fall landing follows destination')
print('MUSIC_POLICY PASS '..e.checks)
