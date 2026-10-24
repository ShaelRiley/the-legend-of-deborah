-- Production static renderer + mesh cache. Native boundaries are doubled;
-- counts below are Lua/native-call work, not GPU timings or Steam Deck FPS.
-- Optional arguments supply baseline mesh/entity source paths for paired probes.
local baseline = arg and arg[1] == '--baseline'
local parity = arg and arg[1] == '--parity'
local stateProbe = arg and arg[1] == '--state-probe'
local kindProbe = arg and arg[1] == '--kind-probe'
local supportProbe = arg and arg[1] == '--support-probe'
local supportGate = arg and arg[1] == '--support-gate'
local viewProbe = arg and arg[1] == '--view-probe'
local viewGate = arg and arg[1] == '--view-gate'
local override = baseline or parity or stateProbe or kindProbe or supportProbe or supportGate or viewProbe or viewGate or arg and arg[1] == '--source'
local meshPath = override and assert(arg[2]) or 'gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua'
local entityPath = override and assert(arg[3]) or 'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua'
local sharedPath = override and arg[5] or 'gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua'
local noop = function() end
local hooks = {}
hook = {Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
local function fire(event,...) for _,fn in pairs(hooks[event] or {}) do fn(...) end end
local now=100
CLIENT=true;SERVER=false
include=noop;CurTime=function() return now end
local validityCalls=0
local entityTables=setmetatable({}, {__mode='k'})
local collisionFieldReads,drawableFieldReads=0,0
function IsValid(e) validityCalls=validityCalls+1;return type(e)=='table' and (entityTables[e] or e).valid~=false end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
color_white=Color(255,255,255)
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
-- Angle axes cross a native vector boundary in GMod. Count their component
-- reads without assigning a hardware cost to the doubled accessors.
local axisReads=0
local AX={__index=function(v,k)
 if k=='x' or k=='y' or k=='z' then axisReads=axisReads+1;return v.values[k] end
 return V[k]
end,__add=V.__add,__sub=V.__sub}
local function axis(x,y,z) return setmetatable({values={x=x,y=y,z=z}},AX) end
local A={};A.__index=A
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},A) end
function A:Forward()
 local p,y=math.rad(self.p),math.rad(self.y)
 return axis(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p))
end
function A:Right()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return axis(-math.sin(r)*math.sin(p)*math.cos(y)+math.cos(r)*math.sin(y),
  -math.sin(r)*math.sin(p)*math.sin(y)-math.cos(r)*math.cos(y),-math.sin(r)*math.cos(p))
end
function A:Up()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return axis(math.cos(r)*math.sin(p)*math.cos(y)+math.sin(r)*math.sin(y),
  math.cos(r)*math.sin(p)*math.sin(y)-math.sin(r)*math.cos(y),math.cos(r)*math.cos(p))
end
angle_zero=Angle();vector_origin=Vector()
local view={origin=Vector(),angles=Angle(),fov=90,aspect=1.6,znear=1}
EyePos=function() return view.origin end;EyeVector=function() return view.angles:Forward() end
local formats,matrices,allocations,live,peak,draws,geometryReads,kindReads=0,0,0,0,0,0,0,0
local nativeVectorReads=0
local function nativeVector(v)
 return setmetatable({value=v},{__index=function(o,k)
  if k=='x' or k=='y' or k=='z' then nativeVectorReads=nativeVectorReads+1;return o.value[k] end
  return V[k]
 end,__newindex=function(o,k,n) o.value[k]=n end,__add=V.__add,__sub=V.__sub})
end
local absoluteValues=0
local absolute=math.abs
math.abs=function(n) absoluteValues=absoluteValues+1;return absolute(n) end
local format=string.format
string.format=function(...) formats=formats+1;return format(...) end
local currentMatrix,lastDraw,seen=nil,nil,{}
local lastMaterial,blend,tint
local stateCalls,wireframes,fallbacks=0,0,0
local failDraw,interruptDraw=false,nil
local matrixStack={}
local submissionSignature = parity and arg[4] and {} or nil
local supportCapture=false
function Matrix()
 matrices=matrices+1
 return {Translate=function(self,p) self.pos=Vector(p.x,p.y,p.z) end,
  Rotate=function(self,a) self.ang=Angle(a.p,a.y,a.r) end}
end
cam={PushModelMatrix=function(m) matrixStack[#matrixStack+1]=m;currentMatrix=m end,
 PopModelMatrix=function() assert(currentMatrix);table.remove(matrixStack);currentMatrix=matrixStack[#matrixStack] end}
local vertices,current,building
function Mesh()
 allocations=allocations+1;live=live+1;peak=math.max(peak,live)
 return {Destroy=function(self) assert(not self.dead,'double destruction');self.dead=true;live=live-1 end,
  Draw=function(self)
   assert(not self.dead,'evicted mesh drawn');assert(currentMatrix)
   if failDraw then error('injected native mesh draw failure',0) end
   if interruptDraw then
    local callback=interruptDraw;interruptDraw=nil
    local m,b,r,g,blue,matrix=lastMaterial,blend,tint[1],tint[2],tint[3],currentMatrix
    callback()
    assert(currentMatrix==matrix and lastMaterial==m and blend==b
     and tint[1]==r and tint[2]==g and tint[3]==blue,'nested draw changed the outer mesh state')
   end
   draws=draws+1;lastDraw={mesh=self,matrix=currentMatrix,material=lastMaterial,blend=blend,tint={tint[1],tint[2],tint[3]}}
   seen[format('%g,%g,%g',currentMatrix.pos.x,currentMatrix.pos.y,currentMatrix.pos.z)]=true
   if submissionSignature then
    local p,a=currentMatrix.pos,currentMatrix.ang or angle_zero
    local row={format(supportCapture and '%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g,%.17g'
     or '%g,%g,%g|%g,%g,%g|%g,%g,%g,%g',p.x,p.y,p.z,a.p,a.y,a.r,tint[1],tint[2],tint[3],blend)}
    if stateProbe or kindProbe or supportCapture then row[#row+1]=lastMaterial.tag end
    for _,v in ipairs(self.vertices) do
     row[#row+1]=format(supportCapture and '%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g'
      or '%g,%g,%g|%g,%g,%g|%.17g,%.17g',v.pos.x,v.pos.y,v.pos.z,
      v.normal.x,v.normal.y,v.normal.z,v.u,v.v)
    end
    submissionSignature[#submissionSignature+1]=table.concat(row,';')
   end
  end}
end
mesh={Begin=function(obj) building=obj;vertices={};current={} end,
 Position=function(p) current.pos=p end,Normal=function(n) current.normal=n end,
 TexCoord=function(_,u,v) current.u,current.v=u,v end,Color=noop,TangentS=noop,TangentT=noop,UserData=noop,
 AdvanceVertex=function() vertices[#vertices+1]=current;current={} end,
 End=function() building.vertices=vertices end}
local material={IsError=function() return false end,GetTexture=function() return {IsError=function() return false end} end}
material.tag='industrial'
local grateMaterial=setmetatable({tag='grate'},{__index=material})
local wireMaterial={tag='wireframe'}
Material=function(path) return path=='models/props_c17/FurnitureMetal001a' and grateMaterial or material end
render={GetViewSetup=function(current) assert(current);return view end,
 SetMaterial=function(m) stateCalls=stateCalls+1;lastMaterial=m end,
 SetBlend=function(b) stateCalls=stateCalls+1;blend=b end,
 SetColorModulation=function(r,g,b) stateCalls=stateCalls+1;tint={r,g,b} end,
 DrawWireframeBox=function(pos,ang,mins,maxs,color,depth)
  assert(blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'mesh tint leaked into a wireframe')
  wireframes=wireframes+1
  if submissionSignature and (stateProbe or kindProbe or supportCapture) then
   submissionSignature[#submissionSignature+1]=format(supportCapture
    and 'wire|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g,%.17g|%s'
    or 'wire|%g,%g,%g|%g,%g,%g|%g,%g,%g|%g,%g,%g|%g,%g,%g,%g|%s',
    pos.x,pos.y,pos.z,ang.p,ang.y,ang.r,mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z,color.r,color.g,color.b,color.a,tostring(depth))
  end
  lastMaterial=wireMaterial -- model the helper's independent material ownership
 end,
 DrawBox=function(pos,ang,mins,maxs,color)
  assert(not currentMatrix and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'fallback inherited mesh state')
  fallbacks=fallbacks+1
  if submissionSignature and supportCapture then
   submissionSignature[#submissionSignature+1]=format('fallback|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g|%.17g,%.17g,%.17g,%.17g|%s',
    pos.x,pos.y,pos.z,ang.p,ang.y,ang.r,mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z,
    color.r,color.g,color.b,color.a,lastMaterial.tag)
  end
 end}
LOD={Config={Geometry={FloorTextureTile=512}},CrateVisuals={GrateInset=8,GratePitch=24,GrateBarWidth=3}}
MATERIAL_QUADS=7
dofile(meshPath);ENT={};dofile(sharedPath);dofile(entityPath)
local B=LOD.TexturedBox
local entities={}
local function box(pos,kind,observed)
 local e=setmetatable({pos=pos,ang=Angle(),mins=Vector(-8,-8,-4),maxs=Vector(8,8,4),kind=kind or 1,nw={}},{__index=ENT})
 function e:GetPos() geometryReads=geometryReads+1;return self.pos end
 function e:GetAngles() geometryReads=geometryReads+1;return self.ang end
 function e:GetBoxMins() geometryReads=geometryReads+1;return self.mins end
 function e:GetBoxMaxs() geometryReads=geometryReads+1;return self.maxs end
 function e:GetBoxKind() kindReads=kindReads+1;return self.kind end;function e:SetRenderBounds() end
 function e:SetNextClientThink(t) self.thinkAt=t end
 function e:GetNW2Bool(k,d) if self.nw[k]==nil then return d end;return self.nw[k] end
 e.GetNW2String=e.GetNW2Bool
 function e:GetClass() return 'lod_static_box' end
 if observed then
  -- Model a native userdata's Lua-field facade separately from GetTable's
  -- actual backing table. All facade lookups cross a counted engine boundary.
  local data=e;local class=ENT
  e=setmetatable({}, {__index=function(_,k)
   assert(data.valid~=false,'invalid native entity field lookup: '..k)
   if data.kind==3 or data.kind==7 then collisionFieldReads=collisionFieldReads+1
   else drawableFieldReads=drawableFieldReads+1 end
   return data[k] or class[k]
  end,__newindex=function(_,k,v) data[k]=v end})
  entityTables[e]=data
  function e:GetTable() return data end
  -- Facepunch's declared DT accessors and receive proxies invoke all observers
  -- BEFORE changing the native value. Initial replication can omit a proxy.
  e.notifies={};e.declared={}
  function e:NetworkVar(_,_,name)
   local field=assert(({BoxMins='mins',BoxMaxs='maxs',BoxKind='kind'})[name])
   self.declared[name]=true
   self.notifies[name]={}
   local get=self['Get'..name]
   self['Get'..name]=function() return get(self) end
   self['Set'..name]=function(_,value)
    for _,fn in ipairs(self.notifies[name] or {}) do fn(self,name,self[field],value) end
    self[field]=value
   end
  end
  function e:NetworkVarNotify(name,fn)
   assert(self.declared[name],'observer preceded datatable declaration')
   self.notifies[name]=self.notifies[name] or {}
   table.insert(self.notifies[name],fn)
  end
  e:SetupDataTables()
 end
 e:Initialize();entities[#entities+1]=e;return e
end
local function resetScene()
 for _,e in ipairs(entities) do e:OnRemove(false) end
 entities={};B:ClearMeshCache();assert(live==0)
end
local function frame()
 seen={};draws=0;fire('PostDrawOpaqueRenderables',false,false,false);return draws
end
local function countVisibilityWork()
 -- Count calls to the actual production frustum evaluator. The published
 -- parent has only inCamera; the candidate keeps that solver unchanged behind
 -- its exact-input guard. No copied visibility formula or wall-clock claim.
 local function upvalue(fn,name)
  for i=1,100 do
   local n,v=debug.getupvalue(fn,i)
   if n==name then return v,i end
   if not n then break end
  end
  error('missing production renderer upvalue: '..name)
 end
 local paint=hooks.PostDrawOpaqueRenderables['LOD.DrawGeneratedStaticGeometry']
 local drawing=upvalue(paint,'drawGeneratedGeometry')
 local checking,index=upvalue(drawing,'inCamera')
 local owner,slot,solver=drawing,index,checking
 for i=1,100 do
  local name,value=debug.getupvalue(checking,i)
  if not name then break end
  if name=='evaluateCamera' then owner,slot,solver=checking,i,value;break end
 end
 local calls=0
 debug.setupvalue(owner,slot,function(...) calls=calls+1;return solver(...) end)
 return function() return calls end
end
local function supportCases(requireWork,tracePath)
 resetScene()
 -- Earlier refresh regressions deliberately replace ENT without shared data.
 -- Start this integrated observed-entity scene from the actual current class.
 dofile(sharedPath)
 view={origin=Vector(),angles=Angle(),fov=90,aspect=1.6,znear=1}
 local scene={}
 for i=1,120 do
  local e=box(Vector(1500+i*2,(i%5)*16,(i%3)*16),(i-1)%3==0 and 1 or (i-1)%3==1 and 2 or 5,true)
  if i%4==0 then e.ang=Angle(13,17+i,7) end
  e.pos,e.mins,e.maxs=nativeVector(e.pos),nativeVector(e.mins),nativeVector(e.maxs)
  scene[i]=e
 end
 assert(frame()==120)
 local visibilityCalls=(viewProbe or viewGate) and countVisibilityWork()
 local traces,passes={},0
 supportCapture=true
 local function sample(label)
  local rows=tracePath and {} or nil
  local parentMatrix,parentDepth=currentMatrix,#matrixStack
  local parentMaterial,parentBlend=lastMaterial,blend
  local parentTint={tint[1],tint[2],tint[3]}
  local previous=submissionSignature;submissionSignature=rows
  local n=frame();submissionSignature=previous;passes=passes+1
  if rows then
   table.sort(rows);traces[#traces+1]=label..'|'..n..'\n'..table.concat(rows,'\n')
  end
  if parentMatrix then
   assert(currentMatrix==parentMatrix and #matrixStack==parentDepth
    and lastMaterial==parentMaterial and blend==parentBlend
    and tint[1]==parentTint[1] and tint[2]==parentTint[2] and tint[3]==parentTint[3],
    'nested support pass lost outer native state: '..label)
  else
   assert(not currentMatrix and #matrixStack==0 and blend==1
    and tint[1]==1 and tint[2]==1 and tint[3]==1,'support pass leaked native state: '..label)
  end
  return n
 end
 absoluteValues,axisReads,geometryReads=0,0,0
 local beforeWires=wireframes
 -- Camera translation changes every frame; orientation and geometry do not.
 -- Both submissions still query the actual camera and every native box value.
 for i=1,120 do
  view.origin.x=i*.25;view.origin.y=(i%5)*.25;view.origin.z=(i%3)*.25
  assert(sample('walk-'..i..'-a')==120)
  assert(sample('walk-'..i..'-b')==120)
 end
 local work={absolute_values=absoluteValues,geometry_getters=geometryReads,
  camera_basis_reads=axisReads,native_draws=120*240,wireframes=wireframes-beforeWires}
 if visibilityCalls then
  work.visibility_evaluations=visibilityCalls()
  print(format('LOW_END_EXACT_VIEW_WORK entities=120 frames=120 passes=240 visibility_evaluations=%d native_geometry_getters=%d camera_basis_reads=%d native_draws=%d wireframes=%d native_fps_measured=false',
   work.visibility_evaluations,work.geometry_getters,work.camera_basis_reads,work.native_draws,work.wireframes))
  if viewGate then assert(work.visibility_evaluations==14400,'duplicate exact views repeat box visibility arithmetic') end
 end
 print(format('LOW_END_SUPPORT_WORK entities=120 rotated=30 frames=120 passes=240 absolute_values=%d native_geometry_getters=%d camera_basis_reads=%d native_draws=%d wireframes=%d native_fps_measured=false',
  work.absolute_values,work.geometry_getters,work.camera_basis_reads,work.native_draws,work.wireframes))
 assert(work.geometry_getters==115200 and work.camera_basis_reads==2160
  and work.wireframes==9600,'support reuse skipped live geometry/camera reads or glyph submissions')
 if requireWork then assert(work.absolute_values==0,'unchanged view axes repeat plane-support arithmetic') end
 -- Visibility itself stays live as the eye crosses the same support planes.
 for _,x in ipairs({0,1490,1600,1800,5000,-1000}) do
  view.origin.x=x;view.origin.y=0;view.origin.z=0
  local n=sample('eye-x-'..x)
  if x==5000 then assert(n==0,'translation borrowed a visibility result') end
 end
 for _,y in ipairs({0,900,3000,-3000}) do view.origin=Vector(0,y,0);sample('eye-y-'..y) end
 for _,z in ipairs({0,900,3000,-3000}) do view.origin=Vector(0,0,z);sample('eye-z-'..z) end
 view.origin=Vector()
 for _,fov in ipairs({30,70,90,110,179.9}) do view.fov=fov;sample('fov-'..fov) end
 view.fov=90
 for _,aspect in ipairs({.5,1,1.6,2,3}) do view.aspect=aspect;sample('aspect-'..aspect) end
 view.aspect=1.6
 for _,a in ipairs({{0,0,0},{0,90,0},{20,45,30},{-35,10,-50},{0,0,90},{0,0,0}}) do
  view.angles.p,view.angles.y,view.angles.r=table.unpack(a);sample('angle-'..table.concat(a,','))
 end
 local e=scene[1]
 e.maxs.x=200;sample('mutable-bounds')
 e.pos.x=-500;sample('mutable-position')
 e.ang.p,e.ang.y,e.ang.r=45,90,27;sample('mutable-pose')
 e.mins=Vector(-300,-20,-10);e.maxs=Vector(300,20,10);e.pos=Vector(1400,0,0);e.ang=Angle()
 sample('replacement-geometry')
 local getter=e.GetBoxMins
 e.GetBoxMins=function() return Vector(-320,-21,-11) end;sample('accessor-override');e.GetBoxMins=getter
 e.nw.LOD_GeometryHidden=true;sample('hidden')
 view.angles.y=90;sample('turn-hidden');e.nw.LOD_GeometryHidden=false;sample('reveal-after-turn')
 view.angles.y=0;e:SetBoxKind(3);sample('collision-kind');e:SetBoxKind(1);sample('visible-kind')
 e.nw.LOD_EventArchetype='false_floor';sample('false-floor');e.nw.LOD_EventArchetype=nil
 e.nw.LOD_CrateGrate=true;sample('grate');e.nw.LOD_CrateGrate=false
 e:OnRemove(true);sample('full-update');fire('NotifyShouldTransmit',e,true);sample('transmission')
 e.valid=false;sample('invalid-owner');e.valid=true;sample('valid-owner')
 local complete=view
 local originalEyePos,originalEyeVector=EyePos,EyeVector
 -- Incomplete render metadata does not remove the engine's eye APIs.
 EyePos=function() return view.origin or complete.origin end
 EyeVector=function() return (view.angles or complete.angles):Forward() end
 for i,v in ipairs({{ortho={},fov=90,znear=1},{offcenter={},fov=90,znear=1},
  {fov=180,znear=1},{fov=90,znear=-1},{fov=90,znear=1},{}}) do
  view=v;sample('incomplete-view-'..i)
 end
 view=complete;sample('complete-view');EyePos,EyeVector=originalEyePos,originalEyeVector
 local slab=B.DrawSlab;B.DrawSlab=nil;sample('native-fallback');B.DrawSlab=slab
 -- A child view replaces the most recent plane set while the parent keeps its
 -- own immutable coefficients. Return to the outer pass without a stale cache.
 interruptDraw=function()
  local parent=view;view={origin=Vector(-100,200,0),angles=Angle(25,60,35),fov=60,aspect=.8,znear=1}
  sample('nested-child');view=parent
 end
 sample('nested-parent');sample('after-nested')
 dofile(entityPath);sample('renderer-refresh');sample('after-refresh')
 if viewProbe or viewGate then
  -- Keys are exact, even immediately beside the one-unit rear-plane boundary.
  -- Equal angle scalars do not permit stale native basis getters either.
  view={origin=Vector(),angles=Angle(),fov=90,aspect=1.6,znear=1}
  e.pos=Vector(1400,0,0);e.ang=Angle();e.mins=Vector(-300,-20,-10);e.maxs=Vector(300,20,10)
  local marker=format('%g,%g,%g',e.pos.x,e.pos.y,e.pos.z)
  for i,x in ipairs({1701-1e-10,1701,1701+1e-10,1701,1701-1e-10}) do
   view.origin.x=x
   for pass=1,2 do
    sample('exact-edge-'..i..'-'..pass)
    assert((seen[marker]==true)==(x<=1701),'exact eye change borrowed an opposite visibility decision')
   end
  end
  view.origin=Vector()
  for i,v in ipairs({90,90+1e-10,90,90-1e-10}) do
   view.fov=v;sample('exact-fov-'..i..'-a');sample('exact-fov-'..i..'-b')
  end
  view.fov=90
  for i,v in ipairs({1.6,1.6+1e-10,1.6,1.6-1e-10}) do
   view.aspect=v;sample('exact-aspect-'..i..'-a');sample('exact-aspect-'..i..'-b')
  end
  view.aspect=1.6
  view.angles.Forward=function() return Angle(0,90,0):Forward() end
  sample('native-basis-override-a');sample('native-basis-override-b')
  view.angles.Forward=nil;sample('native-basis-restored-a');sample('native-basis-restored-b')
 end
 for _,flags in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do
  local before=geometryReads;fire('PostDrawOpaqueRenderables',table.unpack(flags))
  assert(geometryReads==before,'excluded pass queried geometry')
 end
 resetScene();sample('removed-scene');supportCapture=false
 if tracePath then
  local f=assert(io.open(tracePath,'wb'));f:write(table.concat(traces,'\n'));f:close()
 end
 print(format('LOW_END_SUPPORT_PARITY passes=%d exact_native_mesh_wireframe_fallback_values=true; eye translation, axes/projection, mutable bounds/pose, live getters, hazards/grates, life/kind, full update, incomplete/nested views, refresh/removal',passes))
 return work
end
if supportProbe or supportGate or viewProbe or viewGate then supportCases(supportGate or viewGate,arg[4]);return end
-- Same 120 visible static entities; alternating floors/stairs share few meshes.
for i=1,120 do
 local e=box(Vector(1000+i*2,(i%5)*16,(i%3)*16),i%2+1)
 e.pos,e.mins,e.maxs=nativeVector(e.pos),nativeVector(e.mins),nativeVector(e.maxs)
end
assert(frame()==120)
if submissionSignature then
 table.sort(submissionSignature)
 local f=assert(io.open(arg[4],'wb'));f:write(table.concat(submissionSignature,'\n'));f:close()
 submissionSignature=nil
end
formats,matrices,geometryReads,absoluteValues,axisReads,nativeVectorReads=0,0,0,0,0,0
for _=1,120 do assert(frame()==120) end
print(format('LOW_END_STATIC_WORK entities=120 frames=120 cache_key_formats=%d matrix_allocations=%d native_peak_meshes=%d',formats,matrices,peak))
if not baseline then assert(formats==0 and matrices==0,'static drawing repeats compilation/transform allocation') end
print(format('LOW_END_NATIVE_GETTERS entities=120 frames=120 reads=%d native_fps_measured=false',geometryReads))
if not baseline then assert(geometryReads==4*120*120,'drawable boxes repeat native geometry reads within a pass') end
print(format('LOW_END_DRAW_SNAPSHOT entities=120 passes=120 native_vector_components=%d native_fps_measured=false',nativeVectorReads))
if not baseline and not parity and not stateProbe then assert(nativeVectorReads==9*120*120,'mesh cache repeats the renderer native scalar reads') end
print(format('LOW_END_PLANE_WORK entities=120 passes=120 absolute_values=%d basis_component_reads=%d native_fps_measured=false',absoluteValues,axisReads))
if not baseline then
 assert(absoluteValues<=20*120,'identity-axis support repeats plane arithmetic per box')
 assert(axisReads<=9*120,'unchanged box support repeats native basis component reads')
end
resetScene()
-- A warmed continuous floor pass must preserve each mesh's state while avoiding
-- native set/reset calls for every adjacent draw. Both exact-source paired runs
-- execute this same production scene; the parent fails the bounded-work gate.
for i=1,120 do box(Vector(1000+i*2,(i%5)*16,0),1) end
assert(frame()==120)
if stateProbe and arg[4] then submissionSignature={};assert(frame()==120) end
local signatureRows=submissionSignature
submissionSignature=nil
stateCalls=0
for _=1,120 do
 assert(frame()==120)
 assert(not currentMatrix and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'pass left native state applied')
end
local floorStateCalls=stateCalls
print(format('LOW_END_STATE_WORK entities=120 passes=120 submissions=14400 native_state_calls=%d native_fps_measured=false',floorStateCalls))
if not baseline and not parity and not stateProbe then assert(floorStateCalls<=600,'floor pass repeats native material/tint/blend writes') end
resetScene()
for i,kind in ipairs({1,2,5,1,1,2,5}) do
 local e=box(Vector(1000+i*2,0,0),kind)
 if i==4 then e.nw.LOD_CrateGrate=true end
 if i==5 then e.nw.LOD_EventArchetype='false_floor' end
end
assert(frame()==7)
if signatureRows then
 submissionSignature=signatureRows;assert(frame()==7);submissionSignature=nil
 table.sort(signatureRows)
 local f=assert(io.open(arg[4],'wb'));f:write(table.concat(signatureRows,'\n'));f:close()
 print(format('LOW_END_STATE_PARITY submissions=%d mesh_wireframe_bytes_recorded=true',#signatureRows))
end
if stateProbe then resetScene();return end

if not parity and not baseline then
 -- Unknown/replaced draw helpers retain direct-call behavior. Their callers
 -- may depend on neutral state immediately after each mesh, including wrappers.
 local original=B.DrawSlab
 local wrappedCalls=0
 B.DrawSlab=function(self,...)
  original(self,...);wrappedCalls=wrappedCalls+1
  assert(blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'wrapped helper was silently batched')
  lastMaterial=wireMaterial
 end
 assert(frame()==7 and wrappedCalls>0);B.DrawSlab=original
 local neutral=B.NeutralDrawState;B.NeutralDrawState=nil;assert(frame()==7);B.NeutralDrawState=neutral
 local scope=B.WithDrawState;B.WithDrawState=nil;assert(frame()==7);B.WithDrawState=scope
 resetScene();box(Vector(1000,0,0),1)
 local before=fallbacks;B.DrawSlab=nil;frame();assert(fallbacks==before+1);B.DrawSlab=original
 -- Real generated mesh errors must balance the model stack and restore native
 -- color/blend before another ordinary API call or the following render pass.
 failDraw=true;local ok,err=pcall(frame);failDraw=false
 assert(not ok and tostring(err):find('injected native mesh draw failure',1,true))
 assert(not currentMatrix and #matrixStack==0 and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'throwing pass leaked owned native state')
 assert(frame()==1)
 local p,a,mn,mx=Vector(2000,0,0),Angle(),Vector(-8,-8,-4),Vector(8,8,4)
 local outerColor,innerColor=Color(80,100,120,192),Color(120,80,40,96)
 B:WithDrawState(function()
  B:Draw(p,a,mn,mx,material,outerColor)
  local emptyCalls=stateCalls
  B:WithDrawState(noop)
  assert(stateCalls==emptyCalls and lastMaterial==material and blend==outerColor.a/255
   and tint[1]==outerColor.r/255 and tint[2]==outerColor.g/255 and tint[3]==outerColor.b/255,'empty child altered outer borrowed state')
  interruptDraw=function()
   B:WithDrawState(function() B:Draw(p,a,mn,mx,grateMaterial,innerColor) end)
  end
  B:Draw(p,a,mn,mx,material,outerColor)
  local outerMaterial,outerBlend,r,g,b=lastMaterial,blend,tint[1],tint[2],tint[3]
  failDraw=true;local childOk=pcall(function()
   B:WithDrawState(function() B:Draw(p,a,mn,mx,grateMaterial,innerColor) end)
  end);failDraw=false
  assert(not childOk and not currentMatrix and #matrixStack==0)
  assert(lastMaterial==outerMaterial and blend==outerBlend and tint[1]==r and tint[2]==g and tint[3]==b,'throwing child lost outer render state')
  B:Draw(p,a,mn,mx,grateMaterial,innerColor)
  assert(lastDraw.material==grateMaterial and lastDraw.blend==innerColor.a/255
   and lastDraw.tint[1]==innerColor.r/255 and lastDraw.tint[2]==innerColor.g/255 and lastDraw.tint[3]==innerColor.b/255,'live material/tint/alpha transition lost')
 end)
 assert(not currentMatrix and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1)
 stateCalls=0;B:Draw(p,a,mn,mx,material,outerColor)
 assert(stateCalls==5 and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'direct draw inherited a completed scope')
 local callbackOk=pcall(function() B:WithDrawState(function() error('injected callback failure') end) end)
 assert(not callbackOk and not currentMatrix and blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1)
 -- An empty, fully culled or failing-before-draw scope owns no native state.
 -- Preserve arbitrary incoming addon state without even redundant resets.
 resetScene()
 lastMaterial,blend,tint=wireMaterial,0.37,{0.2,0.3,0.4}
 stateCalls=0
 local function untouched()
  assert(stateCalls==0 and lastMaterial==wireMaterial and blend==0.37
   and tint[1]==0.2 and tint[2]==0.3 and tint[3]==0.4,'empty scope altered unowned native state')
 end
 assert(frame()==0);untouched()
 box(Vector(-1000,0,0),1);assert(frame()==0);untouched()
 B:WithDrawState(function() B:WithDrawState(noop) end);untouched()
 local emptyOk=pcall(function() B:WithDrawState(function() error('before first draw') end) end)
 assert(not emptyOk);untouched()
 lastMaterial,blend,tint=material,1,{1,1,1}
 print('LOW_END_STATE_LIFETIME_PASS: mixed floor/stair/grate/false-floor; neutral wireframes; replacement/missing helpers; nested material/alpha; owned error unwind; untouched empty/culled scopes; ordinary API')
end
resetScene()
-- Generated mazes have far more collision-only boxes than drawn floors. Keep
-- the same weak registry/order and all submissions; observe declared kind
-- deltas instead of querying every native BoxKind on every render pass.
resetScene()
for i=1,1200 do box(Vector(1000+i*2,0,0),i<=120 and 1 or (i%2==0 and 3 or 7),true) end
assert(frame()==120)
local kindSignatures=kindProbe and arg[4] and {} or nil
submissionSignature=kindSignatures;assert(frame()==120);submissionSignature=nil
kindReads,validityCalls,collisionFieldReads,drawableFieldReads=0,0,0,0
for _=1,120 do assert(frame()==120) end
local steadyKindReads=kindReads
local steadyValidityCalls=validityCalls
local steadyCollisionFieldReads=collisionFieldReads
local steadyDrawableFieldReads=drawableFieldReads
print(format('LOW_END_KIND_WORK entities=1200 drawable=120 passes=120 submissions=14400 native_kind_reads=%d native_validity_calls=%d collision_entity_field_reads=%d native_fps_measured=false',steadyKindReads,steadyValidityCalls,steadyCollisionFieldReads))
print(format('LOW_END_DRAWABLE_TABLE_WORK drawable=120 passes=120 submissions=14400 native_entity_field_reads=%d native_fps_measured=false',steadyDrawableFieldReads))
if not kindProbe and not parity and not baseline then
 assert(steadyKindReads==0,'declared static kinds still poll native datatables per pass')
 assert(steadyValidityCalls==14400,'collision-only boxes still poll native validity per pass')
 assert(steadyCollisionFieldReads==0,'cached invisible boxes still index native entity fields per pass')
 assert(steadyDrawableFieldReads<=12*14400,'drawable boxes repeat verified Lua-table field lookups through native entity indexing')
end
local changing=entities[121]
local function kindFrame(expected,label)
 submissionSignature=kindSignatures
 assert(frame()==expected,label)
 submissionSignature=nil
end
changing:SetBoxKind(1);kindFrame(121,'notified wall-to-floor change delayed')
changing:SetBoxKind(3);kindFrame(120,'notified floor-to-wall change delayed')
changing:SetBoxKind(2);kindFrame(121,'notified stair kind lost')
changing:SetBoxKind(5);kindFrame(121,'notified underdeck kind lost')
-- A proxy invalidates even when its old/new values agree, or when the native
-- value has not yet changed. Reentrant callbacks must not freeze that old kind.
changing:SetBoxKind(3);assert(frame()==120)
table.insert(changing.notifies.BoxKind,function() assert(frame()==120,'proxy drew an uncommitted kind') end)
changing:SetBoxKind(1);assert(frame()==121,'reentrant proxy retained the old native kind')
changing.notifies.BoxKind[#changing.notifies.BoxKind]=nil
changing:SetBoxKind(1);assert(frame()==121)
for _,fn in ipairs(changing.notifies.BoxKind) do fn(changing,'BoxKind',1,5) end
assert(frame()==121,'receive-only diagnostic proxy changed native geometry')
changing:SetBoxKind(1);assert(frame()==121)
-- A missed spawn proxy from zero to a received kind must recover next pass.
local lateKind=box(Vector(1100,0,0),0,true)
assert(frame()==121);lateKind.kind=1;assert(frame()==122,'initial replication missed by proxy delayed drawing')
-- Unknown getters/setters and unobserved legacy boxes always poll live state.
local originalGet,originalSet=changing.GetBoxKind,changing.SetBoxKind
changing.GetBoxKind=function() kindReads=kindReads+1;return changing.kind end
changing.kind=3;assert(frame()==121);changing.kind=1;assert(frame()==122)
changing.GetBoxKind=originalGet;assert(frame()==122)
changing.SetBoxKind=function(_,k) changing.kind=k end
changing:SetBoxKind(3);assert(frame()==121);changing:SetBoxKind(1);assert(frame()==122)
changing.SetBoxKind=originalSet;assert(frame()==122)
local legacy=box(Vector(1120,0,0),3);assert(frame()==122)
legacy.kind=1;assert(frame()==123);legacy.kind=3;assert(frame()==122)
-- Full updates/transmission can miss a proxy and retain an entity. Reset cached
-- classification immediately; missing bounds still fail open to future retries.
changing:OnRemove(true);changing.kind=3;assert(frame()==121)
changing.kind=1;fire('NotifyShouldTransmit',changing,true);assert(frame()==122)
local savedMins=changing.GetBoxMins;changing.GetBoxMins=nil;assert(frame()==121)
changing.GetBoxMins=savedMins;assert(frame()==122)
changing:OnRemove(false);assert(frame()==121)
fire('NotifyShouldTransmit',changing,true);assert(frame()==122)
-- Reinstalling datatables (Lua refresh) creates a new declared accessor pair.
changing:SetupDataTables();changing:SetBoxKind(3);assert(frame()==121)
changing:SetBoxKind(1);assert(frame()==122)
CLIENT=false;SERVER=true
local serverOnly=box(Vector(1130,0,0),3,true)
assert(not serverOnly._LODVisualKindGetter and #serverOnly.notifies.BoxKind==0,'client observer installed on server')
CLIENT=true;SERVER=false
serverOnly.kind=1;assert(frame()==123);serverOnly.kind=3;assert(frame()==122)
serverOnly:OnRemove(false)
local record=changing._LODVisualKindRecord
if record then
 assert(getmetatable(record.lua).__mode=='v','registry retains bound entity closures through its value')
 local data=changing:GetTable();record.lua[1]=nil
 changing.kind=3;assert(frame()==121,'expired Lua-table borrow lost live polling')
 changing.kind=1;assert(frame()==122);record.lua[1]=data;assert(frame()==122)
 -- A custom GetTable returning a copy cannot stand in for the real storage.
 local tableGetter=changing.GetTable
 changing.GetTable=function()
  local copy={};for k,v in pairs(data) do copy[k]=v end;return copy
 end
 changing:SetupDataTables();fire('NotifyShouldTransmit',changing,true)
 changing:SetBoxKind(3);assert(frame()==121);changing:SetBoxKind(1);assert(frame()==122)
 changing.GetTable=tableGetter;changing:SetupDataTables();fire('NotifyShouldTransmit',changing,true)
 assert(frame()==122)
 changing:SetBoxKind(3);assert(frame()==121)
 changing.valid=false;assert(frame()==121,'invalid cached collision box called native geometry')
 changing.valid=true;changing:SetBoxKind(1);assert(frame()==122)
 local kindGetter=changing.GetBoxKind
 changing.GetBoxKind=function() error('invalid native kind getter') end
 changing.valid=false;assert(frame()==121,'invalid drawable called a native getter')
 changing.valid=true;changing.GetBoxKind=kindGetter;assert(frame()==122)
end
-- The table borrow removes field lookup work, never the native geometry read.
-- Exercise the observed path with in-place bounds/pose and accessor replacement.
local savedMin,savedMax,savedPos,savedAng=changing.mins,changing.maxs,changing.pos,changing.ang
changing.mins=nativeVector(Vector(-8,-8,-4));changing.maxs=nativeVector(Vector(8,8,4))
changing.pos=nativeVector(Vector(1125,0,0))
assert(frame()==122)
local slab,snapshotReads=B.DrawSlab,nil
B.DrawSlab=function(self,pos,ang,mins,maxs,mat,color,tile,owner,...)
 if owner==changing then snapshotReads=nativeVectorReads end
 return slab(self,pos,ang,mins,maxs,mat,color,tile,owner,...)
end
nativeVectorReads=0;changing.mins.x=-12;assert(frame()==122);B.DrawSlab=slab
assert(changing._LODVisualBox.x0==-12,'borrowed Lua table retained stale mutable bounds')
-- Every observed box rechecks its native values on this pass. The changed
-- box consumes each position/bounds component only once before snapshot rebuild.
if not kindProbe then assert(snapshotReads==9,'snapshot rebuild repeated native vector components') end
changing.pos.x=1135;changing.ang=Angle(0,5,0);assert(frame()==122)
assert(changing._LODVisualBox.px==1135 and changing._LODVisualBox.yaw==5,'borrowed table retained stale pose')
local currentMins=changing.GetBoxMins
changing.GetBoxMins=function() return Vector(-17,-19,-23) end
assert(frame()==122 and changing._LODVisualBox.x0==-17,'table borrow bypassed a live geometry accessor override')
changing.GetBoxMins=currentMins
local inheritedMins=ENT.GetBoxMins
ENT.GetBoxMins=currentMins;changing.GetBoxMins=nil
assert(frame()==122,'missing instance accessor did not recover through the live class')
changing.GetBoxMins=currentMins;ENT.GetBoxMins=inheritedMins
changing.nw.LOD_GeometryHidden=true;assert(frame()==121)
changing.nw.LOD_GeometryHidden=false
changing.mins,changing.maxs,changing.pos,changing.ang=savedMin,savedMax,savedPos,savedAng;assert(frame()==122)
submissionSignature=kindSignatures;assert(frame()==122);submissionSignature=nil
if kindSignatures then
 table.sort(kindSignatures)
 local f=assert(io.open(arg[4],'wb'));f:write(table.concat(kindSignatures,'\n'));f:close()
 print(format('LOW_END_KIND_PARITY submissions=%d exact_mesh_bytes_recorded=true',#kindSignatures))
end
print('LOW_END_KIND_LIFETIME_PASS: declared native proxies; same-pass transitions; pre-write reentrancy; missed initial replication; legacy/replaced accessors; weak/copy Lua-table fallback; invalid native guards; full update/transmission; missing datatables; removal')
resetScene()
if not kindProbe and not parity and not baseline then
 local weak=setmetatable({}, {__mode='v'})
 do
  local e=box(Vector(1100,0,0),3,true);weak[1]=e;assert(frame()==0)
  -- Lose the fixture's strong scene list; the registry must not retain it.
  entities={}
 end
 collectgarbage('collect');collectgarbage('collect')
 assert(not weak[1] and next(B.StaticVisualBoxes)==nil,'weak kind registry retained a native owner')
end
if kindProbe then return end
-- Simulate Source honoring SetNextClientThink/true, including the existing
-- one-second deadline. The parent invokes each callback every rendered frame.
for i=1,120 do box(Vector(1000+i*2,(i%5)*16,(i%3)*16),i%2+1) end
assert(frame()==120)
local callbacks=0
for i=1,600 do
 now=100+(i-1)/60
 for _,e in ipairs(entities) do
  if now>=(e.thinkAt or 0) then
   callbacks=callbacks+1
   if e:Think()~=true then e.thinkAt=now end
  end
 end
end
print(format('LOW_END_STATIC_THINK entities=120 frames=600 callbacks=%d native_fps_measured=false',callbacks))
if not baseline then
 assert(callbacks<=120*11,'native idle Think was not scheduled at the existing refresh deadline')
 local e=entities[1];local getter=e.GetBoxMins;e.GetBoxMins=nil
 fire('NotifyShouldTransmit',e,true);assert(e.thinkAt==now,'transmission did not wake deferred bounds')
 assert(e:Think()~=true,'incomplete datatables were put to sleep')
 e.GetBoxMins=getter;assert(e:Think()==true and e.thinkAt>now,'ready datatables did not reschedule')
end
resetScene()
-- Every generated drawing route borrows the same validated snapshot, including
-- grates and the underdeck. A direct call with different arguments falls back
-- to the raw API even when the owner carries a valid generated snapshot.
for i,kind in ipairs({1,2,5,1}) do
 local e=box(Vector(1000+i*2,0,0),kind)
 e.pos,e.mins,e.maxs=nativeVector(e.pos),nativeVector(e.mins),nativeVector(e.maxs)
 if i==4 then e.nw.LOD_CrateGrate=true end
end
assert(frame()==4)
nativeVectorReads=0;assert(frame()==4)
if not parity then assert(nativeVectorReads==36,'floor/stair/underdeck/grate repeated validated vector reads') end
local e=entities[1]
local changedPos=Vector(1400,25,30)
B:DrawSlab(changedPos,e.ang,e.mins,e.maxs,material,color_white,512,e,e._LODVisualBox)
assert(lastDraw.matrix.pos.x==1400 and lastDraw.matrix.pos.y==25 and lastDraw.matrix.pos.z==30,
 'mismatched draw arguments borrowed the owner snapshot')
resetScene()
-- Fixed camera distribution: 100 visible, 200 outside side/top/bottom, 300 rear.
for i=1,600 do
 local pos
 if i<=100 then pos=Vector(1000+i,0,0)
 elseif i<=200 then pos=Vector(1000,3000+i,0)
 elseif i<=300 then pos=Vector(1000,0,(i%2==0 and 1 or -1)*(3000+i))
 else pos=Vector(-1000-i,0,0) end
 box(pos)
end
local submitted=frame()
print(format('LOW_END_VIEW_WORK entities=600 submitted=%d native_fps_measured=false',submitted))
for i=1,100 do assert(seen[format('%g,0,0',1000+i)],'visible box lost') end
if not baseline then assert(submitted==100,'side/top/bottom culling absent') end
resetScene()
-- Long thin floor runs: their enclosing spheres intersect the camera but the
-- actual surfaces are wholly beyond a side plane. Retain all visible stairs,
-- floors and one camera-enclosing underdeck without a distance/floor shortcut.
for i=1,100 do box(Vector(1000+i,0,0),i%2+1) end
for i=1,100 do
 local e=box(Vector(4000,6000+i*2,0))
 e.mins=Vector(-1800,-16,-16);e.maxs=Vector(1800,16,16)
end
for i=1,100 do
 local e=box(Vector(1000,0,0))
 e.mins=Vector(0,3000+i,-16);e.maxs=Vector(64,3500+i,16)
end
local deck=box(Vector(),5);deck.mins=Vector(-4096,-4096,-32);deck.maxs=Vector(4096,4096,0)
submitted=frame()
for i=1,100 do assert(seen[format('%g,0,0',1000+i)],'visible elongated-scene box lost') end
assert(seen['0,0,0'],'camera-enclosing underdeck lost')
print(format('LOW_END_ELONGATED_VIEW entities=301 submitted=%d native_fps_measured=false',submitted))
if baseline then resetScene();return end
assert(submitted==101,'wholly off-camera thin/offset slabs over-admitted')
resetScene()
-- Exercise actual renderer under changing aspect/FOV, pitch/yaw/roll and camera.
local e=box(Vector(1000,800,0))
view.fov=90;assert(frame()==1)
view.fov=60;assert(frame()==0);view.fov=120;assert(frame()==1)
e.pos=Vector(1000,0,800);view.fov=90;view.aspect=1;assert(frame()==1)
view.aspect=2;assert(frame()==0)
view.angles=Angle(0,0,90);assert(frame()==1,'roll ignored')
view.angles=Angle(-90,0,0);e.pos=Vector(0,0,1000);assert(frame()==1,'pitch ignored')
view.angles=Angle(0,180,0);e.pos=Vector(-1000,0,0);assert(frame()==1,'yaw ignored')
view.origin=Vector(-2000,0,0);assert(frame()==0,'moved camera ignored')
view.angles=Angle();assert(frame()==1)
-- Active view wins even if an addon exposes different main EyePos/EyeVector.
local savedEye,savedForward=EyePos,EyeVector
EyePos=function() return Vector(2000,0,0) end;EyeVector=function() return Vector(-1,0,0) end
assert(frame()==1,'nested view used main camera');EyePos,EyeVector=savedEye,savedForward
view.origin=Vector();view.angles=Angle();view.aspect=1.6
e.pos=Vector(1000,1010,0);assert(frame()==1,'plane-intersecting sphere rejected')
e.pos=Vector(0,0,0);assert(frame()==1,'camera-intersecting sphere rejected')
e.pos=Vector(10,300,0);e.maxs.y=600;e.ang=Angle(37,92,18)
assert(frame()==0,'wholly outside rotated box retained by its enclosing sphere')
e.pos=Vector(600,0,0);assert(frame()==1,'visible asymmetric/rotated box rejected')
e.pos=Vector(10,300,0)
e.maxs.y=8;assert(frame()==0,'changed bounds not observed')
for _,field in ipairs({'ortho','offcenter'}) do view[field]={};assert(frame()==1);view[field]=nil end
local savedAspect=view.aspect;view.aspect=nil;assert(frame()==1,'unknown aspect must not side-cull');view.aspect=savedAspect
e.pos=Vector(1000,0,0);e.nw.LOD_GeometryHidden=true;assert(frame()==0)
e:OnRemove(true);e.nw.LOD_GeometryHidden=false;assert(frame()==1)
e:OnRemove(false);assert(frame()==0);fire('NotifyShouldTransmit',e,true);assert(frame()==1)
-- Existing entities can still carry the previous file's cached native basis
-- when only the renderer is hot-reloaded. Rebuild before borrowing new fields.
local priorSnapshot=e._LODVisualBox
ENT={};dofile(entityPath)
assert(frame()==1,'renderer refresh delayed a registered floor')
assert(e._LODVisualBox~=priorSnapshot,'renderer refresh borrowed a previous snapshot schema')
-- Independent corner projection oracle: every sampled visible corner requires a
-- draw. Culling may conservatively retain more, but may never hide such a box.
local function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
local checked=0
for _,aspect in ipairs({.6,1,1.6,2.4}) do
 for _,fov in ipairs({40,75,110,150}) do
  for j=1,60 do
   view.aspect=aspect;view.fov=fov;view.angles=Angle((j*17)%160-80,(j*43)%360,(j*31)%360)
   view.origin=Vector(57,-93,18)
   e.pos=Vector((j*317)%2400-1200,(j*211)%2400-1200,(j*131)%1600-800)
   e.ang=Angle((j*19)%180,(j*29)%360,(j*37)%360)
   e.mins=Vector(-10-j*2,-17,-31);e.maxs=Vector(24,50+j,80)
   local visible=false
   for _,x in ipairs({e.mins.x,e.maxs.x}) do for _,y in ipairs({e.mins.y,e.maxs.y}) do for _,z in ipairs({e.mins.z,e.maxs.z}) do
    local f,r,u=e.ang:Forward(),e.ang:Right(),e.ang:Up()
    local p=Vector(e.pos.x+f.x*x-r.x*y+u.x*z,e.pos.y+f.y*x-r.y*y+u.y*z,e.pos.z+f.z*x-r.z*y+u.z*z)-view.origin
    local depth=dot(p,view.angles:Forward());local half=math.tan(math.rad(fov/2))
    if depth>1 and math.abs(dot(p,view.angles:Right())/depth)<=half
     and math.abs(dot(p,view.angles:Up())/depth)<=half/aspect then visible=true end
   end end end
   local n=frame();if visible then assert(n==1,'visible projected corner culled');checked=checked+1 end
  end
 end
end
assert(checked>50)
-- Independent eight-corner support oracle: if EVERY frustum plane contains at
-- least one corner, the conservative culler must retain the box, even when no
-- corner itself lies inside the whole frustum (large/intersecting slabs).
local conservative,crossing=0,0
for j=1,400 do
 view.aspect=.7+(j%8)*.3;view.fov=45+(j%9)*12;view.origin=Vector(23,-67,13)
 view.angles=Angle((j*17)%160-80,(j*43)%360,(j*31)%360)
 e.pos=Vector((j*317)%4800-2400,(j*211)%4800-2400,(j*131)%2400-1200)
 e.ang=Angle((j*19)%180,(j*29)%360,(j*37)%360)
 e.mins=Vector(-400-j*3,-17,-31);e.maxs=Vector(24,50+j*2,80)
 local cf,cr,cu=view.angles:Forward(),view.angles:Right(),view.angles:Up()
 local tx=math.tan(math.rad(view.fov/2));local ty=tx/view.aspect
 local maxima={-math.huge,-math.huge,-math.huge,-math.huge,-math.huge}
 local cornerInside=false
 for _,x in ipairs({e.mins.x,e.maxs.x}) do for _,y in ipairs({e.mins.y,e.maxs.y}) do for _,z in ipairs({e.mins.z,e.maxs.z}) do
  local f,r,u=e.ang:Forward(),e.ang:Right(),e.ang:Up()
  local p=Vector(e.pos.x+f.x*x-r.x*y+u.x*z,e.pos.y+f.y*x-r.y*y+u.y*z,e.pos.z+f.z*x-r.z*y+u.z*z)-view.origin
  local d,s,h=dot(p,cf),dot(p,cr),dot(p,cu)
  local inside=true
  for k,v in ipairs({d,d*tx-s,d*tx+s,d*ty-h,d*ty+h}) do
   maxima[k]=math.max(maxima[k],v);if v<0 then inside=false end
  end
  if inside then cornerInside=true end
 end end end
 local mustRetain=true;for _,v in ipairs(maxima) do if v<0 then mustRetain=false end end
 if mustRetain then
  assert(frame()==1,'intersecting box rejected by a frustum plane');conservative=conservative+1
  if not cornerInside then crossing=crossing+1 end
 end
end
assert(conservative>20 and crossing>0)
view.origin=Vector();view.angles=Angle();view.aspect=1.6;view.fov=90
e.pos=Vector(1000,1200,0);e.ang=Angle();e.mins=Vector(-100,-100,-16);e.maxs=Vector(100,100,16)
assert(frame()==1,'exact side-plane tangency rejected')
e.pos.y=1202;assert(frame()==0,'strictly outside tangent box retained')
local before=draws
for _,args in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do
 fire('PostDrawOpaqueRenderables',table.unpack(args));assert(draws==before,'depth/sky pass submitted static geometry')
end
e.pos=Vector(1000,0,0);assert(frame()==1)
dofile(entityPath);assert(frame()==1,'scheduled Think delayed floor registration after Lua refresh')
resetScene()
-- Direct calls also keep their historical uncached-owner API, vertex UVs, tint
-- and transform. In-place mutations and eviction must rebuild only what changed.
local owner={};local pos,ang,mins,maxs=Vector(140,233,0),Angle(),Vector(-128,-64,-16),Vector(128,64,16)
local function signature(obj)
 local out={};for _,v in ipairs(obj.vertices) do out[#out+1]=format('%g,%g,%g|%.9g,%.9g',v.pos.x,v.pos.y,v.pos.z,v.u,v.v) end
 return table.concat(out,';')
end
local function check(kind)
 if kind=='slab' then
  B:DrawSlab(pos,ang,mins,maxs,material,color_white,512,owner)
  assert(signature(lastDraw.mesh)==signature(B:GetSlabMesh(mins,maxs,512,pos,ang)))
 elseif kind=='box' then
  B:Draw(pos,ang,mins,maxs,material,color_white,512,owner)
  assert(signature(lastDraw.mesh)==signature(B:GetMesh(mins,maxs,512)))
 else B:DrawGrate(pos,ang,mins,maxs,owner);assert(#lastDraw.mesh.vertices>8) end
 assert(lastDraw.matrix.pos.x==pos.x and lastDraw.matrix.pos.y==pos.y and lastDraw.matrix.pos.z==pos.z)
 assert((lastDraw.matrix.ang or angle_zero).p==ang.p and (lastDraw.matrix.ang or angle_zero).y==ang.y and (lastDraw.matrix.ang or angle_zero).r==ang.r)
 assert(blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'render state leaked')
end
check('slab');local first=lastDraw.mesh;matrices=0
-- An unrelated snapshot must never displace the ordinary direct-call inputs.
owner._LODVisualBox={position=pos,angles=ang,mins=mins,maxs=maxs}
B:DrawSlab(pos,ang,mins,maxs,material,color_white,512,owner,{px=9999,x0=9999})
assert(lastDraw.mesh==first and lastDraw.matrix.pos.x==pos.x,'unmatched snapshot bypassed the direct API')
pos.z=128;check('slab');assert(lastDraw.mesh==first and matrices==1,'Z movement rebuilt planar UVs or left stale matrix')
pos.x=141;check('slab');assert(lastDraw.mesh~=first)
ang.y=90;check('slab');ang.p=30;ang.r=25;check('slab')
maxs.x=192;check('slab');check('box');check('grate');check('slab')
local recent=lastDraw.mesh
for i=1,1000 do B:GetMesh(Vector(),Vector(i,7,9));assert(live<=256) end
assert(recent.dead);check('slab');assert(lastDraw.mesh~=recent and not lastDraw.mesh.dead)
local otherMaterial={};B:DrawSlab(pos,ang,mins,maxs,otherMaterial,color_white,256,owner)
assert(lastMaterial==otherMaterial and signature(lastDraw.mesh)==signature(B:GetSlabMesh(mins,maxs,256,pos,ang)))
local beforeDraw=draws;maxs.x=0/0;B:DrawSlab(pos,ang,mins,maxs,material,color_white,512,owner);assert(draws==beforeDraw)
maxs.x=192;check('slab')
fire('PostCleanupMap');assert(live==0);check('slab')
dofile(meshPath);assert(live==0);check('slab')
-- A weak owner cache cannot retain an otherwise unreachable entity.
local weak=setmetatable({owner},{__mode='v'});owner=nil;collectgarbage('collect');assert(weak[1]==nil)
B:DrawSlab(pos,ang,mins,maxs,material,color_white,512);assert(lastDraw.mesh and currentMatrix==nil)
fire('ShutDown');assert(live==0 and peak<=256)
print(format('LOW_END_RENDER_PASS: %d visible-corner and %d conservative plane cases (%d without an inside corner); native getter reuse and scheduled bounds; FOV/aspect/roll/pitch/yaw/nested views; mutations/kind/UV/material/eviction/cleanup/refresh/weak owners; ceiling=256',checked,conservative,crossing))
if not override then supportCases(true) end
