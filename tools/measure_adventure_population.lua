-- Same closed-four-gate graphs and native-boundary doubles for B26/B27 pairs.
local output=print;print=function() end
local T=dofile('tools/test_bestiary_b23.lua')
local H,W=T.H,T.W;local D,Run=H.D,H.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
istable=istable or function(v) return type(v)=='table' end
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
print=output
local N=LOD.MazeNavigator;local key=LOD.MazeGenerator.CellKey
local function k(c) return key(c.x,c.y,c.z) end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
print('sample,level,party,theme,optional,roamers,roaming_types,target,route_steps,covered_steps,longest_empty_run')
for sample=1,16 do
 local level=1;local party=1
 Run.State={CampaignSeed=sample*7919,CampaignEpoch=1,RunId=1,Level=level};H.setParty(party)
 local g=H.prepare(sample*7919,level);Run.State.GatesOpen={false,false,false,false}
 local p=H.build(g);Run.State.BuildReady=true;T.init(g)
 local ids,homes={},{};local roam,optional=0,0
 for _,e in ipairs(W.Entities) do if IsValid(e) and not e.LODDead then
  roam=roam+1;ids[e.LODArchetypeId]=true;homes[e.LODHomeCellKey]=true
 end end
 for _,e in ipairs(p.encounters) do homes[e.cellKey]=true;if not e.objective then optional=optional+1 end end
 -- One bounded, read-only multi-source BFS for potential route contact (2 cells).
 local dist,q={},{};for h in pairs(homes) do dist[h]=0;q[#q+1]=h end
 local head=1
 while q[head] do
  local a=q[head];head=head+1
  if dist[a]<2 then for b in pairs(g.Cells[a].neighbors) do
   if dist[b]==nil and N:CanTraverse(g,a,b) then dist[b]=dist[a]+1;q[#q+1]=b end
  end end
 end
 local steps,covered,gap,maxGap=0,0,0,0
 for sector=1,4 do
  local entry=sector==1 and g.Start or g.Progression.Gates[sector-1].afterCell
  local goal=sector<4 and g.Progression.Keycards[sector].cell or g.Progression.Gates[4].beforeCell
  local route=N:FindPath(g,entry,goal) or {}
  if sector<4 then
   local back=N:FindPath(g,goal,g.Progression.Gates[sector].beforeCell) or {}
   for i=2,#back do route[#route+1]=back[i] end
  end
  gap=0
  for _,c in ipairs(route) do
   steps=steps+1
   if dist[k(c)] then covered=covered+1;gap=0 else gap=gap+1;maxGap=math.max(maxGap,gap) end
  end
 end
 print(string.format('%d,%d,%d,%s,%d,%d,%d,%d,%d,%d,%d',sample,level,party,p.ecology.theme,
  optional,roam,size(ids),W:GetTargetPopulation(g),steps,covered,maxGap))
end
