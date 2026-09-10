LOD = LOD or {}

local glowTexture = "sprites/light_glow02_add"
local lockColor = Color(255, 205, 72, 230)
local LOCK_SOUND = "buttons/button14.wav"

local AIMABLE_CLASSES = {
    weapon_lod_crowbar = true,
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_ar2 = true,
    weapon_frag = true
}

local function activeVisualWeapon(ply)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not AIMABLE_CLASSES[weapon:GetClass()] then return nil end
    return weapon
end

local function attachmentPos(ent, index)
    if not IsValid(ent) then return nil end
    local data = ent:GetAttachment(index or 1)
    return data and data.Pos or nil
end

local function muzzlePos(ply, weapon)
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then
        local vm = ply:GetViewModel()
        local pos = attachmentPos(vm, 1)
        if pos then return pos end
    end
    return attachmentPos(weapon, 1) or ply:GetShootPos()
end

local function emitLockBurst(ply, weapon)
    local pos = muzzlePos(ply, weapon)
    if not pos then return end

    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    local forward = ply:GetAimVector():GetNormalized()
    local right = forward:Cross(Vector(0, 0, 1))
    if right:LengthSqr() < 0.01 then right = Vector(1, 0, 0) end
    right:Normalize()
    local up = right:Cross(forward):GetNormalized()

    for i = 1, 12 do
        local theta = (i / 12) * math.pi * 2
        local radial = right * math.cos(theta) + up * math.sin(theta)
        local particle = emitter:Add(glowTexture, pos + radial * 2)
        if particle then
            particle:SetVelocity(radial * 24 + forward * 7)
            particle:SetDieTime(0.32)
            particle:SetStartAlpha(220)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3.2)
            particle:SetEndSize(0.6)
            particle:SetColor(lockColor.r, lockColor.g, lockColor.b)
            particle:SetAirResistance(12)
        end
    end

    emitter:Finish()
end

net.Receive("LOD_MagnumAimLocked", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local weapon = activeVisualWeapon(ply)
    if not IsValid(weapon) then return end

    emitLockBurst(ply, weapon)
    surface.PlaySound(LOCK_SOUND)
end)

hook.Add("HUDPaint", "LOD_MagnumAimState_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive()
        or not ply:GetNW2Bool("LOD_UniversalAimState", false)
    then
        return
    end

    local weapon = activeVisualWeapon(ply)
    if not IsValid(weapon) then return end

    local x, y = ScrW() * 0.5, ScrH() * 0.5
    local pulse = 0.75 + 0.25 * math.sin(CurTime() * 8)
    surface.SetDrawColor(lockColor.r, lockColor.g, lockColor.b,
        math.floor(lockColor.a * pulse))

    local inner = 11
    local outer = 17
    surface.DrawLine(x - outer, y - outer, x - inner, y - outer)
    surface.DrawLine(x - outer, y - outer, x - outer, y - inner)
    surface.DrawLine(x + inner, y - outer, x + outer, y - outer)
    surface.DrawLine(x + outer, y - outer, x + outer, y - inner)
    surface.DrawLine(x - outer, y + outer, x - inner, y + outer)
    surface.DrawLine(x - outer, y + inner, x - outer, y + outer)
    surface.DrawLine(x + inner, y + outer, x + outer, y + outer)
    surface.DrawLine(x + outer, y + inner, x + outer, y + outer)

    local multiplier = math.max(1,
        math.floor(ply:GetNW2Float("LOD_UniversalAimMultiplier", 1) + 0.5))
    draw.SimpleText("AIM x" .. tostring(multiplier), "DermaDefaultBold", x, y + 25,
        Color(lockColor.r, lockColor.g, lockColor.b, math.floor(240 * pulse)),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
