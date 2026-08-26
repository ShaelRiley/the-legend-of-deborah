LOD = LOD or {}
LOD.HostileDamageAudit = LOD.HostileDamageAudit or {
    Serial = 0,
    LastByPlayer = setmetatable({}, {__mode = "k"})
}

local Audit = LOD.HostileDamageAudit
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

util.AddNetworkString("LOD_HostileDamageAuditProbe")
util.AddNetworkString("LOD_HostileDamageAuditReply")

local function keyOf(cell)
    if not cell then return "none" end
    if cellKey then return cellKey(cell.x, cell.y, cell.z) end
    return string.format("%d:%d:%d", cell.x or -1, cell.y or -1, cell.z or -1)
end

local function graphCell(ent)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not Navigator or not IsValid(ent) then return nil end
    return Navigator:WorldToCell(graph, ent:GetPos())
end

local function hostileAttacker(dmginfo)
    if not dmginfo then return nil end
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker.LODHostile then return attacker end

    local inflictor = dmginfo:GetInflictor()
    if IsValid(inflictor) then
        local owner = inflictor:GetOwner()
        if IsValid(owner) and owner.LODHostile then return owner end
    end
    return nil
end

hook.Add("EntityTakeDamage", "LOD_AllHostileDamageVisibilityAudit", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return end
    local attacker = hostileAttacker(dmginfo)
    if not IsValid(attacker) then return end

    local attackerPos = attacker:GetPos()
    local targetPos = target:GetPos()
    local color = attacker:GetColor()
    local ac = graphCell(attacker)
    local tc = graphCell(target)
    local inflictor = dmginfo:GetInflictor()

    Audit.Serial = (Audit.Serial or 0) + 1
    local serial = Audit.Serial
    local record = {
        serial = serial,
        at = CurTime(),
        attackerIndex = attacker:EntIndex(),
        archetype = tostring(attacker.LODArchetypeId or attacker:GetNW2String("LOD_Archetype", "?")),
        distance = attackerPos:Distance(targetPos),
        horizontal = Vector(attackerPos.x, attackerPos.y, 0):Distance(Vector(targetPos.x, targetPos.y, 0)),
        zDelta = attackerPos.z - targetPos.z,
        attackerCell = keyOf(ac),
        targetCell = keyOf(tc),
        sameFloor = ac and tc and ac.z == tc.z or false,
        serverNoDraw = attacker:GetNoDraw() == true,
        serverAlpha = color and color.a or 255,
        model = attacker:GetModel() or "none",
        motion = tostring(attacker.LODMotionMode or "none"),
        damage = dmginfo:GetDamage(),
        damageType = dmginfo:GetDamageType(),
        inflictor = IsValid(inflictor) and inflictor:GetClass() or "none",
        client = nil
    }
    Audit.LastByPlayer[target] = record

    net.Start("LOD_HostileDamageAuditProbe")
    net.WriteUInt(serial, 32)
    net.WriteUInt(math.Clamp(attacker:EntIndex(), 0, 65535), 16)
    net.WriteFloat(record.distance)
    net.Send(target)
end)

net.Receive("LOD_HostileDamageAuditReply", function(_, ply)
    if not IsValid(ply) then return end
    local serial = net.ReadUInt(32)
    local record = Audit.LastByPlayer[ply]
    if not record or record.serial ~= serial then return end
    record.client = {
        valid = net.ReadBool(),
        dormant = net.ReadBool(),
        noDraw = net.ReadBool(),
        alpha = net.ReadUInt(8),
        distance = net.ReadFloat(),
        echoedServerDistance = net.ReadFloat(),
        model = net.ReadString()
    }
end)

local function boolText(v)
    if v == nil then return "unknown" end
    return v and "true" or "false"
end

concommand.Add("lod_last_hostile_damage", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local r = Audit.LastByPlayer[ply]
    if not r then
        local line = "none recorded this session"
        print("[LOD:HOSTILE-DAMAGE] " .. line)
        ply:ChatPrint(line)
        return
    end

    local c = r.client
    local line = string.format(
        "age=%.2fs attacker=#%d %s dist=%.1f horiz=%.1f zDelta=%.1f cells=%s->%s sameFloor=%s damage=%.1f inflictor=%s motion=%s serverNoDraw=%s serverAlpha=%d clientValid=%s clientDormant=%s clientNoDraw=%s clientAlpha=%s clientDist=%s clientModel=%s",
        math.max(0, CurTime() - (r.at or CurTime())),
        r.attackerIndex or -1, tostring(r.archetype), r.distance or -1,
        r.horizontal or -1, r.zDelta or 0,
        tostring(r.attackerCell), tostring(r.targetCell), boolText(r.sameFloor),
        r.damage or -1, tostring(r.inflictor), tostring(r.motion),
        boolText(r.serverNoDraw), r.serverAlpha or -1,
        c and boolText(c.valid) or "NO_REPLY",
        c and boolText(c.dormant) or "NO_REPLY",
        c and boolText(c.noDraw) or "NO_REPLY",
        c and tostring(c.alpha) or "NO_REPLY",
        c and string.format("%.1f", c.distance or -1) or "NO_REPLY",
        c and tostring(c.model) or "NO_REPLY")
    print("[LOD:HOSTILE-DAMAGE] " .. line)
    ply:ChatPrint(line)
end)