-- Default H is event-driven; players may bind any key to lod_haste_toggle.
local nextToggle = 0
local function toggle()
    if not IsFirstTimePredicted() or RealTime() < nextToggle then return end
    nextToggle = RealTime() + 0.2
    net.Start("LOD_HasteToggle")
    net.SendToServer()
end
concommand.Add("lod_haste_toggle", toggle)
hook.Add("PlayerButtonDown", "LOD_HasteDefaultH", function(ply, button)
    if ply == LocalPlayer() and button == KEY_H and not vgui.GetKeyboardFocus() then toggle() end
end)

-- Mirror the server-resolved locomotion multiplier for client prediction.
-- No client ownership/cost decisions: the server still resolves every move.
hook.Add("SetupMove","LOD_PredictedVoluntarySpeed",function(ply,move)
    if ply~=LocalPlayer() or not ply:Alive() then return end
    local multiplier=ply:GetNW2Float("LOD_VoluntaryMovementMultiplier",1)
    move:SetForwardSpeed(move:GetForwardSpeed()*multiplier)
    move:SetSideSpeed(move:GetSideSpeed()*multiplier)
    move:SetMaxClientSpeed(move:GetMaxClientSpeed()*multiplier)
    move:SetMaxSpeed(move:GetMaxSpeed()*multiplier)
end)
