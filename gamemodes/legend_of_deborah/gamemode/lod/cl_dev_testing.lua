LOD = LOD or {}

local fWasDown = false

local function canFastForwardRespawn(ply)
    if not IsValid(ply) then return false end
    if not ply:GetNW2Bool("LOD_DeveloperMode", false) then return false end
    if not ply:GetNW2Bool("LOD_PlayedIdentity", false) then return false end
    if ply:Alive() or ply:GetNW2Bool("LOD_Eliminated", false) then return false end
    if ply:GetNW2Bool("LOD_RespawnFastUsed", false) then return false end
    return ply:GetNW2Float("LOD_RespawnRemaining", 0) > 0
end

hook.Add("Think", "LOD_DeveloperRespawnFastInput", function()
    local down = input.IsKeyDown(KEY_F)
    if down and not fWasDown then
        local ply = LocalPlayer()
        if canFastForwardRespawn(ply) then
            RunConsoleCommand("lod_dev_respawn_fast")
        end
    end
    fWasDown = down
end)

hook.Add("HUDPaint", "LOD_DeveloperRespawnFastHint", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_DeveloperMode", false) then return end
    if not ply:GetNW2Bool("LOD_PlayedIdentity", false) or ply:Alive() or ply:GetNW2Bool("LOD_Eliminated", false) then return end
    if ply:GetNW2Float("LOD_RespawnRemaining", 0) <= 0 then return end

    local used = ply:GetNW2Bool("LOD_RespawnFastUsed", false)
    local text = used and "10x TEST SPEED ACTIVE" or "F  —  10x RESPAWN TEST SPEED"
    local font = "LOD_HUD_Small"
    local color = used and Color(160, 205, 160) or Color(190, 190, 190)
    draw.SimpleText(text, font, ScrW() * 0.5, ScrH() * 0.68, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
