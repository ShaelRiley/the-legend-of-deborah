-- Checkpoint D Canonical Feat and Capstone Closure Validator
LOD = LOD or {}; LOD.RPG = LOD.RPG or {}

local observedTimers, observedHooks = {}, {}
local function mockGMod()
    SERVER = true
    CLIENT = false
    unpack = unpack or table.unpack
    AddCSLuaFile = function() end
    DeriveGamemode = function() end
    GM = {}
    Vector = function(x,y,z) return {x=x or 0, y=y or 0, z=z or 0} end
    Color = function(r,g,b,a) return {r=r, g=g, b=b, a=a} end
    util = util or {}
    util.AddNetworkString = util.AddNetworkString or function() end
    util.CRC = util.CRC or function(v) return tostring(v) end
    net = net or {}
    net.Receive = net.Receive or function() end
    hook = hook or {}
    hook.Add = hook.Add or function() end
    hook.GetTable = hook.GetTable or function() return {} end
    concommand = concommand or {}
    concommand.Add = concommand.Add or function() end
    GetConVar = GetConVar or function() return {GetBool = function() return true end} end
    IsValid = IsValid or function() return false end
    isentity = isentity or function() return false end
    isfunction = function(v) return type(v) == "function" end
    istable = function(v) return type(v) == "table" end
    isstring = function(v) return type(v) == "string" end
    isnumber = function(v) return type(v) == "number" end
    math.Clamp = math.Clamp or function(v, min, max) return math.max(min, math.min(max, v)) end
    string.Trim = string.Trim or function(v) return string.match(v, "^%s*(.-)%s*$") end
    table.Copy = table.Copy or function(v)
        if type(v) ~= "table" then return v end
        local copy = {}
        for k, item in pairs(v) do copy[k] = table.Copy(item) end
        return copy
    end
    team = team or {SetUp = function() end}
    timer = timer or {Simple = function() end, Create = function() end, Remove = function() end, Exists = function() return false end}
    local createTimer, addHook = timer.Create, hook.Add
    timer.Create = function(id, interval, repetitions, callback)
        observedTimers[id] = callback
        return createTimer(id, interval, repetitions, callback)
    end
    hook.Add = function(event, id, callback)
        observedHooks[id] = callback
        return addHook(event, id, callback)
    end
    player = player or {GetAll = function() return {} end}
    resource = resource or {AddFile = function() end, AddWorkshop = function() end}
    LOD.CombatRolls = LOD.CombatRolls or {}
    function LOD.CombatRolls:RollProgressionHitDie(seed, sides)
        seed = tonumber(seed) or 12345
        sides = tonumber(sides) or 6
        local value = (LOD.RNG and LOD.RNG.New) and LOD.RNG.New(seed):Int(1, sides) or math.random(1, sides)
        return {seed = seed, sides = sides, formula = "d" .. tostring(sides), values = {value}, total = value}
    end
    include = include or function(path)
        local f = io.open("gamemodes/legend_of_deborah/gamemode/" .. path, "rb")
        if not f then error("Cannot open " .. path) end
        local code = f:read("*a")
        f:close()
        local fn, err = load(code, path)
        if not fn then error("Load error in " .. path .. ": " .. tostring(err)) end
        fn()
    end
end

mockGMod()

dofile("gamemodes/legend_of_deborah/gamemode/shared.lua")
-- These consumers are included by init.lua after the shared RPG graph. Their
-- engine providers are inert here; the production method bodies remain intact.
LOD.Magic = LOD.Magic or {}
LOD.HostileMotionV2 = LOD.HostileMotionV2 or {}
dofile("gamemodes/legend_of_deborah/gamemode/lod/sv_magic_forms.lua")
dofile("gamemodes/legend_of_deborah/gamemode/lod/sv_pushback.lua")

local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "IdentityCatalog required")
local CPS = assert(LOD.CharacterProgressionSystem, "CharacterProgressionSystem required")
local Rules = assert(LOD.RPGAbilityRules, "RPGAbilityRules required")
local Director = assert(LOD.FeatDirector, "FeatDirector required")
local Effects = LOD.RPG.FeatEffectSystem

local errors = {}
local function check(ok, message)
    if not ok then
        table.insert(errors, message)
    end
end

-- 1. Canonical Inventory Specification (Audited against live GDD revision ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q)
local CANONICAL_FEATS = {
    CROSS_METEOR_STRIKE = {ability = "str", req = {str = 15, int = 15}, prereq = {"STR_CROWBAR_D6", "INT_CLOUD_STEP"}, family = "cross_meteor_strike", rank = 1, replaces = false},
    CROSS_TINY_TERROR = {ability = "dex", req = {dex = 15, cha = 15}, prereq = {"DEX_SHRINK", "CHA_MENACE_1"}, family = "cross_tiny_terror", rank = 1, replaces = false},
    CROSS_BIG_SCARY = {ability = "con", req = {con = 15, str = 13, cha = 15}, prereq = {"CON_BIG_GUY", "CHA_MENACE_1"}, family = "cross_big_scary", rank = 1, replaces = false},
    CROSS_CRUSH_PANIC = {ability = "str", req = {str = 17, cha = 17}, prereq = {"STR_KNOCKBACK_1", "CHA_MENACE_2"}, family = "cross_crush_panic", rank = 1, replaces = false},
    CROSS_BOOM_BATTERY = {ability = "dex", req = {dex = 15, int = 15}, prereq = {}, family = "cross_boom_battery", rank = 1, replaces = false},
    CROSS_FORCE_OF_WILL = {ability = "str", req = {str = 15, wis = 15}, prereq = {"STR_KNOCKBACK_1", "WIS_FORCEFUL_MAGIC"}, family = "cross_force_of_will", rank = 1, replaces = false},
    -- CON
    CON_REGEN_11 = {ability = "con", req = {con = 13}, prereq = {}, family = "con_health_regeneration", rank = 1, replaces = false},
    CON_REGEN_22 = {ability = "con", req = {con = 15}, prereq = {"CON_REGEN_11"}, family = "con_health_regeneration", rank = 2, replaces = true},
    CON_REGEN_33 = {ability = "con", req = {con = 17}, prereq = {"CON_REGEN_22"}, family = "con_health_regeneration", rank = 3, replaces = true},
    CON_POISON_PROC_1 = {ability = "con", req = {con = 13}, prereq = {}, family = "con_poison_proc", rank = 1, replaces = false},
    CON_POISON_PROC_2 = {ability = "con", req = {con = 15}, prereq = {"CON_POISON_PROC_1"}, family = "con_poison_proc", rank = 2, replaces = true},
    CON_POISON_PROC_3 = {ability = "con", req = {con = 17}, prereq = {"CON_POISON_PROC_2"}, family = "con_poison_proc", rank = 3, replaces = true},
    CON_GLOW_UP = {ability = "con", req = {con = 17}, prereq = {}, family = "con_glow_up", rank = 1, replaces = false},
    CON_STEADFAST = {ability = "con", req = {con = 13}, prereq = {}, family = "con_steadfast", rank = 1, replaces = false},
    CON_BLAST_PROOF = {ability = "con", req = {con = 15}, prereq = {}, family = "con_blast_proof", rank = 1, replaces = false},
    CON_BIG_GUY = {ability = "con", req = {con = 15, str = 13}, prereq = {}, family = "con_big_guy", rank = 1, replaces = false},
    CON_NOT_YET = {ability = "con", req = {con = 15}, prereq = {}, family = "con_not_yet", rank = 1, replaces = false},
    CON_RUSSIAN_ASSET = {ability = "int", req = {int = 13}, prereq = {}, family = "int_russian_asset", rank = 1, replaces = false},

    -- DEX
    DEX_EXPLODE_D10 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_exploding_damage_dice", rank = 1, replaces = false},
    DEX_EXPLODE_D8 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_EXPLODE_D10"}, family = "dex_exploding_damage_dice", rank = 2, replaces = false},
    DEX_EXPLODE_D4 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_EXPLODE_D8"}, family = "dex_exploding_damage_dice", rank = 3, replaces = false},
    DEX_CLUMSY_PROC_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_clumsy_proc", rank = 1, replaces = false},
    DEX_CLUMSY_PROC_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_CLUMSY_PROC_1"}, family = "dex_clumsy_proc", rank = 2, replaces = true},
    DEX_CLUMSY_PROC_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_CLUMSY_PROC_2"}, family = "dex_clumsy_proc", rank = 3, replaces = true},
    DEX_IMMOLATE_PROC_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_immolate_proc", rank = 1, replaces = false},
    DEX_IMMOLATE_PROC_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_IMMOLATE_PROC_1"}, family = "dex_immolate_proc", rank = 2, replaces = true},
    DEX_IMMOLATE_PROC_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_IMMOLATE_PROC_2"}, family = "dex_immolate_proc", rank = 3, replaces = true},
    DEX_FAST_RELOAD = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_reload_cadence", rank = 1, replaces = false},
    DEX_FAST_RELOAD_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_FAST_RELOAD"}, family = "dex_reload_cadence", rank = 2, replaces = true},
    DEX_FAST_RELOAD_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_FAST_RELOAD_2"}, family = "dex_reload_cadence", rank = 3, replaces = true},
    DEX_RATE_OF_FIRE_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_rate_of_fire", rank = 1, replaces = false},
    DEX_RATE_OF_FIRE_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_RATE_OF_FIRE_1"}, family = "dex_rate_of_fire", rank = 2, replaces = true},
    DEX_RATE_OF_FIRE_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_RATE_OF_FIRE_2"}, family = "dex_rate_of_fire", rank = 3, replaces = true},
    DEX_BURSTER_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_burst_size", rank = 1, replaces = false},
    DEX_BURSTER_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_BURSTER_1"}, family = "dex_burst_size", rank = 2, replaces = true},
    DEX_BURSTER_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_BURSTER_2"}, family = "dex_burst_size", rank = 3, replaces = true},
    DEX_SPRING_HEEL = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_spring_heel", rank = 1, replaces = false},
    DEX_WALL_JUMP = {ability = "dex", req = {dex = 15}, prereq = {}, family = "dex_wall_jump", rank = 1, replaces = false},
    DEX_STRAFER_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_strafe", rank = 1, replaces = false},
    DEX_SIDELER_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_STRAFER_1"}, family = "dex_strafe", rank = 2, replaces = true},
    DEX_LATERAL_MOVER_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_SIDELER_2"}, family = "dex_strafe", rank = 3, replaces = true},
    DEX_SHRINK = {ability = "dex", req = {dex = 15}, prereq = {}, family = "dex_shrink", rank = 1, replaces = false},
    DEX_SMG_COLD_HANDS_1 = {ability = "dex", req = {dex = 13}, prereq = {}, family = "dex_smg_heat", rank = 1, replaces = false},
    DEX_SMG_COLD_HANDS_2 = {ability = "dex", req = {dex = 15}, prereq = {"DEX_SMG_COLD_HANDS_1"}, family = "dex_smg_heat", rank = 2, replaces = true},
    DEX_SMG_COLD_HANDS_3 = {ability = "dex", req = {dex = 17}, prereq = {"DEX_SMG_COLD_HANDS_2"}, family = "dex_smg_heat", rank = 3, replaces = true},
    DEX_MAGNUM_DEADEYE = {ability = "dex", req = {dex = 15}, prereq = {}, family = "dex_magnum_deadeye", rank = 1, replaces = false},

    -- INT
    INT_AMMO_FLOOR_44 = {ability = "int", req = {int = 13}, prereq = {}, family = "int_ammo_regeneration_floor", rank = 1, replaces = false},
    INT_AMMO_FLOOR_55 = {ability = "int", req = {int = 15}, prereq = {"INT_AMMO_FLOOR_44"}, family = "int_ammo_regeneration_floor", rank = 2, replaces = true},
    INT_AMMO_FLOOR_66 = {ability = "int", req = {int = 17}, prereq = {"INT_AMMO_FLOOR_55"}, family = "int_ammo_regeneration_floor", rank = 3, replaces = true},
    INT_ARCANE_PROC_1 = {ability = "int", req = {int = 13}, prereq = {}, family = "int_arcane_disruption_proc", rank = 1, replaces = false},
    INT_ARCANE_PROC_2 = {ability = "int", req = {int = 15}, prereq = {"INT_ARCANE_PROC_1"}, family = "int_arcane_disruption_proc", rank = 2, replaces = true},
    INT_ARCANE_PROC_3 = {ability = "int", req = {int = 17}, prereq = {"INT_ARCANE_PROC_2"}, family = "int_arcane_disruption_proc", rank = 3, replaces = true},
    INT_MANA_BARRIER_1 = {ability = "int", req = {int = 13}, prereq = {}, family = "mana_barrier", rank = 1, replaces = false},
    INT_MANA_BARRIER_2 = {ability = "int", req = {int = 15}, prereq = {"INT_MANA_BARRIER_1"}, family = "mana_barrier", rank = 2, replaces = true},
    INT_MANA_BARRIER_3 = {ability = "int", req = {int = 17}, prereq = {"INT_MANA_BARRIER_2"}, family = "mana_barrier", rank = 3, replaces = true},
    INT_MANA_SPRING = {ability = "int", req = {int = 13}, prereq = {}, family = "int_mana_spring", rank = 1, replaces = false},
    INT_CLOUD_STEP = {ability = "int", req = {int = 13}, prereq = {}, family = "int_cloud_step", rank = 1, replaces = false},
    INT_FLOAT_ON = {ability = "int", req = {int = 15}, prereq = {}, family = "int_float_on", rank = 1, replaces = false},
    INT_SIZE_SHIFTER = {ability = "int", req = {int = 13}, prereq = {}, family = "int_size_shifter", rank = 1, replaces = false},
    INT_QUANTUM_MATHEMATICS_1 = {ability = "int", req = {int = 13}, prereq = {}, family = "int_quantum_cost", rank = 1, replaces = false},
    INT_QUANTUM_MECHANICS_2 = {ability = "int", req = {int = 15}, prereq = {"INT_QUANTUM_MATHEMATICS_1"}, family = "int_quantum_cost", rank = 2, replaces = true},
    INT_QUANTUM_MASTERY_3 = {ability = "int", req = {int = 17}, prereq = {"INT_QUANTUM_MECHANICS_2"}, family = "int_quantum_cost", rank = 3, replaces = true},
    INT_MIDDLE_MANAGER = {ability = "int", req = {int = 13}, prereq = {}, family = "int_summon_management", rank = 1, replaces = false},
    INT_TASKMASTER = {ability = "int", req = {int = 15}, prereq = {"INT_MIDDLE_MANAGER"}, family = "int_summon_management", rank = 2, replaces = true},
    INT_OVERLORD = {ability = "int", req = {int = 17}, prereq = {"INT_TASKMASTER"}, family = "int_summon_management", rank = 3, replaces = true},
    INT_WORLD_WALKER_1 = {ability = "int", req = {int = 13}, prereq = {}, family = "int_map_movement", rank = 1, replaces = false},
    INT_GLOBETROTTER_2 = {ability = "int", req = {int = 15}, prereq = {"INT_WORLD_WALKER_1"}, family = "int_map_movement", rank = 2, replaces = true},
    INT_MIND_STRIDER_3 = {ability = "int", req = {int = 17}, prereq = {"INT_GLOBETROTTER_2"}, family = "int_map_movement", rank = 3, replaces = true},
    INT_GRAND_UNIFIED_THEORY = {ability = "int", req = {int = 17}, prereq = {}, family = "int_grand_unified_theory", rank = 1, replaces = false},
    INT_EXTRACURRICULAR_ACTIVITY = {ability = "int", req = {int = 17}, prereq = {}, family = "int_extracurricular_activity", rank = 1, replaces = false},
    INT_WAS_DEBORAH = {ability = "int", req = {int = 13}, prereq = {}, family = "int_backpedal", rank = 1, replaces = false},
    INT_HASTE_1 = {ability = "int", req = {int = 13}, prereq = {}, family = "int_haste", rank = 1, replaces = false},
    INT_HASTE_2 = {ability = "int", req = {int = 15}, prereq = {"INT_HASTE_1"}, family = "int_haste", rank = 2, replaces = true},
    INT_HASTE_3 = {ability = "int", req = {int = 17}, prereq = {"INT_HASTE_2"}, family = "int_haste", rank = 3, replaces = true},
    INT_FEEDBACK_LOOP = {ability = "int", req = {int = 15}, prereq = {}, family = "int_feedback_loop", rank = 1, replaces = false},
    INT_ARC_RECOVERY = {ability = "int", req = {int = 17}, prereq = {}, family = "int_arc_recovery", rank = 1, replaces = false},

    -- STR
    STR_CROWBAR_D6 = {ability = "str", req = {str = 13}, prereq = {}, family = "str_crowbar_damage", rank = 1, replaces = false},
    STR_CROWBAR_D12 = {ability = "str", req = {str = 15}, prereq = {"STR_CROWBAR_D6"}, family = "str_crowbar_damage", rank = 2, replaces = true},
    STR_CROWBAR_CRUSH = {ability = "str", req = {str = 17}, prereq = {"STR_CROWBAR_D12"}, family = "str_crowbar_crush", rank = 1, replaces = false},
    STR_KNOCKBACK_1 = {ability = "str", req = {str = 13}, prereq = {}, family = "str_pusher", rank = 1, replaces = false},
    STR_KNOCKBACK_2 = {ability = "str", req = {str = 15}, prereq = {"STR_KNOCKBACK_1"}, family = "str_pusher", rank = 2, replaces = true},
    STR_KNOCKBACK_3 = {ability = "str", req = {str = 17}, prereq = {"STR_KNOCKBACK_2"}, family = "str_pusher", rank = 3, replaces = true},
    STR_STEAMROLLER = {ability = "str", req = {str = 17}, prereq = {}, family = "str_steamroller", rank = 1, replaces = false},
    STR_BLEED_PROC_1 = {ability = "str", req = {str = 13}, prereq = {}, family = "str_bleed_proc", rank = 1, replaces = false},
    STR_BLEED_PROC_2 = {ability = "str", req = {str = 15}, prereq = {"STR_BLEED_PROC_1"}, family = "str_bleed_proc", rank = 2, replaces = true},
    STR_BLEED_PROC_3 = {ability = "str", req = {str = 17}, prereq = {"STR_BLEED_PROC_2"}, family = "str_bleed_proc", rank = 3, replaces = true},
    STR_MELEE_REACH = {ability = "str", req = {str = 15}, prereq = {}, family = "str_melee_reach", rank = 1, replaces = false},

    -- WIS
    WIS_SURVEYOR = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_breadcrumb_range", rank = 1, replaces = false},
    WIS_CARTOGRAPHER = {ability = "wis", req = {wis = 15}, prereq = {"WIS_SURVEYOR"}, family = "wis_breadcrumb_range", rank = 2, replaces = true},
    WIS_FRUGAL_MAP = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_frugal_map", rank = 1, replaces = false},
    WIS_MUTE_PROC_1 = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_mute_proc", rank = 1, replaces = false},
    WIS_MUTE_PROC_2 = {ability = "wis", req = {wis = 15}, prereq = {"WIS_MUTE_PROC_1"}, family = "wis_mute_proc", rank = 2, replaces = true},
    WIS_MUTE_PROC_3 = {ability = "wis", req = {wis = 17}, prereq = {"WIS_MUTE_PROC_2"}, family = "wis_mute_proc", rank = 3, replaces = true},
    WIS_HELD_PROC_1 = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_held_proc", rank = 1, replaces = false},
    WIS_HELD_PROC_2 = {ability = "wis", req = {wis = 15}, prereq = {"WIS_HELD_PROC_1"}, family = "wis_held_proc", rank = 2, replaces = true},
    WIS_HELD_PROC_3 = {ability = "wis", req = {wis = 17}, prereq = {"WIS_HELD_PROC_2"}, family = "wis_held_proc", rank = 3, replaces = true},
    WIS_RECKLESS_PROC_1 = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_reckless_proc", rank = 1, replaces = false},
    WIS_RECKLESS_PROC_2 = {ability = "wis", req = {wis = 15}, prereq = {"WIS_RECKLESS_PROC_1"}, family = "wis_reckless_proc", rank = 2, replaces = true},
    WIS_RECKLESS_PROC_3 = {ability = "wis", req = {wis = 17}, prereq = {"WIS_RECKLESS_PROC_2"}, family = "wis_reckless_proc", rank = 3, replaces = true},
    WIS_TRUE_FAITH = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_true_faith", rank = 1, replaces = false},
    WIS_MIND_OVER_MATTER = {ability = "wis", req = {wis = 17}, prereq = {"WIS_TRUE_FAITH"}, family = "wis_mind_over_matter", rank = 1, replaces = false},
    WIS_GPS = {ability = "wis", req = {wis = 17}, prereq = {}, family = "wis_gps", rank = 1, replaces = false},
    WIS_ASTRAL_REACH = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_astral_reach", rank = 1, replaces = false},
    WIS_SPATIAL_AWARENESS = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_spatial_awareness", rank = 1, replaces = false},
    WIS_KILLER_INSTINCT = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_killer_instinct", rank = 1, replaces = false},
    WIS_OMNISCIENCE = {ability = "wis", req = {wis = 17}, prereq = {}, family = "wis_omniscience", rank = 1, replaces = false},
    WIS_SPELLWARD = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_spellward", rank = 1, replaces = false},
    WIS_SPELLBREAKER = {ability = "wis", req = {wis = 15}, prereq = {"WIS_SPELLWARD"}, family = "wis_spellward", rank = 2, replaces = true},
    WIS_SPELLBANE = {ability = "wis", req = {wis = 17}, prereq = {"WIS_SPELLBREAKER"}, family = "wis_spellward", rank = 3, replaces = true},
    WIS_HERO_OF_LEGEND = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_hero_of_legend", rank = 1, replaces = false},
    WIS_FORCEFUL_MAGIC = {ability = "wis", req = {wis = 15}, prereq = {}, family = "wis_forceful_magic", rank = 1, replaces = false},
    WIS_ATTUNEMENT = {ability = "wis", req = {wis = 17}, prereq = {}, family = "wis_attunement", rank = 1, replaces = false},

    -- CHA
    CHA_HITSTUN_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_hitstun_presence", rank = 1, replaces = false},
    CHA_HITSTUN_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_HITSTUN_1"}, family = "cha_hitstun_presence", rank = 2, replaces = true},
    CHA_HITSTUN_3 = {ability = "cha", req = {cha = 17}, prereq = {"CHA_HITSTUN_2"}, family = "cha_hitstun_presence", rank = 3, replaces = true},
    CHA_NERVE_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_nerve", rank = 1, replaces = false},
    CHA_NERVE_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_NERVE_1"}, family = "cha_nerve", rank = 2, replaces = true},
    CHA_MENACE_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_menace", rank = 1, replaces = false},
    CHA_MENACE_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_MENACE_1"}, family = "cha_menace", rank = 2, replaces = true},
    CHA_MENACE_3 = {ability = "cha", req = {cha = 17}, prereq = {"CHA_MENACE_2"}, family = "cha_menace", rank = 3, replaces = true},
    CHA_FEAR_PROC_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_intimidation_proc", rank = 1, replaces = false},
    CHA_FEAR_PROC_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_FEAR_PROC_1"}, family = "cha_intimidation_proc", rank = 2, replaces = true},
    CHA_FEAR_PROC_3 = {ability = "cha", req = {cha = 17}, prereq = {"CHA_FEAR_PROC_2"}, family = "cha_intimidation_proc", rank = 3, replaces = true},
    CHA_PANIC = {ability = "cha", req = {cha = 17}, prereq = {"CHA_MENACE_2"}, family = "cha_panic", rank = 1, replaces = false},
    CHA_ABRASIVE_PERSONALITY_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_personality_aura", rank = 1, replaces = false},
    CHA_NARCISSISM_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_ABRASIVE_PERSONALITY_1"}, family = "cha_personality_aura", rank = 2, replaces = true},
    CHA_MEGALOMANIA_3 = {ability = "cha", req = {cha = 17}, prereq = {"CHA_NARCISSISM_2"}, family = "cha_personality_aura", rank = 3, replaces = true},
    CHA_AURA_BURST_1 = {ability = "cha", req = {cha = 13}, prereq = {}, family = "cha_aura_burst", rank = 1, replaces = false},
    CHA_RADIANCE_2 = {ability = "cha", req = {cha = 15}, prereq = {"CHA_AURA_BURST_1"}, family = "cha_aura_burst", rank = 2, replaces = true},
    CHA_MAJESTY_3 = {ability = "cha", req = {cha = 17}, prereq = {"CHA_RADIANCE_2"}, family = "cha_aura_burst", rank = 3, replaces = true},
    CHA_ACADEMIC_ACHIEVEMENT = {ability = "cha", req = {cha = 15}, prereq = {}, family = "cha_academic_achievement", rank = 1, replaces = false},
    CHA_SELF_ACTUALIZATION = {ability = "cha", req = {cha = 15}, prereq = {}, family = "cha_self_actualization", rank = 1, replaces = false},
    CHA_AGGRESSIVE_PERSONALITY = {ability = "cha", req = {cha = 15}, prereq = {}, family = "cha_aggressive_personality", rank = 1, replaces = false},
    CHA_WINNING_PERSONALITY = {ability = "cha", req = {cha = 17}, prereq = {}, family = "cha_winning_personality", rank = 1, replaces = false},
    WIS_SIXTH_SENSE = {ability = "wis", req = {wis = 13}, prereq = {}, family = "wis_sixth_sense", rank = 1, replaces = false}
}

-- 2. Audit Implementation Feats vs Canonical Set
local implFeats = Catalog.OrdinaryFeats or {}
local l1Feats = Catalog.LevelOneOrdinaryFeats or {}

local implKeys = {}
local implMap = {}
for k, v in pairs(implFeats) do implMap[k] = v end
for k, v in pairs(l1Feats) do if not implMap[k] then implMap[k] = v end end
for k in pairs(implMap) do table.insert(implKeys, k) end
table.sort(implKeys)

local canonicalKeys = {}
for k in pairs(CANONICAL_FEATS) do table.insert(canonicalKeys, k) end
table.sort(canonicalKeys)

print("[AUDIT] Expected Implemented Feats Count: " .. tostring(#canonicalKeys))
print("[AUDIT] Implementation Feats Count: " .. tostring(#implKeys))

local missingIDs = {}
for _, k in ipairs(canonicalKeys) do
    if not implMap[k] then
        table.insert(missingIDs, k)
    end
end
check(#missingIDs == 0, "Missing Canonical Feats: " .. table.concat(missingIDs, ", "))

local extraIDs = {}
for _, k in ipairs(implKeys) do
    if not CANONICAL_FEATS[k] then
        table.insert(extraIDs, k)
    end
end
check(#extraIDs == 0, "Extra Implementation Feats: " .. table.concat(extraIDs, ", "))

-- 3. Detailed Metadata & Restriction Audits
local metadataMismatches = {}
local prereqMismatches = {}
local actorMismatches = {}
local replacementMismatches = {}

for k, spec in pairs(CANONICAL_FEATS) do
    local def = implMap[k]
    if def then
        local abMatch = def.governingAbilities and def.governingAbilities[1] == spec.ability
        local thresholdMatch = true
        for ab, val in pairs(spec.req) do
            if not def.abilityRequirements or def.abilityRequirements[ab] ~= val then
                thresholdMatch = false
                break
            end
        end
        if not abMatch or not thresholdMatch then
            table.insert(metadataMismatches, k)
        end

        local pMatch = true
        local defP = def.prerequisiteFeatIds or {}
        if #defP ~= #spec.prereq then pMatch = false
        else
            for i, p in ipairs(spec.prereq) do
                if defP[i] ~= p then pMatch = false break end
            end
        end
        if not pMatch then
            table.insert(prereqMismatches, k .. " (got [" .. table.concat(defP, ",") .. "], expected [" .. table.concat(spec.prereq, ",") .. "])")
        end

        if (def.replacesLowerRank or false) ~= spec.replaces or (def.rankIndex or 1) ~= spec.rank then
            table.insert(replacementMismatches, k)
        end
    end
end

check(#metadataMismatches == 0, "Metadata Mismatch IDs: " .. table.concat(metadataMismatches, ", "))
check(#prereqMismatches == 0, "Prerequisite Mismatch IDs: " .. table.concat(prereqMismatches, "; "))
check(#replacementMismatches == 0, "Replacement Ladder Mismatch IDs: " .. table.concat(replacementMismatches, ", "))

-- 4. Require a real loaded production consumer for every listed family. Handler
-- labels alone are never proof: periodic families require their installed service.
-- Focused integrated suites exercise arithmetic and event producers separately.
local S, X, M = LOD.RPGStatusElements, LOD.RPGCrossFeats, LOD.MagicProgression
local consumers = {
    academic_magic_regeneration = Effects.AcademicMagicRegenMultiplier,
    aggressive_personality_damage = RPG.ObserveDirectChaDamage,
    ammo_regeneration_floor = Effects.AmmoRegenProfile,
    arcane_disruption_proc = S.ResolveStatusProcFamilies,
    backpedal_movement = Rules.ApplyVoluntaryMovementFeats,
    big_guy_body_scale = Rules.PlayerTargetScale,
    canonical_gps_navigation = observedTimers.LOD_CheckpointDWisGPS,
    cha_hitstun_presence = Rules.HitStunMultiplier,
    cloud_step = Rules.TryCloudStep,
    con_blast_proof = Effects.BlastProofTargetContract,
    cross_big_scary = X.MoraleBonus,
    cross_boom_battery = X.RestoreBoomBattery,
    cross_crush_panic = S.ObserveDamage,
    cross_force_of_will = X.BridgeMagicPush,
    cross_meteor_strike = X.AugmentMeteor,
    cross_tiny_terror = X.MoraleBonus,
    crowbar_family = Effects.ResolveCrowbarPushRequest,
    dex_burst_size = Rules.ResolveBurstSize,
    dex_exploding_damage_dice = Effects.ApplyExplodingDiceToDamageProfile,
    dex_rate_of_fire = Effects.ProcessAttackRateObservation,
    dex_reload_cadence = Effects.ProcessReloadObservation,
    dex_smg_heat = Effects.ResolveSMGHeatSuppression,
    direct_look_hostile_information = observedTimers.LOD_CheckpointDWisInformation,
    float_on = Rules.TickFloatOn,
    forceful_magic_push = Effects.ResolvePushDistance,
    mana_barrier_diversion = Rules.ComputeMagicDiversion,
    glow_up_cha_damage_rider = Rules.AddChaModDerivedDamage,
    grant_distinct_magic_content = M.ApplyCheckpointDMagicGrantFeat,
    grant_distinct_magic_form = M.ApplyCheckpointDMagicGrantFeat,
    haste_sustained_movement = Rules.HasteDrainPerSecond,
    health_regeneration = Effects._TickActor,
    incoming_magical_damage_reduction = Rules.ApplyWisDefense,
    incoming_physical_damage_reduction_cooldown = Rules.ApplyWisDefense,
    lateral_strafe = Effects.ResolveStrafeInput,
    little_guy_body_scale = Rules.PlayerTargetScale,
    magic_continuation_recovery = Effects.ApplyFeedbackLoop,
    magic_kill_recovery = Effects.ApplyArcRecovery,
    magic_save_bonus = S.ConditionSave,
    magic_spatial_bonus_cells = LOD.MagicForms.SpatialBonusCells,
    magnum_deadeye = Rules.AimHoldSeconds,
    mana_spring_regeneration = Effects.ResolveManaSpringTick,
    map_open_movement = Rules.MovementMultiplier,
    melee_reach = Rules.MeleeReach,
    morale_dc_intimidation = S.MoraleDC,
    morale_failure_cascade = S.CascadeMorale,
    morale_proc_family = S.ResolveStatusProcFamilies,
    morale_save_bonus = S.MoraleSave,
    not_yet_death_prevention = Rules.ApplyNotYetDefense,
    personality_aura_pulse = observedHooks.LOD_CheckpointDPersonalityAura,
    private_killer_instinct_priority = observedTimers.LOD_CheckpointDKillerInstinct,
    private_sixth_sense_perception = observedTimers.LOD_CheckpointDSixthSense,
    pusher_weapon_knockback = Effects.TryPusherProc,
    quantum_offensive_cost = Rules.OffensiveMagicCost,
    rear_hostile_awareness = observedTimers.LOD_CheckpointDWisInformation,
    russian_asset = Rules.TetrisOverfillMultiplier,
    self_actualization_magic_damage = Rules.ResolveDamageContract,
    size_shifter = Rules.ApplySizeShifterScale,
    spring_heel = observedHooks.LOD_RPG_GateE_SpringHeel,
    status_proc_family = S.ResolveStatusProcFamilies,
    steadfast_control_resistance = Effects.ResolvePushDistance,
    steamroller_push_save = LOD.Pushback.ResolveSharedPushSave,
    summon_active_cap = M.MaxActiveSummons,
    triggered_magic_aura_burst = observedHooks.LOD_CheckpointDAuraBurst,
    wall_jump = Rules.TryWallJump,
    weakness_bonus_advantage = S.ResolveElementDamage,
    winning_personality_qualification = Effects.WinningPersonalityQualificationScore,
    wis_navigation = Rules.MapDrainPerSecond,
}
for id, definition in pairs(implMap) do
    check(type(consumers[definition.effectHandlerId]) == "function",
        "Missing loaded consumer: " .. id .. ":" .. tostring(definition.effectHandlerId))
end
local function sourceContains(file, token)
    local f = assert(io.open("gamemodes/legend_of_deborah/gamemode/lod/" .. file, "r"))
    local text = f:read("*a"); f:close()
    return text:find(token, 1, true) ~= nil
end
check(sourceContains("sv_magic_forms.lua", 'hook.Run("LODDiscreteMagicSpent", ply, cost, context)'), "Aura Burst activation producer missing")
check(sourceContains("sv_pushback.lua", 'attackerDerived.steamrollerSuccessfulSaveFraction'), "Steamroller shared save consumer missing")
check(sourceContains("sv_smg_capacity_rebalance.lua", 'derived.ammoRegenFloorFraction'), "ammo-regeneration consumer missing")
check(sourceContains("sv_soldier_shot_contract.lua", 'rules:RateOfFireMultiplier(self)'), "AI attack cadence consumer missing")

-- 5. Class Capstones Validation (Fighter, Rogue, Wizard)
local CANONICAL_CAPSTONES = {
    fighter = {"FTR_CAP_ONE_PERSON_ARMY", "FTR_CAP_BUILT_DIFFERENT", "FTR_CAP_UNSTOPPABLE_FORCE"},
    rogue = {"ROG_CAP_LOADED_DICE", "ROG_CAP_NOW_YOU_SEE_ME", "ROG_CAP_ACE_IN_THE_HOLE"},
    wizard = {"WIZ_CAP_ARCHMAGE", "WIZ_CAP_MANA_ENGINE", "WIZ_CAP_LIVING_AEGIS"}
}

local capCatalog = Catalog.ClassCapstones or {}
local capMismatches = {}
for classId, expectedList in pairs(CANONICAL_CAPSTONES) do
    local cDefs = capCatalog[classId] or {}
    for _, expId in ipairs(expectedList) do
        if not cDefs[expId] then
            table.insert(capMismatches, classId .. ":" .. expId)
        end
    end
end

check(#capMismatches == 0, "Class Capstone Mismatches: " .. table.concat(capMismatches, ", "))

-- 6. Cadence & Level-20+ Suppression Check
LOD.RunManager = {
    GetPlayerState = function(_, ply)
        local state = (type(ply) == "table" and ply.classId) and ply or (ply and ply.progressionState)
        return { progressionState = state }
    end,
    State = { Level = 20, CampaignSeed = 12345 }
}

local testState = CPS:NewProgressionState("cadence-test", "hero", "hero")
testState.baseAbilities = RPG.NewAbilityBlock(18)
testState.classId = "wizard"

CPS:AdvanceHeroToLevel(testState, 20)
check(testState.level == 20, "hero reaches level 20")
check(testState.featSlotsGranted == 7, "hero grants 7 feat slots by level 20")

local featSlotsAt20 = testState.featSlotsGranted or 0
CPS:AdvanceHeroToLevel(testState, 21)
local featSlotsAt21 = testState.featSlotsGranted or 0
check(featSlotsAt21 == featSlotsAt20, "level 21 grants zero new ordinary feat slots")

-- Report Final Closure Status
if #errors == 0 then
    print("[CHECKPOINT_D_CLOSURE] PASS — Implemented inventory: 135 ordinary feats and 9 capstones checked. Live-GDD completeness is a separate release gate.")
else
    print("[CHECKPOINT_D_CLOSURE] FAIL — Discrepancies found:")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
    error("Checkpoint D closure validation failed")
end
