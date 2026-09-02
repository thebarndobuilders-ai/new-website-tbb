#!/usr/bin/env python3
# Build the DEALER EDITION from barndo_builders_tool.html.
#   python3 make_dealer_edition.py [output.html]
# Flips BB_EDITION to 'dealer' and physically strips the export buttons and
# in-house tab buttons; the runtime gates baked into the tool (bbDealerInit)
# do the rest: Kit-package pricing view, blueprint sheet filter, guarded
# exports, category-only live material panel.
import io, sys

SRC = 'barndo_builders_tool.html'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'barndo_dealer_edition.html'
src = io.open(SRC, encoding='utf-8').read()

def rep(old, new, n=1):
    global src
    c = src.count(old)
    assert c == n, 'anchor %d != %d: %r' % (c, n, old[:80])
    src = src.replace(old, new)

# 1. edition flag + header stamp
rep("window.BB_EDITION = window.BB_EDITION || 'house';",
    "window.BB_EDITION = 'dealer';")
rep('Local database · this device · v', 'Dealer edition · this device · v')

# 2. physically remove the export buttons (runtime also guards the functions)
for b in [
    '<button onclick="exportCSV()">CSV</button>',
    '<button onclick="exportPDF()">Internal cost sheet</button>',
    '<button onclick="printCutList()">Cut list</button>',
    '<button onclick="exportCutListCSV()" title="Download the cut list as a CSV spreadsheet">Cut list CSV</button>',
]:
    rep(b, '')
# order-sheets button carries a long title attr — match by prefix
i = src.index('<button onclick="printOrderSheets()"')
j = src.index('</button>', i) + len('</button>')
src = src[:i] + src[j:]

# 3. physically remove the in-house tab buttons
for t in ['framing', 'counter', 'jobcost', 'flitch', 'vendors', 'settings']:
    i = src.index('<div class="qbs-tab" data-tab="%s"' % t)
    j = src.index('</div>', i) + len('</div>')
    src = src[:i] + src[j:]

io.open(OUT, 'w', encoding='utf-8').write(src)
print('dealer edition written:', OUT, len(src), 'bytes')
