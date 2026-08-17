include("shared.lua")

local floorColor = Color(58, 62, 64, 255)
local stairColor = Color(120, 126, 132, 255)
local stairEdgeColor = Color(225, 145, 48, 255)

-- render.DrawBox is documented as requiring a 3D rendering context. Drawing the
-- generated slabs from ENT:Draw proved unreliable on the OpenGL/Linux client:
-- wireframes appeared while filled faces did not. Keep a client cache of the
-- transmitted static-box entities and render them from an explicit 3D hook.
local opaqueGeometryMaterial = CreateMaterial("lod_generated_geometry_opaque_v2", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
    ["$nocull"] = "1"
})

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

-- Deliberately do not issue render.Draw* calls from ENT:Draw. The authoritative
-- rendering path below runs inside a documented 3D render hook.
function ENT:Draw()
end

local function drawFilled(ent, color)
    render.SetMaterial(opaqueGeometryMaterial)
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

            -- Rails and anti-bypass blockers remain collision-only. Cargo props
            -- communicate those boundaries visually.
            if kind == 1 then
                drawFilled(ent, floorColor)
            elseif kind == 2 then
                drawFilled(ent, stairColor)
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
