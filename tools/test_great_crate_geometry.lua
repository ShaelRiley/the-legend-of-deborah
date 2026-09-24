-- Real generator + real floor builder; no topology mutation or extra collision.
dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sh_crate_visuals.lua');dofile(root..'sh_crate_brand_metadata.lua')
dofile(root..'sv_maze_generator.lua');dofile(root..'sv_maze_builder.lua');dofile(root..'sv_maze_builder_floor_anchor.lua')
local C,G,B=LOD.CrateVisuals,LOD.MazeGenerator,LOD.MazeBuilder
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
table.Count=count
function Angle(p,y,r) return {p=p,y=y,r=r} end
angle_zero=Angle(0,0,0)
for id=1,256 do
 local f=assert(C.FitBrand(id));assert(f.width>0 and f.height>0 and f.width<=240 and f.height<=78)
end
assert(not C.FitBrand(0) and not C.FitBrand(257))
local ids={}
for seed=1,2048 do
 local a=C.BrandID(seed);assert(a>=1 and a<=256 and a==C.BrandID(seed));ids[a]=true
end
assert(count(ids)==256,'named stream did not exercise every brand')
local boxes={}
ents={Create=function(class)
 assert(class=='lod_static_box')
 local e={valid=true,nw={}}
 function e:SetPos(v) self.pos=v end
 function e:SetAngles(v) self.ang=v end
 function e:SetBoxMins(v) self.mins=v end
 function e:SetBoxMaxs(v) self.maxs=v end
 function e:SetBoxKind(v) self.kind=v end
 function e:Spawn() boxes[#boxes+1]=self end
 function e:Activate() end
 function e:IsLODCollisionReady() return true end
 function e:SetNW2Bool(k,v) self.nw[k]=v end
 return e
end}
local function collisionSignature()
 local out={}
 for _,e in ipairs(boxes) do
  out[#out+1]=string.format('%g,%g,%g|%g|%g,%g,%g|%g,%g,%g|%d',e.pos.x,e.pos.y,e.pos.z,e.ang.y,
   e.mins.x,e.mins.y,e.mins.z,e.maxs.x,e.maxs.y,e.maxs.z,e.kind)
  assert(e.maxs.z-e.mins.z==32 and e.kind==1)
 end
 return table.concat(out,';')
end
local totals,peak,allBoxes=0,0,0
local choose=C.SelectGrates
for seed=1,16 do
 local g=assert(G:Generate(seed*7719))
 local n,e=count(g.Cells),count(g.Edges)
 local a,b=C.SelectGrates(g),C.SelectGrates(g)
 local floors={}
 for key in pairs(a) do
  assert(b[key]);local cell=g.Cells[key];assert(cell and cell.z>0)
  local lower=G.CellKey(cell.x,cell.y,cell.z-1);assert(g.Cells[lower])
  floors[cell.z]=(floors[cell.z] or 0)+1;assert(floors[cell.z]<=1)
 end
 assert(count(a)==count(b) and count(g.Cells)==n and count(g.Edges)==e)
 boxes={};B.Entities={};B.BuildFailures=0;B:_BuildFloors(g)
 local signature=collisionSignature();local expectedCount=#boxes
 local grates=0
 for _,box in ipairs(boxes) do if box.nw.LOD_CrateGrate then grates=grates+1 end end
 assert(grates==count(a) and grates<=g.Layers-1)
 totals=totals+grates;peak=math.max(peak,grates);allBoxes=allBoxes+#boxes
 -- Disable cosmetics and compile the identical graph: every physical box agrees.
 C.SelectGrates=function() return {} end
 boxes={};B.Entities={};B:_BuildFloors(g)
 assert(#boxes==expectedCount and collisionSignature()==signature,'cosmetics changed collision')
 C.SelectGrates=choose
end
assert(totals>0,'selector never admits a real vista')
-- Stacked transitions cannot expose a second aperture below a grate.
local function cell(z) return {x=2,y=3,z=z} end
local c0,c1,c2=cell(0),cell(1),cell(2)
local g={Cells={['2:3:0']=c0,['2:3:1']=c1,['2:3:2']=c2},VerticalEdges={{a=c0,b=c1},{a=c1,b=c2}},LevelSeed=1}
local picked=C.SelectGrates(g);assert(picked['2:3:1'] and not picked['2:3:2'])
g.Cells['2:3:0']=nil;assert(next(C.SelectGrates(g))==nil)
print('CRATE_GEOMETRY_PASS: 256 fits; 2048 deterministic brand seeds; 16 generated mazes; '..allBoxes..' unchanged collision boxes; '..totals..' grates, peak '..peak..'; missing/stacked lower floors rejected')
