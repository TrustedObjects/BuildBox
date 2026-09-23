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

## Render the documentation diagrams, from the SVG sources of src/dev/diagrams
## to PNG files of the site 'public' directory, where the pages reference them
## as /<name>.png.
##
## A diagram accompanied by a <name>.dark.css file is rendered a second time
## to /<name>_dark.png, with that stylesheet appended to the one of the SVG.
## The dark variant therefore holds colours only, the geometry and the type
## having a single source. Pages show one or the other through the
## .bbx-diagram-light and .bbx-diagram-dark classes of styles/index.css.
##
## A diagram is rendered only when its PNG is missing or older than its
## sources, or than this script, so a documentation build that changes no
## diagram costs nothing. Pass --force to render them all.
##
## Rendering needs one of rsvg-convert, Inkscape, ImageMagick, Chromium or
## Chrome. When none is installed the diagrams are skipped with a warning
## rather than failing the documentation build: unlike the other generated
## files, the PNG files are committed, so the site still shows the diagram of
## the last person who had a renderer. This is also why a change to an SVG
## source has to be committed together with its regenerated PNG.
## Usage: generate_diagrams.sh [--force] [SOURCE_DIR [OUTPUT_DIR]]

set -e

SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT}")" > /dev/null 2>&1 && pwd)"

force=0
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
	force=1
	shift
fi
SOURCE_DIR="${1:-${SCRIPT_DIR}/diagrams}"
OUTPUT_DIR="${2:-${SCRIPT_DIR}/../public}"

# Rendered at twice the SVG size, so the diagrams stay sharp on high density
# displays and when the page scales them up
SCALE=2

if [ ! -d "${SOURCE_DIR}" ]; then
	>&2 echo "Diagram source directory not found: ${SOURCE_DIR}"
	exit 1
fi

sources=("${SOURCE_DIR}"/*.svg)
if [ ! -e "${sources[0]}" ]; then
	echo "No diagram to render in ${SOURCE_DIR}"
	exit 0
fi

renderer=""
for candidate in rsvg-convert inkscape magick convert chromium chromium-browser \
                 google-chrome google-chrome-stable chrome; do
	if command -v "${candidate}" > /dev/null 2>&1; then
		renderer="${candidate}"
		break
	fi
done
if [ -z "${renderer}" ]; then
	>&2 echo "Warning: no SVG renderer found, skipping the diagrams"
	>&2 echo "         (install rsvg-convert, Inkscape, ImageMagick or Chromium"
	>&2 echo "          to regenerate ${OUTPUT_DIR}/*.png from ${SOURCE_DIR})"
	exit 0
fi

## Print the intrinsic width and height of an SVG, from its 'width' and
## 'height' attributes, falling back on its 'viewBox'.
svg_size() {
	local svg="$1"
	local head width height viewbox
	head="$(head -c 4096 "${svg}" | tr '\n' ' ')"
	width="$(printf '%s' "${head}" | sed -n 's/.*<svg[^>]* width="\([0-9.]*\)".*/\1/p')"
	height="$(printf '%s' "${head}" | sed -n 's/.*<svg[^>]* height="\([0-9.]*\)".*/\1/p')"
	if [ -z "${width}" ] || [ -z "${height}" ]; then
		viewbox="$(printf '%s' "${head}" | sed -n 's/.*viewBox="\([^"]*\)".*/\1/p')"
		width="$(printf '%s' "${viewbox}" | awk '{print $3}')"
		height="$(printf '%s' "${viewbox}" | awk '{print $4}')"
	fi
	[ -n "${width}" ] && [ -n "${height}" ] || return 1
	printf '%d %d\n' "${width%.*}" "${height%.*}"
}

## Render an SVG to a PNG of the given pixel size, with the first renderer
## found on the machine.
render() {
	local svg="$1" png="$2" width="$3" height="$4"
	local work_dir html

	case "${renderer}" in
		rsvg-convert)
			"${renderer}" --width="${width}" --height="${height}" \
				--output "${png}" "${svg}"
			;;
		inkscape)
			"${renderer}" --export-type=png --export-width="${width}" \
				--export-height="${height}" --export-filename="${png}" \
				"${svg}" > /dev/null 2>&1
			;;
		magick | convert)
			# Density drives the rasterisation of the vectors, resize alone
			# would scale up a low resolution bitmap
			"${renderer}" -background none -density $((96 * SCALE)) \
				"${svg}" -resize "${width}x${height}" "${png}"
			;;
		*)
			# A browser centers a bare SVG in its viewport, so it is wrapped in
			# a page that pins it to the top left corner at its exact size
			work_dir="$(mktemp -d)"
			html="${work_dir}/diagram.html"
			{
				echo '<!DOCTYPE html><html><head><meta charset="utf-8">'
				echo '<style>html,body{margin:0;padding:0;background:#fff}'
				echo "img{display:block;width:$((width / SCALE))px;height:$((height / SCALE))px}"
				echo '</style></head><body>'
				echo "<img src=\"file://$(cd "$(dirname "${svg}")" && pwd)/$(basename "${svg}")\">"
				echo '</body></html>'
			} > "${html}"
			"${renderer}" \
				--headless \
				--disable-gpu \
				--no-sandbox \
				--hide-scrollbars \
				--force-device-scale-factor="${SCALE}" \
				--window-size="$((width / SCALE)),$((height / SCALE))" \
				--screenshot="${png}" \
				"file://${html}" > /dev/null 2>&1
			rm -rf "${work_dir}"
			;;
	esac
}

## Write a copy of an SVG with a stylesheet appended to its own, right before
## the closing tag, so the rules override the palette of the diagram.
inject_stylesheet() {
	local svg="$1" css="$2" out="$3"
	awk -v cssfile="${css}" '
		!injected && /<\/style>/ {
			while ((getline line < cssfile) > 0) print line
			close(cssfile)
			injected = 1
		}
		{ print }
		END { if (!injected) exit 1 }
	' "${svg}" > "${out}"
}

## Tell whether a PNG has to be rendered again, being missing, empty or older
## than one of the files it is made of.
needs_render() {
	local png="$1"
	shift
	[ "${force}" -eq 1 ] && return 0
	[ -s "${png}" ] || return 0
	local dep
	for dep in "$@" "${SCRIPT}"; do
		[ "${png}" -nt "${dep}" ] || return 0
	done
	return 1
}

mkdir -p "${OUTPUT_DIR}"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

rendered=0
skipped=0
for svg in "${sources[@]}"; do
	base="$(basename "${svg}" .svg)"
	dark_css="${SOURCE_DIR}/${base}.dark.css"

	if ! size="$(svg_size "${svg}")"; then
		>&2 echo "Unable to read the size of ${svg}"
		exit 1
	fi
	width=$(( ${size% *} * SCALE ))
	height=$(( ${size#* } * SCALE ))

	png="${OUTPUT_DIR}/${base}.png"
	if needs_render "${png}" "${svg}"; then
		render "${svg}" "${png}" "${width}" "${height}"
		if [ ! -s "${png}" ]; then
			>&2 echo "Rendering ${svg} produced no PNG"
			exit 1
		fi
		echo "Diagram generated: ${png} (${width}x${height}, ${renderer})"
		rendered=$((rendered + 1))
	else
		skipped=$((skipped + 1))
	fi

	[ -f "${dark_css}" ] || continue

	png="${OUTPUT_DIR}/${base}_dark.png"
	if needs_render "${png}" "${svg}" "${dark_css}"; then
		dark_svg="${work_dir}/${base}_dark.svg"
		if ! inject_stylesheet "${svg}" "${dark_css}" "${dark_svg}"; then
			>&2 echo "No <style> element to extend in ${svg}"
			exit 1
		fi
		render "${dark_svg}" "${png}" "${width}" "${height}"
		if [ ! -s "${png}" ]; then
			>&2 echo "Rendering ${svg} for the dark theme produced no PNG"
			exit 1
		fi
		echo "Diagram generated: ${png} (${width}x${height}, ${renderer})"
		rendered=$((rendered + 1))
	else
		skipped=$((skipped + 1))
	fi
done

if [ "${rendered}" -eq 0 ]; then
	echo "Diagrams up to date (${skipped} unchanged)"
fi
