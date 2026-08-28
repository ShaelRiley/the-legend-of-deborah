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

    surface.CreateFont("LOD_StagingInteractionPrompt", {
        font = "DejaVu Sans",
        size = 38,
        weight = 1000,
        antialias = true,
        extended = true
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

        local bolt, inset = 11, 22
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
        return tr.Hit and (tr.HitPos + normal * SURFACE_OFFSET) or origin
    end

    -- Sign/manual entities are authored with Forward pointing into the room.
    -- Use that orientation directly. This is deliberately camera-independent so
    -- plaques cannot rotate, flip, or visibly move as the player's view changes.
    local function panelAngle(ent)
        local ang = Angle(ent:GetAngles().p, ent:GetAngles().y, ent:GetAngles().r)
        ang:RotateAroundAxis(ang:Right(), -90)
        ang:RotateAroundAxis(ang:Up(), 90)
        return ang
    end

    hook.Add("PostDrawOpaqueRenderables", "LOD_StagingQuadrantStyleWallPanels", function(depth, sky)
        if depth or sky then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return end

        for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
            if IsValid(ent) and ent.GetStageKind and ent:GetStageKind() == SIGN_KIND then
                local pos = wallAnchor(ent, 35)
                if pos then
                    cam.Start3D2D(pos, panelAngle(ent), 0.13)
                        drawBoard(1000, 300)
                        drawStencil("IT'S DANGEROUS TO GO", -50)
                        drawStencil("ALONE! TAKE THIS.", 50)
                    cam.End3D2D()
                end
            end
        end

        for _, ent in ipairs(ents.FindByClass("lod_field_manual")) do
            if IsValid(ent) then
                local pos = wallAnchor(ent, 108)
                if pos then
                    cam.Start3D2D(pos, panelAngle(ent), 0.12)
                        drawBoard(850, 170)
                        drawStencil("INSTRUCTION MANUAL", 0)
                    cam.End3D2D()
                end
            end
        end
    end)

    local BINDING_ALIASES = {
        MOUSE1 = "MOUSE 1",
        MOUSE2 = "MOUSE 2",
        MOUSE3 = "MOUSE 3",
        MWHEELUP = "MOUSE WHEEL UP",
        MWHEELDOWN = "MOUSE WHEEL DOWN"
    }

    local function useBindingLabel()
        local binding = input.LookupBinding and input.LookupBinding("+use", true) or nil
        if not binding or binding == "" then
            binding = input.LookupBinding and input.LookupBinding("+use") or nil
        end
        binding = string.upper(string.Trim(tostring(binding or "E")))
        if binding == "" then binding = "E" end
        return BINDING_ALIASES[binding] or binding
    end

    LOD = LOD or {}
    LOD.StagingUseBindingLabel = useBindingLabel

    local function aimedAtManual(ply, maxDist, minDot)
        local eye = ply:EyePos()
        local forward = ply:EyeAngles():Forward()
        local best, bestDot
        for _, ent in ipairs(ents.FindByClass("lod_field_manual")) do
            if IsValid(ent) then
                local delta = ent:WorldSpaceCenter() - eye
                local dist2 = delta:LengthSqr()
                if dist2 <= maxDist * maxDist and dist2 > 1 then
                    delta:Normalize()
                    local dot = forward:Dot(delta)
                    if dot >= (minDot or 0.94) and (not bestDot or dot > bestDot) then
                        best, bestDot = ent, dot
                    end
                end
            end
        end
        return best
    end

    local function aimedAtPortal(ply)
        for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
            if IsValid(ent) and ent.GetStageKind and ent:GetStageKind() == (ent.KIND_PORTAL or 2)
                and ent.IsPortalAimHit and ent:IsPortalAimHit(ply, ent.PORTAL_USE_DISTANCE)
            then
                return ent
            end
        end
        return nil
    end

    hook.Add("HUDPaint", "LOD_FieldManualAndPortalPrompts", function()
        if LOD and LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return end

        local binding = useBindingLabel()
        if IsValid(aimedAtManual(ply, 260, 0.94)) then
            draw.SimpleTextOutlined(
                string.format("Press \"%s\" to Read", binding),
                "LOD_StagingInteractionPrompt", ScrW() * 0.5, ScrH() * 0.64,
                Color(250, 250, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                4, Color(0, 0, 0, 245))
            return
        end

        if IsValid(aimedAtPortal(ply)) then
            draw.SimpleTextOutlined(
                string.format("Press \"%s\" to Enter the Labyrinth", binding),
                "LOD_StagingInteractionPrompt", ScrW() * 0.5, ScrH() * 0.64,
                Color(250, 250, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                4, Color(0, 0, 0, 245))
        end
    end)
end
