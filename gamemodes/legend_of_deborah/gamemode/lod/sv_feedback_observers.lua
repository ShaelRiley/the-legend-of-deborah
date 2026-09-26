-- Observers run AFTER authority, preserve every return (including nil holes), and
-- contain their own errors. They never call RNG, grant resources, or decide rules.
local P = LOD.RPGPresentation
if P.FeedbackObserversInstalled then return end
P.FeedbackObserversInstalled = true
local function pack(...) return {n = select("#", ...), ...} end
local function guarded(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok then ErrorNoHalt("[LOD:FEEDBACK] " .. tostring(value) .. "\n") end
    return ok and value or nil
end
local function observe(owner, key, snapshot, after)
    if not owner or not owner[key] then return end
    local base = owner[key]
    owner[key] = function(self, ...)
        local before = snapshot and guarded(snapshot, self, ...) or nil
        local result = pack(base(self, ...))
        guarded(after, before, result, self, ...)
        return unpack(result, 1, result.n)
    end
end
local function emit(ply, family, text, event, fields, throttle)
    fields = fields or {}; fields.event = event
    P:Event(ply, family, text, fields, throttle)
end
local function statusNotice(target, source, id, result, detail)
    local family = result == "applied" and "status"
        or (result == "saved" or result == "immune") and "resist" or "routine"
    local outcome = result == "saved" and "RESISTED" or string.upper(result)
    local text = string.format("%s: %s %s", P:FeedbackName(target), string.upper(id), outcome)
    if result == "saved" and detail then text = text .. string.format(" (save %s / DC %s)", detail.save, detail.dc) end
    local fields = {status = id, outcome = result, target = IsValid(target) and target:EntIndex() or -1,
        source = IsValid(source) and source:EntIndex() or -1, dc = detail and detail.dc,
        save = detail and detail.save}
    fields.event = "status_result"
    P:CombatEvent(target, source, family, text, fields)
end

observe(LOD.RPGStatusElements, "Apply", nil, function(_, result, _, target, id, source)
    local reason = result[2]
    if reason == "applied" or reason == "saved" or reason == "immune"
        or reason == "refreshed" or reason == "extended" then
        statusNotice(target, source, id, reason, result[3])
    end
end)
observe(LOD.RPGStatusElements, "Clear", function(self, target, id)
    return self.Active[target] and self.Active[target][id]
end, function(entry, result, _, target, id, reason)
    if not result[1] or not entry then return end
    local text = P:FeedbackName(target) .. ": " .. string.upper(id) .. " ENDED (" .. tostring(reason or "cleared") .. ")"
    local fields = {status = id, outcome = reason or "cleared", target = IsValid(target) and target:EntIndex() or -1}
    fields.event = "status_clear"
    P:CombatEvent(target, entry.source, "clear", text, fields)
end)
hook.Add("LODStatusApplied", "LOD_FeedbackMorale", function(target, id, source)
    if id == "morale_flee" then guarded(statusNotice, target, source, id, "applied") end
end)
observe(LOD.RPGStatusElements, "ResolveElementDamage", nil, function(_, result, _, amount, attacker, target)
    local detail = result[2]
    if not detail or (detail.kind ~= "weakness" and detail.kind ~= "resistance") then return end
    local text = string.format("%s: %s %s x%g (%.1f -> %.1f)", P:FeedbackName(target),
        string.upper(detail.element), string.upper(detail.kind), detail.multiplier, amount, result[1])
    local fields = {element = detail.element, outcome = detail.kind, multiplier = detail.multiplier,
        incoming = amount, resolved = result[1], target = IsValid(target) and target:EntIndex() or -1}
    local family = detail.kind == "weakness" and "weakness" or "resist"
    if detail.rolls then
        text = text .. string.format("; d%d [%s], selected %d", detail.dieSides,
            table.concat(detail.rolls, ", "), detail.index)
        fields.rolls, fields.dieSides, fields.selected = detail.rolls, detail.dieSides, detail.index
    end
    fields.event = "element_result"
    P:CombatEvent(target, attacker, family, text, fields)
end)

local Rules = LOD.RPGAbilityRules
observe(Rules, "ApplyNotYetDefense", function(_, target) return target.LODRPGNotYetTriggeredAt end,
    function(before, result, _, target)
        if result[1] and target.LODRPGNotYetTriggeredAt ~= before then
            emit(target, "life", "NOT YET — lethal hit intercepted; 1 HP remains", "not_yet")
        end
    end)

local Effects = LOD.RPG and LOD.RPG.FeatEffectSystem
for _, spec in ipairs({{"ApplyFeedbackLoop", "FEEDBACK LOOP"}, {"ApplyArcRecovery", "ARC RECOVERY"}}) do
    local method, label = spec[1], spec[2]
    observe(Effects, method, nil, function(_, result, _, actor)
        if (tonumber(result[1]) or 0) > 0 then
            P:CombatEvent(actor, nil, "proc", string.format("%s: %s — +%g Magic",
                P:FeedbackName(actor), label, result[1]), {event=method, restored=result[1]})
        end
    end)
end

observe(Effects, "_TickActor", function(_, actor)
    return IsValid(actor) and {hp=actor:Health()} or nil
end, function(before, _, _, actor)
    if not before or not IsValid(actor) then return end
    local after = actor:Health()
    if after > before.hp then
        P:CombatEvent(actor, nil, "resource", string.format("%s: HEALTH REGENERATION +%g HP (%g → %g)",
            P:FeedbackName(actor), after-before.hp, before.hp, after),
            {event="health_regeneration", restored=after-before.hp, before=before.hp, after=after})
    end
end)

local function heroState(actor)
    local ps = LOD.RunManager:GetPlayerState(actor)
    return ps and ps.progressionState
end
local function growthDice(actor, state, previousLevel)
    local ply = P:FeedbackPlayer(actor)
    if not ply or not state then return end
    for level = previousLevel + 1, state.level do
        local roll = state.hitDieRollsByLevel and state.hitDieRollsByLevel[level]
        if roll then
            P:DiceEvent(ply, nil, "LEVEL " .. level .. " HP GROWTH", roll.formula,
                roll.values, roll.total, {event="progression_hp_dice", family="progression", level=level,
                    detail="hit-die total before ability/feat adjustments"})
        end
    end
end
observe(LOD.CharacterProgressionSystem, "AdvanceHeroToLevel", function(_, actor)
    local state = heroState(actor)
    return state and {owner=state, level=state.level}
end, function(before, result, _, actor)
    local state = heroState(actor)
    if before and result[1] and state == before.owner then growthDice(actor, state, before.level) end
end)
observe(LOD.CharacterProgressionSystem, "AwardHeroXP", function(_, actor)
    local state = heroState(actor)
    return state and {owner=state, xp=state.xp or 0}
end, function(before, _, _, actor)
    local state = heroState(actor)
    if not before or state ~= before.owner then return end
    local gained = (state.xp or 0) - before.xp
    if gained > 0 then emit(actor, "resource", string.format("+%d Hero XP (%d total)", gained, state.xp),
        "hero_xp", {granted = gained, xp = state.xp}) end
end)
local function soldierState(target)
    return type(target) == "table" and target.actorType == "human_soldier" and target
        or target and target.LODHumanSoldierProgressionState
end
observe(LOD.SoldierProgression, "Attach", function(_, actor)
    return soldierState(actor)
end, function(before, result, _, actor)
    local state = soldierState(actor)
    if state and state ~= before and result[1] == state then growthDice(actor, state, 1) end
end)
observe(LOD.SoldierProgression, "Award", function(_, target)
    local state = soldierState(target)
    return state and {owner=state, xp = state.soldierXP, level = state.level}
end, function(before, _, _, target)
    local state = soldierState(target)
    if not before or state ~= before.owner or state.soldierXP <= before.xp then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply.LODHumanSoldierProgressionState == state then
            growthDice(ply, state, before.level)
            local advanced = state.level > before.level
            emit(ply, advanced and "progress" or "resource", string.format("+%d SoldierXP (%d total) — Soldier Level %d",
                state.soldierXP - before.xp, state.soldierXP, state.level), "soldier_xp",
                {granted = state.soldierXP - before.xp, xp = state.soldierXP, level = state.level})
        end
    end
end)

-- Observe published lifecycle snapshots rather than reimplementing death/queue
-- rules. First sync establishes a baseline; campaign epochs do not compare lives.
local lifeSnapshots = setmetatable({}, {__mode = "k"})
observe(LOD.RunManager, "_SyncPlayerVars", nil, function(_, _, self, ply)
    if not IsValid(ply) then return end
    local ps = self:GetPlayerState(ply)
    if not ps then lifeSnapshots[ply] = nil; return end
    local current = {lives = ps.lives or 0, soldier = self:IsSoldierControl(ply),
        eliminated = ps.eliminated == true, wait = ps.soldierRespawnWait == true,
        epoch = self.State.CampaignEpoch}
    local before = lifeSnapshots[ply]; lifeSnapshots[ply] = current
    -- Compare only the SAME retained Hero. A fresh Hero is not a revival, and
    -- replacement run objects may deliberately reuse a numeric campaign seed.
    current.owner, current.identity, current.progression, current.run = ps, ps.identity, ps.progressionState, self.State
    if not before or current.epoch ~= before.epoch or current.owner ~= before.owner
        or current.identity ~= before.identity or current.progression ~= before.progression
        or current.run ~= before.run then return end
    -- Never ship native/state references into telemetry.
    local fields = {lives=current.lives, soldier=current.soldier, eliminated=current.eliminated,
        wait=current.wait, epoch=current.epoch}
    if current.lives < before.lives then
        emit(ply, "danger", current.eliminated and "HERO ELIMINATED — await revival or request Soldier role"
            or string.format("LIFE LOST — %d remaining", current.lives), "life_lost", fields)
    elseif current.lives > before.lives then
        emit(ply, "life", string.format("%s — %d %s", before.eliminated and "HERO REVIVED" or "LIFE GAINED",
            current.lives, current.lives == 1 and "life" or "lives"), "life_gained", fields)
    end
    if current.soldier and not before.soldier then
        emit(ply, "soldier", "SOLDIER ACTIVE — disposable incarnation; SoldierXP starts fresh", "soldier_enter", fields)
    elseif before.soldier and not current.soldier then
        emit(ply, "soldier", current.wait and "SOLDIER LOST — incarnation retired; respawn delay"
            or "SOLDIER RETIRED — Hero queue / staging", "soldier_exit", fields)
    end
end)

observe(LOD.ProgressionDirector, "Announce", nil, function(_, _, _, text, presentation)
    for _, ply in ipairs(player.GetAll()) do
        -- Existing banner stays the visual authority. Retain its EXACT sentence.
        local fields = table.Copy(presentation or {})
        fields.dungeon = LOD.RunManager.State.Level
        emit(ply, "objective", text, fields.event or "announcement", fields)
    end
end)

observe(LOD.RunManager, "BuildCurrentLevel", nil, function(_, result, self)
    if result[1] ~= true or not self.State.BuildReady then return end
    for _, ply in ipairs(player.GetAll()) do
        emit(ply, "progress", "DUNGEON " .. tostring(self.State.Level) .. " READY — staging",
            "dungeon_ready", {dungeon = self.State.Level})
    end
end)

local spellSnapshots = setmetatable({}, {__mode = "k"})
observe(LOD.MagicProgression, "SendSnapshot", nil, function(_, _, _, ply)
    if not IsValid(ply) then return end
    local state = heroState(ply)
    if not state or LOD.RunManager:IsSoldierControl(ply) then spellSnapshots[ply] = nil return end
    local current = {state = state, forms = table.Copy(state.magicFormIds or {}), contents = table.Copy(state.contentIds or {}),
        form = state.selectedMagicFormId, content = state.selectedMagicContentId,
        epoch = LOD.RunManager.State.CampaignEpoch}
    local previous = spellSnapshots[ply]; spellSnapshots[ply] = current
    if not previous or previous.epoch ~= current.epoch or previous.state ~= current.state then return end
    for _, spec in ipairs({{"forms", LOD.RPG.MagicForms, "FORM"}, {"contents", LOD.RPG.MagicContents, "CONTENT"}}) do
        local known = {}; for _, id in ipairs(previous[spec[1]]) do known[id] = true end
        for _, id in ipairs(current[spec[1]]) do
            local definition = spec[2] and spec[2][id]
            if not known[id] then emit(ply, "progress", spec[3] .. " LEARNED — " .. tostring(definition and definition.displayName or id)
                .. " / Press I for Spellbook", "magic_learned", {kind = spec[3], id = id}) end
        end
    end
    if current.form ~= previous.form or current.content ~= previous.content then
        emit(ply, "magic", string.upper(current.form or "no Form") .. " / " .. string.upper(current.content or "raw")
            .. " SELECTED", "magic_selected", {form = current.form, content = current.content or "raw"})
    end
end)

observe(LOD.CombatAttributionSystem, "Settle", function(_, hostile)
    return P:FeedbackName(hostile)
end, function(name, result, _, hostile)
    if not result[1] then return end
    local settlement = hostile and hostile.LODRPGXPSettlement
    if settlement and settlement.killer then emit(settlement.killer, "kill", name, "kill_settled") end
end)

-- Ordinary passive Magic sync and full-cap crossing are HUD state, not events
-- (author-directed SPOT-05 exception). Authored restoration, spend and diversion
-- keep their own canonical producers; never infer their cause from pool deltas.
