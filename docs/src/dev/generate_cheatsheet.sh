#!/bin/bash
# This file is part of BuildBox project
# Copyright (C) 2020-2026 Trusted Objects

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2, as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, see
# <https://www.gnu.org/licenses/>.

## Render the BuildBox Cheat Sheet, a single page PDF of the usual commands,
## from cheatsheet.html.template.
##
## The PDF is written in the site 'public' directory, so the documentation
## build copies it to the site root and it is served as /cheatsheet.pdf.
##
## Rendering needs a headless Chromium or Chrome. When none is installed the
## sheet is skipped with a warning rather than failing the documentation build:
## the site is complete without it, only the download is missing.
## Usage: generate_cheatsheet.sh [OUTPUT_DIR]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
TEMPLATE="${SCRIPT_DIR}/cheatsheet.html.template"
OUTPUT_DIR="${1:-${SCRIPT_DIR}/../public}"
OUTPUT="${OUTPUT_DIR}/cheatsheet.pdf"

if [ ! -f "${TEMPLATE}" ]; then
	>&2 echo "Cheat sheet template not found: ${TEMPLATE}"
	exit 1
fi

# Same version as the documentation site header
version="$(git -C "${SCRIPT_DIR}" describe --tags --match '*' 2> /dev/null || echo dev)"

browser=""
for candidate in chromium chromium-browser google-chrome google-chrome-stable chrome; do
	if command -v "${candidate}" > /dev/null 2>&1; then
		browser="${candidate}"
		break
	fi
done
if [ -z "${browser}" ]; then
	>&2 echo "Warning: no Chromium nor Chrome found, skipping the cheat sheet"
	>&2 echo "         (install one to get ${OUTPUT})"
	exit 0
fi

mkdir -p "${OUTPUT_DIR}"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
html="${work_dir}/cheatsheet.html"
sed "s|@VERSION@|${version}|g" "${TEMPLATE}" > "${html}"

# --no-pdf-header-footer keeps the page free of the browser URL and date, the
# sheet carries its own footer. The page size comes from the '@page' rule.
"${browser}" \
	--headless \
	--disable-gpu \
	--no-sandbox \
	--no-pdf-header-footer \
	--print-to-pdf="${OUTPUT}" \
	"file://${html}" > /dev/null 2>&1

if [ ! -s "${OUTPUT}" ]; then
	>&2 echo "Cheat sheet rendering produced no PDF"
	exit 1
fi

# A cheat sheet spilling over one page is a layout regression, not a detail
pages="$(strings "${OUTPUT}" | sed -n 's/.*\/Count \([0-9][0-9]*\).*/\1/p' | head -n 1)"
if [ -n "${pages}" ] && [ "${pages}" -ne 1 ]; then
	>&2 echo "Warning: the cheat sheet spans ${pages} pages, it is meant to be one"
fi

echo "Cheat sheet generated: ${OUTPUT} (BuildBox ${version})"
