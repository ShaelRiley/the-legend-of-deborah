local V=LOD.BossPresentation
V.Modules=V.Modules or {}
local M={}
local steel,rubber,wood=Color(125,145,160),Color(22,25,29),Color(107,69,38)
local function hammer(pos,f,r,u,size,angles)
 render.DrawBeam(pos-u*30*size,pos+u*48*size,5*size,0,1,wood)
 render.DrawBox(pos+u*44*size,angles,Vector(-14,-22,-10)*size,Vector(14,22,10)*size,steel)
end
function M:Draw(e,size,s)
 size=tonumber(size) or 1.55;render.SetColorMaterial()
 if s.dead then return end
 local lo=e:GetNW2Vector('LOD_RoadMin',e:GetPos());local hi=e:GetNW2Vector('LOD_RoadMax',e:GetPos())
 for lane=1,4 do local y=lo.y+(hi.y-lo.y)*lane/5
  for dash=0,7 do local x=lo.x+(hi.x-lo.x)*dash/8
   render.DrawBeam(Vector(x,y,lo.z+4),Vector(x+(hi.x-lo.x)/15,y,lo.z+4),3,0,1,Color(245,220,105,180))
  end
  render.DrawBeam(Vector(lo.x,y+80,lo.z+4),Vector(hi.x,y+80,lo.z+4),4,0,1,Color(95,195,150,125))
 end
 local f,r,u=e:GetForward(),e:GetRight(),e:GetUp();local a=e:GetAngles();local origin=e:GetPos()
 -- Salvaged grille breastplate, bumper and paired tyre shoulders on the human rig.
 render.DrawBox(e:LocalToWorld(Vector(7,0,45)*size),a,Vector(-4,-15,-12)*size,Vector(5,15,12)*size,steel)
 for i=-2,2 do local p=e:LocalToWorld(Vector(13,i*5,45)*size);render.DrawBeam(p-u*9*size,p+u*9*size,2*size,0,1,rubber) end
 render.DrawBox(e:LocalToWorld(Vector(9,0,30)*size),a,Vector(-4,-19,-4)*size,Vector(4,19,4)*size,Color(175,185,190))
 for side=-1,1,2 do local p=e:LocalToWorld(Vector(0,side*18,54)*size)
  render.DrawSphere(p,9*size,12,8,rubber);render.DrawSphere(p+f*5*size,5*size,10,6,steel)
 end
 local h=e:LocalToWorld(Vector(7,-21,43)*size);local bone=e:LookupBone('ValveBiped.Bip01_R_Hand')
 if bone then local p=e:GetBonePosition(bone);if p and p:DistToSqr(origin)>1 then h=p end end
 local act=e:GetNW2String('LOD_BossAction','');local t=CurTime()-e:GetNW2Float('LOD_BossActionAt',CurTime())
 if string.find(act,'SLEDGE',1,true) then h=h+u*math.sin(math.min(t/2.65,1)*math.pi)*40*size
 elseif string.find(act,'FORE',1,true) then h=h-f*math.sin(math.min(t/2.2,1)*math.pi)*30*size end
 if not s.dead then hammer(h,f,r,u,size,a) end
end
function M:Pose(e,size,s)
 if not s.dead then return end
 local t=math.max(0,CurTime()-(s.deathAt or CurTime()));local carry=math.max(0,t-1.5)
 return {angles=Angle(-math.min(75,carry*100),e:GetAngles().y,0),offset=Vector(carry*410,0,carry>0 and 25 or 0)}
end
function M:DrawObject(e,size,s)
 if e:GetNW2String('LOD_BossObjectKind','')~='marion_death_hammer' then return end
 render.SetColorMaterial();hammer(e:GetPos()+Vector(0,0,43),Vector(1,0,0),Vector(0,1,0),Vector(0,0,1),1.55,Angle())
end
V.Modules.marion=M
