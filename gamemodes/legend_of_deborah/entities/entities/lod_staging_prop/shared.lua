ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Staging Prop"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.KIND_GUIDE = 1
ENT.KIND_PORTAL = 2
ENT.KIND_WEAPON = 3
ENT.KIND_SIGN = 4
ENT.KIND_TORCH = 5
ENT.KIND_PEDESTAL = 6

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "StageKind")
    self:NetworkVar("String", 0, "StageLabel")

    -- Historical staging code still assigns an E-specific portal label. Keep the
    -- networked/world label input-agnostic; the client HUD resolves each player's
    -- actual +use binding independently.
    if SERVER then
        self:NetworkVarNotify("StageLabel", function(ent, _, _, newValue)
            if not IsValid(ent) or ent:GetStageKind() ~= ent.KIND_PORTAL then return end
            if tostring(newValue or "") ~= "PRESS E — ENTER THE DUNGEON" then return end
            timer.Simple(0, function()
                if IsValid(ent) and ent:GetStageKind() == ent.KIND_PORTAL
                    and ent:GetStageLabel() == "PRESS E — ENTER THE DUNGEON"
                then
                    ent:SetStageLabel("ENTER THE DUNGEON")
                end
            end)
        end)
    end
end