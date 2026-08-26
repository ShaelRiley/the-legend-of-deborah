net.Receive("LOD_HostileDamageAuditProbe", function()
    local serial = net.ReadUInt(32)
    local attackerIndex = net.ReadUInt(16)
    local serverDistance = net.ReadFloat()

    local attacker = Entity(attackerIndex)
    local valid = IsValid(attacker)
    local dormant = valid and attacker:IsDormant() or false
    local noDraw = valid and attacker:GetNoDraw() or false
    local color = valid and attacker:GetColor() or color_white
    local distance = valid and IsValid(LocalPlayer())
        and attacker:GetPos():Distance(LocalPlayer():GetPos()) or -1
    local model = valid and (attacker:GetModel() or "none") or "none"

    net.Start("LOD_HostileDamageAuditReply")
    net.WriteUInt(serial, 32)
    net.WriteBool(valid)
    net.WriteBool(dormant)
    net.WriteBool(noDraw)
    net.WriteUInt(math.Clamp(color and color.a or 255, 0, 255), 8)
    net.WriteFloat(distance)
    net.WriteFloat(serverDistance)
    net.WriteString(model)
    net.SendToServer()
end)