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
    life = {label = "LIFE", priority = 3, sound = "items/suitchargeok1.wav"},
    soldier = {label = "SOLDIER", priority = 2, sound = "buttons/combine_button1.wav"},
    progress = {label = "PROGRESS", priority = 2, sound = "items/suitchargeok1.wav"},
    kill = {label = "DEFEATED", priority = 0}
}
