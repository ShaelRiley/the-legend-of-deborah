#!/usr/bin/env python3
"""Correct V15 full-face topology classification to the manifest's 1..4 DIRS indices."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"

OLD = '''    local ax, ay, bx, by, orientation
    if direction == 0 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y + 1, 2 * x + 1, 2 * y + 1, "h"
    elseif direction == 2 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x + 1, 2 * y - 1, "h"
    elseif direction == 1 then
        ax, ay, bx, by, orientation = 2 * x + 1, 2 * y - 1, 2 * x + 1, 2 * y + 1, "v"
    else
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x - 1, 2 * y + 1, "v"
    end
'''

NEW = '''    local ax, ay, bx, by, orientation
    -- DIRS is a normal Lua array: 1=north, 2=east, 3=south, 4=west.
    if direction == 1 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y + 1, 2 * x + 1, 2 * y + 1, "h"
    elseif direction == 3 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x + 1, 2 * y - 1, "h"
    elseif direction == 2 then
        ax, ay, bx, by, orientation = 2 * x + 1, 2 * y - 1, 2 * x + 1, 2 * y + 1, "v"
    elseif direction == 4 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x - 1, 2 * y + 1, "v"
    else
        return nil
    end
'''


def main():
    text = WALLS.read_text(encoding="utf-8")
    if NEW in text:
        print("V15.1 direction mapping already correct")
        return
    count = text.count(OLD)
    if count != 1:
        raise SystemExit(f"expected one legacy V15 direction block, found {count}")
    WALLS.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print("V15.1 corrected full-face direction mapping to 1=north 2=east 3=south 4=west")


if __name__ == "__main__":
    main()
