-- Three complementary clipped draws of the SAME native mesh. No added models,
-- surface patterns, replacement base textures, whole-model tint or hand recolor.
local V=LOD.WeaponAppearance
local mappings=setmetatable({}, {__mode='k'})
V.SegmentDrawing=setmetatable({}, {__mode='k'})
local function gunMaterial(path)
    path=path:lower()
    if not path:find('weapons/',1,true) then return false end
    for _,s in ipairs({'hand','arm','glove','finger','skin','sleeve','lens','scope','glass'}) do
        if path:find(s,1,true) then return false end
    end
    return true
end
function V:SegmentPlanes(ent,spec)
    local id=ent:LookupAttachment('muzzle')
    local muzzle=spec.rear and id and id>0 and ent:GetAttachment(id)
    if muzzle then
        local normal=muzzle.Ang:Forward()
        local scale=ent.GetModelScale and ent:GetModelScale() or 1
        return normal,normal:Dot(muzzle.Pos-normal*spec.rear*scale),normal:Dot(muzzle.Pos-normal*spec.front*scale)
    end
    -- Native bounds fallback for the crowbar and world meshes without a muzzle.
    local mins,maxs=ent:OBBMins(),ent:OBBMaxs()
    local axis='x';for _,k in ipairs({'y','z'}) do if maxs[k]-mins[k]>maxs[axis]-mins[axis] then axis=k end end
    local span=maxs[axis]-mins[axis];if span<=0 then return end
    local unit=Vector(0,0,0);unit[axis]=1
    local origin=ent:LocalToWorld(Vector(0,0,0))
    local normal=(ent:LocalToWorld(unit)-origin):GetNormalized()
    local base=normal:Dot(origin)+mins[axis]
    return normal,base+span*(spec.low or .28),base+span*(spec.high or .72)
end
function V:DrawSegmented(ent,style,class,owner,view,flags)
    if not style or not self:Visible(ent,owner,view) or self.SegmentDrawing[ent] then return false end
    if flags and flags~=0 and bit.band(flags,STUDIO_RENDER)==0 then return false end
    local spec=self.Segments[class];if not spec then return false end
    local model=string.lower(ent:GetModel() or '')
    -- Only the stock family is authorized for spatial partitioning.
    local name=model:match('^models/weapons/(.+)%.mdl$')
    name=name and name:match('([^/]+)$')
    if not name or not name:match('^[cvw]_'..spec.stem..'$') then return false end
    if ent.GetMaterial and ent:GetMaterial()~='' then return false end
    local mapping=mappings[ent]
    if not mapping or mapping.model~=model or mapping.class~=class then
        mapping={model=model,class=class,slots={}};local native={}
        for index,path in ipairs(ent:GetMaterials()) do
            if gunMaterial(path) then
                mapping.slots[#mapping.slots+1]={slot=index-1,path=path}
                native[self:MaterialRegion(class,path)]=true
            end
        end
        mapping.native=native.control and native.a and native.b
        mappings[ent]=mapping
    end
    if mapping.native or #mapping.slots==0 then return false end
    self:Restore(ent)
    local slots={}
    for _,s in ipairs(mapping.slots) do
        local previous=ent:GetSubMaterial(s.slot)
        if previous and previous~='' then return false end -- respect external skins
        local a,b=self:Surface(s.path,style,'a'),self:Surface(s.path,style,'b')
        if not a or not b then return false end
        slots[#slots+1]={slot=s.slot,previous=previous,a=a,b=b}
    end
    local normal,low,high=self:SegmentPlanes(ent,spec);if not normal then return false end
    local old=render.EnableClipping(true)
    -- Enabled is not a clip-stack depth. Native held draws can enter with it
    -- already enabled; restore that state, but still render all three regions.
    local planes=0
    local function push(n,d) render.PushCustomClipPlane(n,d);planes=planes+1 end
    local function pop() while planes>0 do render.PopCustomClipPlane();planes=planes-1 end end
    self.SegmentDrawing[ent]=true
    local ok,err=pcall(function()
        push(-normal,-low);ent:DrawModel(flags);pop() -- protected grip/stock
        for _,s in ipairs(slots) do ent:SetSubMaterial(s.slot,s.a) end
        push(normal,low);push(-normal,-high);ent:DrawModel(flags);pop()
        for _,s in ipairs(slots) do ent:SetSubMaterial(s.slot,s.b) end
        push(normal,high);ent:DrawModel(flags);pop()
    end)
    pop();render.EnableClipping(old)
    self.SegmentDrawing[ent]=nil
    if IsValid(ent) then
        for _,s in ipairs(slots) do
            local current=ent:GetSubMaterial(s.slot)
            if current==s.a or current==s.b then ent:SetSubMaterial(s.slot,s.previous) end
        end
    end
    if not ok then ErrorNoHalt(tostring(err)..'\n') end
    return true
end
hook.Add('PreCleanupMap','LOD_WeaponSegmentCache',function() mappings=setmetatable({}, {__mode='k'}) end)
