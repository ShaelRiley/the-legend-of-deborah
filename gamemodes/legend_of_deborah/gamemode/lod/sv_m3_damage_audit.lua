LOD = LOD or {}
LOD.M3DamageAudit = LOD.M3DamageAudit or {}

local Audit = LOD.M3DamageAudit
local eventCapture = CreateConVar(
    "lod_m3_damage_audit_enabled", "0", FCVAR_NONE,
    "Capture and print detailed per-hit Milestone 3 damage audit events"
)

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:M3-DMG] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

hook.Add("EntityTakeDamage", "LOD_M3_RecordHostileIncomingDamage", function(ent, dmginfo)
    if not IsValid(ent) or not ent.LODHostile then return end
    -- The audit is diagnostic instrumentation, not production combat logic.
    -- Keep all attacker/weapon lookup, table creation, formatting, and console
    -- output dormant unless a developer explicitly arms it for a focused test.
    if not eventCapture:GetBool() then return end

    local attacker = dmginfo and dmginfo:GetAttacker() or nil
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local weapon = attacker:GetActiveWeapon()
    local weaponClass = IsValid(weapon) and weapon:GetClass() or "unknown"
    local amount = dmginfo:GetDamage() or 0
    local damageType = dmginfo:GetDamageType() or 0

    ent.LODLastPlayerDamage = amount
    ent.LODLastPlayerWeapon = weaponClass

    -- Persist independently of the hostile entity so a lethal shot or the
    -- one-second death presentation cannot erase the evidence before audit.
    Audit.LastEvent = {
        time = CurTime(),
        entIndex = ent:EntIndex(),
        archetype = tostring(ent.LODArchetypeId or "unknown"),
        healthBefore = ent:Health(),
        maxHealth = ent:GetMaxHealth(),
        damage = amount,
        damageType = damageType,
        bulletBit = dmginfo:IsDamageType(DMG_BULLET),
        weapon = weaponClass,
        attacker = attacker:Nick()
    }

    print(string.format(
        "[LOD:M3-DMG-EVENT] #%d %s hpBefore=%d damage=%.2f weapon=%s type=%d bullet=%s",
        Audit.LastEvent.entIndex, Audit.LastEvent.archetype, Audit.LastEvent.healthBefore,
        Audit.LastEvent.damage, Audit.LastEvent.weapon, Audit.LastEvent.damageType,
        tostring(Audit.LastEvent.bulletBit)
    ))
end)

concommand.Add("lod_m3_damage_audit_status", function(ply)
    if not developerAllowed(ply) then return end

    local enabled = eventCapture:GetBool()
    local line = string.format(
        "enabled=%s lastEvent=%s productionFormatting=%s result=%s",
        tostring(enabled), Audit.LastEvent and "present" or "none",
        enabled and "ON" or "OFF", enabled and "ARMED" or "PASS"
    )
    print("[LOD:M3-DMG-STATUS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_m3_damage_audit", function(ply)
    if not developerAllowed(ply) then return end

    local pistolConVar = GetConVar("sk_plr_dmg_pistol")
    local pistolConVarValue = pistolConVar and pistolConVar:GetFloat() or nil
    tell(ply, "testkit weapon=weapon_pistol; sk_plr_dmg_pistol=" .. (pistolConVarValue ~= nil and tostring(pistolConVarValue) or "unavailable"))

    for _, id in ipairs({"shambler", "runner", "soldier", "deadcrab", "bioblaster"}) do
        local cfg = LOD.Config.Encounter.Archetypes[id]
        if cfg then
            local estimate = "n/a"
            if pistolConVarValue and pistolConVarValue > 0 then
                estimate = tostring(math.ceil(cfg.baseHP / pistolConVarValue))
            end
            tell(ply, string.format("%s baseHP=%d nominal body-shot estimate=%s (instances vary)", id, cfg.baseHP or -1, estimate))
        end
    end

    local last = Audit.LastEvent
    if last then
        tell(ply, string.format(
            "LAST EVENT #%d %s hpBefore=%d/%d damage=%.2f weapon=%s type=%d bullet=%s age=%.2fs attacker=%s",
            last.entIndex, last.archetype, last.healthBefore, last.maxHealth, last.damage,
            last.weapon, last.damageType, tostring(last.bulletBit),
            math.max(0, CurTime() - last.time), tostring(last.attacker)
        ))
    else
        tell(ply, "LAST EVENT none")
    end

    local found = 0
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) then
            found = found + 1
            tell(ply, string.format("live %s size=%.3f hp=%d/%d speed=%.1f lastPlayerDamage=%s weapon=%s",
                tostring(ent.LODArchetypeId), ent:GetNW2Float("LOD_SizeScale", 1),
                ent:Health(), ent:GetMaxHealth(), ent.LODConfig and ent.LODConfig.speed or 0,
                ent.LODLastPlayerDamage and string.format("%.2f", ent.LODLastPlayerDamage) or "none",
                tostring(ent.LODLastPlayerWeapon or "none")))
        end
    end
    if found == 0 then tell(ply, "no live hostile currently; LAST EVENT above remains available after death/removal") end
end)
