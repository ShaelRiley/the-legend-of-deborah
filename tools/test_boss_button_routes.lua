-- Continuous baseline traversal + real E input, no teleport/UseDamage shortcut.
local F=dofile('tools/boss_framework_fixture.lua');local B,N=F.B,F.N
local original=F.players;local speed=150
local function route(c,p,o)
 local from=B:ExactCell(c,p:GetPos());local to=B:ExactCell(c,o.pos)
 local path=N:FindPath(c.graph,from,to,function(cell) return c.arena.court[B.Key(cell)] end)
 assert(path,'no Button graph path')
 local points=N:PathToWaypoints(c.graph,path);points[#points+1]={pos=o.pos+Vector(60,0,-26)}
 local distance,last=0,p:GetPos();for _,q in ipairs(points) do distance=distance+last:Distance(q.pos);last=q.pos end
 return {p=p,o=o,points=points,index=1,time=distance/speed+.4}
end
for _,party in ipairs({1,2,4}) do
 F.players={original[1]};if party>=2 then F.players[2]=original[2] end
 while #F.players<party do F.hero('review-hero-'..#F.players+1) end
 local s,c=F.setup(10);local attempts,expired,worst=0,0,0
 for i,p in ipairs(F.players) do p:SetPos(B:Center(c)+Vector(120*i,0,0)) end
 while not c.dead and attempts<25 do
  while not c.data.deadline do F.step(.1) end
  attempts=attempts+1;local cycle=c.data.cycle;local routes={}
  for i,o in ipairs(c.data.real) do routes[i]=route(c,F.players[i],o);worst=math.max(worst,routes[i].time/(c.data.deadline-F.clock)) end
  while c.data.deadline and cycle==c.data.cycle and not c.dead do
   for _,r in ipairs(routes) do
    local q=r.points[r.index]
    if q then local delta=q.pos-r.p:GetPos();local dist=delta:Length();if dist<=speed*.05 then r.p:SetPos(q.pos);r.index=r.index+1 else r.p:SetPos(r.p:GetPos()+delta/dist*speed*.05) end
    elseif not r.pressed then
     r.ready=r.ready or F.clock+.4
     if F.clock>=r.ready then F.lookAt(r.p,r.o.pos);hook.Run('KeyPress',r.p,IN_USE);if r.o.claimed or r.o.retired then r.pressed=true end end
    end
   end
   F.step(.05)
  end
  if not c.dead and c.data.successes<attempts-expired then expired=expired+1 end
 end
 assert(c.dead and c.data.successes==c.data.required,'baseline party could not finish Button through actual route/use')
 assert(expired==0 and worst<1,'baseline Hero route exceeds authored time window')
 print('BOSS_BUTTON_ROUTES_PASS baseline150','party',party,'dead',c.dead==true,'successes',c.data.successes,'attempts',attempts,'timeouts',expired,'worst_route_window_ratio',worst)
end
