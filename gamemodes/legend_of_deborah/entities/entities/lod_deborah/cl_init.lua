include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 82)
    local ang = Angle(0, EyeAngles().y - 90, 90)
    cam.Start3D2D(pos, ang, 0.11)
        draw.RoundedBox(4, -90, -24, 180, 48, Color(20, 22, 24, 225))
        draw.SimpleText("DEBORAH", "DermaLarge", 0, 0, Color(240, 196, 94), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
