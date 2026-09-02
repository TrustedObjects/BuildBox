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

## Tests for the generation of the reference embedded in the Claude Code skills.

generator="${BB_DIR}/settings/claude/generate_reference.sh"

function test_generate_reference {
	dest="${TMPDIR}/skills"
	rm -rf "${dest}"
	mkdir -p "${dest}/buildbox" "${dest}/buildbox-scripting" "${dest}/buildbox-develop"
	${generator} "${BB_DIR}/docs/src" "${dest}" > /dev/null
	asserteq $? 0
	# Every skill gets the pages it needs
	assertf "${dest}/buildbox/reference/install.md"
	assertf "${dest}/buildbox/reference/project.md"
	assertf "${dest}/buildbox/reference/target.md"
	assertf "${dest}/buildbox/reference/package.md"
	assertf "${dest}/buildbox/reference/tool.md"
	assertf "${dest}/buildbox-scripting/reference/api.md"
	assertf "${dest}/buildbox-scripting/reference/envvars.md"
	assertf "${dest}/buildbox-develop/reference/developing.md"
	# Nothing specific to the documentation site is left
	asserteq "$(grep -rl '^:::' ${dest} | wc -l)" "0"
	asserteq "$(grep -rl '@include' ${dest} | wc -l)" "0"
	# Cross references point to the documentation site
	assertn "$(grep -l 'buildbox.trusted-objects.com' ${dest}/buildbox/reference/target.md)"
}
bb_declare_test test_generate_reference

function test_generate_reference_conversions {
	docs="${TMPDIR}/docs"
	rm -rf "${docs}"
	mkdir -p "${docs}"
	cp -a "${BB_DIR}/docs/src/user" "${BB_DIR}/docs/src/dev" \
		"${BB_DIR}/docs/src/getting-started" "${docs}/"
	# The API reference is generated for the site, stub it when absent
	[ -f "${docs}/dev/api.md" ] || echo "# API" > "${docs}/dev/api.md"
	cat > "${docs}/user/project.md" <<-EOT
		---
		layout: home
		---
		# Projects

		::: warning Upgrading
		Careful here.
		:::

		<!--@include: ./parts/news.md-->

		See [targets](target.md#pre-built-targets) and the [API](/dev/api.md).
	EOT
	dest="${TMPDIR}/skills_conversions"
	rm -rf "${dest}"
	mkdir -p "${dest}/buildbox" "${dest}/buildbox-scripting" "${dest}/buildbox-develop"
	${generator} "${docs}" "${dest}" > /dev/null
	asserteq $? 0
	page="${dest}/buildbox/reference/project.md"
	assertf "${page}"
	# Frontmatter dropped, container turned into a note, include dropped
	asserteq "$(grep -c '^layout: home' ${page})" "0"
	asserteq "$(grep -c '^\*\*Warning: Upgrading\*\*' ${page})" "1"
	asserteq "$(grep -c '@include' ${page})" "0"
	# Links rewritten, relative and absolute
	asserteq "$(grep -c 'buildbox.trusted-objects.com/user/target.html#pre-built-targets' ${page})" "1"
	asserteq "$(grep -c 'buildbox.trusted-objects.com/dev/api.html' ${page})" "1"
	# The page it comes from is recorded
	asserteq "$(grep -c 'Generated from docs/src/user/project.md' ${page})" "1"
}
bb_declare_test test_generate_reference_conversions

function test_generate_reference_unknown_dirs {
	${generator} /does/not/exist "${TMPDIR}" > /dev/null 2>&1
	assertne $? 0
}
bb_declare_test test_generate_reference_unknown_dirs
