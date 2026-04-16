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

restore_working() {
	local name="${1}"
	local dest="${REPOS_DIR}/${2:-${name}}"
	[ -d "${dest}/.git" ] && return 0
	git clone --local "${BUNDLES_DIR}/${name}.bundle" "${dest}" --no-single-branch 2>/dev/null
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
restore_bare remote_projects    projects

# Project fixtures — working copies used by tests
restore_working foo_project
restore_working bar_project
restore_working projects

# Initialize the 'packages' submodule in the projects fixture using the local bare repo
if [ ! -d "${REPOS_DIR}/projects/packages/.git" ]; then
	git -C "${REPOS_DIR}/projects" config submodule.packages.url \
		"file://${REPOS_DIR}/remote/packages.git"
	git -C "${REPOS_DIR}/projects" \
		-c protocol.file.allow=always submodule update --init
fi
