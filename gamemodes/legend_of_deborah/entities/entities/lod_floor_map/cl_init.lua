include("shared.lua")
local MC=LOD.Config.Maze
local INK,WHITE,IRIS=Color(18,35,48),Color(252,247,224),Color(74,178,226)
LOD.FloorMapVisual=LOD.FloorMapVisual or {}
local Visual=LOD.FloorMapVisual
Visual.pickups=Visual.pickups or setmetatable({}, {__mode="k"})
Visual.stock=Visual.stock or setmetatable({}, {__mode="k"})
-- Retire the superseded globe on Lua refresh.
if Visual.mesh then Visual.mesh:Destroy();Visual.mesh=nil end

local function retire(ent)
    local row=Visual.stock[ent]
    for _,model in pairs(row or {}) do if IsValid(model) then model:Remove() end end
    Visual.stock[ent]=nil
end
local function cleanup()
    for ent in pairs(Visual.stock) do retire(ent) end
end
cleanup()

local function circle(radius,dx,dy)
    local out={}
    for i=0,19 do
        local a=i*math.pi*2/20
        out[#out+1]={x=(dx or 0)+math.cos(a)*radius,y=(dy or 0)+math.sin(a)*radius}
    end
    return out
end
local function almond(rx,ry)
    local out={}
    for i=0,31 do
        local a=i*math.pi*2/32
        out[#out+1]={x=math.cos(a)*rx,y=math.sin(a)*ry*(.65+.35*math.abs(math.sin(a)))}
    end
    return out
end
local eyeLayers={{almond(26,12),INK},{almond(24,10),WHITE},
    {circle(8),IRIS},{circle(4),INK},{circle(2,-2,-3),WHITE}}
local function facing(pos)
    -- Pitch and yaw both follow the viewer, also from above/below.
    local ang=(EyePos()-pos):Angle()
    ang:RotateAroundAxis(ang:Right(),90);ang:RotateAroundAxis(ang:Up(),-90)
    return ang
end

function ENT:Initialize()
    LOD.ProgressionProps:RefreshBounds(self)
    Visual.pickups[self]=true
end

function ENT:OnRemove(fullUpdate)
    if fullUpdate then return end
    retire(self);Visual.pickups[self]=nil
end
hook.Add("NotifyShouldTransmit","LOD_Recover_lod_floor_map",function(ent,transmitting)
    if transmitting and IsValid(ent) and ent:GetClass()=="lod_floor_map" then
        Visual.pickups[ent]=true;LOD.ProgressionProps:RefreshBounds(ent)
    end
end)

function ENT:Draw()
    LOD.ProgressionProps:Draw(self)
end

local function drawInfo(self,finder)
    local pos=self:GetPickupPosition()
    if not finder and pos:DistToSqr(EyePos())>(MC.CellSize*2)^2 then return end
    local eye=pos+Vector(0,0,33)
    cam.Start3D2D(eye,facing(eye),1)
        draw.NoTexture()
        for _,layer in ipairs(eyeLayers) do
            surface.SetDrawColor(layer[2]);surface.DrawPoly(layer[1])
        end
    cam.End3D2D()
    local label=pos+Vector(0,0,60)
    local scale=.12*(finder and math.max(1,math.sqrt(pos:DistToSqr(EyePos()))/600) or 1)
    cam.Start3D2D(label,facing(label),scale)
        draw.RoundedBox(4,-145,-25,290,50,Color(16,18,20,230))
        draw.SimpleText("FLOOR "..(self:GetFloorIndex()+1).." MAP","DermaLarge",0,0,WHITE,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:DrawTranslucent() drawInfo(self,false) end

local function drawStock(source,row,name)
    if not IsValid(source) then return end
    local model=row[name]
    if IsValid(model) and model:GetModel()~=source:GetModel() then model:Remove();model=nil end
    if not IsValid(model) then
        model=ClientsideModel(source:GetModel(),RENDERGROUP_OPAQUE)
        if not IsValid(model) then return end
        model:SetNoDraw(true);row[name]=model
    end
    model:SetPos(source:GetPos());model:SetAngles(source:GetAngles())
    model:SetColor(source:GetColor());model:SetMaterial(source:GetMaterial())
    model:SetupBones();model:DrawModel()
end

hook.Add("PostDrawTranslucentRenderables","LOD_MapFinderPickups",function(depth,sky)
    if depth or sky then return end
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2Bool("LOD_IsSoldier",false)
        or ply:GetNW2Bool("LOD_Eliminated",false)
        or not ply:GetNW2Bool("LOD_RPGMapFinder",false) then return end
    if ply.GetObserverMode and ply:GetObserverMode()~=(OBS_MODE_NONE or 0) then return end
    cam.IgnoreZ(true);render.SuppressEngineLighting(true)
    local ok,err=pcall(function()
        for ent in pairs(Visual.pickups) do
            if IsValid(ent) then
                local row=Visual.stock[ent] or {};Visual.stock[ent]=row
                -- Native helper models avoid recursive DrawModel calls on a scripted entity.
                drawStock(ent,row,"book");drawStock(ent:GetNW2Entity("LOD_MapPedestal"),row,"pedestal")
                drawInfo(ent,true)
            else retire(ent);Visual.pickups[ent]=nil end
        end
    end)
    render.SuppressEngineLighting(false);cam.IgnoreZ(false)
    if not ok then ErrorNoHalt(tostring(err).."\n") end
end)

hook.Add("OnReloaded","LOD_FloorMapStockCleanup",cleanup)
hook.Add("ShutDown","LOD_FloorMapGlobeCleanup",cleanup)

