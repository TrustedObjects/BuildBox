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

## @brief Executable build mode
## Build mode used to install a single executable file (script, binary, ...)

## @fn bb_executable_build
## Install executable package.
## @param Package directory
## @return 0 on success
function bb_executable_build () (
	bb_trap_errors_silent
	local pkg_dir=${1}
	mkdir -p "${PREFIX}/bin"
	# In this mode, we expect exactly one file in the package directory.
	# We use -L to follow symlink if pkg_dir is a symlink (shared sources).
	local file=$(find -L "${pkg_dir}" -maxdepth 1 -type f | head -n 1)
	if [ -z "${file}" ]; then
		echo "No file found to install in ${pkg_dir}"
		return 1
	fi
	local filename=$(basename "${file}")
	cp -af "${file}" "${PREFIX}/bin/"
	chmod +x "${PREFIX}/bin/${filename}"
	return $?
)
bb_exportfn bb_executable_build

## @fn bb_executable_build_fast
## Same as bb_executable_build()
## @param Package directory
## @return 0 on success
function bb_executable_build_fast () (
	bb_executable_build ${1}
	return $?
)
bb_exportfn bb_executable_build_fast

## @fn bb_executable_clean
## Nothing to clean for executable.
## @param Package directory
function bb_executable_clean () (
	local pkg_dir=${1}
)
bb_exportfn bb_executable_clean

## @fn bb_executable_stat_warning
## No warnings for executable.
## @param package directory
## @print Always "0"
function bb_executable_stat_warning {
	local pkg_dir=${1}
	echo "0"
}
bb_exportfn bb_executable_stat_warning

## @fn bb_executable_supports_sources_sharing
## Executable build plugin supports sources sharing
## @return 1
function bb_executable_supports_sources_sharing {
	return 1
}
bb_exportfn bb_executable_supports_sources_sharing
