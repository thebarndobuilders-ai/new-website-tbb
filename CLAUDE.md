# The Barndo Builders — repo rules for Claude sessions

## 🔒 TAKEOFF TAB IS LOCKED — DO NOT MODIFY
The takeoff tab in `barndo_builders_tool.html` (the `#tab-takeoff` markup block and the
`<script>` block whose banner reads "BLUEPRINT TAKEOFF — load a plan PDF") is **frozen at
the v202 state the builder confirmed working** after a long, painful debugging saga.

- **Never** edit, refactor, "improve", or reformat anything inside those two sections —
  not cursors, not event handling, not canvas sizing, not the scale flow — unless the
  builder explicitly asks for a takeoff change **in their own words in the current
  session**, and even then read `BARNDO_TOOL_HANDOFF.md` § "DO NOT TOUCH" first.
- The frozen reference copy lives at `takeoff_LOCKED_v198.html`
  (sha256 `b6e9f7c1511959a475073569316d1497a395049fe11437444fab5b88d70738ce`).
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

## Hopes and Dreams (speech/OT practice tool) — standing preferences
- **BUILD over BUY, always.** The owner prefers building software into
  `hopes_dreams_billing_tool.html` over purchasing SaaS. When a need comes up,
  default to building it into the tool; only recommend buying when building is
  truly infeasible (e.g., requires a HIPAA BAA-covered messaging vendor or a
  claims clearinghouse), and say so plainly.
- The tool is a single self-contained HTML file, data in localStorage, offline-first,
  JSON backup export/import. Keep that architecture.
- Owner: Hopes and Dreams Speech Therapy — pediatric ST + OT, two TN locations,
  Fusion EMR (tool is its companion). Work happens on branch
  `claude/speech-therapy-billing-tool-3ndf91`; never touch the barndo tool from
  these sessions.
