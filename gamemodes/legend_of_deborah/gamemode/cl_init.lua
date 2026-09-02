include("shared.lua")
include("lod/sh_tetris.lua")
include("lod/cl_textured_box.lua")
include("lod/cl_wall_visuals.lua")
include("lod/cl_container_wayfinding_projection.lua")
include("lod/cl_container_section_recolor.lua")
include("lod/cl_container_marking_panel.lua")
include("lod/cl_debug.lua")
include("lod/cl_hud.lua")
include("lod/cl_tetris.lua")
include("lod/cl_intermission_tetris.lua")
include("lod/cl_victory_celebration.lua")
include("lod/cl_magic_hud.lua")
include("lod/cl_dev_testing.lua")
include("lod/cl_hit_confirm.lua")
include("lod/cl_combat_roll_feed.lua")
include("lod/cl_combat_roll_feed_semantics.lua")
include("lod/cl_melee_contact_audit.lua")
include("lod/cl_hostile_damage_audit.lua")
include("lod/cl_minimap.lua")
include("lod/cl_minimap_magic_quadrants.lua")
include("lod/cl_minimap_reliability.lua")
include("lod/cl_minimap_logical_cell.lua")
include("lod/cl_minimap_player_contrast.lua")
include("lod/cl_topology_sync_safety.lua")
include("lod/cl_soldier_shot_contract.lua")
include("lod/cl_player_weapon_specials.lua")
include("lod/cl_magnum_aim_state.lua")
include("lod/cl_watcher.lua")
include("lod/cl_watcher_polish.lua")
include("lod/cl_hostile_presentation_safety.lua")
include("lod/cl_seeker.lua")
include("lod/cl_magic.lua")
include("lod/cl_pushback_fx.lua")
include("lod/cl_character_sheet.lua")

-- The sheet's identity column is intentionally narrow at Steam Deck scale. Give
-- only the hero name another 32 px (roughly 3-4 condensed characters) by borrowing
-- the otherwise-empty inter-column gutter, without shrinking the feat/class cards.
do
    local sheet = LOD.CharacterSheet
    local baseOpen = sheet and sheet.Open
    if sheet and baseOpen and not sheet.LODNameWidthQOLInstalled then
        sheet.LODNameWidthQOLInstalled = true

        local function widenName(panel, expectedName)
            if not IsValid(panel) then return false end
            for _, child in ipairs(panel:GetChildren()) do
                if child.GetText and child.GetFont
                    and child:GetText() == expectedName
                    and child:GetFont() == "LOD_SheetHeading"
                then
                    local x, y = child:GetPos()
                    if x == 164 then
                        child:SetPos(156, y)
                        child:SetWide(child:GetWide() + 32)
                    end
                    return true
                end
                if widenName(child, expectedName) then return true end
            end
            return false
        end

        function sheet:Open(requestFresh)
            baseOpen(self, requestFresh)
            local snapshot = self.Snapshot
            if snapshot and IsValid(self.Frame) then
                widenName(self.Frame, tostring(snapshot.fullDisplayName or ""))
            end
        end
    end
end

-- One staging interaction-prompt authority. Manual scrolling belongs exclusively to
-- lod_manual_reader_runtime.lua; portal geometry belongs to lod_staging_prop/shared.
surface.CreateFont("LOD_StagingBoundPrompt", {
    font = "DejaVu Sans",
    size = 38,
    weight = 1000,
    antialias = true
})

local function useBindingLabel()
    local binding = input.LookupBinding("+use")
    if not isstring(binding) or binding == "" then binding = "E" end
    binding = string.upper(binding)
    binding = string.gsub(binding, "MOUSE(%d+)", "MOUSE %1")
    binding = string.gsub(binding, "MWHEELUP", "MOUSE WHEEL UP")
    binding = string.gsub(binding, "MWHEELDOWN", "MOUSE WHEEL DOWN")
    return binding
end

local function aimedAtManual(ply)
    if not IsValid(ply) then return nil end
    local eye, forward = ply:EyePos(), ply:EyeAngles():Forward()
    local best, bestDot

    for _, ent in ipairs(ents.FindByClass("lod_field_manual")) do
        if IsValid(ent) then
            local delta = ent:WorldSpaceCenter() - eye
            local dist2 = delta:LengthSqr()
            if dist2 <= 260 * 260 and dist2 > 1 then
                delta:Normalize()
                local dot = forward:Dot(delta)
                if dot >= 0.94 and (not bestDot or dot > bestDot) then
                    best, bestDot = ent, dot
                end
            end
        end
    end
    return best
end

local function aimedAtPortal(ply)
    if not IsValid(ply) then return nil end
    local best, bestFraction
    for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
        if IsValid(ent) and ent.GetStageKind and ent:GetStageKind() == ent.KIND_PORTAL
            and ent.PortalAimFraction
        then
            local fraction = ent:PortalAimFraction(ply, ent.PORTAL_USE_DISTANCE or 340)
            if fraction and (not bestFraction or fraction < bestFraction) then
                best, bestFraction = ent, fraction
            end
        end
    end
    return best
end

hook.Add("HUDPaint", "LOD_StagingInteractionPrompt", function()
    local manual = LOD and LOD.FieldManual
    if manual and IsValid(manual.Frame) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return end

    local text
    local key = useBindingLabel()
    if IsValid(aimedAtManual(ply)) then
        text = string.format("Press \"%s\" to Read", key)
    elseif IsValid(aimedAtPortal(ply)) then
        text = string.format("Press \"%s\" to Enter the Labyrinth", key)
    end

    if text then
        draw.SimpleTextOutlined(text, "LOD_StagingBoundPrompt",
            ScrW() * 0.5, ScrH() * 0.64,
            Color(250, 250, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            4, Color(0, 0, 0, 245))
    end
end)
