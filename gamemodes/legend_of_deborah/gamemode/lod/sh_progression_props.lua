LOD = LOD or {}
LOD.ProgressionProps = LOD.ProgressionProps or {}
local Props = LOD.ProgressionProps

-- Native stock geometry is the body in every view. Keep the original gameplay
-- anchor independent of model pivots, so appearance never moves the touch target.
function Props:RotatedBounds(lo,hi,angles)
    local mins,maxs=Vector(math.huge,math.huge,math.huge),Vector(-math.huge,-math.huge,-math.huge)
    for _,x in ipairs({lo.x,hi.x}) do for _,y in ipairs({lo.y,hi.y}) do for _,z in ipairs({lo.z,hi.z}) do
        local p=Vector(x,y,z);p:Rotate(angles)
        for _,axis in ipairs({"x","y","z"}) do
            mins[axis]=math.min(mins[axis],p[axis]);maxs[axis]=math.max(maxs[axis],p[axis])
        end
    end end end
    return mins,maxs
end

function Props:Place(ent,anchor,model,fallback,color)
    ent:SetModel(util.IsValidModel(model) and model or fallback)
    local lo,hi=ent:GetModelBounds()
    local size=hi-lo
    local angles=Angle(0,0,0)
    if size.x>=size.y and size.x>=size.z then angles=Angle(-90,0,0)
    elseif size.y>=size.z then angles=Angle(0,0,90) end
    local mins,maxs=self:RotatedBounds(lo,hi,angles)
    local pedestal=ents.Create("lod_floor_map_pedestal")
    if not IsValid(pedestal) then ent:Remove();return false end
    ent:DeleteOnRemove(pedestal)
    pedestal.LODPropColor=color
    pedestal:SetPos(anchor-Vector(0,0,LOD.Config.Progression.KeycardHeight))
    pedestal:Spawn()
    if not IsValid(pedestal) then ent:Remove();return false end
    pedestal:Activate()
    ent.LODProgressionPedestal=pedestal
    ent:SetNW2Entity("LOD_MapPedestal",pedestal)
    local top=pedestal:GetPos().z+pedestal:OBBMaxs().z
    ent:SetPos(Vector(anchor.x-(mins.x+maxs.x)*.5,anchor.y-(mins.y+maxs.y)*.5,top+2-mins.z))
    ent:SetAngles(angles)
    ent:SetMoveType(MOVETYPE_NONE)
    -- Only the low plinth is solid. Upright items cannot obstruct a narrow path.
    ent:SetSolid(SOLID_NONE)
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:DrawShadow(false)
    ent.LODStockBoundsMins,ent.LODStockBoundsMaxs=lo,hi
    if color then ent:SetColor(color) end
    return true
end

function Props:RefreshBounds(ent)
    local model=ent:GetModel()
    if ent.LODBoundsModel==model then return end
    ent.LODBoundsModel=model
    local lo,hi=ent:GetModelBounds()
    -- Bounds are model-local: Source applies entity rotation exactly once.
    ent:SetRenderBounds(Vector(lo.x-128,lo.y-128,lo.z-128),Vector(hi.x+128,hi.y+128,hi.z+128))
end

function Props:Draw(ent)
    self:RefreshBounds(ent)
    render.SuppressEngineLighting(true)
    local ok,err=pcall(ent.DrawModel,ent)
    render.SuppressEngineLighting(false)
    if not ok then ErrorNoHalt(tostring(err).."\n") end
end

function Props:LabelFacing(pos)
    local ang=(EyePos()-pos):Angle()
    ang:RotateAroundAxis(ang:Right(),90);ang:RotateAroundAxis(ang:Up(),-90)
    return ang
end
