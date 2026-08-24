include("shared.lua")

local PC = LOD.Config.Progression
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry or {}
local DRAW_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 64
local LABEL_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 16
local doorMaterial = CreateMaterial("lod_jail_door_solid_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

LOD.ClientJailDoors = LOD.ClientJailDoors or setmetatable({}, {__mode = "k"})

function ENT:Initialize()
    LOD.ClientJailDoors[self] = true
end

function ENT:OnRemove()
    LOD.ClientJailDoors[self] = nil
end

function ENT:Draw()
    if self:GetPos():DistToSqr(EyePos()) > DRAW_DISTANCE_SQR then return end
    local frac = 0
    if self:GetOpened() then
        local started = self:GetOpenedAt()
        frac = started > 0 and math.Clamp((CurTime() - started) / PC.GateOpenSeconds, 0, 1) or 1
    end
    if frac >= 1 then return end

    local halfThickness = PC.GateThickness * 0.5
    local halfWidth = PC.GateWidth * 0.5
    local halfHeight = PC.GateBlockerHeight * 0.5
    local mins, maxs
    if self:GetDoorAxis() == 0 then
        mins, maxs = Vector(-halfThickness, -halfWidth, -halfHeight), Vector(halfThickness, halfWidth, halfHeight)
    else
        mins, maxs = Vector(-halfWidth, -halfThickness, -halfHeight), Vector(halfWidth, halfThickness, halfHeight)
    end
    render.SetMaterial(doorMaterial)
    render.DrawBox(self:GetPos() + Vector(0, 0, PC.GateBlockerHeight * frac), angle_zero,
        mins, maxs, Color(74, 78, 84))
end

hook.Add("PostDrawTranslucentRenderables", "LOD_DrawJailDoorLabel", function()
    for ent in pairs(LOD.ClientJailDoors) do
        if IsValid(ent) and ent:GetPos():DistToSqr(EyePos()) <= LABEL_DISTANCE_SQR then
            local z = -PC.GateBlockerHeight * 0.5 + 126
            local positions
            if ent:GetDoorAxis() == 0 then
                positions = {
                    {ent:GetPos() + Vector(PC.GateThickness * 0.5 + 18, 0, z), Angle(0, 90, 90)},
                    {ent:GetPos() + Vector(-PC.GateThickness * 0.5 - 18, 0, z), Angle(0, -90, 90)}
                }
            else
                positions = {
                    {ent:GetPos() + Vector(0, PC.GateThickness * 0.5 + 18, z), Angle(0, 180, 90)},
                    {ent:GetPos() + Vector(0, -PC.GateThickness * 0.5 - 18, z), Angle(0, 0, 90)}
                }
            end
            for _, item in ipairs(positions) do
                cam.Start3D2D(item[1], item[2], 0.12)
                    draw.RoundedBox(4, -180, -36, 360, 72, Color(18, 20, 22, 242))
                    draw.SimpleText("DEBORAH — JAIL", "DermaLarge", 0, -9, Color(225, 225, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(ent:GetOpened() and "UNLOCKED" or "USE JAIL KEY", "DermaDefaultBold", 0, 21,
                        ent:GetOpened() and Color(100, 230, 120) or Color(255, 222, 104), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end
    end
end)
