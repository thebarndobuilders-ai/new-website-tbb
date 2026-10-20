#!/usr/bin/env python3
# Refresh the published GitHub Pages site (docs/) from the current builds.
# Run from the repo root AFTER make_dealer_edition.py on every release:
#   index.html  = dealer program page (public marketing)
#   app.html    = the software (customers sign in here)
#   dealer.html = dealer edition
import shutil
shutil.copyfile('dealer_program.html', 'docs/index.html')
shutil.copyfile('barndo_builders_tool.html', 'docs/app.html')
shutil.copyfile('barndo_dealer_edition.html', 'docs/dealer.html')
open('docs/.nojekyll', 'w').close()   # serve files verbatim, no Jekyll pass
print('site refreshed: docs/index.html, docs/app.html, docs/dealer.html')
