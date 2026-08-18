LOD = LOD or {}

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
    local attacker = dmginfo and dmginfo:GetAttacker() or nil
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    ent.LODLastPlayerDamage = dmginfo:GetDamage()
    local weapon = attacker:GetActiveWeapon()
    ent.LODLastPlayerWeapon = IsValid(weapon) and weapon:GetClass() or "unknown"
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
    if found == 0 then tell(ply, "no live hostile to report; spawn one, shoot it once, then rerun this command") end
end)
