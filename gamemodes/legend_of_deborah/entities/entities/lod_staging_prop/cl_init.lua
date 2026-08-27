include("shared.lua")

local portalGlow = Material("sprites/light_glow02_add")

surface.CreateFont("LOD_StagingLabel", {
    font = "DejaVu Sans",
    size = 32,
    weight = 800,
    antialias = true
})

surface.CreateFont("LOD_StagingLine", {
    font = "DejaVu Sans",
    size = 24,
    weight = 650,
    antialias = true
})

local function labelColor(kind)
    if kind == ENT.KIND_PORTAL then return Color(110, 165, 255) end
    if kind == ENT.KIND_WEAPON then return Color(248, 213, 105) end
    return Color(235, 110, 105)
end

local function drawLabel(ent)
    local eye = EyePos()
    local pos = ent:WorldSpaceCenter() + Vector(0, 0, ent:GetStageKind() == ent.KIND_GUIDE and 54 or 34)
    local ang = (eye - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)

    cam.Start3D2D(pos, ang, 0.055)
        local kind = ent:GetStageKind()
        local label = ent:GetStageLabel()
        draw.SimpleTextOutlined(label ~= "" and label or "THE LEGEND OF DEBORAH",
            "LOD_StagingLabel", 0, 0, labelColor(kind), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            2, Color(0, 0, 0, 230))
        if kind == ent.KIND_GUIDE then
            draw.SimpleTextOutlined("It's dangerous to go alone. Take this.",
                "LOD_StagingLine", 0, 34, Color(235, 235, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                2, Color(0, 0, 0, 230))
        end
    cam.End3D2D()
end

function ENT:Draw()
    self:DrawModel()
    drawLabel(self)
end

function ENT:DrawTranslucent()
    self:DrawModel()
    if self:GetStageKind() == self.KIND_PORTAL then
        local pos = self:GetPos() + Vector(0, 0, 30)
        render.SetMaterial(portalGlow)
        render.DrawSprite(pos, 86, 86, Color(92, 148, 255, 190))
    end
    drawLabel(self)
end
