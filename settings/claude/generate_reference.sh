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

set -e

## Generate the reference documentation embedded in the BuildBox skills for
## Claude Code, from the documentation sources: the documentation stays the
## single source of truth, the skills only add the operating instructions.
## Usage: generate_reference.sh <docs source dir> <skills dir>

DOCS_DIR="${1}"
SKILLS_DIR="${2}"
SITE_URL="https://buildbox.trusted-objects.com"

if [ ! -d "${DOCS_DIR}" ] || [ ! -d "${SKILLS_DIR}" ]; then
	>&2 echo "Usage: $(basename "${0}") <docs source dir> <skills dir>"
	exit 1
fi
DOCS_DIR=$(cd -- "${DOCS_DIR}" > /dev/null 2>&1 && pwd)
SKILLS_DIR=$(cd -- "${SKILLS_DIR}" > /dev/null 2>&1 && pwd)

# Pages of each skill, as "<skill> <page> <page> ..."
SKILL_PAGES=(
	"buildbox getting-started/install.md user/index.md user/project.md user/target.md user/package.md user/tool.md user/container.md user/shell_plugin.md user/advanced.md user/utils.md user/migration.md"
	"buildbox-scripting dev/scripting.md dev/envvars.md dev/build_modes.md dev/api.md"
	"buildbox-develop dev/index.md dev/developing.md dev/container.md dev/shell.md"
)

## Convert a documentation page into a reference file: what is specific to the
## documentation site has no meaning in a file read on its own.
## @param Page path, relative to the documentation source dir
## @param Destination file
function convert_page {
	local page="${1}"
	local destination="${2}"
	local page_dir=$(dirname "${page}")

	{
		echo "<!-- Generated from docs/src/${page} by settings/claude/generate_reference.sh -->"
		echo "<!-- Do not edit: update the documentation source instead -->"
		echo ""
		# Drop the frontmatter, the partial includes, and turn the containers
		# into plain markdown notes
		awk '
		BEGIN { in_frontmatter = 0; first = 1 }
		first && /^---[[:space:]]*$/ { in_frontmatter = 1; first = 0; next }
		{ first = 0 }
		in_frontmatter && /^---[[:space:]]*$/ { in_frontmatter = 0; next }
		in_frontmatter { next }
		/^<!--@include:/ { next }
		/^:::[[:space:]]*$/ { next }
		/^:::[[:space:]]*[a-z]+/ {
			kind = $2
			title = ""
			if (NF > 2) {
				title = substr($0, index($0, $3))
			}
			label = toupper(substr(kind, 1, 1)) substr(kind, 2)
			if (title == "") {
				printf "**%s:**\n", label
			} else {
				printf "**%s: %s**\n", label, title
			}
			next
		}
		{ print }
		' "${DOCS_DIR}/${page}" \
		| sed \
			-e "s|](/\([^)#]*\)\.md\(#[^)]*\)\?)|](${SITE_URL}/\1.html\2)|g" \
			-e "s|](\([a-zA-Z0-9_-]*\)\.md\(#[^)]*\)\?)|](${SITE_URL}/${page_dir}/\1.html\2)|g"
	} > "${destination}"
}

# The API reference is itself generated for the documentation site
if [ ! -f "${DOCS_DIR}/dev/api.md" ]; then
	echo -n "Generating API documentation first... "
	"${DOCS_DIR}/dev/generate_apidoc.sh" "${DOCS_DIR}/../../src/" > /dev/null
	echo -e "\e[32mOK\e[0m"
fi

for entry in "${SKILL_PAGES[@]}"; do
	set -- ${entry}
	skill="${1}"
	shift
	if [ ! -d "${SKILLS_DIR}/${skill}" ]; then
		>&2 echo "Unknown skill ${skill} in ${SKILLS_DIR}"
		exit 1
	fi
	echo -n "Generating ${skill} reference... "
	reference_dir="${SKILLS_DIR}/${skill}/reference"
	rm -rf "${reference_dir}"
	mkdir -p "${reference_dir}"
	for page in "$@"; do
		if [ ! -f "${DOCS_DIR}/${page}" ]; then
			>&2 echo "Documentation page not found: ${page}"
			exit 1
		fi
		convert_page "${page}" "${reference_dir}/$(basename "${page}")"
	done
	echo -e "\e[32mOK\e[0m ($# pages)"
done
