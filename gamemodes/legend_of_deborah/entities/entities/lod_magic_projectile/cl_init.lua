include("shared.lua")

local iron = Material("models/debug/debugwhite")
local fuseMaterial = Material("cable/cable2")
local emberMaterial = Material("sprites/light_glow02_add")
local ironColor, fuseColor = Color(24, 25, 28), Color(185, 151, 99)

function ENT:Initialize()
    -- Include the cosmetic fuse in culling bounds. Server hull/travel stay intact.
    self:SetRenderBounds(Vector(-16,-16,-16),Vector(16,16,20))
end

function ENT:DrawBomb()
    local origin, angles = self:GetPos(), self:GetAngles()
    local up, right = angles:Up(), angles:Right()
    render.SetMaterial(iron)
    render.DrawSphere(origin, 6, 16, 12, ironColor)
    render.DrawBox(origin+up*5,angles,Vector(-1.8,-1.8,0),Vector(1.8,1.8,2.5),ironColor)
    local root = origin+up*7
    local bend = root+up*3+right*1.5
    local tip = bend+up*1.5+right*3
    render.SetMaterial(fuseMaterial)
    render.DrawBeam(root,bend,1.2,0,0.5,fuseColor)
    render.DrawBeam(bend,tip,1.2,0.5,1,fuseColor)
    render.SetMaterial(emberMaterial)
    local pulse = 3 + math.sin(CurTime()*25+self:EntIndex())*0.6
    render.DrawSprite(tip,pulse,pulse,Color(255,185,65))
    -- Three tiny sparks, no particles, extra entities, timer, or dynamic light.
    for i=1,3 do
        local phase = CurTime()*12+i*2.1
        local direction = up*math.sin(phase)+right*math.cos(phase)
        render.DrawBeam(tip+direction*1.2,tip+direction*3,0.5,0,1,Color(255,205,95,200))
    end
end

function ENT:Draw()
    if self:GetMagicForm() == "bomb" then self:DrawBomb() return end
    self:DrawModel()
    local color = self:GetColor()
    local light = DynamicLight(self:EntIndex())
    if light then
        light.pos = self:GetPos()
        light.r = color.r
        light.g = color.g
        light.b = color.b
        light.brightness = 1.4
        light.Decay = 900
        light.Size = 96
        light.DieTime = CurTime() + 0.08
    end
end
