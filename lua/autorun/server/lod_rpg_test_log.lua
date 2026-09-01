if CLIENT then return end

LOD = LOD or {}
LOD.RPGTestLog = LOD.RPGTestLog or {}

local Log = LOD.RPGTestLog
local DATA_DIR = "legend_of_deborah"
local DATA_PATH = DATA_DIR .. "/rpg_test_log.txt"
local SCHEMA = "rpg-test-log-v1"

local function developerEnabled()
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() or false
end

local function safe(value)
    if value == nil then return "" end
    if isbool(value) then return value and "true" or "false" end
    local text = tostring(value)
    text = string.gsub(text, "[\r\n\t]", " ")
    return text
end

local function valueList(values)
    local out = {}
    for index, value in ipairs(values or {}) do
        out[index] = safe(value)
    end
    return table.concat(out, ",")
end

local function encodedFields(fields)
    local keys = {}
    for key in pairs(fields or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    local out = {}
    for _, key in ipairs(keys) do
        out[#out + 1] = key .. "=" .. safe(fields[key])
    end
    return table.concat(out, "\t")
end

local function entityLabel(ent)
    if not IsValid(ent) then return "invalid" end
    if ent:IsPlayer() then
        return string.format("player:%s#%d", safe(ent:Nick()), ent:EntIndex())
    end
    if ent.LODHostile then
        return string.format("hostile:%s#%d", safe(ent.LODArchetypeId or ent:GetClass()), ent:EntIndex())
    end
    return string.format("%s#%d", safe(ent:GetClass()), ent:EntIndex())
end

local function contractFormula(contract)
    if not contract then return "" end
    if contract.formula then return safe(contract.formula) end
    local profile = contract.profile or {}
    local count = math.max(1, math.floor(tonumber(profile.count) or 1))
    local sides = math.max(1, math.floor(tonumber(profile.sides) or 1))
    local text = string.format("%dd%d", count, sides)
    if profile.exploding then text = text .. "!" end
    local bonus = tonumber(profile.bonus) or 0
    if bonus > 0 then text = text .. "+" .. safe(bonus) end
    if bonus < 0 then text = text .. safe(bonus) end
    return text
end

local function addProfile(fields, prefix, actor)
    local rules = LOD.RPGAbilityRules
    if not rules or not IsValid(actor) then return end
    local state = rules.ProgressionState and rules:ProgressionState(actor) or nil
    local derived = state and state.derivedStats or (rules.Derived and rules:Derived(actor) or nil)
    if not derived then return end
    fields[prefix .. "class"] = state and state.classId or ""
    fields[prefix .. "level"] = state and state.level or ""
    fields[prefix .. "strx"] = derived.physicalDamageMultiplier
    fields[prefix .. "aimx"] = derived.aimSpreadMultiplier
    fields[prefix .. "movex"] = derived.movementSpeedMultiplier
    fields[prefix .. "dr_per_die"] = derived.damageResistancePerDie
    fields[prefix .. "regenx"] = derived.magicRegenMultiplier
    fields[prefix .. "magicx"] = derived.magicPowerMultiplier
    fields[prefix .. "mapx"] = derived.utilityMagicCostMultiplier
    fields[prefix .. "crumbs"] = derived.breadcrumbCells
    fields[prefix .. "stun_inflict_x"] = derived.chaHitStunInflictMultiplier
    fields[prefix .. "stun_resist_x"] = derived.chaHitStunResistanceMultiplier
    fields[prefix .. "diversion"] = derived.hpToMagicDiversionFraction
    fields[prefix .. "rogue_explodes"] = derived.rogueAllDamageDiceExplode
    fields[prefix .. "boom_shift"] = derived.boomShift
    fields[prefix .. "rogue_boom_shift"] = derived.rogueBoomThresholdShift
    fields[prefix .. "rogue_capstone_shift"] = derived.rogueCapstoneBoomThresholdShift
    fields[prefix .. "ace_prime_seconds"] = derived.rogueAcePrimeSeconds
    fields[prefix .. "fighter_capstone_x"] = derived.fighterCapstonePhysicalDamageMultiplier
    fields[prefix .. "wizard_capstone_magic_x"] = derived.wizardCapstoneMagicPowerMultiplier
end

local function sessionHeader(reason)
    return table.concat({
        "# The Legend of Deborah RPG runtime test log",
        "# schema=" .. SCHEMA,
        "# generated_utc=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "# map=" .. safe(game.GetMap()),
        "# gamemode=" .. safe(engine.ActiveGamemode()),
        "# reason=" .. safe(reason or "manual"),
        "# fields are tab-separated key=value pairs; one event per line",
        ""
    }, "\n")
end

function Log:BeginSession(reason)
    if not developerEnabled() then return false end
    file.CreateDir(DATA_DIR)
    self.Sequence = 0
    self.Started = true
    self.ProfileSignatures = {}
    local separator = file.Exists(DATA_PATH, "DATA") and "\n# --- NEW SERVER SESSION ---\n" or ""
    file.Append(DATA_PATH, separator .. sessionHeader(reason))
    return true
end

function Log:Reset(reason)
    if not developerEnabled() then return false end
    file.CreateDir(DATA_DIR)
    file.Write(DATA_PATH, "")
    self.Started = false
    return self:BeginSession(reason or "manual reset")
end

function Log:Ensure()
    if self.Started then return true end
    return self:BeginSession("automatic session start")
end

function Log:Write(eventName, fields)
    if not developerEnabled() then return end
    if not self:Ensure() then return end
    self.Sequence = (self.Sequence or 0) + 1
    local line = string.format("%06d\t%.3f\t%s", self.Sequence, CurTime(), safe(eventName))
    local encoded = encodedFields(fields)
    if encoded ~= "" then line = line .. "\t" .. encoded end
    file.Append(DATA_PATH, line .. "\n")
end

function Log:WriteProfile(ply, reason)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local fields = {
        player = entityLabel(ply),
        reason = reason or "profile",
        hp = ply:Health(),
        max_hp = ply:GetMaxHealth()
    }
    addProfile(fields, "", ply)
    local magic = LOD.Magic
    local ps = magic and magic._EnsureState and magic:_EnsureState(ply) or nil
    if ps then fields.magic = ps.magic end
    self:Write("PROFILE", fields)
end

local function profileSignature(ply)
    local rules = LOD.RPGAbilityRules
    if not rules or not IsValid(ply) then return "" end
    local state = rules.ProgressionState and rules:ProgressionState(ply) or nil
    local derived = state and state.derivedStats or nil
    if not derived then return "unresolved" end
    local parts = {
        state.classId or "",
        state.level or 0,
        derived.physicalDamageMultiplier or 1,
        derived.aimSpreadMultiplier or 1,
        derived.movementSpeedMultiplier or 1,
        derived.damageResistancePerDie or 0,
        derived.magicRegenMultiplier or 1,
        derived.magicPowerMultiplier or 1,
        derived.utilityMagicCostMultiplier or 1,
        derived.breadcrumbCells or 0,
        derived.hpToMagicDiversionFraction or 0,
        derived.rogueAllDamageDiceExplode and 1 or 0,
        derived.boomShift or 0,
        derived.rogueBoomThresholdShift or 0,
        derived.rogueCapstoneBoomThresholdShift or 0,
        derived.rogueAcePrimeSeconds or 0,
        derived.fighterCapstonePhysicalDamageMultiplier or 1,
        derived.wizardCapstoneMagicPowerMultiplier or 1
    }
    for index, value in ipairs(parts) do parts[index] = safe(value) end
    return table.concat(parts, "|")
end

local function xpForIdentity(identity)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(identity) or nil
    local state = ps and ps.progressionState
    return state and state.xp or nil
end

local function shareList(shares)
    local out = {}
    for _, share in ipairs(shares or {}) do
        out[#out + 1] = string.format("%s:%s", safe(share.identity), safe(share.amount))
    end
    return table.concat(out, ",")
end

local function install()
    if Log.Installed then return true end
    if engine.ActiveGamemode() ~= "legend_of_deborah" then return false end
    if not developerEnabled() then return false end

    local Rolls = LOD.CombatRolls
    local Rules = LOD.RPGAbilityRules
    local Attribution = LOD.CombatAttributionSystem
    if not Rolls or not Rules or not Attribution then return false end
    if not Rolls.ResolveActorDamage or not Rolls.RollPlayerWeapon or not Rolls.RollHostileAttack then return false end

    Log:BeginSession("server instrumentation installed")

    Log.BaseResolveActorDamage = Rolls.ResolveActorDamage
    Rolls.ResolveActorDamage = function(self, contract, attacker, target, tags)
        local resolved = Log.BaseResolveActorDamage(self, contract, attacker, target, tags)
        local values = contract and contract.values or {}
        local baseDice = contract and (contract.baseDice
            or (contract.profile and contract.profile.count)) or 1
        local fields = {
            attacker = entityLabel(attacker),
            target = entityLabel(target),
            source = contract and (contract.weaponClass
                or (contract.profile and (contract.profile.source or contract.profile.label))) or "",
            formula = contractFormula(contract),
            values = valueList(values),
            contributions = valueList(contract and contract.contributions or nil),
            thresholds = valueList(contract and contract.thresholds or nil),
            raw = contract and contract.total or "",
            resolved = resolved,
            base_dice = baseDice,
            explosion_continuations = math.max(0, #values - math.max(1, tonumber(baseDice) or 1)),
            ace_bonus_dice = contract and contract.aceBonusDice or 0,
            physical = tags and tags.physical == true or false,
            magic = tags and tags.magic == true or false,
            authored_scale = tags and tags.authoredScale or 1,
            target_hp_before = IsValid(target) and target.Health and target:Health() or ""
        }
        addProfile(fields, "attacker_", attacker)
        addProfile(fields, "target_", target)
        Log:Write("DAMAGE_RESOLVE", fields)
        return resolved
    end

    Log.BaseRollPlayerWeapon = Rolls.RollPlayerWeapon
    Rolls.RollPlayerWeapon = function(self, ply, weaponClass)
        local contract = Log.BaseRollPlayerWeapon(self, ply, weaponClass)
        if contract then
            local fields = {
                actor = entityLabel(ply),
                weapon = weaponClass,
                formula = contractFormula(contract),
                values = valueList(contract.values),
                thresholds = valueList(contract.thresholds),
                raw = contract.total,
                base_dice = contract.baseDice,
                ace_bonus_dice = contract.aceBonusDice or 0,
                capped = contract.capped == true
            }
            addProfile(fields, "", ply)
            Log:Write("PLAYER_ROLL", fields)
        end
        return contract
    end

    Log.BaseRollHostileAttack = Rolls.RollHostileAttack
    Rolls.RollHostileAttack = function(self, hostile, profile, originalDamage, cacheOwner)
        local contract = Log.BaseRollHostileAttack(self, hostile, profile, originalDamage, cacheOwner)
        if contract then
            Log:Write("HOSTILE_ROLL", {
                actor = entityLabel(hostile),
                formula = contractFormula(contract),
                values = valueList(contract.values),
                raw = contract.total,
                source_damage = originalDamage,
                scale = contract.scale,
                pre_rpg_final = contract.final
            })
        end
        return contract
    end

    if Rules.ApplyPlayerDefense then
        Log.BaseApplyPlayerDefense = Rules.ApplyPlayerDefense
        Rules.ApplyPlayerDefense = function(self, target, dmginfo)
            local incoming = dmginfo and dmginfo.GetDamage and dmginfo:GetDamage() or 0
            local magicBefore
            local derived = self.Derived and self:Derived(target) or nil
            if derived and (tonumber(derived.hpToMagicDiversionFraction) or 0) > 0 then
                local magic = LOD.Magic
                local ps = magic and magic._EnsureState and magic:_EnsureState(target) or nil
                magicBefore = ps and ps.magic or nil
            end
            local result = Log.BaseApplyPlayerDefense(self, target, dmginfo)
            local magicAfter
            if magicBefore ~= nil then
                local ps = LOD.Magic and LOD.Magic._EnsureState and LOD.Magic:_EnsureState(target) or nil
                magicAfter = ps and ps.magic or nil
            end
            local fields = {
                target = entityLabel(target),
                attacker = dmginfo and entityLabel(dmginfo:GetAttacker()) or "invalid",
                incoming = incoming,
                final = dmginfo and dmginfo:GetDamage() or incoming,
                evaded = result and result.evaded == true or false,
                diverted_hp = result and result.actualMagicDiversion or 0,
                magic_spent = result and result.magicSpent or 0,
                magic_before = magicBefore,
                magic_after = magicAfter
            }
            addProfile(fields, "", target)
            Log:Write("PLAYER_DEFENSE", fields)
            return result
        end
    end

    if Attribution._Award then
        Log.BaseAttributionAward = Attribution._Award
        Attribution._Award = function(self, identity, amount, hostile)
            local granted = Log.BaseAttributionAward(self, identity, amount, hostile)
            Log:Write("XP_AWARD", {
                identity = identity,
                requested = amount,
                granted = granted,
                xp_after = xpForIdentity(identity),
                hostile = entityLabel(hostile),
                archetype = IsValid(hostile) and hostile.LODArchetypeId or "",
                spawn_reason = IsValid(hostile) and hostile.LODWanderSpawnReason or ""
            })
            return granted
        end
    end

    if Attribution.Settle then
        Log.BaseAttributionSettle = Attribution.Settle
        Attribution.Settle = function(self, hostile)
            local ok = Log.BaseAttributionSettle(self, hostile)
            local settlement = IsValid(hostile) and hostile.LODRPGXPSettlement or nil
            Log:Write("XP_SETTLEMENT", {
                hostile = entityLabel(hostile),
                result = ok == true,
                value = settlement and settlement.value or "",
                killer = settlement and settlement.killer or "",
                contribution_shares = settlement and shareList(settlement.shares) or ""
            })
            return ok
        end
    end

    if Rules.ValidateGateD then
        Log.BaseValidateGateD = Rules.ValidateGateD
        Rules.ValidateGateD = function(self, ply)
            local ok, errors = Log.BaseValidateGateD(self, ply)
            Log:Write("GATE_D_VALIDATE", {
                player = entityLabel(ply),
                result = ok and "PASS" or "FAIL",
                errors = errors and table.concat(errors, " | ") or ""
            })
            return ok, errors
        end
    end

    local gm = GAMEMODE
    if gm and gm.EntityTakeDamage then
        Log.BaseEntityTakeDamage = gm.EntityTakeDamage
        gm.EntityTakeDamage = function(self, target, dmginfo)
            local hpBefore = IsValid(target) and target.Health and target:Health() or nil
            local attacker = dmginfo and dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
            local inflictor = dmginfo and dmginfo.GetInflictor and dmginfo:GetInflictor() or nil
            local result = Log.BaseEntityTakeDamage(self, target, dmginfo)
            if IsValid(target) and dmginfo and dmginfo:GetDamage() > 0
                and (target:IsPlayer() or target.LODHostile)
            then
                local fields = {
                    attacker = entityLabel(attacker),
                    inflictor = entityLabel(inflictor),
                    target = entityLabel(target),
                    target_hp_before = hpBefore,
                    final_engine_damage = dmginfo:GetDamage(),
                    damage_type = dmginfo:GetDamageType()
                }
                addProfile(fields, "attacker_", attacker)
                addProfile(fields, "target_", target)
                Log:Write("DAMAGE_APPLIED", fields)
            end
            return result
        end
    end

    hook.Add("PlayerSpawn", "LOD_RPGTestLog_PlayerSpawn", function(ply)
        timer.Simple(0.25, function()
            if IsValid(ply) then Log:WriteProfile(ply, "spawn") end
        end)
    end)

    timer.Create("LOD_RPGTestLog_ProfileWatch", 0.5, 0, function()
        if not developerEnabled() then return end
        for _, ply in ipairs(player.GetHumans()) do
            local signature = profileSignature(ply)
            if Log.ProfileSignatures[ply] ~= signature then
                Log.ProfileSignatures[ply] = signature
                Log:WriteProfile(ply, "profile changed")
            end
        end
    end)

    local function commandAllowed(ply)
        return not IsValid(ply) or ply:IsAdmin()
    end

    concommand.Add("lod_rpg_test_log_reset", function(ply)
        if not commandAllowed(ply) then return end
        Log:Reset("manual reset")
        for _, candidate in ipairs(player.GetHumans()) do
            Log:WriteProfile(candidate, "manual reset")
        end
        local msg = "RPG test log reset: data/" .. DATA_PATH
        print("[LOD:RPG-LOG] " .. msg)
        if IsValid(ply) then ply:ChatPrint(msg) end
    end)

    concommand.Add("lod_rpg_test_log_status", function(ply)
        if not commandAllowed(ply) then return end
        local size = file.Size(DATA_PATH, "DATA")
        local msg = string.format("RPG test log: data/%s bytes=%s events=%d",
            DATA_PATH, safe(size), Log.Sequence or 0)
        print("[LOD:RPG-LOG] " .. msg)
        if IsValid(ply) then ply:ChatPrint(msg) end
    end)

    concommand.Add("lod_rpg_test_log_mark", function(ply, _, _, argStr)
        if not commandAllowed(ply) then return end
        Log:Write("MARK", {player = entityLabel(ply), label = argStr or ""})
    end)

    Log.Installed = true
    print("[LOD:RPG-LOG] writing data/" .. DATA_PATH)
    for _, ply in ipairs(player.GetHumans()) do Log:WriteProfile(ply, "instrumentation installed") end
    return true
end

hook.Add("InitPostEntity", "LOD_RPGTestLog_Bootstrap", function()
    timer.Simple(0, install)
end)

-- Autorun normally precedes InitPostEntity. This one-shot fallback covers a
-- development lua refresh without creating a recurring production watcher.
timer.Simple(1, install)
