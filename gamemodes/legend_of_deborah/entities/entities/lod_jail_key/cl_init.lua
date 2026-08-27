include("shared.lua")

local MC = LOD.Config.Maze
local DRAW_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 36
local keyMaterial = CreateMaterial("lod_jail_key_opaque_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})
local beaconMaterial = Material("sprites/light_glow02_add")

function ENT:Draw()
    if self:GetPos():DistToSqr(EyePos()) > DRAW_DISTANCE_SQR then return end
    local pos = self:GetPos()
    local ang = Angle(0, CurTime() * 55 % 360, 0)
    local temporaryCore = self:GetKeySource() == "temporary_core"

    render.SetMaterial(keyMaterial)
    render.DrawBox(pos, ang, Vector(-8, -30, -5), Vector(8, 30, 5), Color(238, 194, 92))
    render.DrawBox(pos + ang:Forward() * 24, ang, Vector(-14, -10, -5), Vector(14, 10, 5), Color(255, 222, 104))

    -- During the pre-Warden vertical slice, the player has not just completed a
    -- boss encounter that naturally tells them "the key is here." Give that
    -- temporary Core stand-in a local arrival beacon instead of overloading the
    -- maze's quadrant colors with progression meaning. The cue disappears
    -- automatically when the production Warden supplies the normal Jail Key.
    if temporaryCore then
        local pulse = 0.72 + math.sin(CurTime() * 4.5) * 0.18
        render.SetMaterial(beaconMaterial)
        render.DrawSprite(pos + Vector(0, 0, 30), 34 * pulse, 34 * pulse, Color(255, 218, 104, 225))
        render.DrawSprite(pos + Vector(0, 0, 74), 24 * pulse, 24 * pulse, Color(255, 238, 170, 190))
        render.DrawSprite(pos + Vector(0, 0, 118), 14 * pulse, 14 * pulse, Color(255, 245, 205, 145))
    end

    local labelAng = Angle(0, EyeAngles().y - 90, 90)
    cam.Start3D2D(pos + Vector(0, 0, temporaryCore and 48 or 38), labelAng, 0.12)
        local width = temporaryCore and 310 or 240
        draw.RoundedBox(4, -width * 0.5, -26, width, 52, Color(16, 18, 20, 232))
        draw.SimpleText(temporaryCore and "CORE — JAIL KEY" or "JAIL KEY", "DermaLarge", 0, 0,
            Color(255, 222, 104), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
