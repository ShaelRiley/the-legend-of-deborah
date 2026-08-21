include("shared.lua")

local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
local floorColor = GC.FloorColor or Color(46, 49, 51, 255)
local stairColor = GC.StairColor or Color(68, 72, 74, 255)
local stairEdgeColor = GC.DebugColor or Color(225, 145, 48, 255)
local textureTile = GC.FloorTextureTile or 384

local function floorMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.GetIndustrialMaterial then
        return LOD.TexturedBox:GetIndustrialMaterial(GC.FloorMaterialFallback)
    end
    local mat = Material(GC.FloorMaterial or "models/props_wasteland/metal_tram001a")
    if mat:IsError() then
        mat = Material(GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
    end
    return mat
end

local visualBoxes = visualBoxes or setmetatable({}, {__mode = "k"})

local function refreshRenderBounds(ent)
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()
    local margin = Vector(32, 32, 32)
    ent:SetRenderBounds(mins - margin, maxs + margin)
end

function ENT:Initialize()
    visualBoxes[self] = true
    refreshRenderBounds(self)
    self._LODNextBoundsRefresh = 0
end

function ENT:Think()
    if CurTime() >= (self._LODNextBoundsRefresh or 0) then
        refreshRenderBounds(self)
        self._LODNextBoundsRefresh = CurTime() + 1
    end
end

function ENT:OnRemove()
    visualBoxes[self] = nil
end

function ENT:Draw()
end

local function drawFloorSlab(ent, color)
    local material = floorMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.DrawSlab then
        LOD.TexturedBox:DrawSlab(
            ent:GetPos(),
            ent:GetAngles(),
            ent:GetBoxMins(),
            ent:GetBoxMaxs(),
            material,
            color,
            textureTile
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(ent:GetPos(), ent:GetAngles(), ent:GetBoxMins(), ent:GetBoxMaxs(), color)
end

local function drawFullMetalBox(ent, color)
    local material = floorMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.Draw then
        LOD.TexturedBox:Draw(
            ent:GetPos(),
            ent:GetAngles(),
            ent:GetBoxMins(),
            ent:GetBoxMaxs(),
            material,
            color,
            textureTile
        )
        return
    end

    render.SetMaterial(material)
    render.DrawBox(ent:GetPos(), ent:GetAngles(), ent:GetBoxMins(), ent:GetBoxMaxs(), color)
end

hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end

    for ent in pairs(visualBoxes) do
        if IsValid(ent) then
            local kind = ent:GetBoxKind()

            -- Ordinary floor runs render only their top and underside. Their
            -- collision remains a substantial 32-unit steel plate, but internal
            -- row-run side faces are not visible, eliminating false step/riser
            -- seams across a mathematically flat deck. Stair boxes retain all six
            -- faces because their vertical risers are real geometry.
            if kind == 1 then
                drawFloorSlab(ent, floorColor)
            elseif kind == 2 then
                drawFullMetalBox(ent, stairColor)
                render.DrawWireframeBox(
                    ent:GetPos(),
                    ent:GetAngles(),
                    ent:GetBoxMins(),
                    ent:GetBoxMaxs(),
                    stairEdgeColor,
                    true
                )
            elseif kind == 5 then
                -- The continuous level-0 underdeck is deliberately recessed only
                -- half a unit beneath the ordinary deck. Use the identical material
                -- and color and draw only broad faces, so any container-base or
                -- exterior-corner sightline resolves to seamless industrial steel.
                drawFloorSlab(ent, floorColor)
            end
        end
    end
end)
