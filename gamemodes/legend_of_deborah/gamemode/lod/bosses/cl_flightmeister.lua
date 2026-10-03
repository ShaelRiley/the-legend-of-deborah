local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
 local a=e:GetAngles();local t=CurTime()
 if s.dead then
  local elapsed=math.max(0,t-(s.deathAt or t));local origin=s.position or e:GetPos();local target=s.deathTarget or (origin-Vector(0,0,300))
  local f=math.min(1,elapsed/4.8);local spiral=math.sin(f*math.pi)*95
  local delta=(target-origin)*f+Vector(math.cos(elapsed*3)*spiral,math.sin(elapsed*3)*spiral,0)
  return {angles=Angle(18+f*60,a.y+elapsed*120,f*115),offset=delta}
 end
 local damaged=e:GetNW2Bool('LOD_BossEngineDamaged',false)
 local act=e:GetNW2String('LOD_BossAction','');local bank=string.find(act,'HOVER',1,true) and 3 or damaged and 18 or 10
 return {angles=Angle(math.sin(t*1.1)*3,a.y,math.sin(t*.8)*bank)}
end
function M:Draw(e,size,s)
 render.SetColorMaterial();local t=CurTime();local damaged=e:GetNW2Bool('LOD_BossEngineDamaged',false) or (s.phase or 1)>=3 or s.dead
 local exposed=e:GetNW2Float('LOD_BossExposedUntil',0)>t
 local p=e:LocalToWorld(Vector(-70,0,-35))+(s.dead and self:Pose(e,size,s).offset or Vector())
 if exposed then render.DrawWireframeSphere(p,30,10,8,Color(255,215,90),true) end
 if damaged then for i=1,6 do local phase=(t*.8+i*.17)%1
  render.DrawSphere(p+Vector(-phase*80,math.sin(i+t)*12,phase*100),10+phase*20,7,5,Color(55,60,65,100*(1-phase)))
 end end
 if s.dead then local elapsed=t-(s.deathAt or t)
  if elapsed>4.6 and elapsed<5.4 then render.DrawWireframeSphere(e:GetPos()+self:Pose(e,size,s).offset,(elapsed-4.6)*300,16,8,Color(240,170,65,160),true) end
 end
end
V.Modules.flightmeister=M
