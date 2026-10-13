include("shared.lua")

local MC = LOD.Config.Maze
local DRAW_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 36
local INK, VIOLET = Color(18, 20, 28), Color(48, 32, 112)
local IVORY, GOLD = Color(255, 248, 222), Color(255, 222, 104)
local keyMaterial = CreateMaterial("lod_jail_key_opaque_v2", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1", ["$vertexalpha"] = "1", ["$ignorez"] = "0"
})
local beaconMaterial = CreateMaterial("lod_jail_key_beacon_depth_v2", "UnlitGeneric", {
    ["$basetexture"] = "sprites/light_glow02", ["$additive"] = "1",
    ["$vertexcolor"] = "1", ["$vertexalpha"] = "1", ["$ignorez"] = "0"
})
local labelBackground = Color(16, 18, 20, 232)

-- Cached solid parts, in deck space for the plinth and facing space for the key.
-- Gold/ivory luminance and a complementary blue-violet body stay legible against
-- the variable maze palette. Shape and the label also identify it without color.
local pedestalParts = {
    {Vector(-20, -20, 0), Vector(20, 20, 4), INK},
    {Vector(-18, -18, 4), Vector(18, 18, 24), VIOLET},
    {Vector(-20, -20, 24), Vector(20, 20, 28), IVORY},
    {Vector(-18.5, -12, 9), Vector(-18, 12, 19), GOLD},
    {Vector(18, -12, 9), Vector(18.5, 12, 19), GOLD},
    {Vector(-12, -18.5, 9), Vector(12, -18, 19), GOLD},
    {Vector(-12, 18, 9), Vector(12, 18.5, 19), GOLD}
}
local keyParts = {
    {Vector(-4, -12, 19), Vector(4, 12, 24), IVORY},
    {Vector(-4, -12, 8), Vector(4, 12, 13), GOLD},
    {Vector(-4, -12, 13), Vector(4, -7, 19), GOLD},
    {Vector(-4, 7, 13), Vector(4, 12, 19), GOLD},
    {Vector(-4, -3, -24), Vector(4, 3, 8), GOLD},
    {Vector(-4, 3, -22), Vector(4, 12, -17), GOLD},
    {Vector(-4, 3, -12), Vector(4, 9, -7), GOLD}
}
local KEY_OFFSET, LABEL_OFFSET = Vector(0, 0, 20), Vector(0, 0, 62)
local BEACON_OFFSETS = {Vector(0, 0, 30), Vector(0, 0, 74), Vector(0, 0, 118)}
local BEACON_SIZES = {34, 24, 14}
local BEACON_COLORS = {Color(255, 218, 104, 225), Color(255, 238, 170, 190), Color(255, 245, 205, 145)}

local function refreshBounds(ent)
    ent:SetRenderBounds(ent.KeyRenderMins, ent.KeyRenderMaxs)
end
function ENT:Initialize()
    refreshBounds(self)
end
hook.Add("NotifyShouldTransmit", "LOD_JailKeyDisplayBounds", function(ent, transmitting)
    if transmitting and IsValid(ent) and ent:GetClass() == "lod_jail_key" then refreshBounds(ent) end
end)
hook.Add("OnReloaded", "LOD_JailKeyDisplayBounds", function()
    for _, ent in ipairs(ents.FindByClass("lod_jail_key")) do refreshBounds(ent) end
end)

local function reduced()
    return LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
end
local function keyPosition(ent, still)
    return ent:GetPos() + KEY_OFFSET + Vector(0, 0, still and 0 or math.sin(CurTime() * 1.8 + ent:EntIndex()) * 3)
end
local function labelFacing(pos)
    local ang = (EyePos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    return ang
end

function ENT:Draw()
    local eye = EyePos()
    if self:GetPos():DistToSqr(eye) > DRAW_DISTANCE_SQR then return end
    render.SetMaterial(keyMaterial)
    local deck = self:GetPos() + Vector(0, 0, self.PedestalMins.z)
    for _, part in ipairs(pedestalParts) do
        render.DrawBox(deck, angle_zero, part[1], part[2], part[3], true)
    end
    -- An eight-unit-thick upright key, not an edge-on horizontal slab. Its bow,
    -- shaft and teeth always face the viewer, including views from above/below.
    local pos = keyPosition(self, reduced())
    local ang = (eye - pos):Angle()
    for _, part in ipairs(keyParts) do
        render.DrawBox(pos, ang, part[1], part[2], part[3], true)
    end
end

function ENT:DrawTranslucent()
    if self:GetPos():DistToSqr(EyePos()) > DRAW_DISTANCE_SQR then return end
    local still = reduced()
    local temporaryCore = self.GetKeySource and self:GetKeySource() == "temporary_core"
    if temporaryCore then
        local pulse = still and 1 or .72 + math.sin(CurTime() * 4.5) * .18
        render.SetMaterial(beaconMaterial)
        for index, offset in ipairs(BEACON_OFFSETS) do
            local size = BEACON_SIZES[index] * pulse
            render.DrawSprite(self:GetPos() + offset, size, size, BEACON_COLORS[index])
        end
    end
    if LOD.AdventurePresentation then
        LOD.AdventurePresentation:Glint(keyPosition(self, still), self:EntIndex(), GOLD)
    end
    local pos = self:GetPos() + LABEL_OFFSET
    cam.Start3D2D(pos, labelFacing(pos), .12)
        local width = temporaryCore and 310 or 240
        draw.RoundedBox(4, -width * .5, -26, width, 52, labelBackground)
        draw.SimpleText(temporaryCore and "CORE — JAIL KEY" or "JAIL KEY", "DermaLarge", 0, 0,
            GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
