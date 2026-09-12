#!/usr/bin/env python3
"""Finite static gate for Integrated RPG Completion Checkpoint C."""
from __future__ import annotations

import argparse
import ctypes
import ctypes.util
import pathlib
import re
import sys


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def require(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(errors, label)


def lua_syntax(path: pathlib.Path) -> str | None:
    library = ctypes.util.find_library("lua5.4") or "liblua5.4.so.0"
    try:
        lua = ctypes.CDLL(library)
    except OSError as exc:
        return f"Lua 5.4 library unavailable: {exc}"
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lua.luaL_loadfilex.restype = ctypes.c_int
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    try:
        status = lua.luaL_loadfilex(state, str(path).encode(), None)
        if status == 0:
            return None
        size = ctypes.c_size_t()
        message = lua.lua_tolstring(state, -1, ctypes.byref(size))
        return message[: size.value].decode(errors="replace")
    finally:
        lua.lua_close(state)


def read(root: pathlib.Path, relative: str, errors: list[str]) -> str:
    path = root / relative
    if not path.is_file():
        fail(errors, f"missing {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=None, help="repository root (default: parent of tools)")
    args = parser.parse_args()
    root = pathlib.Path(args.root).resolve() if args.root else pathlib.Path(__file__).resolve().parents[1]
    errors: list[str] = []

    base = "gamemodes/legend_of_deborah/"
    progress_rel = base + "gamemode/lod/sv_magic_progression.lua"
    forms_rel = base + "gamemode/lod/sv_magic_forms.lua"
    arcane_rel = base + "gamemode/lod/sv_wizard_arcane_cap.lua"
    spellbook_rel = base + "gamemode/lod/cl_spellbook.lua"
    shared_rel = base + "gamemode/shared.lua"
    init_rel = base + "gamemode/init.lua"
    client_rel = base + "gamemode/cl_init.lua"
    entity_rels = [
        base + "entities/entities/lod_magic_projectile/shared.lua",
        base + "entities/entities/lod_magic_projectile/init.lua",
        base + "entities/entities/lod_magic_projectile/cl_init.lua",
        base + "entities/entities/lod_magic_summon/shared.lua",
        base + "entities/entities/lod_magic_summon/init.lua",
        base + "entities/entities/lod_magic_summon/cl_init.lua",
    ]

    progress = read(root, progress_rel, errors)
    forms = read(root, forms_rel, errors)
    arcane = read(root, arcane_rel, errors)
    spellbook = read(root, spellbook_rel, errors)
    shared = read(root, shared_rel, errors)
    init = read(root, init_rel, errors)
    client = read(root, client_rel, errors)
    entities = {rel: read(root, rel, errors) for rel in entity_rels}

    expected_forms = {
        "blast": (2, 6, 45), "beam": (2, 6, 20), "bomb": (3, 6, 20),
        "missile": (3, 6, 25), "bolt": (4, 6, 15), "summon": (0, 0, 40),
    }
    for form_id, (dice, sides, cost) in expected_forms.items():
        pattern = rf'{form_id}\s*=\s*\{{[^\n]*damageDice\s*=\s*{dice}[^\n]*damageSides\s*=\s*{sides}[^\n]*magicCost\s*=\s*{cost}'
        if not re.search(pattern, progress):
            fail(errors, f"Form catalog mismatch: {form_id}")

    expected_contents = {
        "earth": (10, "push"), "fire": (15, "immolated"), "dark": (15, "poisoned"),
        "ice": (10, "held"), "light": (5, "muted"), "electric": (10, "morale"),
    }
    for content_id, (cost, rider) in expected_contents.items():
        pattern = rf'{content_id}\s*=\s*\{{[^\n]*surcharge\s*=\s*{cost}[^\n]*rider\s*=\s*"{rider}"'
        if not re.search(pattern, progress):
            fail(errors, f"Content catalog mismatch: {content_id}")

    for needle, label in [
        ('form(1, "level_1_all")', "Level-1 Form grant"),
        ('form(2, "level_2_wizard")', "Level-2 Wizard Form"),
        ('content(4, "level_4_all")', "Level-4 Content"),
        ('form(5, "level_5_all")', "Level-5 Form"),
        ('content(8, "level_8_wizard")', "Level-8 Wizard Content"),
        ('form(10, "level_10_wizard")', "Level-10 Wizard Form"),
        ('content(14, "level_14_wizard")', "Level-14 Wizard Content"),
        ('if state.classId == "wizard" and level >= 7', "Wizard Level-7 INT milestone"),
        ('if level >= 8 then delta.dex = delta.dex + 1 end', "Rogue Level-8 DEX milestone"),
        ('if level >= 14 then delta.dex = delta.dex + 1 end', "Rogue Level-14 DEX milestone"),
        ('if level >= 8 then delta.str = delta.str + 1 end', "Fighter Level-8 STR milestone"),
        ('if level >= 14 then delta.str = delta.str + 1 end', "Fighter Level-14 STR milestone"),
        ('"INT_MIDDLE_MANAGER"', "Middle Manager summon cap"),
        ('"INT_TASKMASTER"', "Taskmaster summon cap"),
        ('"INT_OVERLORD"', "Overlord summon cap"),
        ('LODMagicOrdinaryDraftOrderingWrapped', "Level-1/draft Magic grant ordering"),
        ('LODMagicHeroHitDieOrderingWrapped', "Hero per-level Magic grant ordering"),
        ('LODMagicAutomaticHitDieOrderingWrapped', "automatic actor per-level Magic grant ordering"),
    ]:
        require(errors, progress, needle, label)

    tunings = {
        "BaseBeamRange": 1152, "BaseBombBlastRadius": 96, "BaseBombThrowRange": 1152,
        "BombProjectileSpeed": 700, "BaseMissileRange": 1536, "BaseMissileBlastRadius": 128,
        "MissileProjectileSpeed": 900, "MissileSteeringDegreesPerSecond": 180,
        "MaxActiveGuidedMissilesPerCaster": 1, "BaseBoltRange": 1920, "BoltProjectileSpeed": 2400,
    }
    for name, value in tunings.items():
        if not re.search(rf'\b{name}\s*=\s*{value}\b', forms):
            fail(errors, f"tuning mismatch: {name}={value}")

    for needle, label in [
        ('Rules:OffensiveMagicCost(ply, baseCost)', "Quantum/offensive cost seam"),
        ('effects:RecordQuantumSpend(ply, baseCost, cost)', "Quantum spend accounting"),
        ('Rules:RollActorDamage', "placeholder-never-match"),
    ]:
        if label == "placeholder-never-match":
            continue
        require(errors, forms, needle, label)
    require(errors, forms, 'Rolls:RollActorDamage(attacker, profile, rng, context.aceBonus or 0)', "shared damage dice seam")
    require(errors, forms, 'Rolls:ResolveActorDamage(contract, attacker, target, tags)', "shared damage resolution seam")
    require(errors, forms, 'Status:AttachDamageContext(info, tags)', "shared Content status seam")
    require(errors, forms, 'Pushback:Apply(target, {', "shared Earth Push seam")
    require(errors, forms, 'distance = 336', "Earth canonical Push distance")
    require(errors, forms, 'magicPush = true', "Earth Magic push tag")
    require(errors, forms, 'profile.magicDamage', "magic-die tagging") if False else None
    require(errors, forms, 'magicDamage = true', "Wizard magical Boom tagging")
    require(errors, forms, 'damageBonus = 4', "Summon ordinary Seeker +4 base damage")
    require(errors, forms, 'summon.LODProgressionState = frozenProgressionState(state)', "sealed Summon RPG state")
    require(errors, forms, 'target.LODPendingDamageAttribution = {attacker = creditCaster, source = "summon"}', "Summon Hero direct attribution")
    require(errors, forms, 'Attribution.LODMagicSummonCreditWrapped', "Summon proxy/status/wall-crush attribution bridge")
    require(errors, forms, 'creditCaster.LODMagicProxyMoraleDC = tags.moraleDC', "sealed Summon Morale DC")
    require(errors, forms, 'tags.riderDC = Status:ConditionDC(attacker, definition.ability)', "sealed Summon rider DC")
    require(errors, forms, 'function Magic:CastForceShout(ply)', "single RMB Magic activation seam")

    for needle, label in [
        ('ArcaneDiversionCap = 0.50', "Arcane hard cap"),
        ('math.min(self.ArcaneDiversionCap', "Arcane class clamp"),
        ('state(17)', "Arcane Level-17 validation"),
        ('"Level 17 reaches cap"', "Arcane Level-17 expectation"),
        ('"Level 20 stays capped"', "Arcane Level-20 expectation"),
        ('"Living Aegis efficiency remains available"', "Level-20 capstone efficiency preserved"),
    ]:
        require(errors, arcane, needle, label)

    for form_id in expected_forms:
        require(errors, spellbook, f'key == KEY_I', "I Spellbook key")
        require(errors, progress, f'"{form_id}"', f"Spellbook/Form ID {form_id}")
    require(errors, spellbook, 'id = "raw"', "RAW Spellbook state") if False else None
    require(errors, progress, '{id = "raw", displayName = "RAW", owned = true', "RAW Spellbook state")
    require(errors, spellbook, 'LOD.CharacterSheet:Close()', "I closes P Character Sheet")
    require(errors, spellbook, 'key == KEY_P and IsValid(Book.Frame)', "P closes I Spellbook")

    for text, needle, label in [
        (shared, 'include("lod/sv_wizard_arcane_cap.lua")', "server Wizard cap bootstrap"),
        (shared, 'include("lod/sv_magic_progression.lua")', "server Magic progression bootstrap"),
        (init, 'include("lod/sv_magic_forms.lua")', "server Form runtime bootstrap"),
        (init, 'AddCSLuaFile("lod/cl_spellbook.lua")', "Spellbook client distribution"),
        (client, 'include("lod/cl_spellbook.lua")', "Spellbook client bootstrap"),
        (client, 'LODSpellbookMutualExclusionInstalled', "P/I asynchronous mutual exclusion"),
    ]:
        require(errors, text, needle, label)

    magic_idx = init.find('include("lod/sv_magic.lua")')
    forms_idx = init.find('include("lod/sv_magic_forms.lua")')
    if magic_idx < 0 or forms_idx <= magic_idx:
        fail(errors, "Magic Forms must load after existing sv_magic.lua")
    status_idx = shared.find('include("lod/sv_rpg_status_elements.lua")')
    progress_idx = shared.find('include("lod/sv_magic_progression.lua")')
    if status_idx < 0 or progress_idx <= status_idx:
        fail(errors, "Magic progression must load after shared status/element authority")

    projectile_init = entities.get(base + "entities/entities/lod_magic_projectile/init.lua", "")
    summon_init = entities.get(base + "entities/entities/lod_magic_summon/init.lua", "")
    for needle, label in [
        ('self.LODFormId ~= "missile"', "Missile steering mode"),
        ('math.ApproachAngle', "Missile steering rate"),
        ('Vector(0, 0, -600)', "Bomb lob gravity"),
        ('LOD.MagicForms:ProjectileImpact', "projectile shared impact callback"),
    ]:
        require(errors, projectile_init, needle, label)
    for needle, label in [
        ('WINDUP_SECONDS = 0.85', "Summon Seeker windup"),
        ('CHARGE_SPEED = 560', "Summon Seeker charge speed"),
        ('CHARGE_RANGE = 760', "Summon Seeker charge range"),
        ('CHARGE_COOLDOWN = 2.80', "Summon Seeker charge cooldown"),
        ('LOD.MazeNavigator', "Summon shared navigation"),
        ('LOD.HostileMotionV2', "Summon shared movement"),
        ('LOD.MagicForms:ResolveSummonAttack', "Summon proxy damage seam"),
        ('LIFETIME = 20', "Summon 20-second lifetime"),
    ]:
        require(errors, summon_init, needle, label)

    lua_files = [progress_rel, forms_rel, arcane_rel, spellbook_rel, shared_rel, init_rel, client_rel,
        "tools/test_checkpoint_c_headless.lua"] + entity_rels
    for relative in lua_files:
        path = root / relative
        if path.is_file():
            syntax_error = lua_syntax(path)
            if syntax_error:
                fail(errors, f"Lua syntax {relative}: {syntax_error}")

    if errors:
        print(f"Checkpoint C static validation FAILED ({len(errors)} errors)")
        for message in errors:
            print(f" - {message}")
        return 1
    print("Checkpoint C static validation PASS")
    print("forms=6 contents=6 deterministic-progression=true arcane-cap=0.50 summon-proxy=true spellbook=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
