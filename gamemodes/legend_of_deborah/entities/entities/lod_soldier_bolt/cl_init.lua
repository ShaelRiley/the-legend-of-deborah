include("shared.lua")

local glow = Material("sprites/light_glow02_add")

function ENT:Initialize()
    -- Presentation-only culling bounds belong on the client. Keeping them here
    -- avoids server-side entity initialization errors while ensuring the moving
    -- sprite remains visible between networked position updates.
    if self.SetRenderBounds then
        self:SetRenderBounds(Vector(-16, -16, -16), Vector(16, 16, 16))
    end
end

function ENT:DrawTranslucent()
    render.SetMaterial(glow)
    render.DrawSprite(self:GetPos(), 14, 14, Color(255, 145, 70, 235))
end
