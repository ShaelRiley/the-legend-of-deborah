-- Geometry and engraving only: no emitters, dynamic lights, extra entities,
-- model scaling, RenderOverride, or mutations to weapon/hand materials.
local V,E=LOD.WeaponAppearance,LOD.Equipment
local cache=setmetatable({}, {__mode='k'})
local itemCache=setmetatable({}, {__mode='k'})
local colors={};for name,c in pairs(V.Colors) do colors[name]=Color(c[1],c[2],c[3]) end
local ink=Color(23,29,36);local pale=Color(218,225,227)
local metal=CreateMaterial('LOD_WeaponCraftMetal','VertexLitGeneric',{
    ['$basetexture']='color/white',['$model']='1',['$vertexcolor']='1',['$phong']='1',['$phongboost']='.35',['$phongexponent']='24'})
local ceramic=CreateMaterial('LOD_WeaponCraftCeramic','VertexLitGeneric',{
    ['$basetexture']='color/white',['$model']='1',['$vertexcolor']='1',['$phong']='1',['$phongboost']='.1',['$phongexponent']='6'})
local glow=CreateMaterial('LOD_WeaponCraftInk','UnlitGeneric',{
    ['$basetexture']='color/white',['$vertexcolor']='1',['$vertexalpha']='1',['$translucent']='1',['$ignorez']='0'})
surface.CreateFont('LOD_WeaponRune',{font='DejaVu Sans',size=18,weight=800})
local lengths={weapon_pistol=9,weapon_357=13,weapon_smg1=16,weapon_ar2=21,weapon_shotgun=25,weapon_lod_crowbar=17}
local frame,count=-1,0
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
-- All silhouettes are assembled from small base-engine primitives.
function V:Module(kind,pos,ang,size,color,reduced)
    local f,r,u=ang:Forward(),ang:Right(),ang:Up()
    local function box(x,y,z,sx,sy,sz)
        render.DrawBox(pos+f*x+r*y+u*z,ang,Vector(-sx,-sy,-sz),Vector(sx,sy,sz),color)
    end
    if kind=='anvil' then box(0,0,0,size, size*.75,size*.5);box(0,0,size*.6,size*.65,size*.4,size*.3)
    elseif kind=='fin' or kind=='fang' then
        local tilt=Angle(ang.p,ang.y,ang.r);tilt:RotateAroundAxis(r,kind=='fin' and 35 or -35)
        render.DrawBox(pos,tilt,Vector(-size*.3,-size*.25,-size),Vector(size*.3,size*.25,size),color)
    elseif kind=='shard' then
        local tilt=Angle(ang.p,ang.y,ang.r);tilt:RotateAroundAxis(f,45)
        render.DrawBox(pos,tilt,Vector(-size*.3,-size*.4,-size),Vector(size*.3,size*.4,size),color)
    elseif kind=='plate' then box(0,0,0,size*.65,size*.65,size*.2)
    elseif kind=='crown' then
        box(0,0,0,size,size*.4,size*.25)
        for i=-1,1 do box(i*size*.8,0,size*.6,size*.18,size*.3,size*.6) end
    elseif kind=='cage' then
        for i=-1,1,2 do box(0,i*size*.65,0,size*.8,size*.15,size*.8) end
        box(0,0,size*.7,size*.8,size*.8,size*.15)
    elseif kind=='bud' then
        render.DrawSphere(pos,size*.65,6,4,color);render.DrawSphere(pos+u*size*.8,size*.4,6,4,color)
    elseif kind=='lens' then render.DrawSphere(pos,size*.7,8,4,color)
    elseif kind=='coil' then
        local steps=reduced and 6 or 10
        for i=1,steps do
            local a,b=(i-1)/steps*math.pi*4,i/steps*math.pi*4
            render.DrawBeam(pos+f*((i-1)/steps*size*2-size)+r*(math.cos(a)*size*.6)+u*(math.sin(a)*size*.6),
                pos+f*(i/steps*size*2-size)+r*(math.cos(b)*size*.6)+u*(math.sin(b)*size*.6),size*.18,0,1,color)
        end
    end
end
function V:Anchor(ent,class,view)
    local length=lengths[class] or 13
    local id=ent:LookupAttachment('muzzle')
    local muzzle=id and id>0 and ent:GetAttachment(id)
    if muzzle then return muzzle.Pos-muzzle.Ang:Forward()*(length*.6),muzzle.Ang,length end
    -- Animated melee viewmodels may have no muzzle. Follow their hand bone
    -- so the fittings travel with the swing instead of floating at the origin.
    if view and ent.LookupBone and ent.GetBonePosition then
        local bone=ent:LookupBone('ValveBiped.Bip01_R_Hand')
        if bone then
            local p,a=ent:GetBonePosition(bone)
            if p and a then return p+a:Forward()*(length*.2),a,length end
        end
    end
    return ent:LocalToWorld(ent:OBBCenter()),ent:GetAngles(),length
end
function V:Glyph(trait,x,y,width,height,active)
    local c=colors[trait.color] or pale
    surface.SetDrawColor(ink);surface.DrawRect(x,y,width,height)
    draw.SimpleText(trait.glyph,'LOD_WeaponRune',x+width*.5,y+2,c,TEXT_ALIGN_CENTER)
    surface.SetDrawColor(c)
    for i=1,trait.bars do surface.DrawRect(x+3+(i-1)*(width-6)/4,y+height-6,(width-10)/4,3) end
    if trait.negative then
        surface.DrawLine(x+2,y+2,x+width*.4,y+height*.45)
        surface.DrawLine(x+width*.4,y+height*.45,x+width*.25,y+height*.65)
        surface.DrawLine(x+width*.25,y+height*.65,x+width-2,y+height-2)
    end
    if active then surface.DrawOutlinedRect(x,y,width,height,2) end
end
local function condition(t,owner)
    if not IsValid(owner) then return false end
    if t.id=='injured' then return owner:Health()<=owner:GetMaxHealth()*.5
    elseif t.id=='charged' then return owner:GetNW2Float('LOD_Magic',0)>=75
    elseif t.id=='still' then return owner:GetVelocity():Length2D()<5 end
    return false
end
function V:Draw(ent,style,class,owner,view)
    if not style or not IsValid(ent) or ent:GetNoDraw() and not view then return end
    if IsValid(owner) and (owner:GetNoDraw() or owner:GetNW2Bool('LOD_Watcher',false)) then return end
    local distance=view and 0 or ent:GetPos():DistToSqr(EyePos())
    if distance>1200*1200 then return end
    local reduced=GetConVar('lod_reduced_effects');reduced=reduced and reduced:GetBool()
    if not view then
        local tick=FrameNumber();if frame~=tick then frame,count=tick,0 end
        if count>=(reduced and 4 or 8) then return end;count=count+1
    end
    local pos,ang,length=self:Anchor(ent,class,view)
    local f,r,u=ang:Forward(),ang:Right(),ang:Up()
    local color=colors[style.element];local size=.65+style.variant*.35
    local time=reduced and 0 or CurTime()
    local pulse=reduced and 1 or .9+.1*math.sin(time*2+style.phase)
    render.SetMaterial(style.finish=='ceramic' and ceramic or metal)
    -- Two narrow receiver plates form a finish-bearing frame without covering
    -- sights, the muzzle, reload components, or the actor's hands.
    local finish=style.finish=='carbon' and Color(45,53,62) or style.finish=='ceramic' and pale or color
    for _,side in ipairs({-1,1}) do
        render.DrawBox(pos+r*(side*1.4),ang,Vector(-length*.25,-.16,-.65),Vector(length*.25,.16,.65),finish)
    end
    -- Finish texture is geometric: carbon cross-weave, long brushed grooves,
    -- hammered studs, or a clean ceramic face. No per-item texture allocation.
    render.SetMaterial(glow)
    for i=1,4 do
        local at=pos+f*((i-2.5)*length*.09)+r*1.57
        if style.finish=='hammered metal' then
            render.DrawBox(at,ang,Vector(-.16,-.12,-.16),Vector(.16,.12,.16),pale)
        elseif style.finish=='carbon' then
            render.DrawBeam(at-f*.4-u*.5,at+f*.4+u*.5,.07,0,1,pale)
            render.DrawBeam(at-f*.4+u*.5,at+f*.4-u*.5,.07,0,1,pale)
        elseif style.finish=='brushed metal' then
            render.DrawBeam(at-u*.45,at+u*.45,.06,0,1,ink)
        end
    end
    render.SetMaterial(style.finish=='ceramic' and ceramic or metal)
    self:Module(style.structure,pos-u*.7,ang,size,finish,reduced)
    self:Module(V.Grammar['element_'..style.element] and V.Grammar['element_'..style.element].shape or 'lens',
        pos+f*(length*.2)+u*1.3,ang,size*pulse,color,reduced)
    if style.rider then self:Module(style.rider.shape,pos-f*(length*.25)+u,ang,size,pale,reduced) end
    -- Rarity is craftsmanship: one to four bands, never a second element color.
    for i=1,style.rarity do
        render.DrawBox(pos+f*(-length*.2+i*.65)+u*.8,ang,Vector(-.12,-1.3,-.12),Vector(.12,1.3,.12),pale)
    end
    if distance>512*512 then return end
    render.SetMaterial(glow)
    for i,t in ipairs(style.traits) do
        local spot=pos+f*((i-(#style.traits+1)/2)*length/(#style.traits+1))
        self:Module(t.shape,spot+u*(1.7+style.variant*.3),ang,.22+t.strength*.3,colors[t.color],true)
    end
    local plane=Angle(ang.p,ang.y,ang.r);plane:RotateAroundAxis(f,90)
    local scale=length/(#style.traits*40)
    cam.Start3D2D(pos+r*1.62,plane,scale)
    for i,t in ipairs(style.traits) do self:Glyph(t,(i-1-#style.traits/2)*40,-20,38,40,condition(t,owner)) end
    -- Stable machining serial: every property/amount contributes to this pattern.
    surface.SetDrawColor(color)
    for i=0,15 do if math.floor(style.hash/2^i)%2==1 then surface.DrawRect(-32+i*4,25,2,3) end end
    cam.End3D2D()
end
hook.Add('PostDrawViewModel','LOD_ProceduralWeaponAppearance',function(vm,ply,weapon)
    if not IsValid(weapon) then return end
    V:Draw(vm,V:EntityStyle(weapon),weapon:GetClass(),ply,true)
end)
hook.Add('PostPlayerDraw','LOD_ProceduralWorldWeaponAppearance',function(ply)
    local weapon=ply:GetActiveWeapon();if not IsValid(weapon) then return end
    V:Draw(weapon,V:EntityStyle(weapon),weapon:GetClass(),ply,false)
end)
function V:DrawPickup(ent)
    local style=self:EntityStyle(ent);if not style then return false end
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
hook.Add('PreCleanupMap','LOD_WeaponAppearanceCleanup',function()
    cache=setmetatable({}, {__mode='k'});itemCache=setmetatable({}, {__mode='k'});frame,count=-1,0
end)
