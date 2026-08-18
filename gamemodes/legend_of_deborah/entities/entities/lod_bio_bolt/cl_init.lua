include("shared.lua")

local glow = Material("sprites/light_glow02_add")

function ENT:Initialize()
    if self.SetRenderBounds then
        self:SetRenderBounds(Vector(-56, -56, -56), Vector(56, 56, 56))
    end
end

function ENT:DrawTranslucent()
    render.SetMaterial(glow)
    local pos = self:GetPos()
    -- Exactly three times the Soldier bolt's 14-unit primary sprite diameter.
    render.DrawSprite(pos, 42, 42, Color(88, 255, 112, 245))
    render.DrawSprite(pos, 24, 24, Color(210, 255, 170, 255))
end
