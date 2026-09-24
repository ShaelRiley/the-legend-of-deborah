# The Legend of Deborah — 256 Procedural Shipping-Container Brand Textures

## Overview & Purpose
This asset archive provides **exactly 256 distinct fictional shipping-container company branding textures** created for ***The Legend of Deborah***, a procedural cooperative survival-maze game built in Garry’s Mod.

In *The Legend of Deborah*, the survival maze is constructed largely from shipping containers. Rather than exposing players to repetitive stock Source/Garry’s Mod branding (such as Northern Petrol) across every single game, this asset library enables rich run-to-run corporate variety while maintaining procedural aesthetic consistency.

### The "One Run = One Fictional Company" Rule
- **Procedural Run Seed Selection**: At the start of dungeon generation, the game engine uses the run seed to select exactly **one brand ID** from the 256 available companies.
- **Dungeon-Wide Consistency**: That single company becomes the apparent owner, operator, or logistics contractor of all shipping containers generated throughout that entire run.
- **No Chaotic Mixing**: The engine does **not** randomly shuffle or mix brands between individual containers within a normal run. The visual variety happens *between runs*, creating distinct thematic atmospheres (e.g., an abandoned cryogenic pharmaceutical warehouse in one run, a post-apocalyptic grain reserve in another, a synthetic fuel refinery in a third, and an unhinged private equity logistics terminal in a fourth).
- **Special Encounter (ID 256)**: Brand `256` represents *Deborah Logistics Unlimited* ("Everything Everywhere. All The Time."), the enigmatic parent entity behind the labyrinthine maze itself.

---

## Technical Specifications

| Property | Value / Specification |
| :--- | :--- |
| **Asset Count** | Exactly 256 unique texture files (`container_brand_001.png` to `container_brand_256.png`) |
| **Canvas Dimensions** | **1024 × 512 pixels** (2:1 aspect ratio, power-of-two for Source engine mipmapping) |
| **Color Space / Format** | 32-bit RGBA lossless PNG with alpha transparency channel |
| **Background** | Transparent (`RGBA(0, 0, 0, 0)`). No baked hull paint. |
| **Visual Architecture** | Value-first dual-layer contrast (high-contrast core with protective dark/light keylines) |
| **Footprint** | Horizontal industrial door/side placard layout matching standard 20ft/40ft ISO container flutes |

---

## Procedural Recoloring Architecture (Crucial Gameplay Requirement)

### Gameplay-Authoritative Coloration
In *The Legend of Deborah*, shipping container paint color is **gameplay-authoritative information**:
1. **Dungeon Floor** identification (e.g., Sub-Level 1 vs. Sub-Level 4)
2. **Quadrant / Sector / Wing** orientation (e.g., Sector North vs. Sector West)
3. **Hazard / Navigation State** (safe zones, high-threat radiation wings, extraction depots)

### Value Before Hue Design
Because the game recolors container hulls dynamically and procedurally independently of the branding decal, **no brand texture relies on a fixed container background color**.
Every asset was designed under strict value contrast principles:
- **Dual-Value Keylining**: Lettering, emblems, dividing rules, and hazard borders are constructed with high-contrast luminance separation (e.g., crisp white `#FFFFFF` fills paired with deep charcoal `#0B0E14` outer strokes, or dark stencil badges framed with light borders).
- **Universal Container Legibility**: The textures remain 100% readable over:
  - Pitch-black / weathered dark containers (`#111418`)
  - Crisp white / light gray refrigerated reefer containers (`#F0F2F5`)
  - Saturated primary color containers (safety yellow, signal red, cobalt blue)
  - Muted earth tones (olive drab, rust orange, desert tan, oxide brown)
- **Grayscale Verification**: If any asset is rendered in pure grayscale over any background value (from 0% to 100% luminance), the typography and emblem silhouette remain clearly legible.

---

## Source / Garry's Mod Material Integration Guide

To integrate these textures into the Source Engine / Garry’s Mod asset pipeline:

### 1. Texture Compilation (VTF)
Convert the PNG files to Valve Texture Format (`.vtf`) using `vtex.exe`, `VTFEdit`, or CLI batch tools:
- **Format**: `DXT5` (for compressed RGBA with smooth alpha) or `RGBA8888` (for uncompressed maximum fidelity).
- **Flags**:
  - `Clamp S` and `Clamp T` (to prevent edge bleeding on decals)
  - `No Minimum Mipmap`
  - `Normal Mipmaps` enabled for distant LOD performance.

### 2. Material Definition (VMT)
Two primary integration patterns are recommended depending on your shader setup:

#### Option A: Projected Decal / Overlay Material (`$decal 1`)
```vmt
"VertexLitGeneric"
{
    "$basetexture" "models/props_c17/container_brands/container_brand_001"
    "$translucent" "1"
    "$decal" "1"
    "$decalscale" "0.25"
    "$model" "1"
    "$surfaceprop" "metal"
}
```

#### Option B: Multi-Layer Detail / Modulate Shader
For a model where the container base color is set via `$color2` or a proxy material:
```vmt
"VertexLitGeneric"
{
    "$basetexture" "models/props_c17/container_base_corrugated"
    "$blendtintbybasealpha" "1"
    "$detail" "models/props_c17/container_brands/container_brand_001"
    "$detailscale" "1"
    "$detailblendmode" "2" // Translucent decal composite
    "$detailblendfactor" "1.0"
    "$surfaceprop" "metal"
}
```

---

## Directory Structure
```
legend_of_deborah_container_brands_256/
├── textures/
│   ├── container_brand_001.png
│   ├── container_brand_002.png
│   ├── ...
│   └── container_brand_256.png   (exactly 256 individual files)
├── manifest.json                  (machine-readable full metadata catalog)
├── manifest.csv                   (spreadsheet/data catalog)
├── README.md                      (this technical specification document)
├── generation_notes.md            (creative principles & implementation details)
└── contact_sheet.png              (16x16 visual proof sheet for human review)
```

---

## Manifest Data Schema
Both `manifest.json` and `manifest.csv` contain the following fields for every asset from ID `001` to `256`:
- **`id`**: 3-digit zero-padded unique identifier (`001` through `256`).
- **`filename`**: File name corresponding to the texture in `textures/`.
- **`company_name`**: The fictional corporate entity name.
- **`slogan`**: The official corporate motto or slogan.
- **`category`**: Industrial sector and trade specialization.
- **`concept`**: One-sentence narrative concept explaining corporate backstory and tone.
- **`visual_description`**: Summary of the visual mark, typography, and layout.
- **`motif`**: The primary geometric or iconographic symbol.
- **`typography`**: Typographic character and classification.
- **`recolor_notes`**: Specific notes detailing contrast behavior under procedural container recoloring.
