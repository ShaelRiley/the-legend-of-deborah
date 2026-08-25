LOD = LOD or {}

local aimMaterial = Material("cable/redlaser")
local glowMaterial = Material("sprites/light_glow02_add")
local smokeTexture = "particle/particle_smokegrenade"
local AR2_LASER_COLOR = Color(255, 80, 60, 225)
local AR2_LASER_WIDTH = 2.5
local SMG_MAX_HEAT = 6

local smoke = setmetatable({}, {__mode = "k"})
local tinted = setmetatable({}, {__mode = "k"})
local nextVisualTick = 0
local ar2AttackHeld = false
local ar2InputBlockUntil = 0

local function activeWeapon(ply)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon or nil
end

local function attachmentPos(ent, index)
    if not IsValid(ent) then return nil end
    local data = ent:GetAttachment(index or 1)
    return data and data.Pos or nil
end

local function weaponMuzzlePos(ply, weapon)
    local localPlayer = LocalPlayer()
    if ply == localPlayer and not ply:ShouldDrawLocalPlayer() then
        local vm = ply:GetViewModel()
        local pos = attachmentPos(vm, 1)
        if pos then return pos end
    end

    local pos = attachmentPos(weapon, 1)
    if pos then return pos end
    return ply:GetShootPos()
end

local function heatColor(heat)
    local fraction = math.Clamp((heat or 0) / SMG_MAX_HEAT, 0, 1)
    local channel = math.floor(255 * (1 - 0.78 * fraction))
    return Color(255, channel, channel, 255), fraction
end

local function restoreWorldTint(weapon)
    if not IsValid(weapon) then return end
    weapon:SetColor(Color(255, 255, 255, 255))
    weapon:SetRenderMode(RENDERMODE_NORMAL)
    tinted[weapon] = nil
end

local function updateWorldTint(weapon)
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_smg1" then return end
    local heat = weapon:GetNW2Float("LOD_SMGHeat", 0)
    if heat <= 0 then
        if tinted[weapon] then restoreWorldTint(weapon) end
        return
    end

    local color = heatColor(heat)
    weapon:SetRenderMode(RENDERMODE_TRANSCOLOR)
    weapon:SetColor(color)
    tinted[weapon] = true
end

local function stopSmoke(weapon)
    local state = smoke[weapon]
    if state and state.emitter then state.emitter:Finish() end
    smoke[weapon] = nil
end

local function emitSmoke(ply, weapon, now)
    if not IsValid(weapon) then return end
    if not weapon:GetNW2Bool("LOD_SMGOverheated", false) then
        stopSmoke(weapon)
        return
    end

    local pos = weaponMuzzlePos(ply, weapon)
    if not pos then return end

    local state = smoke[weapon]
    if not state then
        state = {emitter = ParticleEmitter(pos), nextAt = 0}
        smoke[weapon] = state
    end
    if not state.emitter or now < (state.nextAt or 0) then return end
    state.nextAt = now + 0.11

    local particle = state.emitter:Add(smokeTexture, pos)
    if not particle then return end
    particle:SetVelocity(Vector(math.Rand(-4, 4), math.Rand(-4, 4), math.Rand(14, 24)))
    particle:SetDieTime(0.75)
    particle:SetStartAlpha(115)
    particle:SetEndAlpha(0)
    particle:SetStartSize(3)
    particle:SetEndSize(13)
    particle:SetRoll(math.Rand(0, 360))
    particle:SetRollDelta(math.Rand(-0.6, 0.6))
    particle:SetColor(120, 120, 120)
    particle:SetAirResistance(18)
end

hook.Add("CreateMove", "LOD_PlayerWeaponSpecials_PredictedInput", function(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        ar2AttackHeld = false
        return
    end

    local weapon = activeWeapon(ply)
    local class = IsValid(weapon) and weapon:GetClass() or ""

    if class == "weapon_smg1" and weapon:GetNW2Bool("LOD_SMGOverheated", false) then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end

    if class == "weapon_ar2" then
        local down = cmd:KeyDown(IN_ATTACK)
        if down and not ar2AttackHeld then
            net.Start("LOD_PlayerAR2Activate")
            net.SendToServer()
            ar2InputBlockUntil = CurTime() + 0.85
        end
        ar2AttackHeld = down
        cmd:RemoveKey(IN_ATTACK)
        if CurTime() < ar2InputBlockUntil then cmd:RemoveKey(IN_RELOAD) end
    else
        ar2AttackHeld = false
    end
end)

hook.Add("PreDrawViewModel", "LOD_SMGHeat_ViewModel", function(vm, ply, weapon)
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_smg1" then return end
    local _, fraction = heatColor(weapon:GetNW2Float("LOD_SMGHeat", 0))
    if fraction <= 0 then return end
    render.SetColorModulation(1, 1 - 0.78 * fraction, 1 - 0.78 * fraction)
end)

hook.Add("PostDrawViewModel", "LOD_SMGHeat_ViewModelReset", function()
    render.SetColorModulation(1, 1, 1)
end)

hook.Add("Think", "LOD_PlayerWeaponSpecials_VisualState", function()
    local now = CurTime()
    if now < nextVisualTick then return end
    nextVisualTick = now + 0.05

    local seen = {}
    for _, ply in ipairs(player.GetAll()) do
        local weapon = activeWeapon(ply)
        if IsValid(weapon) and weapon:GetClass() == "weapon_smg1" then
            seen[weapon] = true
            updateWorldTint(weapon)
            emitSmoke(ply, weapon, now)
        end
    end

    for weapon in pairs(tinted) do
        if not seen[weapon] then restoreWorldTint(weapon) end
    end
    for weapon in pairs(smoke) do
        if not seen[weapon] then stopSmoke(weapon) end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_PlayerAR2TargetingLaser", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply:GetNW2Bool("LOD_PlayerAR2Telegraph", false) then
            local weapon = activeWeapon(ply)
            if IsValid(weapon) and weapon:GetClass() == "weapon_ar2" then
                local direction = ply:GetNW2Vector("LOD_PlayerAR2Direction", vector_origin)
                if direction ~= vector_origin then
                    direction = direction:GetNormalized()
                    local origin = weaponMuzzlePos(ply, weapon)
                    if origin then
                        local trace = util.TraceLine({
                            start = origin,
                            endpos = origin + direction * 1600,
                            mask = MASK_SHOT,
                            filter = {ply, weapon}
                        })
                        local endPos = trace.HitPos
                        render.SetMaterial(aimMaterial)
                        render.DrawBeam(origin, endPos, AR2_LASER_WIDTH, 0, 1, AR2_LASER_COLOR)
                        render.SetMaterial(glowMaterial)
                        render.DrawSprite(endPos, 5, 5, AR2_LASER_COLOR)
                    end
                end
            end
        end
    end
end)
