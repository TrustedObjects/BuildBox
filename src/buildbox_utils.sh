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

## @brief BuildBox API entry point
## This is the user API entry point, this file is the only to be sourced in
## scripts which have to use BuildBox API.
##
## When this file is sourced, the BuildBox environment is automatically set up
## from the current working directory (project root is detected by locating
## the .bbx/ directory).

## Resolve the library directory: src/ in the source tree, lib/ when installed.
if [ -d "${BB_DIR}/src" ]; then
	_bb_lib_dir="${BB_DIR}/src"
else
	_bb_lib_dir="${BB_DIR}/lib"
fi

## @fn bb_include
## Safely source a BuildBox script in the current script.
## Before including BuildBox scripts, we go to the library directory to
## avoid including a script from the current working directory having the same
## name as a BuildBox script; current working directory is restored just after.
## @param Script file base name
## @return 0 on success, else error
function bb_include {
	if [ $# -ne 1 ]; then
		echo "Invalid use of $0"
		return 1
	fi
	local script_name="${1}"
	if [ ! -f "${_bb_lib_dir}/${script_name}" ]; then
		echo "Unable to include unknown script ${script_name}"
		return 1
	fi
	local cwd=$(pwd)
	cd "${_bb_lib_dir}"
	source "${script_name}"
	cd "${cwd}"
	return 0
}
# Include BuildBox internal scripts
bb_include _common.sh
bb_include _log.sh
bb_include _error.sh
bb_include _trash.sh
bb_include _local_env.sh
bb_include _clone.sh
bb_include _build.sh
bb_include _project.sh
bb_include _target.sh
bb_include _package.sh
bb_include _tool.sh
bb_include _cache.sh
bb_include _locks.sh
bb_include _host.sh
## Export bb_include
bb_exportfn bb_include

# Auto-detect project from current working directory and set environment
bb_autodetect_project
