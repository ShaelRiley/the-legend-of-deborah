LOD = LOD or {}
LOD.RPGWisInformation = LOD.RPGWisInformation or {}
local Information = LOD.RPGWisInformation
local NET_OMNISCIENCE = "LOD_RPGWisOmniscience"

Information.Omniscience = Information.Omniscience or nil

net.Receive(NET_OMNISCIENCE, function()
    local target = net.ReadEntity()
    if not IsValid(target) then
        Information.Omniscience = nil
        return
    end
    Information.Omniscience = {
        target = target,
        type = net.ReadString(),
        level = net.ReadUInt(8),
        class = net.ReadString(),
        hp = net.ReadInt(16),
        maxHP = net.ReadUInt(16)
    }
end)

local function hostileIdentityAnchor(ent)
    local authority = LOD.HostileIdentityPresentation
    if authority and authority.AnchorFor then
        local x, y = authority:AnchorFor(ent)
        if x and y then return x, y end
    end
    local top = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z + 18)):ToScreen()
    return top.x, top.y
end

hook.Add("HUDPaint", "LOD_RPGWisOmniscience", function()
    local data = Information.Omniscience
    local ply = LocalPlayer()
    if not IsValid(ply) or not data or not IsValid(data.target) then return end
    local trace = ply:GetEyeTrace()
    if not trace or trace.Entity ~= data.target then return end

    local x, y = hostileIdentityAnchor(data.target)
    draw.SimpleText(tostring(data.type), "DermaDefaultBold", x, y,
        color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(string.format("LEVEL %d / CLASS %s", data.level or 1, tostring(data.class or "Hostile")),
        "DermaDefault", x, y + 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("HP %d/%d", data.hp or 0, data.maxHP or 0),
        "DermaDefault", x, y + 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
