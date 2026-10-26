local f=dofile('tools/test_equipment_economy_runtime.lua')
local E,V=LOD.Equipment,LOD.WeaponAppearance
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local seen,hashes,maxBytes={}, {},0
for i=1,2500 do
    local item=E:Generate(i*197,1+i%100,'weapon_357','visual:'..i)
    local packet=V:Encode(item);maxBytes=math.max(maxBytes,#packet)
    assert(#packet>0 and #packet<=480)
    local style=assert(V:Decode(packet));local raw=assert(V:Compile(V:Data(item)))
    assert(style.hash==raw.hash and #style.traits==#item.properties)
    local frozen=table.Copy(item);frozen.id='recreated:'..i
    assert(V:Encode(frozen)==packet,'DFT recreation/renaming cannot change frozen appearance')
    local reverse=table.Copy(item);local list={};for j=#reverse.properties,1,-1 do list[#list+1]=reverse.properties[j] end
    reverse.properties=list;assert(V:Encode(reverse)==packet,'Property ordering is not identity')
    for _,t in ipairs(style.traits) do seen[t.id]=true;assert(t.glyph~='' and t.bars>=1 and t.bars<=4) end
    assert(not hashes[style.hash],'Sample repeated a full visual fingerprint');hashes[style.hash]=true
end
-- Every catalog property can be represented, including wearable-only properties
-- if future weapon eligibility changes. Each amount affects identity.
for _,id in ipairs(E.EconomyOrder) do
    local g=assert(V.Grammar[id]);assert(g.label and g.shape and g.glyph)
    local data={1,42,1,100,{{g.index,1}}};local first=assert(V:Compile(data))
    data[5][1][2]=2;assert(V:Compile(data).hash~=first.hash)
    data[5][1][2]=-1;local negative=assert(V:Compile(data));assert(negative.traits[1].negative)
end
for _,packet in ipairs({'','bad',string.rep('x',481),'1;0;1;1;999:2','2;0;1;1;1:2','1;nan;1;1;1:2','1;1;1;1;1:2,1:3'}) do
    assert(not V:Decode(packet))
end
local gun=f.actor('visual-owner');gun:Give('weapon_357');gun:SelectWeapon('weapon_357');E:Sync(gun)
local weapon=gun:GetActiveWeapon();local first=weapon.nw.LOD_WeaponAppearance;assert(V:Decode(first))
local copy=E:NewItem(gun,'weapon_357','another');assert(E:AcquireWorldItem(gun,copy,false,'pickup'))
assert(weapon.nw.LOD_WeaponAppearance==first,'Collecting a copy leaves the held style intact')
assert(E:InventoryWeapon(gun,copy.id,false));assert(weapon.nw.LOD_WeaponAppearance==V:Encode(copy))
local writes=0;local old=weapon.SetNW2String
function weapon:SetNW2String(k,v) if k=='LOD_WeaponAppearance' then writes=writes+1 end;return old(self,k,v) end
for i=1,100 do V:Stamp(weapon,copy) end;assert(writes==0,'Unchanged records do not send appearance again')
print('APPEARANCE_DATA_PASS: 2500 distinct sampled fingerprints; all '..#E.EconomyOrder..' properties; max packet '..maxBytes..' bytes; frozen/order identity; copy selection; unchanged sends')

-- Exercise the real renderer with strict engine-resource and material doubles.
local vectors={};vectors.__index=vectors
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vectors) end
vectors.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vectors.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vectors.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
vectors.__unm=function(a) return a*-1 end
function vectors:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function vectors:GetNormalized() return self*(1/math.sqrt(self:Dot(self))) end
function vectors:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
function Angle() return {Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end,Up=function() return Vector(0,0,1) end} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
local calls,now,low,tick=0,0,false,1
local function forbidden() error('Attachment/global render state allocation forbidden') end
render={SetMaterial=function() end,DrawSprite=function() calls=calls+1 end,
    DrawBox=forbidden,DrawBeam=function() calls=calls+1 end,DrawSphere=forbidden,MaterialOverride=forbidden,SetColorModulation=forbidden}
ClientsideModel=forbidden;ParticleEmitter=forbidden;DynamicLight=forbidden;Mesh=forbidden
surface={SetDrawColor=function() end,DrawRect=function() end,DrawLine=function() end}
CurTime=function() return now end;FrameNumber=function() return tick end;EyePos=function() return Vector() end
GetConVar=function() return {GetBool=function() return low end} end
E.DrawItemIcon=function() end
local hooks,receivers={},{}
hook.Add=function(_,id,fn) hooks[id]=fn end
net.Receive=function(id,fn) receivers[id]=fn end
local created,materials=0,{}
local nativeType=type
-- GMod's type() reports ITexture; keep that exact engine boundary while the
-- standalone Lua harness represents native handles with tagged tables.
type=function(value)
    if nativeType(value)=='table' and value.nativeTexture then return 'ITexture' end
    return nativeType(value)
end
local function texture(name,isError)
    return {nativeTexture=true,GetName=function() return name end,
        IsError=function() return isError==true end}
end
local materialProfiles,invalidTextureQueries={},{}
local function material(name,params,stock)
    local profile=materialProfiles[name] or {}
    local m={params=params or {},name=name,base=profile.base or texture(name..'_base')}
    function m:GetName() return self.name end
    function m:GetShader() return profile.shader or 'VertexLitGeneric' end
    function m:IsError() return profile.errorMaterial==true end
    function m:GetString() return '' end
    function m:GetInt(key) return profile.ints and profile.ints[key] or 0 end
    function m:GetKeyValues()
        local values={['$basetexture']=self.base}
        for key,value in pairs(profile.optional or {}) do values[key]=value end
        return values
    end
    function m:GetTexture(key)
        local value=self:GetKeyValues()[key]
        if type(value)=='ITexture' then return value end
        invalidTextureQueries[#invalidTextureQueries+1]={material=name,key=key}
        -- The native warning path can return Texture[error] that passes the
        -- old IsError check; it must never become a clone's optional map.
        return texture('error',false)
    end
    function m:SetVector(k,v) assert(not stock,'Mutated shared stock material');self.params[k]=v end
    function m:SetFloat(k,v) assert(not stock);self.params[k]=v end
    return m
end
function Material(name) return material(name,nil,true) end
function CreateMaterial(name,_,params)
    assert(not materials[name],'Unbounded duplicate native material allocation')
    created=created+1;materials[name]=material(name,params);return materials[name]
end
local legacyPath='models/weapons/v_357/357_sheet'
local legacy=material('old_invalid_weapon_surface',{['$basetexture']='legacy_base',['$bumpmap']='error'})
materials[legacy:GetName()]=legacy;created=1
LOD.WeaponSurfacePool={rows={[legacyPath..':tint-v2:a']={material=legacy}},count=1}
util.CRC=function(s) return s:gsub('[^%w]','_') end
dofile(root..'cl_weapon_appearance.lua')
local function entity(paths)
    local ent={valid=true,pos=Vector(),model='gun',slots={},paths=paths or {'models/weapons/v_hands','models/weapons/357_body','models/weapons/357_barrel','models/weapons/357_grip'}}
    function ent:GetNW2String() return self.packet or V:Encode(copy) end
    function ent:GetNoDraw() return self.hidden or false end
    function ent:GetNW2Bool() return self.watcher or false end
    function ent:GetPos() return self.pos end
    function ent:LookupAttachment() return self.noMuzzle and 0 or 1 end
    function ent:GetAttachment() return {Pos=Vector(10,0,0),Ang=Angle()} end
    function ent:GetClass() return self.class or 'weapon_357' end
    function ent:OBBCenter() return Vector() end
    function ent:LocalToWorld(p) return p end
    function ent:GetAngles() return Angle() end
    function ent:GetModel() return self.model end
    function ent:GetMaterials() return self.paths end
    function ent:GetSubMaterial(i) return self.slots[i] or '' end
    function ent:SetSubMaterial(i,v) assert(i~=0 or not self.paths[1]:find('hands'));self.slots[i]=v end
    function ent:GetOwner() return self.owner end
    function ent:GetActiveWeapon() return self.weapon end
    function ent:DrawModel() self.drawn=(self.drawn or 0)+1; if self.failDraw then error('draw failure') end end
    return ent
end
local ent=entity();local style=V:ItemStyle(copy)
for _,id in ipairs(E.EconomyOrder) do
    local g=V.Grammar[id];local st=V:Compile({1,42,4,100,{{g.index,2}}})
    for _,mode in ipairs({false,true}) do
        low=mode;calls=0;V:Apply(ent,st,nil,true)
        local changed=0;for _,s in pairs(ent.slots) do if s~='' then changed=changed+1 end end
        assert(changed==2 and ent:GetSubMaterial(0)=='' and ent:GetSubMaterial(3)=='','Two configured tints; protected grip and hands')
        V:Draw(ent,st,'weapon_357',nil,true);assert(calls==(low and 1 or 2))
        V:Restore(ent);for _,s in pairs(ent.slots) do assert(s=='') end
    end
end
for _,m in pairs(materials) do
    assert(m.params['$basetexture']:find('_base',1,true),'Native base map discarded')
    assert(m.params['$detail']==nil,'Retired surface patterns must never be applied')
end
assert(#invalidTextureQueries==0,'undefined/nontexture optional shader variable queried as a texture')
local n=created
for i=1,1000 do
    local st=V:Compile({1,i,1,100,{{1,2}}});V:Apply(ent,st,nil,true);V:Restore(ent)
end
assert(created<=8,'Material pool must depend on surfaces/finishes, not item identity')
-- Another skin remains owned by its creator. Mid-draw replacement is respected.
V:Apply(ent,style,nil,true);local slot
for k,v in pairs(ent.slots) do if v~='' then slot=k end end
ent.slots[slot]='another_skin';V:Restore(ent);assert(ent.slots[slot]=='another_skin')
V:Apply(ent,style,nil,true);assert(ent.slots[slot]=='another_skin');ent.slots[slot]=''
-- Model change with reused native viewmodel: do not restore old slot into new model.
V:Apply(ent,style,nil,true);ent.model='changed';ent.slots={};V:Restore(ent);assert(next(ent.slots)==nil)
local hands=entity({'models/weapons/v_hands'});V:Apply(hands,style,nil,true);assert(next(hands.slots)==nil)
local unknown=entity({'models/custom/gun'});V:Apply(unknown,style,nil,true);assert(next(unknown.slots)==nil)
-- Caps, hidden actors, distance and no attachment fallback.
low=false;calls=0;for i=1,20 do V:Draw(ent,style,'weapon_357',nil,false) end;assert(calls==16)
tick=tick+1;low=true;calls=0;for i=1,20 do V:Draw(ent,style,'weapon_357',nil,false) end;assert(calls==4)
ent.pos=Vector(2000,0,0);calls=0;V:Draw(ent,style,'weapon_357',nil,false);assert(calls==0)
ent.pos=Vector();ent.noMuzzle=true;V:Draw(ent,style,'weapon_lod_crowbar',nil,true);ent.noMuzzle=false
local owner=entity();owner.weapon=ent;ent.owner=owner
owner.hidden=true;calls=0;V:Draw(ent,style,'weapon_357',owner,true);assert(calls==0);owner.hidden=false
LocalPlayer=function() return owner end
-- Prediction/server duplicate, shell-event preservation, fade and melee exclusion.
net.ReadEntity=function() return ent end
calls=0;low=false;now=1;hooks.LOD_ProceduralWeaponPredictedFlash(owner)
V:Draw(ent,style,'weapon_357',owner,true,ent);assert(calls>=6 and calls<=8)
now=1.1;receivers.LOD_WeaponSurfaceFlash();now=1.3;calls=0;V:Draw(ent,style,'weapon_357',owner,true,ent);assert(calls==2)
assert(hooks.LOD_ProceduralWeaponMuzzle(owner,nil,nil,20)==nil)
now=2;assert(hooks.LOD_ProceduralWeaponMuzzle(owner,nil,nil,5003)==true)
ent.class='weapon_lod_crowbar';assert(hooks.LOD_ProceduralWeaponMuzzle(owner,nil,nil,5003)==nil);ent.class=nil
-- Real paired hooks, suppressed-draw fallback, pickup error cleanup.
hooks.LOD_ProceduralWeaponSurface(ent,owner,ent);hooks.LOD_ProceduralWeaponAppearance(ent,owner,ent)
hooks.LOD_ProceduralWorldWeaponSurface(owner)
assert(ent.RenderOverride,'World finish must wrap the actual weapon draw')
ent.RenderOverride(ent);assert(ent.drawn==1);ent.drawn=0
E.ConcealedPlayer=function(_,p) return p==owner end
ent.RenderOverride(ent);assert(ent.drawn==0,'cloaked held gun does not render')
E.ConcealedPlayer=nil

local protected=entity();protected.RenderOverride=function() end;local override=protected.RenderOverride
V:WorldWeapon(protected);assert(protected.RenderOverride==override,'Respect another renderer')
V:Apply(ent,style,nil,true);hooks.LOD_WeaponSurfaceRestore();for _,v in pairs(ent.slots) do assert(v=='') end
ent.failDraw=true;local errors=0;ErrorNoHalt=function() errors=errors+1 end
assert(V:DrawPickup(ent));assert(errors==1);for _,v in pairs(ent.slots) do assert(v=='') end
ent.failDraw=false;assert(V:DrawPickup(ent));assert(ent.drawn==2)
E:DrawItemIcon(copy,0,0,48,pale)
local same=V:ItemStyle(copy);V:Apply(ent,style,nil,true);hooks.LOD_WeaponAppearanceCleanup()
assert(ent.RenderOverride==nil,'Owned draw wrapper must be removed on cleanup');assert(V:ItemStyle(copy)~=same);for _,v in pairs(ent.slots) do assert(v=='') end
-- Every stock family also works with a single gun material. The same mesh is
-- partitioned into disjoint intervals, with at most two active clip planes.
local clipping,planes=false,{}
render.EnableClipping=function(enabled) local old=clipping;clipping=enabled;return old end
render.PushCustomClipPlane=function(n,d) planes[#planes+1]={n=n,d=d};assert(#planes<=2) end
render.PopCustomClipPlane=function() assert(#planes>0);table.remove(planes) end
dofile(root..'cl_weapon_segments.lua')
for class,spec in pairs(V.Segments) do
 for _,prefix in ipairs({'c','v','w'}) do
    local e=entity({'models/weapons/v_hands','models/weapons/'..spec.stem})
    e.model='models/weapons/'..prefix..'_'..spec.stem..'.mdl';e.class=class
    e.OBBMins=function() return Vector(-20,-2,-2) end;e.OBBMaxs=function() return Vector(20,2,2) end
    local draws={}
    function e:DrawModel()
        assert(self:GetSubMaterial(0)=='','Hands must retain their material')
        assert(not V:DrawSegmented(self,style,class,nil,true),'Recursive segmented draw')
        local copy={};for _,p in ipairs(planes) do copy[#copy+1]=p end
        draws[#draws+1]={material=self:GetSubMaterial(1),planes=copy}
    end
    assert(V:DrawSegmented(e,style,class,nil,true));assert(#draws==3)
    assert(draws[1].material=='' and draws[2].material~='' and draws[3].material~=draws[2].material)
    local normal,lo,hi=V:SegmentPlanes(e,spec)
    for index,distance in ipairs({lo-1,(lo+hi)/2,hi+1}) do
        local point=normal*distance;local visible=0
        for j,draw in ipairs(draws) do
            local inside=true;for _,p in ipairs(draw.planes) do if p.n:Dot(point)<p.d then inside=false end end
            if inside then assert(j==index);visible=visible+1 end
        end
        assert(visible==1,'Complementary regions must not overlap or leave a gap')
    end
    assert(not clipping and #planes==0 and e:GetSubMaterial(1)=='')
    function e:DrawModel() error('deliberate render failure') end
    assert(V:DrawSegmented(e,style,class,nil,true))
    assert(not clipping and #planes==0 and e:GetSubMaterial(1)=='' and not V.SegmentDrawing[e])
    clipping=true;assert(V:DrawSegmented(e,style,class,nil,true) and clipping);clipping=false
    e.slots[1]='external';assert(not V:DrawSegmented(e,style,class,nil,true));assert(e.slots[1]=='external')
 end
end
-- Reproduce the actual held entry points: native clipping already enabled,
-- c_model view mesh, remote world mesh, record switches and base hand completion.
local held=entity({'models/weapons/v_hands','models/weapons/357'})
held.model='models/weapons/w_357.mdl';held.owner=owner;owner.weapon=held
local vm=entity(held.paths);vm.model='models/weapons/c_357.mdl'
local completed=0
hook.Run=function(event,...)
 assert(event=='PostDrawViewModel');completed=completed+1
 hooks.LOD_ProceduralWeaponAppearance(...)
end
for _,packet in ipairs({V:Encode(copy),V:Encode(E:Generate(776,9,'weapon_357','held-swap'))}) do
 held.packet=packet;clipping=true
 local before=vm.drawn or 0
 assert(hooks.LOD_ProceduralWeaponSurface(vm,owner,held,0)==true)
 assert(vm.drawn==before+3 and clipping and #planes==0)
 for _,v in pairs(vm.slots) do assert(v=='') end
end
assert(completed==2,'Each manual wielded draw must finish the native hands path once')
V:WorldWeapon(held);clipping=true;held.RenderOverride(held,0)
assert(held.drawn==3 and clipping and #planes==0)
LOD.MagicFX={ViewModelHidden=function() return true end}
local before=vm.drawn;assert(hooks.LOD_ProceduralWeaponSurface(vm,owner,held,0)==true and vm.drawn==before)
LOD.MagicFX=nil;clipping=false;owner.weapon=ent
print('WEAPON_SEGMENTS_PASS: all six families/view-world meshes, two-plane ceiling, three disjoint regions, hands, external ownership and error cleanup')
-- Native BUG-002: missing optional vars are not textures, while actual normal
-- maps, separate masks and authored mask flags retain their original meaning.
local function surface(path,profile)
    materialProfiles[path]=profile or {}
    local result=assert(V:Surface(path,style))
    return assert(materials[result:sub(2)]),result
end
local repaired,repairedName=surface(legacyPath)
assert(repaired~=legacy and repaired.params['$bumpmap']==nil and repaired.params['$envmapmask']==nil,
    'hot reload reused the invalid v2 clone or copied a nonexistent optional map')
assert(repaired.params['$normalmapalphaenvmapmask']==nil,'repair invented an alpha-mask flag')
assert(legacy.params['$bumpmap']=='error','repair mutated an already-created native material')
for index,value in ipairs({false,0,1,'','unloaded/texture/path',{},texture('broken',true),texture('error',false),texture('',false)}) do
    local m=surface('models/weapons/optional_invalid_'..index,{optional={['$bumpmap']=value,['$envmapmask']=value}})
    assert(m.params['$bumpmap']==nil and m.params['$envmapmask']==nil,'nontexture/error optional map reached clone')
end
local normal=surface('models/weapons/real_normal',{optional={['$bumpmap']=texture('stock/normal')},
    ints={['$normalmapalphaenvmapmask']=1}})
assert(normal.params['$bumpmap']=='stock/normal' and normal.params['$envmapmask']==nil)
assert(normal.params['$normalmapalphaenvmapmask']=='1','authored normal-alpha flag was lost')
local mask=surface('models/weapons/real_mask',{optional={['$envmapmask']=texture('stock/mask')},
    ints={['$basealphaenvmapmask']=1,['$selfillum']=1,['$alphatest']=1}})
assert(mask.params['$envmapmask']=='stock/mask' and mask.params['$bumpmap']==nil)
for _,key in ipairs({'$basealphaenvmapmask','$selfillum','$alphatest'}) do assert(mask.params[key]=='1') end
for _,m in ipairs({repaired,normal,mask}) do
    assert(m.params['$model']=='1' and m.params['$phong']=='1' and m.params['$phongboost']=='.25')
    assert(m.params['$basetexture']:find('_base',1,true) and m.params['$color2'],
        'repair changed native base texture or tint application')
end
local beforeRejected=created
for index,profile in ipairs({{errorMaterial=true},{shader='UnlitGeneric'},{base=texture('broken_base',true)}}) do
    local path='models/weapons/rejected_'..index;materialProfiles[path]=profile
    assert(V:Surface(path,style)==nil)
end
assert(created==beforeRejected and #invalidTextureQueries==0,'invalid source was admitted or optional texture queried')
local pool,countBeforeReload=LOD.WeaponSurfacePool,created
dofile(root..'cl_weapon_appearance.lua')
assert(LOD.WeaponSurfacePool==pool and pool.count==countBeforeReload)
assert(V:Surface(legacyPath,style)==repairedName and created==countBeforeReload,
    'reloading discarded the bounded pool or allocated a duplicate corrected clone')
print('WEAPON_MATERIAL_TYPES_PASS: absent/nontexture/error optional maps rejected; real normal/mask and authored flags preserved; v2 clone excluded; corrected pool reused across reload')
-- Pool reaches its hard native allocation ceiling across many source paths.
for i=1,200 do V:Surface('models/weapons/custom_'..i,style) end
assert(created==128 and pool.count==128)
dofile(root..'cl_weapon_appearance.lua')
assert(LOD.WeaponSurfacePool==pool and pool.count==128)
assert(V:Surface(legacyPath,style)==repairedName and V:Surface('models/weapons/over_capacity',style)==nil)
assert(created==128 and legacy.params['$bumpmap']=='error','reload exceeded shared material ceiling or mutated old clone')
-- A process whose entire budget predates the fix must fall back to the stock
-- material, never reuse an invalid old clone or allocate material129.
local fullLegacyPool={rows={},count=pool.count}
for key,row in pairs(pool.rows) do fullLegacyPool.rows[(key:gsub(':tint%-v3:',':tint-v2:'))]=row end
fullLegacyPool.rows[legacyPath..':tint-v2:a']={material=legacy}
for key in pairs(fullLegacyPool.rows) do assert(not key:find(':tint-v3:',1,true)) end
LOD.WeaponSurfacePool=fullLegacyPool;dofile(root..'cl_weapon_appearance.lua')
assert(V:Surface(legacyPath,style)==nil and created==128 and fullLegacyPool.count==128,
    'saturated legacy pool reused an invalid clone or exceeded native allocation ceiling')
LOD.WeaponSurfacePool=pool;dofile(root..'cl_weapon_appearance.lua')
-- Frozen names are display-migrated, never rewritten.
local old={definition=copy.definition,name='Watery Revolver of Watery Warding'}
assert(E:ItemName(old)=='Wintery Revolver of Wintery Warding' and old.name:find('Watery'))
print('APPEARANCE_RENDER_PASS: no attachments; native base/hand preservation; two tint regions plus control; 128-material ceiling; hooks/restoration; visibility/budgets; muzzle dedup/fade; frozen name migration')
-- Native shot observer runs on server: no bullet mutation/extra shots, one
-- publication for a shotgun's pellets and one for the next shot tick.
SERVER=true
local assets,sent={},0
resource={AddFile=function(path) assets[#assets+1]=path end}
util.AddNetworkString=function() end
engine={TickCount=function() return tick end}
net.Start=function(id) assert(id=='LOD_WeaponSurfaceFlash') end
net.WriteEntity=function(w) assert(w==ent) end
net.SendPVS=function(p) assert(p==owner.pos);sent=sent+1 end
function owner:IsPlayer() return true end
function owner:GetShootPos() return self.pos end
dofile(root..'sh_weapon_appearance.lua')
assert(#assets==0)
for i=1,36 do assert(hooks.LOD_ProceduralWeaponMuzzle(owner)==nil) end
assert(sent==1);tick=tick+1;hooks.LOD_ProceduralWeaponMuzzle(owner);assert(sent==2)
ent.packet='';tick=tick+1;hooks.LOD_ProceduralWeaponMuzzle(owner);assert(sent==2)
print('APPEARANCE_SERVER_PASS: no procedural pattern textures; native shot observer; 36-pellet coalescing; unstyled exclusion')
