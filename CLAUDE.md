# The Barndo Builders — repo rules for Claude sessions

## 🔒 TAKEOFF TAB IS LOCKED — DO NOT MODIFY
The takeoff tab in `barndo_builders_tool.html` (the `#tab-takeoff` markup block and the
`<script>` block whose banner reads "BLUEPRINT TAKEOFF — load a plan PDF") is **frozen at
the v360 state the builder confirmed working (v202 + the builder-ordered bigger
PDF viewer, 2026-09-15)** after a long, painful debugging saga.

- **Never** edit, refactor, "improve", or reformat anything inside those two sections —
  not cursors, not event handling, not canvas sizing, not the scale flow — unless the
  builder explicitly asks for a takeoff change **in their own words in the current
  session**, and even then read `BARNDO_TOOL_HANDOFF.md` § "DO NOT TOUCH" first.
- The frozen reference copy lives at `takeoff_LOCKED_v198.html`
  (sha256 `2298ca20574c00ff29773e238bb5db8bc10d9cbc929d25440a3bd247f3650b82`).
- **Verify before shipping any change to the tool:** re-extract the two sections from
  `barndo_builders_tool.html` and diff against the snapshot. If a change was NOT
  builder-ordered and the diff is non-empty, restore the sections verbatim from the
  snapshot.
- Two rules that must survive any authorized edit: **zero browser dialogs**
  (prompt/alert are silently killable by Chrome; use `toToast()`) and the **self-init
  at the end of the takeoff IIFE** (the app opens on this tab before its script parses —
  removing self-init makes the mouse dead on fresh opens).

## Other standing rules
- Every change: commit + push to `claude/new-session-87wo5r`, bump `BB_VERSION` and the
  header stamp, and send the user a plain `.html` file named `barndo_vNNN.html` (never a zip).
- Verify changes headless (Playwright, chromium at /opt/pw-browsers) with REAL mouse
  input and with dialogs force-dismissed before shipping.
- Pricing rules, builder conventions, and feature history: see `BARNDO_TOOL_HANDOFF.md`.
