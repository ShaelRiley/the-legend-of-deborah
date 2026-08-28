include("shared.lua")

local portalGlow = Material("sprites/light_glow02_add")
local flameGlow = Material("sprites/light_glow02_add")
local KIND_GUIDE = 1
local KIND_PORTAL = 2
local KIND_WEAPON = 3
local KIND_SIGN = 4
local KIND_TORCH = 5
local KIND_PEDESTAL = 6
local CELEBRATION_DURATION = 1.45

surface.CreateFont("LOD_StagingLabel", {
    font = "DejaVu Sans",
    size = 32,
    weight = 800,
    antialias = true
})

surface.CreateFont("LOD_StagingWallQuote", {
    font = "DejaVu Sans",
    size = 48,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_StagingPortalPrompt", {
    font = "DejaVu Sans",
    size = 38,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_StagingCelebration", {
    font = "DejaVu Sans",
    size = 34,
    weight = 1000,
    antialias = true
})

local function facing3D2DAngle(pos)
    local ang = (EyePos() - pos):Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    return ang
end

local function boneAngle(ent, name, ang)
    local bone = ent:LookupBone(name)
    if bone then ent:ManipulateBoneAngles(bone, ang) end
end

local function applyGuidePose(ent)
    if ent.LODClientGuidePoseApplied then return end
    ent.LODClientGuidePoseApplied = true

    ent:ResetSequence(0)
    ent:SetCycle(0)
    ent:SetPlaybackRate(0)

    boneAngle(ent, "ValveBiped.Bip01_L_Thigh", Angle(0, 0, 18))
    boneAngle(ent, "ValveBiped.Bip01_R_Thigh", Angle(0, 0, -18))
    boneAngle(ent, "ValveBiped.Bip01_L_Calf", Angle(0, 0, -7))
    boneAngle(ent, "ValveBiped.Bip01_R_Calf", Angle(0, 0, 7))

    boneAngle(ent, "ValveBiped.Bip01_L_UpperArm", Angle(-8, -28, -58))
    boneAngle(ent, "ValveBiped.Bip01_L_Forearm", Angle(2, -70, -12))
    boneAngle(ent, "ValveBiped.Bip01_L_Hand", Angle(0, 0, 28))

    boneAngle(ent, "ValveBiped.Bip01_R_UpperArm", Angle(-12, 22, 52))
    boneAngle(ent, "ValveBiped.Bip01_R_Forearm", Angle(0, 58, 18))
    boneAngle(ent, "ValveBiped.Bip01_R_Hand", Angle(-8, 0, -28))

    for _, name in ipairs({
        "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11",
        "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21",
        "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31",
        "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41"
    }) do
        boneAngle(ent, name, Angle(0, 0, 58))
    end
    boneAngle(ent, "ValveBiped.Bip01_R_Finger0", Angle(0, -42, -28))
    boneAngle(ent, "ValveBiped.Bip01_R_Finger01", Angle(0, -18, -8))

    if ent.SetFlexScale then ent:SetFlexScale(1) end
    if ent.GetFlexNum and ent.GetFlexName and ent.SetFlexWeight then
        for flex = 0, ent:GetFlexNum() - 1 do
            local name = string.lower(ent:GetFlexName(flex) or "")
            if string.find(name, "smile", 1, true) or string.find(name, "happy", 1, true)
                or string.find(name, "grin", 1, true)
            then
                ent:SetFlexWeight(flex, 1)
            elseif string.find(name, "jaw", 1, true)
                and (string.find(name, "drop", 1, true) or string.find(name, "open", 1, true))
            then
                ent:SetFlexWeight(flex, 0.24)
            elseif string.find(name, "cheek", 1, true) and string.find(name, "raise", 1, true) then
                ent:SetFlexWeight(flex, 0.55)
            end
        end
    end
end

local function labelColor(kind)
    if kind == KIND_PORTAL then return Color(110, 165, 255) end
    if kind == KIND_WEAPON then return Color(248, 213, 105) end
    return Color(235, 110, 105)
end

local function drawLabel(ent)
    local kind = ent:GetStageKind()
    local pos = ent:WorldSpaceCenter() + Vector(0, 0, kind == KIND_GUIDE and 54 or 34)
    local ang = facing3D2DAngle(pos)

    cam.Start3D2D(pos, ang, 0.055)
        local label = ent:GetStageLabel()
        draw.SimpleTextOutlined(label ~= "" and label or "THE LEGEND OF DEBORAH",
            "LOD_StagingLabel", 0, 0, labelColor(kind), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            2, Color(0, 0, 0, 230))
    cam.End3D2D()
end

local function drawWallQuote(ent)
    local pos = ent:GetPos()
    local ang = facing3D2DAngle(pos)
    local lines = string.Explode("\\n", ent:GetStageLabel() or "")

    cam.Start3D2D(pos, ang, 0.082)
        for index, line in ipairs(lines) do
            draw.SimpleTextOutlined(line,
                "LOD_StagingWallQuote", 0, (index - 1) * 50,
                Color(248, 248, 244), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                4, Color(0, 0, 0, 250))
        end
    cam.End3D2D()
end

local function drawTorch(ent)
    local time = CurTime()
    local pos = ent:GetPos() + Vector(0, 0, 22)
    local flicker = math.sin(time * 17 + ent:EntIndex()) * 2.5
    local shimmer = math.sin(time * 23 + ent:EntIndex() * 0.7) * 1.5

    render.SetMaterial(flameGlow)
    render.DrawSprite(pos, 30 + flicker, 38 + flicker, Color(255, 72, 18, 215))
    render.DrawSprite(pos + Vector(0, 0, 7), 18 + shimmer, 28 + shimmer, Color(255, 198, 54, 245))
    render.DrawSprite(pos + Vector(0, 0, 12), 9, 18, Color(255, 245, 178, 255))

    local light = DynamicLight(ent:EntIndex())
    if light then
        light.pos = pos
        light.r = 255
        light.g = 92
        light.b = 28
        light.brightness = 1.6 + math.sin(time * 19 + ent:EntIndex()) * 0.18
        light.decay = 420
        light.size = 125
        light.dietime = time + 0.12
    end
end

local function drawPortalGlow(ent)
    local pos = ent:GetPos() + Vector(0, 0, 30)
    render.SetMaterial(portalGlow)
    render.DrawSprite(pos, 86, 86, Color(92, 148, 255, 190))
end

local function drawStarterPedestal(ent)
    local pos, ang = ent:GetPos(), ent:GetAngles()
    render.SetColorMaterial()
    render.DrawBox(pos, ang, Vector(-16, -16, 0), Vector(16, 16, 10), Color(66, 48, 40))
    render.DrawBox(pos + Vector(0, 0, 10), ang, Vector(-20, -20, 0), Vector(20, 20, 3), Color(128, 85, 55))
    render.DrawBox(pos + Vector(0, 0, 13), ang, Vector(-18, -18, 0), Vector(18, 18, 1.5), Color(196, 151, 74))
end

function ENT:Draw()
    local kind = self:GetStageKind()

    if kind == KIND_SIGN then
        drawWallQuote(self)
        return
    end

    if kind == KIND_PEDESTAL then
        drawStarterPedestal(self)
        return
    end

    if kind == KIND_GUIDE then applyGuidePose(self) end

    self:DrawModel()
    if kind == KIND_TORCH then
        drawTorch(self)
        return
    end

    if kind == KIND_PORTAL then drawPortalGlow(self) end
    drawLabel(self)
end

function ENT:DrawTranslucent()
    self:Draw()
end

local celebration = nil
local celebrationSerial = 0

local function clearCelebration()
    if celebration and IsValid(celebration.weaponModel) then celebration.weaponModel:Remove() end
    celebration = nil
end

local function playFanfare(serial)
    local notes = {
        {delay = 0.00, pitch = 96},
        {delay = 0.12, pitch = 118},
        {delay = 0.24, pitch = 142},
        {delay = 0.39, pitch = 170}
    }

    for _, note in ipairs(notes) do
        timer.Simple(note.delay, function()
            if not celebration or celebration.serial ~= serial then return end
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            sound.Play("buttons/button17.wav", ply:EyePos(), 66, note.pitch, 0.62)
        end)
    end
end

local function beginCelebration(weaponClass, weaponLabel, modelPath)
    clearCelebration()
    celebrationSerial = celebrationSerial + 1

    local weaponModel = nil
    if modelPath ~= "" and util.IsValidModel(modelPath) then
        weaponModel = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)
        if IsValid(weaponModel) then
            weaponModel:SetNoDraw(true)
            weaponModel:SetModelScale(1.05, 0)
        end
    end

    celebration = {
        serial = celebrationSerial,
        started = CurTime(),
        finishes = CurTime() + CELEBRATION_DURATION,
        weaponClass = weaponClass,
        weaponLabel = weaponLabel ~= "" and weaponLabel or "STARTER WEAPON",
        weaponModel = weaponModel
    }

    playFanfare(celebrationSerial)
end

net.Receive("LOD_StagingStarterCelebration", function()
    beginCelebration(net.ReadString(), net.ReadString(), net.ReadString())
end)

hook.Add("Think", "LOD_StagingCelebrationLifetime", function()
    if celebration and CurTime() >= celebration.finishes then clearCelebration() end
end)

hook.Add("ShutDown", "LOD_StagingCelebrationCleanup", clearCelebration)

hook.Add("CalcView", "LOD_StagingStarterCelebrationView", function(ply, origin, angles, fov)
    if not celebration or CurTime() >= celebration.finishes or not IsValid(ply) or not ply:Alive() then return end

    local target = ply:GetPos() + Vector(0, 0, 56)
    local desired = target - angles:Forward() * 92 + angles:Right() * 38 + Vector(0, 0, 30)
    local trace = util.TraceHull({
        start = target,
        endpos = desired,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SOLID_BRUSHONLY,
        filter = ply
    })
    local cameraPos = trace.HitPos + trace.HitNormal * 3

    return {
        origin = cameraPos,
        angles = (target - cameraPos):Angle(),
        fov = math.min(fov, 74),
        drawviewer = true
    }
end)

hook.Add("ShouldDrawLocalPlayer", "LOD_StagingStarterCelebrationPlayer", function()
    if celebration and CurTime() < celebration.finishes then return true end
end)

hook.Add("PreDrawViewModel", "LOD_StagingStarterCelebrationHideViewModel", function()
    if celebration and CurTime() < celebration.finishes then return true end
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_StagingStarterCelebrationWeapon", function(drawingDepth, drawingSkybox)
    if drawingDepth or drawingSkybox or not celebration or CurTime() >= celebration.finishes then return end
    local ply = LocalPlayer()
    local weaponModel = celebration.weaponModel
    if not IsValid(ply) or not IsValid(weaponModel) then return end

    local elapsed = CurTime() - celebration.started
    local rise = math.sin(math.Clamp(elapsed / CELEBRATION_DURATION, 0, 1) * math.pi) * 7
    weaponModel:SetPos(ply:GetPos() + Vector(0, 0, 94 + rise))
    weaponModel:SetAngles(Angle(0, (CurTime() * 105) % 360, -7))
    weaponModel:SetupBones()
    weaponModel:DrawModel()
end)

hook.Add("HUDPaint", "LOD_StagingPortalAndCelebrationHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if celebration and CurTime() < celebration.finishes then
        local remaining = math.Clamp((celebration.finishes - CurTime()) / CELEBRATION_DURATION, 0, 1)
        local alpha = math.floor(255 * math.min(1, remaining * 2.5))
        draw.SimpleTextOutlined(
            "STARTER ACQUIRED — " .. celebration.weaponLabel,
            "LOD_StagingCelebration", ScrW() * 0.5, ScrH() * 0.22,
            Color(248, 226, 124, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            3, Color(0, 0, 0, alpha))
        return
    end

    if not ply:GetNW2Bool("LOD_Staged", false) then return end
    local trace = ply:GetEyeTrace()
    local ent = trace and trace.Entity
    if not IsValid(ent) or ent:GetClass() ~= "lod_staging_prop" or ent:GetStageKind() ~= KIND_PORTAL then return end
    if ply:EyePos():DistToSqr(ent:WorldSpaceCenter()) > (260 * 260) then return end

    draw.SimpleTextOutlined(
        "Press \"E\" to Enter the Labyrinth",
        "LOD_StagingPortalPrompt", ScrW() * 0.5, ScrH() * 0.63,
        Color(250, 250, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
        4, Color(0, 0, 0, 245))
end)
