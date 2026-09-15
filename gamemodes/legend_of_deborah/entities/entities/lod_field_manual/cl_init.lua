include("shared.lua")

-- The portable reader is loaded by the gamemode; this entity only draws the book.
surface.CreateFont("LOD_InstructionBook", {font="Georgia", size=20, weight=900, antialias=true})

local function facing3D2DAngle(pos)
    local ang = (EyePos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    return ang
end

local function drawPedestal(ent)
    local pos, ang = ent:GetPos(), ent:GetAngles()
    local up, right = Vector(0, 0, 1), ent:GetRight()
    render.SetColorMaterial()
    render.DrawBox(pos, ang, Vector(-18, -15, 0), Vector(18, 15, 36), Color(66, 48, 40))
    render.DrawBox(pos + up * 36, ang, Vector(-23, -19, 0), Vector(23, 19, 4), Color(122, 82, 55))
    render.DrawBox(pos + up * 40, ang, Vector(-21, -17, 0), Vector(21, 17, 2), Color(72, 46, 33))

    local bookCenter = pos + up * 45
    render.DrawQuadEasy(bookCenter - up * 1.3 - right * 7.6,
        (up + right * 0.22):GetNormalized(), 21, 28, Color(103, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - up * 1.3 + right * 7.6,
        (up - right * 0.22):GetNormalized(), 21, 28, Color(103, 34, 31), 0)
    render.DrawQuadEasy(bookCenter - right * 7.3,
        (up + right * 0.25):GetNormalized(), 19, 26, Color(246, 237, 207), 0)
    render.DrawQuadEasy(bookCenter + right * 7.3,
        (up - right * 0.25):GetNormalized(), 19, 26, Color(246, 237, 207), 0)
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-220, -220, -24), Vector(220, 220, 220))
end

function ENT:Draw()
    drawPedestal(self)

    local bookPos = self:GetPos() + Vector(0, 0, 49)
    cam.Start3D2D(bookPos, facing3D2DAngle(bookPos), 0.06)
        draw.SimpleTextOutlined("THE LEGEND OF DEBORAH", "LOD_InstructionBook", 0, 0,
            Color(124, 42, 38), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(255, 248, 225, 235))
    cam.End3D2D()
end

function ENT:DrawTranslucent()
    self:Draw()
end
