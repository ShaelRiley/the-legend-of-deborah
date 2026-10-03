local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
function M:Pose(e,size,s)
 if not s.dead then return end
 local t=math.max(0,CurTime()-(s.deathAt or CurTime()));local run=math.min(1,t/1.3)
 local flip=math.min(1,math.max(0,(t-1.3)/1.1))
 local origin=s.position or e:GetPos();local snag=s.deathTarget or origin+Vector(210,0,0)
 return {angles=Angle(0,e:GetAngles().y,flip*180),offset=(snag-origin)*run+Vector(0,0,math.sin(flip*math.pi)*180+flip*120)}
end
function M:Draw(e,size,s)
 render.SetColorMaterial()
 if not s.dead then
  local lo=e:GetNW2Vector('LOD_RoadMin',e:GetPos());local hi=e:GetNW2Vector('LOD_RoadMax',e:GetPos())
  for lane=1,4 do local y=lo.y+(hi.y-lo.y)*lane/5
   for dash=0,7 do local x=lo.x+(hi.x-lo.x)*dash/8
    render.DrawBeam(Vector(x,y,lo.z+4),Vector(x+(hi.x-lo.x)/15,y,lo.z+4),3,0,1,Color(250,205,65,180))
   end
  end
 end
 if (s.phase or 1)>=3 then
  for i=1,3 do local p=e:LocalToWorld(Vector(0,0,8+i*7)*(tonumber(size) or 6.8))
   render.DrawWireframeSphere(p,18*(1-i*.18),10,5,Color(80,60,45,180),true)
  end
 end

end
V.Modules.conan=M
