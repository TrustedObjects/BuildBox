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

## Initialize test fixture repositories from bundles.
## Run once after cloning BuildBox, or whenever tests/bundles/ changes.
## Safe to re-run: already-initialized repos are left untouched.

set -e
BB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." > /dev/null 2>&1 && pwd)"
BUNDLES_DIR="${BB_DIR}/tests/bundles"
REPOS_DIR="${BB_DIR}/tests/repositories"

restore_bare() {
	local bundle_name="${1}"
	local dir_name="${2:-${bundle_name}}"
	local dest="${REPOS_DIR}/remote/${dir_name}.git"
	[ -d "${dest}" ] && return 0
	git clone --bare --local "${BUNDLES_DIR}/${bundle_name}.bundle" "${dest}" 2>/dev/null
	# Expose all branches so cloners see them without 'origin/' prefix
	git -C "${dest}" config remote.origin.fetch '+refs/heads/*:refs/heads/*'
}

# Restore a project fixture: creates a project directory with the profile
# bundle cloned into .bbx/.
restore_project_fixture() {
	local bundle_name="${1}"
	local dir_name="${2:-${bundle_name}}"
	local dest="${REPOS_DIR}/${dir_name}"
	[ -d "${dest}/.bbx/.git" ] && return 0
	mkdir -p "${dest}"
	git clone --local "${BUNDLES_DIR}/${bundle_name}.bundle" "${dest}/.bbx" --no-single-branch 2>/dev/null
	# Remove origin so fixtures have no remote (mirrors a project after migrate/init)
	git -C "${dest}/.bbx" remote remove origin 2>/dev/null || true
}

# Remote bare repos — clone sources for package/tool tests
restore_bare remote_packages    packages
restore_bare remote_foo_package foo_package
restore_bare remote_bar_package bar_package
restore_bare remote_baz_package baz_package
restore_bare remote_qux_package qux_package
restore_bare remote_quux_package quux_package
restore_bare remote_corge_package corge_package
restore_bare remote_foo_tool    foo_tool
restore_bare remote_bar_tool    bar_tool
restore_bare remote_baz_tool    baz_tool
restore_bare remote_qux_tool    qux_tool
restore_bare foo_profile        foo_profile

# Project fixtures — project directories with profile cloned into .bbx/
restore_project_fixture foo_profile foo_project
restore_project_fixture bar_profile bar_project
