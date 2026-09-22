LOD = LOD or {}
-- One second, normal -> red -> normal -> red, matching the corpse lifetime.
function LOD.EnemyDeathPulse(elapsed)
    return .5 - .5 * math.cos(math.max(0, math.min(1, elapsed)) * math.pi * 3)
end
-- Presentation policy only. No gameplay probabilities, costs or durations.
LOD.FeedbackLanguage = {
    routine = {label = "", priority = 0},
    status = {label = "STATUS +", priority = 1, cueId = "status"},
    clear = {label = "STATUS -", priority = 1, cueId = "status_clear"},
    resist = {label = "RESIST", priority = 1, cueId = "resist"},
    weakness = {label = "WEAKNESS", priority = 1, cueId = "weakness"},
    proc = {label = "PROC", priority = 1, cueId = "proc"},
    resource = {label = "RESOURCE", priority = 0},
    magic = {label = "MAGIC", priority = 0}, -- cast already has positional sound/FX
    blocked = {label = "BLOCKED", priority = 1}, -- preserve existing denial sounds
    objective = {label = "OBJECTIVE", priority = 0}, -- existing banner/world cues
    danger = {label = "DANGER", priority = 3, cueId = "danger"},
    awareness = {label = "AWARENESS", priority = 2, cueId = "spatial_awareness"},
    life = {label = "LIFE", priority = 3, cueId = "life"},
    soldier = {label = "SOLDIER", priority = 2, cueId = "soldier"},
    progress = {label = "PROGRESS", priority = 2, cueId = "progress"},
    kill = {label = "DEFEATED", priority = 0}
}

-- Cosmetic event vocabulary carried by the existing authoritative logger packet.
-- Never infer success from wording, a predicted interaction, or a UI opening.
LOD.AdventureCues = {
    [1] = {id = "discovery", priority = 2, duration = 2.1, caption = "POCKET-SIZED POSSIBILITY."},
    [2] = {id = "unlock", priority = 2, duration = 1.7, caption = "ONWARD, PROBABLY."},
    [3] = {id = "learn", priority = 2, duration = 2.0, caption = "REALITY HAS A NEW LOOPHOLE."},
    [4] = {id = "treasure", feedback = "loot_pickup", priority = 1, duration = 1.4, caption = "FINDERS. KEEPERS."},
    [5] = {id = "level_up", priority = 3, duration = 1.8},
    [6] = {id = "rescue", priority = 4, duration = 2.4},
    [7] = {id = "feat", priority = 1, duration = .65},
    [8] = {id = "gift", feedback = "gift", priority = 2, duration = 1.5}
}
function LOD.AdventureCueForEvent(fields)
    fields = fields or {}
    local event = fields.event
    if event == "keycard_acquired" or event == "jail_key_acquired" then return 1 end
    if event == "gate_opened" or event == "jail_opened" then return 2 end
    if event == "magic_learned" then return 3 end
    if event == "loot_collected" and (fields.kind == "weapon" or fields.kind == "cache") then return 4 end
    return 0
end
