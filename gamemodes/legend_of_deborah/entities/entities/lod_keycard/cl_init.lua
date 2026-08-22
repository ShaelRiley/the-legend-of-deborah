include("shared.lua")

local PC = LOD.Config.Progression
local MC = LOD.Config.Maze
local KEYCARD_BODY_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 36
local PROGRESSION_LABEL_DISTANCE_SQR = (MC and MC.CellSize or 384) ^ 2 * 16

LOD.ProgressionRenderStats = LOD.ProgressionRenderStats or {}
local RenderStats = LOD.ProgressionRenderStats
local cardMaterial = CreateMaterial("lod_keycard_opaque_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

LOD.ClientKeycards = LOD.ClientKeycards or setmetatable({}, {__mode = "k"})

function ENT:Initialize()
    LOD.ClientKeycards[self] = true
end

function ENT:OnRemove()
    LOD.ClientKeycards[self] = nil
end

function ENT:Draw()
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawKeycards", function()
    local eyePos = EyePos()
    local registered, drawn, culled = 0, 0, 0
    render.SetMaterial(cardMaterial)
    render.CullMode(MATERIAL_CULLMODE_NONE)
    for ent in pairs(LOD.ClientKeycards) do
        if IsValid(ent) then
            registered = registered + 1
            if ent:GetPos():DistToSqr(eyePos) <= KEYCARD_BODY_DISTANCE_SQR then
                drawn = drawn + 1
                local card = PC.Cards[math.Clamp(ent:GetCardIndex(), 1, 3)]
                render.DrawBox(ent:GetPos(), Angle(0, CurTime() * 45 % 360, 0),
                    Vector(-18, -28, -3), Vector(18, 28, 3), card.color)
            else
                culled = culled + 1
            end
        end
    end
    render.CullMode(MATERIAL_CULLMODE_CCW)
    RenderStats.keycards = registered
    RenderStats.keycardBodiesDrawn = drawn
    RenderStats.keycardBodiesCulled = culled
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_DrawKeycardLabels", function()
    local eyePos = EyePos()
    local drawn, culled = 0, 0
    for ent in pairs(LOD.ClientKeycards) do
        if IsValid(ent) then
            if ent:GetPos():DistToSqr(eyePos) <= PROGRESSION_LABEL_DISTANCE_SQR then
                drawn = drawn + 1
                local card = PC.Cards[math.Clamp(ent:GetCardIndex(), 1, 3)]
                local ang = Angle(0, EyeAngles().y - 90, 90)
                cam.Start3D2D(ent:GetPos() + Vector(0, 0, 38), ang, 0.12)
                    draw.RoundedBox(4, -130, -30, 260, 60, Color(16, 18, 20, 230))
                    draw.SimpleText(card.name .. " KEYCARD", "DermaLarge", 0, -8, card.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(card.letter .. " / " .. card.symbol, "DermaDefaultBold", 0, 18, Color(245, 245, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            else
                culled = culled + 1
            end
        end
    end
    RenderStats.keycardLabelsDrawn = drawn
    RenderStats.keycardLabelsCulled = culled
end)
