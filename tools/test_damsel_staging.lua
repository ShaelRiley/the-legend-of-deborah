local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local V=getmetatable(Vector());function V:Dot(v) return self.x*v.x+self.y*v.y+self.z*v.z end
function V:Angle() return {y=math.deg(math.atan(self.y,self.x))} end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,
    Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end} end
local D,R=LOD.Damsels,LOD.RunManager
if not D then dofile(root..'sh_damsels.lua');D=LOD.Damsels end
R.State={CampaignSeed=72,CampaignEpoch=1,Level=1,BuildReady=true,RescuedDamsels={},DamselClaims={}}
local states={};R.GetPlayerState=function(_,p) return states[p] end
R.IsSlotActivePlayer=function() return true end;R.IsSoldierControl=function() return false end
R.NewCampaign=function(self)
 self.State={CampaignSeed=84,CampaignEpoch=2,Level=1,BuildReady=true,RescuedDamsels={},DamselClaims={}}
 return true
end
LOD.Equipment={};LOD.CryptoDirector={};LOD.CryptoStore={}
local S={HutCenter=Vector(),HutAngles=Angle(),HutHalfForward=448,HutHalfRight=288,HutEntities={},
 EnsureHut=function() return true end,IsPlayerInHut=function() return true end}
LOD.StagingDeployment=S
for _,p in ipairs({Vector(82,0,0),Vector(-82,0,0),Vector(-408,-160,0),Vector(350,0,96),Vector(0,254,50),Vector(100,254,50)}) do
 S.HutEntities[#S.HutEntities+1]={GetPos=function() return p end}
end
local born,removed=0,0
ents.Create=function(class)
 assert(class=='lod_rescued_damsel');born=born+1
 return {SetPos=function(self,p) self.pos=p end,GetPos=function(self) return self.pos end,
 WorldSpaceCenter=function(self) return self.pos+Vector(0,0,36) end,
 SetAngles=function(self,a) self.ang=a end,Spawn=noop,Activate=noop,
 Remove=function(self) assert(self.valid~=false);removed=removed+1;self.valid=false end}
end
util.TraceHull=function(t)
 local p=t.start
 return {Hit=math.abs(p.x)+14>=S.HutHalfForward or math.abs(p.y)+14>=S.HutHalfRight}
end
util.TraceLine=function() return {Hit=false} end
local packets,packet={},nil
net.Start=function(name) packet={name=name,values={}} end
local function write(v) packet.values[#packet.values+1]=v end
net.WriteUInt=write;net.WriteDouble=write;net.WriteBool=write;net.WriteString=write
net.Send=function(p) packet.player=p;packets[#packets+1]=packet end
function ErrorNoHalt(s) error(s) end
dofile(root..'sv_damsels.lua')
local positions={}
assert(S:EnsureHut() and born==0)
for level=1,20 do
 R.State.RescuedDamsels[level]=true;R.State.Level=level+1
 assert(S:EnsureHut());assert(S:EnsureHut())
 assert(born==level and removed==0,'ordinary transition duplicates or removes staged actor')
 for i=1,level do
    local ent=D.Entities[i];assert(IsValid(ent))
    local p=ent:GetPos()
    if positions[i] then assert(p==positions[i],'stable placement changed') else positions[i]=p end
    for j=1,i-1 do assert(p:DistToSqr(positions[j])>=48^2,'actors overlap') end
    for _,prop in ipairs(S.HutEntities) do
        local q=prop:GetPos();assert((p.x-q.x)^2+(p.y-q.y)^2>=48^2,'staging interaction obstructed')
    end
 end
end
R.State.Abundance=true
local late={};states[late]={identity='late'}
D:Sync(late);assert(#packets==2 and packets[1].name=='LOD_DamselState' and packets[2].name=='LOD_DamselDialogue')
assert(packets[1].values[2]==21)
for i=4,23 do assert(packets[1].values[i]==true,'late join omitted rescued damsel') end
D:Sync(late);assert(#packets==3,'letter repeats on ordinary sync')
local hero={IsPlayer=function() return true end,Alive=function() return true end,
 GetPos=function() return D.Entities[1]:GetPos() end,EyePos=function() return D.Entities[1]:WorldSpaceCenter()-Vector(40,0,0) end,
 GetAimVector=function() return Vector(1,0,0) end}
states[hero]={identity='hero',lives=2}
assert(D:CanUse(hero,D.Entities[1]))
local claimed=0;D.Grant=function() claimed=claimed+1;return true,'done' end
IN_USE=32
hero.GetEyeTrace=function() return {Entity=S.HutEntities[1],HitPos=hero:EyePos()+Vector(40,0,0)} end
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==0,'talk intercepted another staging interaction')
hero.GetEyeTrace=nil
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==1,'E did not interact')
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==1,'repeated E duplicated reward')
local old=D.Entities[1]
assert(R:NewCampaign());assert(removed==20 and next(D.Entities)==nil and not D:CanUse(hero,old))
assert(S:EnsureHut() and born==20,'new campaign respawned old roster')
-- The native room discovery can report smaller enclosed rooms. Exercise a
-- 400 x 260 floor with six existing interaction/decor points, not only an arena.
S.HutHalfForward=200;S.HutHalfRight=130;S.HutEntities={}
for _,p in ipairs({Vector(82,0,0),Vector(-82,0,0),Vector(-160,-90,0),Vector(152,0,96),Vector(0,116,50),Vector(88,116,50)}) do
 S.HutEntities[#S.HutEntities+1]={GetPos=function() return p end}
end
for i=1,20 do R.State.RescuedDamsels[i]=true end
assert(S:EnsureHut() and born==40)
assert(S:EnsureHut() and born==40)
for i=1,20 do
 local pos=D.Entities[i]:GetPos()
 assert(math.abs(pos.x)+14<200 and math.abs(pos.y)+14<130)
 for j=1,i-1 do assert(pos:DistToSqr(D.Entities[j]:GetPos())>=40^2) end
 for _,prop in ipairs(S.HutEntities) do
  local q=prop:GetPos();assert((pos.x-q.x)^2+(pos.y-q.y)^2>=48^2)
 end
end
print('DAMSEL_STAGING_PASS: all20 fit clear perimeter, stable positions, no transition duplication, late join/one letter, E use and campaign removal')

-- Actual portrait panel construction; model colors and material selection stay
-- at the native render boundary for the in-engine playtest.
SERVER=false;CLIENT=true
local receivers,panels={},{}
net.Receive=function(name,fn) receivers[name]=fn end
surface={SetDrawColor=noop,DrawRect=noop,DrawOutlinedRect=noop}
function ScrW() return 1280 end;function ScrH() return 800 end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a} end
function Material() return {GetTexture=function() return nil end} end
function HSVToColor() return Color(100,150,210) end
LOD.RNG=LOD.RNG or {New=function() return {Int=function(_,a) return a end} end}
LOD.Seeds=LOD.Seeds or {Derive=function() return 1 end}
vgui={Create=function(kind,parent)
 local panel={kind=kind,parent=parent,Entity={GetModel=function() return 'portrait' end,GetMaterials=function() return {} end}}
 for _,method in ipairs({'SetTitle','SetDraggable','MakePopup','SetFOV','SetCamPos','SetLookAt','SetFont','SetTextColor','SetWrap','SetVisible','SetAutoStretchVertical','Dock','DockMargin'}) do panel[method]=noop end
 panel.SetPos=function(self,x,y) self.x=x;self.y=y end
 panel.SetSize=function(self,w,h) self.w=w;self.h=h end
 panel.SetModel=function(self,m) self.model=m end
 panel.SetText=function(self,text) self.text=text end
 panel.Remove=function(self) self.valid=false;if self.OnRemove then self.OnRemove() end end;panel.Close=panel.Remove
 panels[#panels+1]=panel;return panel
end}
LOD.Config.Models=LOD.Config.Models or {Deborah='models/Humans/Group01/Female_01.mdl'}
dofile(root..'cl_damsels.lua')
D:ShowDialogue(1,'Rescued.','Ammo replenished.')
assert(panels[2].kind=='DModelPanel' and panels[2].x<panels[3].x and panels[2].y<panels[4].y)
assert(panels[3].text=='Nessa' and panels[4].kind=='DScrollPanel')
assert(panels[5].text=='Rescued.' and panels[6].text=='Ammo replenished.' and panels[5].parent==panels[4])
local firstFrame=D.DialogueFrame
D:ShowDialogue(20,'At last.','ABUNDANCE')
assert(not firstFrame.valid and panels[9].model==LOD.Config.Models.Deborah)
local finalFrame=D.DialogueFrame
KEY_E=18;finalFrame.OnKeyCodePressed(nil,KEY_E);assert(not finalFrame.valid and D.DialogueFrame==nil)
print('DAMSEL_DIALOGUE_PASS: native panel hierarchy, upper-left portrait, name/text/receipt and E dismissal')

-- BUG-003: native GetKeyValues contains compiled flags and ITexture/VMatrix
-- handles, not a CreateMaterial-ready table. Exercise the actual appearance
-- authority used by jailed/rescued actors, victory actors and dialogue portraits.
local nativeType=type
type=function(value)
 if nativeType(value)=='table' then
  if value.nativeTexture then return 'ITexture' end
  if value.nativeMatrix then return 'VMatrix' end
  if getmetatable(value)==V then return 'Vector' end
 end
 return nativeType(value)
end
local function texture(name,isError)
 return {nativeTexture=true,GetName=function() return name end,IsError=function() return isError==true end}
end
local clothPath='models/humans/female/group01/citizen_sheet'
local transform={nativeMatrix=true,identity=true}
local raw={['$flags']=134217728,['$flags2']=262226,['$flags_defined']=134217728,['$flags_defined2']=0,
 ['$basetexture']=texture(clothPath),['$bumpmap']=texture(clothPath..'_normal'),
 ['$phong']=1,['$phongboost']=.5,['$envmaptint']=Vector(.25,.5,.75),['$basetexturetransform']=transform}
local source={GetTexture=function(_,key) assert(key=='$basetexture');return raw[key] end,
 GetKeyValues=function() return raw end,GetShader=function() return 'VertexLitGeneric' end}
local materialCount,clones=0,{}
Material=function(path) assert(path:find('sheet',1,true));return source end
local oldCRC=util.CRC;util.CRC=function(id) return id:gsub('[^%w]','_') end
CreateMaterial=function(name,shader,params)
 for _,key in ipairs({'$flags','$flags2','$flags_defined','$flags_defined2'}) do
  assert(params[key]==nil,'compiled shader metadata passed to CreateMaterial: '..key)
 end
 for _,value in pairs(params) do
  assert(type(value)~='ITexture' and type(value)~='VMatrix' and type(value)~='Vector',
   'native handle passed without serialization')
 end
 assert(not clones[name],'same appearance allocated twice')
 materialCount=materialCount+1
 local m={params=params,shader=shader,matrices={},GetName=function() return name end}
 function m:SetMatrix(key,value) assert(type(value)=='VMatrix');self.matrices[key]=value end
 clones[name]=m;return m
end
local function appearanceActor(model)
 local actor={model=model or D.Models[1],slots={},draws=0}
 function actor:GetModel() return self.model end
 function actor:GetMaterials() return {clothPath,'models/humans/female/face_sheet','models/humans/female/head_sheet','models/humans/female/eyeball'} end
 function actor:SetSubMaterial(slot,value) assert(slot==0,'skin, face or eyes were tinted');self.slots[slot]=value end
 function actor:GetNW2Int(key) return key=='LOD_DamselLevel' and 1 or 6102601 end
 function actor:GetPos() return Vector(10000,0,0) end
 function actor:DrawModel() self.draws=self.draws+1 end
 return actor
end
D.Materials={}
local actor=appearanceActor();D:ApplyAppearance(actor,1,6102601)
local clone=assert(clones[assert(actor.slots[0]):sub(2)])
assert(clone.shader=='VertexLitGeneric' and clone.params['$basetexture']==clothPath)
assert(clone.params['$bumpmap']==clothPath..'_normal','source normal map was lost')
assert(clone.params['$halflambert']=='1' and clone.params['$model']=='1','source shading/model flags were lost')
assert(clone.params['$phong']==1 and clone.params['$phongboost']==.5,'source shader parameters were retuned')
assert(clone.params['$envmaptint']=='[0.25 0.5 0.75]' and clone.matrices['$basetexturetransform']==transform)
assert(clone.params['$color2']=='[0.392157 0.588235 0.823529]','cloth palette changed')
assert(type(raw['$basetexture'])=='ITexture' and type(raw['$bumpmap'])=='ITexture' and raw['$flags']==134217728,
 'stock material values were mutated')
for _=1,100 do D:ApplyAppearance(actor,1,6102601) end
local other=appearanceActor(D.Models[2]);D:ApplyAppearance(other,2,6102601)
assert(materialCount==1 and other.slots[0]==actor.slots[0],'shared cloth/colour failed to reuse material')
local legacy={GetName=function() return 'old_malformed_clone' end}
D.Materials[clothPath..':100:150:210']=legacy
local retained=appearanceActor();retained.LODDamselAppearance='6102601:1:'..retained:GetModel()
D:ApplyAppearance(retained,1,6102601)
assert(retained.slots[0]==actor.slots[0],'retained entity reused old appearance cache or malformed clone')
local names={'$selfillum','$additive','$alphatest','$nocull','$basealphaenvmapmask','$translucent','$normalmapalphaenvmapmask','$halflambert'}
local masks={64,128,256,8192,1048576,2097152,4194304,134217728}
for index,mask in ipairs(masks) do
 raw['$flags']=mask
 local test=appearanceActor();test.GetMaterials=function() return {'models/humans/test_'..index..'_sheet'} end
 D:ApplyAppearance(test,1,6102601)
 local m=assert(clones[test.slots[0]:sub(2)])
 for j,name in ipairs(names) do assert((m.params[name]=='1')==(j==index),'source flag was changed or invented: '..name) end
end
raw['$flags']=134217728
local count=materialCount
for level=17,20 do
 local untouched=appearanceActor();D:ApplyAppearance(untouched,level,6102601)
 assert(next(untouched.slots)==nil,'last four stock appearances changed')
end
EyePos=function() return Vector() end
local world=appearanceActor();D:DrawActor(world,false);D:DrawActor(world,true)
assert(world.draws==2 and world.slots[0]==actor.slots[0] and materialCount==count)
local create=vgui.Create
vgui.Create=function(kind,parent)
 local p=create(kind,parent);if kind=='DModelPanel' then p.Entity=appearanceActor() end;return p
end
D:ShowDialogue(1,'Complete dialogue remains available.','Separate actual receipt.')
assert(materialCount==count,'portrait allocated instead of reusing the actor material')
local materialStore=D.Materials;dofile(root..'cl_damsels.lua')
local reloaded=appearanceActor();D:ApplyAppearance(reloaded,1,6102601)
assert(D.Materials==materialStore and materialCount==count and reloaded.slots[0]==actor.slots[0],
 'Lua reload discarded the valid appearance cache or allocated a duplicate')
util.CRC=oldCRC
print('DAMSEL_MATERIAL_CLONE_PASS: compiled metadata excluded; native normal/texture/vector/matrix values and source flags preserved; palette/skin/final-four unchanged; actor/portrait/cache/reload identity')
