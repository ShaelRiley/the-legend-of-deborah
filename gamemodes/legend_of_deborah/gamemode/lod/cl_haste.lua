-- Default H is event-driven; players may bind any key to lod_haste_toggle.
local function toggle()
    net.Start("LOD_HasteToggle")
    net.SendToServer()
end
concommand.Add("lod_haste_toggle", toggle)
hook.Add("PlayerButtonDown", "LOD_HasteDefaultH", function(ply, button)
    if ply == LocalPlayer() and button == KEY_H and not vgui.GetKeyboardFocus() then toggle() end
end)
