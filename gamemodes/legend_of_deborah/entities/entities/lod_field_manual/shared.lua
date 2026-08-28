ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "The Legend of Deborah Instruction Manual"
ENT.Spawnable = false
ENT.AdminOnly = false

if CLIENT then
    local PANEL_MATERIAL = Material("models/props_c17/FurnitureWood001a")
    local PANEL_COLOR = Color(198, 168, 120, 255)
    local PANEL_EDGE = Color(69, 51, 35, 245)
    local PANEL_SHADOW = Color(15, 12, 10, 235)
    local STENCIL_COLOR = Color(250, 250, 246, 255)
    local SURFACE_OFFSET = 2.5
    local WALL_TRACE = 140
    local SIGN_KIND = 4

    surface.CreateFont("LOD_HutDINStencil", {
        font = "Roboto Condensed",
        size = 82,
        weight = 900,
        antialias = true,
        extended = false
    })

    local STENCIL_BRIDGE_CHARS = {
        A = true, B = true, D = true, O = true, P = true, R = true,
        ["0"] = true, ["6"] = true, ["8"] = true, ["9"] = true
    }

    local function drawBoard(width, height)
        local border = 11
        surface.SetDrawColor(PANEL_SHADOW)
        surface.DrawRect(-width * 0.5 - border, -height * 0.5 - border,
            width + border * 2, height + border * 2)

        if PANEL_MATERIAL and not PANEL_MATERIAL:IsError() then
            surface.SetMaterial(PANEL_MATERIAL)
            surface.SetDrawColor(PANEL_COLOR)
            surface.DrawTexturedRect(-width * 0.5, -height * 0.5, width, height)
        else
            surface.SetDrawColor(PANEL_COLOR)
            surface.DrawRect(-width * 0.5, -height * 0.5, width, height)
        end

        surface.SetDrawColor(PANEL_EDGE)
        surface.DrawRect(-width * 0.5, -height * 0.5, width, 5)
        surface.DrawRect(-width * 0.5, height * 0.5 - 5, width, 5)
        surface.DrawRect(-width * 0.5, -height * 0.5, 5, height)
        surface.DrawRect(width * 0.5 - 5, -height * 0.5, 5, height)

        local bolt = 11
        local inset = 22
        for _, x in ipairs({-width * 0.5 + inset, width * 0.5 - inset - bolt}) do
            for _, y in ipairs({-height * 0.5 + inset, height * 0.5 - inset - bolt}) do
                surface.DrawRect(x, y, bolt, bolt)
            end
        end
    end

    local function drawStencil(text, y)
        text = tostring(text or "")
        surface.SetFont("LOD_HutDINStencil")
        local totalW, totalH = surface.GetTextSize(text)

        draw.SimpleText(text, "LOD_HutDINStencil", 5, y + 6,
            Color(18, 18, 17, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "LOD_HutDINStencil", 0, y,
            STENCIL_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local charW = totalW / math.max(1, #text)
        for index = 1, #text do
            local ch = string.upper(string.sub(text, index, index))
            if STENCIL_BRIDGE_CHARS[ch] then
                local cx = -totalW * 0.5 + (index - 0.5) * charW
                local bridgeW = math.max(6, math.floor(charW * 0.08))
                local bridgeH = math.max(15, math.floor(totalH * 0.15))
                surface.SetDrawColor(PANEL_COLOR)
                surface.DrawRect(cx - bridgeW * 0.5, y - bridgeH * 0.18, bridgeW, bridgeH)
            end
        end
    end

    local function wallAnchor(ent, up)
        if not IsValid(ent) then return nil end
        local normal = ent:GetForward():GetNormalized()
        local origin = ent:GetPos() + Vector(0, 0, up or 0)
        local tr = util.TraceLine({
            start = origin + normal * 12,
            endpos = origin - normal * WALL_TRACE,
            mask = MASK_SOLID_BRUSHONLY
        })
        local pos = tr.Hit and (tr.HitPos + normal * SURFACE_OFFSET) or origin
        return pos, normal
    end

    -- Exact wall-panel orientation copied from the proven maze quadrant marking
    -- renderer. The entity's local +X/Forward direction is the room-facing surface
    -- normal, just as the container's broad side normal is used by that routine.
    local function panelAngle(ent, pos)
        local ang = ent:GetAngles()
        ang = Angle(ang.p, ang.y, ang.r)
        local side = ent:GetForward():Dot(EyePos() - pos) >= 0 and 1 or -1
        ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
        ang:RotateAroundAxis(ang:Up(), 90)
        if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end
        return ang
    end

    local function drawZeldaPanel(ent)
        local pos = wallAnchor(ent, 0)
        if not pos then return end
        cam.Start3D2D(pos, panelAngle(ent, pos), 0.12)
            drawBoard(930, 280)
            drawStencil("IT'S DANGEROUS TO GO", -46)
            drawStencil("ALONE! TAKE THIS.", 46)
        cam.End3D2D()
    end

    local function drawManualPanel(ent)
        local pos = wallAnchor(ent, 108)
        if not pos then return end
        cam.Start3D2D(pos, panelAngle(ent, pos), 0.12)
            drawBoard(850, 170)
            drawStencil("INSTRUCTION MANUAL", 0)
        cam.End3D2D()
    end

    hook.Add("PostDrawOpaqueRenderables", "LOD_StagingQuadrantStyleWallPanels", function(depth, sky)
        if depth or sky then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return end

        for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
            if IsValid(ent) and ent.GetStageKind and ent:GetStageKind() == SIGN_KIND then
                drawZeldaPanel(ent)
            end
        end

        for _, ent in ipairs(ents.FindByClass("lod_field_manual")) do
            if IsValid(ent) then drawManualPanel(ent) end
        end
    end)
end
