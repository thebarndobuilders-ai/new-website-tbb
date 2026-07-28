# The Barndo Builders — Estimating Tool · Session Handoff

**Purpose of this file:** Carry the full context of our work to a new computer (or a new Claude session). On the new machine, start a fresh Claude session, **upload `barndo_builders_tool_v127.html`**, and **paste this whole file in**. We'll pick up exactly where we left off.

_Last updated: 2026-07-26_

---

## 1. What this is
A single, self-contained HTML app — **The Barndo Builders** post-frame / barndominium **estimating + quoting tool**. Tabs: Dimensions, Foundation, Takeoff (blueprint PDF), Materials, Subs & Labor, Quote, Customer Proposal, 3D shell audit, Leads CRM, Pricing master, Counter ticket, Settings. Runs entirely in a browser; data (leads, quotes, settings) saves to the browser's localStorage, with optional Supabase cloud sign-in.

## 2. Current version
- **Source of truth is now the git repo:** `thebarndobuilders-ai/new-website-tbb`, file `barndo_builders_tool.html` (branch `claude/new-session-87wo5r`). Git history replaces filename version numbers — no more v-number drift.
- v128 = v127 + CSV export of the cut list. ~2.18 MB (pdf.js bundled inline for offline use).
- Older on-disk versions exist (v105–v127). **Ignore them.**

## 3. How to run / view it
- **Simplest:** double-click → opens in Edge/Chrome. (If nothing happens, right-click → Open with → Edge → check "always".)
- **Saved dev server:** `.claude/launch.json` has a config named **`barndo-tool`** (PowerShell static server → port 8770). It runs `C:\Users\stone\Downloads\serve-barndo.ps1`, which now points at **v127**. Claude can launch it with preview_start and view at `localhost:8770`.
- Three.js is now **bundled inline** (like pdf.js) — the 3D viewer works fully offline. Internet is only needed for web fonts and Supabase cloud sync.

## 4. ⚠️ Critical warnings

### 🔒 DO NOT TOUCH — Takeoff viewer rendering (locked at v177, commit 429aa90)
The builder confirmed the takeoff scale/pan works on their machine as of **v177**. The fix that made it work is the **GPU-safe canvas split** in the takeoff viewer, and it must never be reverted or "simplified":
- The canvas **backing store is capped** (≤48M px, ≤10,000px per side) via `TO.pixelScale`; deeper zoom is **CSS scaling only** (`TO.renderScale` = display zoom). Weak Windows GPUs silently refuse to composite bigger canvases — drawings vanish from screen while pixel reads still pass, so headless tests will NOT catch a regression here.
- `toBase()` and `redraw()`'s `S` divide/multiply by `TO.pixelScale` (NOT `renderScale`).
- Other locked-in takeoff behavior: loads start in **PAN** tool; native OS cursors only (no custom image cursors — Windows DPI hides them); pointer events with capture; pdf.js renders serialized (cancel in-flight before new); blue drag band for Set scale; persistent green scale line; sticky status bar with version; 🩺 self-test + on-sheet X diagnostic.

- **VERSION DRIFT:** Work has been lost twice by editing across two different chats (v105→v115, then v117→v123 silently re-broke fixes). **Always start the next session from v127.** If you go back to any old chat, upload v127 there FIRST.
- **localStorage doesn't travel in the file:** saved leads, quotes, company contact info, imported master list, and settings live in the browser on the original machine. The **logo IS baked into the file**; the rest is not. Use Supabase sign-in to sync, or ask Claude to build a localStorage export/import.

## 5. Everything built/fixed (cumulative, all in v127)

### Bug fixes
- **`getInputs` null-crash + insulation $0 trap** — null-guarded `num`/`txt`; insulation default restored (2.20/sf).
- **Leads "Quoted" counter** — starting a quote no longer auto-flips New leads to "Quoted."
- **Post count bug** — eave posts were spaced at truss spacing (defaulting to 2'), over-counting. Fixed via the post↔truss spacing link.

### Estimating changes (builder-requested)
- **Corner & rake trim → stock-length model** (`splitTrimRun()`): wall corners = nearest stock (10/12/14/16) ≥ wall ht + 1'; gable rakes = fewest equal pieces, +1' waste/pc, nearest stock. Dynamic labels.
- **2×6 roof lathing** option (post-frame, cut to truss spacing); fixed a double-count with the 2×4 purlin line.
- **Electrical & meter panel** manual-entry card (Subs & Labor). $0 = excluded. All tiers.
- **Dry-set post plates (post-on-slab):** Post foundation selector = Embedded (Sakrete) vs Dry-set plates. On slab → no Sakrete, posts cut to wall height only.
- **Post plates SIZED TO THE POST** — 8 per-size plate lines (4×6, 6×6, 6×8, 6×10, 6×12, 8×8, 10×10, 12×12), each its own price on Pricing master. Wall posts get the selected size; garage jambs = 6×6; man-door jambs = 4×6. (`postPlateCount()`.)
- **Trusses = manual entry only** — removed the auto percentage fallback; trusses come only from the Truss table; new rows default to manual. Added a **⚠ "No trusses entered — roof structure $0" warning** on the Quote tab.
- **Truss spacing in FEET** (internal math still inches, converted at the input boundary).
- **Post-frame: truss spacing auto-follows post spacing** (trusses bear on eave posts); field auto-fills + locks.
- **2×6×12 sub-fascia** (replaces old 1×6 backer): always used, qty from eave + rake length (`fasciaLF`), 12' boards.
- **Gable metal piece count** shown next to the LF on gable panel lines.

### Proposal + outputs
- **Customer Proposal tab (Tab 7):** client-facing — dimensions, specs, scope chips, single total price. NO costs/quantities/markup. Verified: only one dollar figure appears.
- **Company & branding card** + **real logo baked into the file** (from `barndo logo.png`) — shows on proposal + internal cost sheet by default.
- **Header "Internal cost sheet"** button (full breakdown, red "not for customer" banner).
- **Cut list** (header button): printable, grouped Cut-to-length / By-the-foot / Count-only. Display/print-only.

### Master-list SKUs (Counter ticket)
- Counter-ticket lumber lines show an **auto-generated dimensional SKU** in the builder's master format: **`L-<size>-<length>-<grade>`** e.g. `L-2X6-12-SYP`, `L-2X6-10-TPT` (treated), `L-2X4-8-SPF` (studs). (`lumberSku()`.)
- Grade logic: treated/PT/ground-contact → **TPT**; studs → **SPF**; else untreated framing → **SYP**. Masonry/concrete/sheets are skipped (map sheets by hand).
- Each SKU is checked against the imported master list (`flitchData`) — **green if present, amber "⚠ not in master"** if not. (`skuInMaster()`, `skuBadge()`.)
- **Master list = `Lumber_Yard_Sales_Sheet_AutoPricing.xlsx`.** Format: columns `Code, Description, Size/Grade, Unit, Unit Price, Category, Last Updated`; SKU codes like `L-2X6-10-TPT`.
- Import parser adapted to read that sheet: accepts a **"Code"** column as the SKU and maps **"Unit Price" → cost**. To load it: Save the xlsx as **CSV**, then upload on the **Pricing master** tab.

## 6. Key conventions / decisions
- **Trim stock lengths:** 10/12/14/16 ft; per-piece rounding (a shipped kit can't come up short).
- **Pricing model:** only catalog `priceCost` matters; sell/retail = cost × global markup (default 30%/45%). `customUnitPrice(i)` hook prices dynamically.
- **Dynamic line labels:** via `labelFn(i)`; **material detail text** via `materialDetailText(m, i)`.
- **SKU grade codes:** SYP (untreated framing), TPT (treated), SPF (studs).

## 7. Open items / next steps
- **Confirm plate prices** (defaults 4×6 $12 … 12×12 $60) and the **2×6×12 fascia** price ($8.47) on Pricing master.
- **Variable-length lumber** (posts, studs, lathing cut to spacing) auto-generates a SKU **without a length** (e.g. `L-2X6-SPF`) → flags amber until mapped to an exact SKU on Pricing master (manual mapping always wins over auto).
- **Confirm treated code** — used `TPT`; change if any treated items use a different code.
- **Sheet goods** (plywood/OSB/LP panels) don't auto-generate (codes like `S-CDX-12` aren't derivable) — map by hand if needed.
- **Re-check saved post-frame quotes** — post counts (and plates/Sakrete scaling off them) are now lower and correct.
- **Trim exact-fit edge case:** a run exactly equal to a stock length splits into 2 pieces (the +1' waste won't fit). Decide if a zero-waste single stick is wanted there.
- ~~CSV export of the cut list~~ — **built (v128):** "Cut list CSV" header button, same sections as the printable view.
- ~~localStorage export/import~~ — **already existed in v127:** "⬇ Export full backup (JSON)" / "⬆ Import backup" buttons on the Pricing master tab. Covers all `bb_*`/`barndo_*`/`qbs_*` keys including leads, quotes, price overrides, company info, and the imported master list (`bb_store:app_state`). To move machines: export on the old computer, import on the new one.

## 8. How to resume on the new computer
1. Copy `barndo_builders_tool_v127.html` **and** this file to the new machine (cloud/email/USB).
2. Start a fresh Claude session there.
3. Upload `barndo_builders_tool_v127.html` and paste this whole handoff file into the chat.
4. Say what you want to work on next. Claude can re-serve the file locally to verify changes live.
