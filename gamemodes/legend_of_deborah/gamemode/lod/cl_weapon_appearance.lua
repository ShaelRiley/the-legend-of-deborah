-- Surface-only gun identity. Never create cosmetic geometry/model entities or
-- mutate stock materials, collision, animation, scale, or gameplay state.
if LOD.WeaponSurfaceRestore then LOD.WeaponSurfaceRestore() end
local V,E=LOD.WeaponAppearance,LOD.Equipment
local cache=setmetatable({}, {__mode='k'})
local itemCache=setmetatable({}, {__mode='k'})
local applied=setmetatable({}, {__mode='k'})
local flashes=setmetatable({}, {__mode='k'})
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
function V:Surface(path,style)
    local pattern=style.hash%4+1
    local key=path..':'..pattern
    local row=pool.rows[key]
    if row==false then return nil end
    if not row then
        if pool.count>=128 then return nil end
        local source=Material(path)
        if source:IsError() or source:GetShader()~='VertexLitGeneric' then pool.rows[key]=false;return nil end
        local texture=source:GetTexture('$basetexture')
        if not texture or texture:IsError() then pool.rows[key]=false;return nil end
        -- Neutral grey leaves most texels untouched in detail mode 0. Only the
        -- sparse procedural marks change texture; the native base map survives.
        local params={['$basetexture']=texture:GetName(),['$model']='1',
            ['$detail']='lod/weapon_finish/patch_'..pattern,['$detailblendmode']='0',
            ['$detailscale']='1',['$detailblendfactor']='.65',['$phong']='1',
            ['$phongboost']='.25',['$phongexponent']='18'}
        for _,name in ipairs({'$bumpmap','$envmapmask'}) do
            local t=source:GetTexture(name);if t and not t:IsError() then params[name]=t:GetName() end
        end
        local env=source:GetString('$envmap');if env and env~='' then params['$envmap']=env end
        for _,name in ipairs({'$basealphaenvmapmask','$normalmapalphaenvmapmask','$selfillum','$alphatest'}) do
            local value=source:GetInt(name);if value and value~=0 then params[name]=tostring(value) end
        end
        pool.count=pool.count+1
        row={material=CreateMaterial('LOD_WeaponSurface_'..util.CRC(key),'VertexLitGeneric',params)}
        pool.rows[key]=row
    end
    local c=colors[style.element] or pale
    local amount=.18+style.rarity*.035
    row.material:SetVector('$color2',Vector(1-amount+amount*c.r/255,1-amount+amount*c.g/255,1-amount+amount*c.b/255))
    row.material:SetFloat('$detailscale',1+style.variant*2)
    row.material:SetFloat('$detailblendfactor',.45+style.variant*.3)
    row.material:SetFloat('$phongexponent',({24,6,12,36})[pattern])
    return '!'..row.material:GetName()
end
function V:Restore(ent)
    local state=applied[ent];if not state then return end
    applied[ent]=nil
    if IsValid(ent) and ent:GetModel()==state.model and ent:GetSubMaterial(state.slot)==state.ours then
        ent:SetSubMaterial(state.slot,state.previous)
    end
end
function V:Apply(ent,style,owner,view)
    self:Restore(ent)
    if not style or not self:Visible(ent,owner,view) then return end
    local row=cache[ent] or {};cache[ent]=row
    local model=ent:GetModel()
    if row.model~=model then
        row.model=model;row.surfaces={}
        for index,path in ipairs(ent:GetMaterials() or {}) do
            if gunSurface(path) then row.surfaces[#row.surfaces+1]={slot=index-1,path=path} end
        end
    end
    local choices=row.surfaces or {}
    if #choices==0 then return end
    -- One gun-only material region, never arms or a full-model override. Even
    -- single-material guns retain their base map under a sparse detail mask.
    local surface=choices[style.hash%#choices+1]
    local previous=ent:GetSubMaterial(surface.slot)
    if previous and previous~='' then return end -- respect unrelated skins
    local material=self:Surface(surface.path,style);if not material then return end
    applied[ent]={model=model,slot=surface.slot,previous=previous,ours=material}
    ent:SetSubMaterial(surface.slot,material)
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
        local fade=math.min(1,(flash.untilTime-CurTime())/.075)
        local radius=(low and 8 or 13)*fade
        render.DrawSprite(muzzle,radius,radius,Color(c.r,c.g,c.b,230*fade))
        if not low then render.DrawSprite(muzzle+ang:Forward()*2,radius*.45,radius*.45,Color(c.r,c.g,c.b,255*fade)) end
    end
end
function V:Flash(weapon)
    if not IsValid(weapon) or not lengths[weapon:GetClass()] or weapon:GetClass()=='weapon_lod_crowbar' then return end
    if not self:EntityStyle(weapon) then return end
    local prior=flashes[weapon]
    -- Collapse shotgun pellets and predicted/server copies of the same shot.
    if prior and CurTime()-prior.started<.05 then return end
    flashes[weapon]={started=CurTime(),untilTime=CurTime()+.075}
end
hook.Add('PreDrawViewModel','LOD_ProceduralWeaponSurface',function(vm,ply,weapon)
    V:Apply(vm,IsValid(weapon) and V:EntityStyle(weapon),ply,true)
end)
hook.Add('PostDrawViewModel','LOD_ProceduralWeaponAppearance',function(vm,ply,weapon)
    V:Restore(vm)
    if IsValid(weapon) then V:Draw(vm,V:EntityStyle(weapon),weapon:GetClass(),ply,true,weapon) end
end)
-- Native world weapons may render separately from their player. Scope the
-- surface to the gun's actual DrawModel call, not the player's pre/post pair.
-- Install only on already-rendered, settled client weapons; respect any addon
-- override and keep the original native DrawModel path (no extra model draw).
function V:WorldWeapon(weapon)
    if worldDraws[weapon] or weapon.RenderOverride~=nil then return end
    local function drawWeapon(ent,flags)
        local owner=ent:GetOwner()
        local active=IsValid(owner) and owner:GetActiveWeapon()==ent
        local style=active and V:EntityStyle(ent) or nil
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
