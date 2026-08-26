LOD = LOD or {}

local hWasDown = false

-- F previously accelerated the death timer in developer mode. That affordance is
-- retired: production death/Tetris interaction now owns F for every build.

hook.Add("Think", "LOD_DeveloperM3TestkitInput", function()
    local down = input.IsKeyDown(KEY_H)
    if not down then
        hWasDown = false
        return
    end
    if hWasDown then return end
    hWasDown = true

    -- Do not turn the letter H typed into a console/chat/UI field into a kit
    -- grant. The hotkey is only active during ordinary in-world input.
    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if not ply:GetNW2Bool("LOD_DeveloperMode", false) then return end
    RunConsoleCommand("lod_m3_testkit")
end)
