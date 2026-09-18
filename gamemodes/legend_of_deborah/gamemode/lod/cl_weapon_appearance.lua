-- Surface-only gun identity. Never create cosmetic geometry/model entities or
-- mutate stock materials, collision, animation, scale, or gameplay state.
if LOD.WeaponSurfaceRestore then LOD.WeaponSurfaceRestore() end
local V,E=LOD.WeaponAppearance,LOD.Equipment
local cache=setmetatable({}, {__mode='k'})
local itemCache=setmetatable({}, {__mode='k'})
local applied=setmetatable({}, {__mode='k'})
local flashes=setmetatable({}, {__mode='k'})
local regions=setmetatable({}, {__mode='k'})
local worldDraws=setmetatable({}, {__mode='k'})
-- Source materials cannot be freed. Retain a bounded pool across map/Lua reloads;
-- keys depend on stock material + four finishes, never on a random item ID.
LOD.WeaponSurfacePool=LOD.WeaponSurfacePool or {rows={},count=0}
local pool=LOD.WeaponSurfacePool
local colors={};for name,c in pairs(V.Colors) do colors[name]=Color(c[1],c[2],c[3]) end
local pale,ink=Color(218,225,227),Color(23,29,36)
local glow=Material('sprites/light_glow02_add')
local lengths={weapon_pistol=9,weapon_357=13,weapon_smg1=16,weapon_ar2=21,weapon_shotgun=25,weapon_lod_crowbar=17}
local frame,count=-1,0
local function reduced()
    local c=GetConVar('lod_reduced_effects');return c and c:GetBool()
end
function V:ItemStyle(item)
    if not item then return nil end
    local row=itemCache[item]
    if row==nil then row=self:Compile(self:Data(item));itemCache[item]=row or false end
    return row or nil
end
function V:EntityStyle(ent)
    local packet=ent:GetNW2String('LOD_WeaponAppearance','')
    local row=cache[ent]
    if not row or row.packet~=packet then row={packet=packet,style=self:Decode(packet)};cache[ent]=row end
    return row.style
end
function V:Visible(ent,owner,view)
    if not IsValid(ent) or (not view and ent:GetNoDraw()) then return false end
    if IsValid(owner) and (owner:GetNoDraw() or owner:GetNW2Bool('LOD_Watcher',false)) then return false end
    return view or ent:GetPos():DistToSqr(EyePos())<=1200*1200
end
function V:Anchor(ent,class,view)
    local length=lengths[class] or 13
    local id=ent:LookupAttachment('muzzle')
    local muzzle=id and id>0 and ent:GetAttachment(id)
    if muzzle then return muzzle.Pos-muzzle.Ang:Forward()*(length*.6),muzzle.Ang,length,muzzle.Pos end
    if view and ent.LookupBone and ent.GetBonePosition then
        local bone=ent:LookupBone('ValveBiped.Bip01_R_Hand')
        if bone then
            local p,a=ent:GetBonePosition(bone)
            if p and a then return p+a:Forward()*(length*.2),a,length end
        end
    end
    return ent:LocalToWorld(ent:OBBCenter()),ent:GetAngles(),length
end
local function gunSurface(path)
    path=path:lower()
    if not path:find('weapons/',1,true) then return false end
    for _,word in ipairs({'hand','arm','glove','finger','skin','sleeve','lens','scope','glass'}) do
        if path:find(word,1,true) then return false end
    end
    return true
end
function V:Surface(path,style,region)
    region=region or 'a'
    local key=path..':tint-v2:'..region
    local row=pool.rows[key]
    if row==false then return nil end
    if not row then
        if pool.count>=128 then return nil end
        local source=Material(path)
        if source:IsError() or source:GetShader()~='VertexLitGeneric' then pool.rows[key]=false;return nil end
        local texture=source:GetTexture('$basetexture')
        if not texture or texture:IsError() then pool.rows[key]=false;return nil end
        local params={['$basetexture']=texture:GetName(),['$model']='1',['$phong']='1',['$phongboost']='.25'}
        for _,name in ipairs({'$bumpmap','$envmapmask'}) do
            local t=source:GetTexture(name);if t and not t:IsError() then params[name]=t:GetName() end
        end
        for _,name in ipairs({'$basealphaenvmapmask','$normalmapalphaenvmapmask','$selfillum','$alphatest'}) do
            local v=source:GetInt(name);if v and v~=0 then params[name]=tostring(v) end
        end
        pool.count=pool.count+1
        row={material=CreateMaterial('LOD_WeaponSurface_'..util.CRC(key),'VertexLitGeneric',params)}
        pool.rows[key]=row
    end
    local rgb=region=='b' and style.tintBRGB or style.tintARGB
    local c=rgb and Color(rgb[1],rgb[2],rgb[3]) or colors[region=='b' and style.tintB or style.tintA] or colors[style.element] or pale
    local amount=.58+style.rarity*.035
    row.material:SetVector('$color2',Vector(1-amount+amount*c.r/255,1-amount+amount*c.g/255,1-amount+amount*c.b/255))
    return '!'..row.material:GetName()
end
function V:Restore(ent)
    local state=applied[ent];if not state then return end
    applied[ent]=nil
    if not IsValid(ent) or ent:GetModel()~=state.model then return end
    for _,row in ipairs(state.rows) do
        if ent:GetSubMaterial(row.slot)==row.ours then ent:SetSubMaterial(row.slot,row.previous) end
    end
end
function V:Apply(ent,style,owner,view)
    self:Restore(ent)
    if not style or not self:Visible(ent,owner,view) then return end
    local class=ent:GetClass()
    if view and IsValid(owner) then local weapon=owner:GetActiveWeapon();if IsValid(weapon) then class=weapon:GetClass() end end
    if class=="lod_loot_pickup" then class=ent:GetNW2String("LOD_WeaponAppearanceClass","") end
    local mapping=regions[ent]
    if not mapping or mapping.model~=ent:GetModel() or mapping.class~=class then
        mapping={model=ent:GetModel(),class=class,surfaces={},control=false}
        for index,path in ipairs(ent:GetMaterials() or {}) do
            if gunSurface(path) then
                local region=self:MaterialRegion(class,path)
                if region=='control' then mapping.control=true
                else mapping.surfaces[#mapping.surfaces+1]={slot=index-1,path=path,region=region} end
            end
        end
        regions[ent]=mapping
    end
    local surfaces,control=mapping.surfaces,mapping.control
    -- Single gun-material meshes cannot expose independent native sections.
    -- Preserve them intact instead of recoloring the whole gun or its hands.
    if not control then return end
    local state={model=ent:GetModel(),rows={}}
    for _,surface in ipairs(surfaces) do
        local previous=ent:GetSubMaterial(surface.slot)
        if not previous or previous=='' then
            local material=self:Surface(surface.path,style,surface.region)
            if material then
                state.rows[#state.rows+1]={slot=surface.slot,previous=previous,ours=material}
                ent:SetSubMaterial(surface.slot,material)
            end
        end
    end
    applied[ent]=state
end
function V:Draw(ent,style,class,owner,view,weapon)
    if not style or not self:Visible(ent,owner,view) then return end
    local low=reduced()
    if not view then
        local tick=FrameNumber();if frame~=tick then frame,count=tick,0 end
        if count>=(low and 4 or 8) then return end;count=count+1
    end
    local pos,ang,length,muzzle=self:Anchor(ent,class,view)
    local c=colors[style.element] or pale
    local pulse=low and 1 or .9+.1*math.sin(CurTime()*2+style.phase)
    local alpha=(view and 24 or 38)+style.rarity*4
    local size=(view and 4 or 8)+style.rarity+style.variant*2
    render.SetMaterial(glow)
    render.DrawSprite(pos,size*pulse,size*pulse,Color(c.r,c.g,c.b,alpha))
    if not low then
        render.DrawSprite(pos+ang:Forward()*length*.18,size*.6,size*.6,Color(c.r,c.g,c.b,alpha*.7))
    end
    local flash=flashes[weapon or ent]
    if flash and flash.untilTime>CurTime() and muzzle and class~='weapon_lod_crowbar' then
        local fade=math.min(1,(flash.untilTime-CurTime())/(style.muzzleDuration or .12))
        local radius=(style.muzzleSize or 16)*(low and .7 or 1)*fade
        render.DrawSprite(muzzle,radius,radius,Color(c.r,c.g,c.b,230*fade))
        if not low then
            render.DrawSprite(muzzle+ang:Forward()*2,radius*.4,radius*.4,Color(255,245,220,255*fade))
            local count=style.muzzleFamily=='fin' and 2 or style.muzzleFamily=='coil' and 4 or 3
            for i=1,count do
                local a=i*math.pi*2/count+style.phase
                local tip=muzzle+ang:Forward()*radius*.6+(ang:Right()*math.cos(a)+ang:Up()*math.sin(a))*radius*.5
                render.DrawBeam(muzzle,tip,1.5,0,1,Color(c.r,c.g,c.b,190*fade))
            end
        end
    end
end
function V:Flash(weapon)
    if not IsValid(weapon) or not lengths[weapon:GetClass()] or weapon:GetClass()=='weapon_lod_crowbar' then return end
    if not self:EntityStyle(weapon) then return end
    local prior=flashes[weapon]
    -- Collapse shotgun pellets and predicted/server copies of the same shot.
    if prior and CurTime()-prior.started<.05 then return end
    flashes[weapon]={started=CurTime(),untilTime=CurTime()+(self:EntityStyle(weapon).muzzleDuration or .12)}
end
hook.Add('PreDrawViewModel','LOD_ProceduralWeaponSurface',function(vm,ply,weapon,flags)
    if V.SegmentDrawing and V.SegmentDrawing[vm] then return end
    if V.DrawSegmented and IsValid(weapon) and V:DrawSegmented(vm,V:EntityStyle(weapon),weapon:GetClass(),ply,true,flags) then
        V:Draw(vm,V:EntityStyle(weapon),weapon:GetClass(),ply,true,weapon)
        return true -- the default draw and PostDrawViewModel are suppressed together
    end
    V:Apply(vm,IsValid(weapon) and V:EntityStyle(weapon),ply,true)
end)
hook.Add('PostDrawViewModel','LOD_ProceduralWeaponAppearance',function(vm,ply,weapon)
    if V.SegmentDrawing and V.SegmentDrawing[vm] then return end
    V:Restore(vm)
    if IsValid(weapon) then V:Draw(vm,V:EntityStyle(weapon),weapon:GetClass(),ply,true,weapon) end
end)
-- Native world weapons may render separately from their player. Scope the
-- surface to the gun's actual DrawModel call, not the player's pre/post pair.
-- Install only on already-rendered, settled client weapons; respect any addon
-- override and keep drawing the original native mesh.
function V:WorldWeapon(weapon)
    if worldDraws[weapon] or weapon.RenderOverride~=nil then return end
    local function drawWeapon(ent,flags)
        local owner=ent:GetOwner()
        local active=IsValid(owner) and owner:GetActiveWeapon()==ent
        local style=active and V:EntityStyle(ent) or nil
        if V.DrawSegmented and V:DrawSegmented(ent,style,ent:GetClass(),owner,false,flags) then
            V:Draw(ent,style,ent:GetClass(),owner,false,ent);return
        end
        V:Apply(ent,style,owner,false)
        local ok,err=pcall(ent.DrawModel,ent,flags)
        V:Restore(ent)
        if not ok then ErrorNoHalt(tostring(err)..'\n');return end
        if active and (flags==nil or flags==STUDIO_RENDER) then V:Draw(ent,style,ent:GetClass(),owner,false,ent) end
    end
    worldDraws[weapon]=drawWeapon;weapon.RenderOverride=drawWeapon
end
hook.Add('PrePlayerDraw','LOD_ProceduralWorldWeaponSurface',function(ply)
    local weapon=ply:GetActiveWeapon();if not IsValid(weapon) then return end
    V:WorldWeapon(weapon)
end)
-- Native bullet prediction is available in multiplayer; the server message
-- below also covers singleplayer and remote weapons. Never alter bullet data.
hook.Add('EntityFireBullets','LOD_ProceduralWeaponPredictedFlash',function(actor)
    if IsValid(actor) and actor==LocalPlayer() then V:Flash(actor:GetActiveWeapon()) end
end)
-- Player model animation hook: suppress only the stock third-person muzzle
-- event after scheduling its elemental replacement; retain shell/sound events.
hook.Add('PlayerFireAnimationEvent','LOD_ProceduralWeaponMuzzle',function(ply,_,_,event)
    if event~=5003 or not IsValid(ply) then return end
    local weapon=ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass()=='weapon_lod_crowbar' or not V:EntityStyle(weapon) then return end
    V:Flash(weapon);return true
end)
net.Receive('LOD_WeaponSurfaceFlash',function()
    local weapon=net.ReadEntity()
    if not IsValid(weapon) then return end
    local owner=weapon:GetOwner()
    if not IsValid(owner) or owner:GetActiveWeapon()~=weapon then return end
    -- Local prediction already displayed this shot; only use server fallback
    -- when it did not produce a recent predicted shot.
    local prior=flashes[weapon]
    if owner==LocalPlayer() and prior and CurTime()-prior.started<.2 then return end
    V:Flash(weapon)
end)
function V:DrawPickup(ent)
    local style=self:EntityStyle(ent);if not style then return false end
    if V.DrawSegmented and V:DrawSegmented(ent,style,ent:GetNW2String('LOD_WeaponAppearanceClass',''),nil,false) then
        self:Draw(ent,style,'pickup',nil,false);return true
    end
    self:Apply(ent,style,nil,false)
    local ok,err=pcall(ent.DrawModel,ent)
    self:Restore(ent)
    if not ok then ErrorNoHalt(tostring(err)..'\n');return true end
    self:Draw(ent,style,'pickup',nil,false);return true
end
local baseIcon=E.DrawItemIcon
function E:DrawItemIcon(item,x,y,size,color,family)
    local style=V:ItemStyle(item)
    baseIcon(self,item,x,y,size,style and colors[style.element] or color,family)
    if not style then return end
    local step=size/#style.traits
    for i,t in ipairs(style.traits) do
        local c=colors[t.color];surface.SetDrawColor(c)
        local h=2+t.bars
        surface.DrawRect(x+(i-1)*step,y+size-h,math.max(1,step-1),h)
        if t.negative then surface.DrawLine(x+(i-1)*step,y+size-h,x+i*step-1,y+size) end
    end
    surface.SetDrawColor(pale)
    for i=1,style.rarity do surface.DrawRect(x+(i-1)*5,y,3,3) end
    surface.SetDrawColor(ink)
    for i=0,7 do if math.floor(style.hash/2^i)%2==1 then surface.DrawRect(x+size*.22+i*size*.06,y+size*.4,2,size*.12) end end
end
local function restoreAll() for ent in pairs(applied) do V:Restore(ent) end end
local function teardown()
    restoreAll()
    for ent,fn in pairs(worldDraws) do
        if IsValid(ent) and ent.RenderOverride==fn then ent.RenderOverride=nil end
    end
    worldDraws=setmetatable({}, {__mode='k'})
end
LOD.WeaponSurfaceRestore=teardown
-- Fallback if an external hook suppresses a paired draw, plus map/role changes.
hook.Add('PostRender','LOD_WeaponSurfaceRestore',restoreAll)
hook.Add('PreCleanupMap','LOD_WeaponAppearanceCleanup',function()
    teardown();cache=setmetatable({}, {__mode='k'});itemCache=setmetatable({}, {__mode='k'})
    flashes=setmetatable({}, {__mode='k'});frame,count=-1,0
end)
hook.Add('ShutDown','LOD_WeaponSurfaceShutdown',teardown)

-- Inspect the actual mounted Source topology when authoring another mapping.
concommand.Add('lod_weapon_regions',function()
    local p=LocalPlayer();if not IsValid(p) then return end
    local weapon=p:GetActiveWeapon();if not IsValid(weapon) then return end
    for _,ent in ipairs({weapon,p:GetViewModel()}) do
        if IsValid(ent) then
            print('[LOD:REGIONS] '..weapon:GetClass()..' '..ent:GetModel())
            for index,path in ipairs(ent:GetMaterials()) do print(index-1,path,V:MaterialRegion(weapon:GetClass(),path)) end
        end
    end
end)
