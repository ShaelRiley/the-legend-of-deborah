LOD = LOD or {}

net.Receive("LOD_MeleeContactAuditProbe", function()
    local serial = net.ReadUInt(32)
    local attacker = net.ReadEntity()
    net.ReadString() -- archetype is preserved server-side; client only reports presentation state.
    net.ReadFloat()  -- authoritative server distance, likewise preserved server-side.

    local valid = IsValid(attacker)
    local dormant = valid and attacker:IsDormant() or false
    local noDraw = valid and attacker:GetNoDraw() or false
    local color = valid and attacker:GetColor() or nil
    local alpha = color and color.a or 0
    local ply = LocalPlayer()
    local distance = valid and IsValid(ply) and attacker:GetPos():Distance(ply:GetPos()) or -1

    net.Start("LOD_MeleeContactAuditReply")
    net.WriteUInt(serial, 32)
    net.WriteBool(valid)
    net.WriteBool(dormant)
    net.WriteBool(noDraw)
    net.WriteUInt(math.Clamp(alpha, 0, 255), 8)
    net.WriteFloat(distance)
    net.SendToServer()
end)
