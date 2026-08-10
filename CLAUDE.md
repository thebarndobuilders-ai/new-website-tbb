# The Barndo Builders — repo rules for Claude sessions

## 🔒 TAKEOFF TAB IS LOCKED — DO NOT MODIFY
The takeoff tab in `barndo_builders_tool.html` (the `#tab-takeoff` markup block and the
`<script>` block whose banner reads "BLUEPRINT TAKEOFF — load a plan PDF") is **frozen at
the v201 state the builder confirmed working** after a long, painful debugging saga.

- **Never** edit, refactor, "improve", or reformat anything inside those two sections —
  not cursors, not event handling, not canvas sizing, not the scale flow — unless the
  builder explicitly asks for a takeoff change **in their own words in the current
  session**, and even then read `BARNDO_TOOL_HANDOFF.md` § "DO NOT TOUCH" first.
- The frozen reference copy lives at `takeoff_LOCKED_v198.html`
  (sha256 `c0eebb69b610b4b6d6569782b65aaf08a88a40856fe2c59edb5ab22a3a7899dc`).
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
