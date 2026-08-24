LOD = LOD or {}

local aimMaterial = Material("cable/redlaser")
local LASER_WIDTH = 2.5
local SOLDIER_LASER_COLOR = Color(255, 80, 60, 220)
local BLITZER_LASER_COLOR = Color(80, 220, 100, 220)

local function installRenderer()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end
    if class.LODSoldierShotContractRendererInstalled then return true end
    class.LODSoldierShotContractRendererInstalled = true

    local baseDraw = class.Draw
    function class:Draw()
        if baseDraw then
            baseDraw(self)
        else
            self:DrawModel()
        end

        if not self:GetNW2Bool("LOD_SoldierShotTelegraph", false) then return end

        local archetype = self:GetNW2String("LOD_Archetype", "")
        if archetype ~= "soldier" and archetype ~= "blitzer" then return end

        local origin = self:GetNW2Vector("LOD_SoldierShotOrigin", vector_origin)
        local direction = self:GetNW2Vector("LOD_SoldierShotDirection", vector_origin)
        if origin == vector_origin or direction == vector_origin then return end
        direction = direction:GetNormalized()

        local aimPoint = self:GetNW2Vector("LOD_SoldierShotAimPoint", vector_origin)
        local targetDistance = aimPoint ~= vector_origin and origin:Distance(aimPoint) or 768

        -- Extend the literal firing line beyond the frozen target point. This is
        -- not a presentation proxy: every ordinary Soldier bolt uses the same
        -- origin and direction. The extension only keeps the warning legible when
        -- the intended point is near the local player's first-person camera.
        local visualDistance = math.Clamp(targetDistance + 256, 512, 1600)
        local endPos = origin + direction * visualDistance

        render.SetMaterial(aimMaterial)
        local color = archetype == "blitzer" and BLITZER_LASER_COLOR or SOLDIER_LASER_COLOR
        render.DrawBeam(origin, endPos, LASER_WIDTH, 0, 1, color)
    end

    return true
end

if not installRenderer() then
    hook.Add("OnEntityCreated", "LOD_InstallSoldierShotContractRenderer", function(ent)
        if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
        if installRenderer() then
            hook.Remove("OnEntityCreated", "LOD_InstallSoldierShotContractRenderer")
        end
    end)
end
