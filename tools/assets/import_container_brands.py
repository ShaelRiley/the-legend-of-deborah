#!/usr/bin/env python3
"""Import the authoritative 256-brand archive into the mounted GMod gamemode content."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
import zipfile
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
BRAND_RE = re.compile(r"(?:^|/)textures/container_brand_(\d{3})\.png$")
EXPECTED_IDS = {f"{i:03d}" for i in range(1, 257)}
EXPECTED_WIDTH = 1024
EXPECTED_HEIGHT = 512
EXPECTED_BIT_DEPTH = 8
EXPECTED_COLOR_TYPE = 6  # RGBA

RUNTIME_REL = Path(
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_brands"
)
DOCS_REL = Path("docs")


def png_ihdr(data: bytes) -> tuple[int, int, int, int]:
    if len(data) < 33 or data[:8] != PNG_SIGNATURE:
        raise ValueError("not a PNG")
    length = struct.unpack(">I", data[8:12])[0]
    chunk_type = data[12:16]
    if length != 13 or chunk_type != b"IHDR":
        raise ValueError("missing canonical IHDR")
    width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, bit_depth, color_type


def find_member(names: list[str], basename: str) -> str:
    matches = [name for name in names if name == basename or name.endswith("/" + basename)]
    if len(matches) != 1:
        raise ValueError(f"expected exactly one {basename}, found {len(matches)}")
    return matches[0]


def import_archive(zip_path: Path, repo_root: Path) -> None:
    if not zip_path.is_file():
        raise FileNotFoundError(zip_path)

    runtime_dir = repo_root / RUNTIME_REL
    docs_dir = repo_root / DOCS_REL
    runtime_dir.mkdir(parents=True, exist_ok=True)
    docs_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path) as archive:
        names = [info.filename for info in archive.infolist() if not info.is_dir()]

        textures: dict[str, str] = {}
        for name in names:
            match = BRAND_RE.search(name)
            if match:
                brand_id = match.group(1)
                if brand_id in textures:
                    raise ValueError(f"duplicate brand ID {brand_id}")
                textures[brand_id] = name

        actual_ids = set(textures)
        if actual_ids != EXPECTED_IDS:
            missing = sorted(EXPECTED_IDS - actual_ids)
            extra = sorted(actual_ids - EXPECTED_IDS)
            raise ValueError(
                f"brand ID set mismatch; missing={missing[:8]} extra={extra[:8]}"
            )

        # Remove stale runtime textures only after the source archive passes its
        # structural ID check. The directory is dedicated exclusively to this set.
        for old in runtime_dir.glob("container_brand_*.png"):
            old.unlink()

        for brand_id in sorted(EXPECTED_IDS):
            data = archive.read(textures[brand_id])
            width, height, bit_depth, color_type = png_ihdr(data)
            if (width, height) != (EXPECTED_WIDTH, EXPECTED_HEIGHT):
                raise ValueError(
                    f"brand {brand_id}: expected 1024x512, got {width}x{height}"
                )
            if bit_depth != EXPECTED_BIT_DEPTH or color_type != EXPECTED_COLOR_TYPE:
                raise ValueError(
                    f"brand {brand_id}: expected 8-bit RGBA PNG, "
                    f"got bit_depth={bit_depth} color_type={color_type}"
                )
            (runtime_dir / f"container_brand_{brand_id}.png").write_bytes(data)

        manifest_member = find_member(names, "manifest.json")
        manifest_bytes = archive.read(manifest_member)
        manifest = json.loads(manifest_bytes.decode("utf-8"))
        if not isinstance(manifest, list) or len(manifest) != 256:
            raise ValueError("manifest must contain exactly 256 entries")
        manifest_ids = {str(item.get("id", "")) for item in manifest if isinstance(item, dict)}
        if manifest_ids != EXPECTED_IDS:
            raise ValueError("manifest IDs do not exactly match 001..256")
        (docs_dir / "CONTAINER_BRAND_MANIFEST.json").write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

        readme_member = find_member(names, "README.md")
        notes_member = find_member(names, "generation_notes.md")
        (docs_dir / "CONTAINER_BRAND_SOURCE_README.md").write_bytes(
            archive.read(readme_member)
        )
        (docs_dir / "CONTAINER_BRAND_GENERATION_NOTES.md").write_bytes(
            archive.read(notes_member)
        )

    print(
        f"Imported 256 full-resolution brand PNGs to {RUNTIME_REL} "
        f"and preserved source metadata under {DOCS_REL}."
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
    )
    args = parser.parse_args()

    try:
        import_archive(args.archive.resolve(), args.repo_root.resolve())
    except Exception as exc:
        print(f"container-brand import failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
