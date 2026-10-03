local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
 local a=e:GetAngles();local now=CurTime()
 if s.dead then
  local t=math.max(0,now-(s.deathAt or now))
  if t<2.4 then return {angles=Angle(0,a.y,math.sin(t*math.pi/1.2)*7),offset=Vector(t*35,0,math.sin(t*math.pi/1.2)*-12)} end
  local kneel=math.min(1,(t-2.4)/1.5);local collapse=math.min(1,math.max(0,(t-4.1)/1.1))
  return {angles=Angle(collapse*70,a.y,collapse*28),offset=Vector(84+collapse*90,0,-kneel*130-collapse*85)}
 end
 local lower=e:GetNW2Float('LOD_MookyLowerUntil',0)>now and -90 or 0
 local limp=e:GetNW2Bool('LOD_MookyDamaged',false) and math.sin(now*2)*3 or 0
 return {angles=Angle(0,a.y,limp),offset=Vector(0,0,lower)}
end
function M:Draw(e,size,s)
 render.SetColorMaterial();local now=CurTime()
 if not s.dead then
  local protected=e:GetNW2String('LOD_MookyProtectedKnee','')
  for _,side in ipairs({'Left','Right'}) do
   local p=e:GetNW2Vector('LOD_Mooky'..side..'Knee',e:LocalToWorld(Vector(145,side=='Left' and -140 or 140,190)))
   local c=string.lower(side)==protected and Color(110,140,175,140) or Color(245,200,80,190)
   render.DrawWireframeSphere(p,34,10,7,c,true)
  end
 end
 if e:GetNW2Bool('LOD_MookyDamaged',false) or (s.phase or 1)>=3 or s.dead then
  local p=e:LocalToWorld(Vector(0,0,345))+(s.dead and self:Pose(e,size,s).offset or Vector())
  for i=1,6 do local f=(now*.5+i*.17)%1
   render.DrawSphere(p+Vector(math.sin(i+now)*24,math.cos(i)*15,f*100),12+f*22,7,5,Color(55,60,65,100*(1-f)))
  end
 end
 if s.dead then local t=now-(s.deathAt or now)
  if t>5 and t<5.8 then render.DrawWireframeSphere(e:GetPos()+self:Pose(e,size,s).offset+Vector(0,0,215),math.min(330,(t-5)*500),18,7,Color(150,140,120,140),true) end
 end
end
V.Modules.little_mooky=M
