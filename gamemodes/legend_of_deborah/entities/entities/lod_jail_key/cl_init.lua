include("shared.lua")

local MC = LOD.Config.Maze
local DRAW_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 36
local keyMaterial = CreateMaterial("lod_jail_key_opaque_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

function ENT:Draw()
    if self:GetPos():DistToSqr(EyePos()) > DRAW_DISTANCE_SQR then return end
    local pos = self:GetPos()
    local ang = Angle(0, CurTime() * 55 % 360, 0)
    render.SetMaterial(keyMaterial)
    render.DrawBox(pos, ang, Vector(-8, -30, -5), Vector(8, 30, 5), Color(238, 194, 92))
    render.DrawBox(pos + ang:Forward() * 24, ang, Vector(-14, -10, -5), Vector(14, 10, 5), Color(255, 222, 104))

    local labelAng = Angle(0, EyeAngles().y - 90, 90)
    cam.Start3D2D(pos + Vector(0, 0, 38), labelAng, 0.12)
        draw.RoundedBox(4, -120, -26, 240, 52, Color(16, 18, 20, 232))
        draw.SimpleText("JAIL KEY", "DermaLarge", 0, 0, Color(255, 222, 104), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
