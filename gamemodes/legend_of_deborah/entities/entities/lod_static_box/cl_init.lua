include("shared.lua")

local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
local floorColor = GC.FloorColor or Color(46, 49, 51, 255)
local stairColor = GC.StairColor or Color(68, 72, 74, 255)
local stairEdgeColor = GC.DebugColor or Color(225, 145, 48, 255)

-- Use a stock Garry's Mod metal-floor material so the generated deck reads as a
-- real grippy steel plate rather than a flat debug slab. This path is part of the
-- base GMod material set exposed by Sandbox's material tool; retain a known HL2
-- metal fallback in case a client reports the preferred material as unavailable.
local floorMaterial = Material(GC.FloorMaterial or "phoenix_storms/metalfloor_2-3")
if floorMaterial:IsError() then
    floorMaterial = Material(GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
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

local function drawMetal(ent, color)
    render.SetMaterial(floorMaterial)
    render.DrawBox(
        ent:GetPos(),
        ent:GetAngles(),
        ent:GetBoxMins(),
        ent:GetBoxMaxs(),
        color
    )
end

hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end

    for ent in pairs(visualBoxes) do
        if IsValid(ent) then
            local kind = ent:GetBoxKind()

            -- Floors and stair treads share one solid industrial steel language.
            -- Rails and anti-bypass blockers remain collision-only because cargo
            -- props and the visible stair geometry already communicate them.
            if kind == 1 then
                drawMetal(ent, floorColor)
            elseif kind == 2 then
                drawMetal(ent, stairColor)
                render.DrawWireframeBox(
                    ent:GetPos(),
                    ent:GetAngles(),
                    ent:GetBoxMins(),
                    ent:GetBoxMaxs(),
                    stairEdgeColor,
                    true
                )
            end
        end
    end
end)
