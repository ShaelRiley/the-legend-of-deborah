# The Legend of Deborah — Asset Generation & Engineering Notes

## Creative Architecture & Design Philosophy

### 1. Tonal Calibration: The Believable Dystopia
The creative mission for the 256 shipping container brands was guided by a strict principle:
> **At least 80% of these companies should appear so plausible that, outside the game, an observer might genuinely believe they exist.**

Rather than filling the maze with cartoonish parody brands or overt joke names, comedy and dread emerge from:
- **Corporate Euphemism**: Friendly, cheerful slogans masking extraction, algorithmic exploitation, or industrial indifference (e.g., *Continuance Foods* — "Tomorrow Still Needs Lunch.", *HumanMetric Logistics* — "Maximizing Worker Unit Output.", *Apex Horizon Capital Partners* — "Optimizing Human and Material Assets.").
- **Historical Verisimilitude**: Companies spanning distinct institutional eras:
  - 19th-century foundry and mining roots (e.g., *Vulcan Valve & Flange*, *Keystone Brick & Tile*, *Oakhaven Lube & Greasing*).
  - Mid-20th-century national infrastructural titans (e.g., *Northern Petrol*, *Great Northern Pulp & Box*, *Monarch Pump Works*).
  - Aggressive 1980s B2B contractors and cold-chain consolidators (e.g., *Formwork Sealants*, *HarvestLine Frozen Bulk*, *Pelican Wharf Logistics*).
  - 2026 Contemporary Realities: AI cluster infrastructure, immersion cooling, synthetic food biomass, algorithmic gig-warehousing, and venture-backed prepper survival caches (e.g., *Orthogonal Compute*, *CoreMatrix Thermal Systems*, *Vitalis Algal Paste*, *SubTerra Vault Systems*).
- **Garry's Mod & Source Cultural Undercurrent**: Capturing the deadpan industrial surrealism of the Source engine, where forgotten concrete corridors, rusted maritime hulls, and locked metal doors carry corporate markings that have silently presided over the environment for decades.
- **Climax Lore Branding (#256)**: Company `256` is *Deborah Logistics Unlimited* ("Everything Everywhere. All The Time."), the meta-corporate operator of the maze itself, featuring an impossible Escher-like looping labyrinth emblem.

### 2. Sector Distribution (Balanced Variety)
The 256 companies are systematically distributed across 14 comprehensive industrial sectors to prevent over-indexing on any single theme:
1. **Petroleum, Lubricants, Solvents & Heavy Fuels** (IDs 001–020)
2. **Logistics, Freight, Rail, Intermodal & Port Handling** (IDs 021–040)
3. **Chemicals, Polymers, Adhesives, Resins & Solvents** (IDs 041–060)
4. **Food, Frozen Storage, Shelf-Stable Rations & Institutional Nutrition** (IDs 061–080)
5. **AI Infrastructure, Data Center Hardware, Immersion Cooling & Robotics** (IDs 081–100)
6. **Biotech, Pharmaceuticals, Clinical Supplies & Life Sciences** (IDs 101–120)
7. **Waste Management, Hazmat Remediation, Scrap Recycling & Slag** (IDs 121–140)
8. **Defense-Adjacent Manufacturing, Perimeter Security & Surveillance** (IDs 141–160)
9. **Emergency Preparedness, Bunker Systems & Disaster Recovery** (IDs 161–180)
10. **Paper Products, Cardboard, Pulp Milling & Industrial Dunnage** (IDs 181–195)
11. **Heavy Machinery, Pumps, Valves, Piping & Hydraulics** (IDs 196–210)
12. **Construction Materials, Cement, Aggregate & Structural Steel** (IDs 211–225)
13. **Wholesale Liquidation, Discount Retail & Speculative Commodities** (IDs 226–240)
14. **Private Equity Industrial Rollups, Compliance & Algorithmic Labor** (IDs 241–256)

---

## Technical Decisions & Production Engineering

### 1. Canvas Selection & Aspect Ratio
- **Resolution**: `1024 × 512` pixels.
- **Aspect Ratio**: 2:1 horizontal rectangle.
- **Rationale**: 
  - Corresponds to the standard aspect ratio of shipping container sidewall and door branding zones across Source engine container props (`props_c17/oildrum001`, `models/props_c17/shipping_container`).
  - Strict power-of-two (`2^10 x 2^9`) dimensions ensure zero mipmap filtering distortion, seamless DXT compression block alignment (4x4 texels), and high memory efficiency.

### 2. Dual-Value Keyline Rendering Engine
To satisfy the strict constraint that container paint color communicates gameplay floor/quadrant data and must not conflict with company branding:
- All vector marks, geometric emblems, typography, and dividing rules were implemented with **dual-luminance contours**:
  - High-luminance fill (`#FFFFFF` or `#F4F6F8`) backed by a thick low-luminance outer keyline (`#0B0E14` or `#161C24` at 4–8px stroke width).
  - Selected assets utilize bounded container placards (dark composite metal plates with mounting bolts and crisp white stencils), allowing the decal to maintain a consistent background zone without altering the container color around it.
- **Recolor Proofing**: Decals were tested against test hull colors including:
  - Dark Charcoal (`#1A1D20`)
  - Refrigerated White (`#E8EAE6`)
  - Oxide Red (`#9B2318`)
  - Cobalt Blue (`#1B4965`)
  - Safety Ochre (`#DDA15E`)
  In all cases, either the bright fill or dark stroke provided 100% boundary contrast.

### 3. Dynamic Typographic Scaling
To eliminate typographic clipping and text overflow across varying name lengths:
- Typography uses bounding-box measurement (`font.getbbox()`) with progressive downscaling from 54pt down to 32pt.
- Slogans are similarly measured and scaled from 24pt down to 18pt.
- Authentic ISO 6346 container rating strings (`ISO 6346 / UIC 592-2 // TARE 2,185 KG // MAX 30,480 KG // ID: LOD-XXX`) and sector designations are rendered in high-contrast monospace along the lower boundary.

---

## Instructions for Downstream Developers & AI Coding Agents

1. **Procedural Seed Binding**:
   When implementing the run generator in Lua (`autorun/server/sv_dungeon_gen.lua`), bind the company ID to the dungeon seed:
   ```lua
   local company_id = string.format("%03d", (math.abs(dungeon_seed) % 256) + 1)
   local brand_texture = "models/props_c17/container_brands/container_brand_" .. company_id
   ```
2. **Decal Overlaying**:
   If applying brands as overlays on existing prop models, use `util.Decal` or dynamic material proxies on the container entities.
3. **Manifest Integration**:
   `manifest.json` can be loaded directly in GMod via `util.JSONToTable(file.Read("data_static/manifest.json", "GAME"))` to display the company name on HUD readouts, loading screens, or terminal lore monitors.
