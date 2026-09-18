LOD = LOD or {}
-- Presentation policy only. No gameplay probabilities, costs or durations.
LOD.FeedbackLanguage = {
    routine = {label = "", priority = 0},
    status = {label = "STATUS +", priority = 1, sound = "buttons/lightswitch2.wav"},
    clear = {label = "STATUS -", priority = 1, sound = "buttons/button19.wav"},
    resist = {label = "RESIST", priority = 1, sound = "physics/metal/metal_solid_impact_soft1.wav"},
    weakness = {label = "WEAKNESS", priority = 1, sound = "buttons/button17.wav"},
    proc = {label = "PROC", priority = 1, sound = "buttons/button15.wav"},
    resource = {label = "RESOURCE", priority = 0},
    magic = {label = "MAGIC", priority = 0}, -- cast already has positional sound/FX
    blocked = {label = "BLOCKED", priority = 1}, -- preserve existing denial sounds
    objective = {label = "OBJECTIVE", priority = 0}, -- existing banner/world cues
    danger = {label = "DANGER", priority = 3, sound = "buttons/button10.wav"},
    awareness = {label = "AWARENESS", priority = 2, sound = "buttons/blip1.wav"},
    life = {label = "LIFE", priority = 3, sound = "items/suitchargeok1.wav"},
    soldier = {label = "SOLDIER", priority = 2, sound = "buttons/combine_button1.wav"},
    progress = {label = "PROGRESS", priority = 2, sound = "items/suitchargeok1.wav"},
    kill = {label = "DEFEATED", priority = 0}
}

-- Cosmetic event vocabulary carried by the existing authoritative logger packet.
-- Never infer success from wording, a predicted interaction, or a UI opening.
LOD.AdventureCues = {
    [1] = {id = "discovery", priority = 2, duration = 2.1, caption = "POCKET-SIZED POSSIBILITY."},
    [2] = {id = "unlock", priority = 2, duration = 1.7, caption = "ONWARD, PROBABLY."},
    [3] = {id = "learn", priority = 2, duration = 2.0, caption = "REALITY HAS A NEW LOOPHOLE."},
    [4] = {id = "treasure", sound = "discovery", priority = 1, duration = 1.4, caption = "FINDERS. KEEPERS."},
    [5] = {id = "level_up", priority = 3, duration = 1.8},
    [6] = {id = "rescue", priority = 4, duration = 2.4},
    [7] = {id = "feat", priority = 1, duration = .65},
    [8] = {id = "gift", sound = "discovery", priority = 2, duration = 1.5}
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
