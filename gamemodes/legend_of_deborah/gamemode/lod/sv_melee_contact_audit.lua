LOD = LOD or {}
LOD.MeleeContactAudit = LOD.MeleeContactAudit or {
    Serial = 0,
    LastByPlayer = setmetatable({}, {__mode = "k"})
}

local Audit = LOD.MeleeContactAudit
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

util.AddNetworkString("LOD_MeleeContactAuditProbe")
util.AddNetworkString("LOD_MeleeContactAuditReply")

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

local function directOrdinaryMelee(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return nil end
    local attacker = dmginfo and dmginfo:GetAttacker() or nil
    local inflictor = dmginfo and dmginfo:GetInflictor() or nil
    if not IsValid(attacker) or not attacker.LODHostile then return nil end
    local archetype = attacker.LODArchetypeId
    if archetype ~= "runner" and archetype ~= "shambler" then return nil end
    -- Ordinary melee is authored with target:TakeDamage(..., self, self). This
    -- excludes later ranged/special archetypes and keeps the audit event-only.
    if IsValid(inflictor) and inflictor ~= attacker then return nil end
    return attacker, archetype
end

hook.Add("EntityTakeDamage", "LOD_MeleeContactForensicAudit", function(target, dmginfo)
    local attacker, archetype = directOrdinaryMelee(target, dmginfo)
    if not attacker then return end

    local attackerPos = attacker:GetPos()
    local targetPos = target:GetPos()
    local attackerCell = graphCell(attacker)
    local targetCell = graphCell(target)
    local cfg = attacker.LODConfig or {}

    local los = nil
    if attacker._HasLineOfSight then
        local ok, value = pcall(attacker._HasLineOfSight, attacker, target)
        if ok then los = value == true end
    end

    local color = attacker:GetColor()
    Audit.Serial = (Audit.Serial or 0) + 1
    local serial = Audit.Serial
    local record = {
        serial = serial,
        at = CurTime(),
        attackerIndex = attacker:EntIndex(),
        archetype = archetype,
        distance = attackerPos:Distance(targetPos),
        range = tonumber(cfg.meleeRange) or 0,
        los = los,
        attackerCell = keyOf(attackerCell),
        targetCell = keyOf(targetCell),
        sameFloor = attackerCell and targetCell and attackerCell.z == targetCell.z or false,
        noDraw = attacker:GetNoDraw() == true,
        alpha = color and color.a or 255,
        model = attacker:GetModel() or "none",
        motion = tostring(attacker.LODMotionMode or "none"),
        speed = attacker:GetVelocity():Length2D(),
        damageAtAudit = dmginfo:GetDamage(),
        client = nil
    }
    Audit.LastByPlayer[target] = record

    -- Ask only the player who was struck what their client knew about the exact
    -- attacker at that instant. This is one tiny message per accepted ordinary
    -- melee hit: there is no polling, PVS scan, or recurring diagnostic work.
    net.Start("LOD_MeleeContactAuditProbe")
    net.WriteUInt(serial, 32)
    net.WriteEntity(attacker)
    net.WriteString(archetype)
    net.WriteFloat(record.distance)
    net.Send(target)
end)

net.Receive("LOD_MeleeContactAuditReply", function(_, ply)
    if not IsValid(ply) then return end
    local serial = net.ReadUInt(32)
    local record = Audit.LastByPlayer[ply]
    if not record or record.serial ~= serial then return end
    record.client = {
        valid = net.ReadBool(),
        dormant = net.ReadBool(),
        noDraw = net.ReadBool(),
        alpha = net.ReadUInt(8),
        distance = net.ReadFloat()
    }
end)

local function boolText(value)
    if value == nil then return "unknown" end
    return value and "true" or "false"
end

concommand.Add("lod_last_melee_contact", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local r = Audit.LastByPlayer[ply]
    if not r then
        local line = "none recorded this session"
        print("[LOD:MELEE-CONTACT] " .. line)
        ply:ChatPrint(line)
        return
    end

    local c = r.client
    local line = string.format(
        "age=%.2fs attacker=#%d %s dist=%.1f range=%.1f LOS=%s cells=%s->%s sameFloor=%s serverNoDraw=%s serverAlpha=%d motion=%s speed=%.1f damage=%.1f clientValid=%s clientDormant=%s clientNoDraw=%s clientAlpha=%s clientDist=%s",
        math.max(0, CurTime() - (r.at or CurTime())), r.attackerIndex or -1,
        tostring(r.archetype), r.distance or -1, r.range or -1, boolText(r.los),
        tostring(r.attackerCell), tostring(r.targetCell), boolText(r.sameFloor),
        boolText(r.noDraw), r.alpha or -1, tostring(r.motion), r.speed or -1,
        r.damageAtAudit or -1,
        c and boolText(c.valid) or "NO_REPLY",
        c and boolText(c.dormant) or "NO_REPLY",
        c and boolText(c.noDraw) or "NO_REPLY",
        c and tostring(c.alpha) or "NO_REPLY",
        c and string.format("%.1f", c.distance or -1) or "NO_REPLY"
    )
    print("[LOD:MELEE-CONTACT] " .. line)
    ply:ChatPrint(line)
end)
