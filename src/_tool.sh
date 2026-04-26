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

## @brief Tools (packages)

## @fn bb_find_matching_tools
## Given a filter list, find matching tools for current project target.
## @param Filter list, separated by spaces. Must not be empty.
## @env `BB_TARGET`: current target
## @env `BB_PROJECT_PROFILE_DIR`: current project path
## @print Matching tools list
##
## @return 0 on success
function bb_find_matching_tools () (
	if [ $# -eq 0 ]; then
		return 1
	fi
	# Select tools matching given list, and make results unique
	IFS=' '
	tools_list=( $(echo -e "${@}") )
	unset IFS
	selected_tools=""
	# Get TOOLS var
	if [ -z ${BB_TARGET} ]; then
		return 1
	fi
	bb_source $(bb_get_target_profile_path ${BB_TARGET})
	if [ $? -ne 0 ]; then
		return 1
	fi
	if [ -n ${TOOLS} ]; then
		for req in "${tools_list[@]}"; do
			req=${req/$'\n'/}
			tool=$(grep ${req} ${BB_PROJECT_PROFILE_DIR}/${TOOLS} | grep "^[^#]" || true)
			if [ -z "${tool}" ]; then
				continue
			fi
			if [ -n "${selected_tools}" ]; then
				selected_tools+=$'\n'
			fi
			selected_tools+="${tool}"
		done
		selected_tools=$(echo "${selected_tools}"|sort|uniq)
		echo "${selected_tools}"
	fi
	return 0
)
bb_exportfn bb_find_matching_tools

## @fn bb_get_tools
## Get tools list for current project target
## @param Set to 1 to return only cloned tools (optional, default 0)
## @env `BB_TARGET`: current target
## @env `BB_PROJECT_PROFILE_DIR`: current project path
## @print tools list
## @return 0 on success
function bb_get_tools () (
	only_cloned=${1}
	# Get TOOLS var
	if [ -z ${BB_TARGET} ]; then
		return 1
	fi
	bb_source $(bb_get_target_profile_path ${BB_TARGET})
	if [ $? -ne 0 ]; then
		return 1
	fi
	if [ -n ${TOOLS} ]; then
		if [ -f "${BB_PROJECT_PROFILE_DIR}/${TOOLS}" ]; then
			while read -r tool_name || [ -n "${tool_name}" ]; do
				if [ -z "${tool_name}" ]; then
					continue
				fi
				if [[ ${tool_name} =~ ^#.* ]]; then
					continue
				fi
				if [ -n "${only_cloned}" ] && [ "${only_cloned}" -eq 1 ]; then
					local tool_dir=${BB_TOOLS_DIR}/$(basename ${tool_name})
					if [ -d "${tool_dir}" ]; then
						echo ${tool_name}
					fi
				else
					echo ${tool_name}
				fi
			done < "${BB_PROJECT_PROFILE_DIR}/${TOOLS}"
		fi
	fi
	return 0
)
bb_exportfn bb_get_tools

## @fn bb_clone_tool
## Generic function to clone a tool into the tools directory.
## Packages sources are cloned into `BB_TOOLS_DIR` directory.
## @param Tool package name
## @env `BB_TOOLS_DIR`: path where cloned package are symlinked
## @env `BB_PROJECT_PROFILE_DIR`: current project path
## @return 0 on success
function bb_clone_tool () (
	bb_trap_errors_silent
	local tool_name=${1}
	bb_load_package ${tool_name}
	[ $? -ne 0 ] && return 1
	local tool_dir=$(basename ${tool_name})
	bb_source _clone_${SRC_PROTO}.sh
	[ $? -ne 0 ] && return 1
	if ! typeset -f bb_${SRC_PROTO}_clone > /dev/null; then
		echo "Unsupported protocol to clone sources: ${SRC_PROTO}"
		return 1
	fi
	if [ ! -d ${BB_TOOLS_DIR}/${tool_dir} ]; then
		if [ -d ${BB_TOOLS_DIR}/.tmp ]; then
			rm -rf ${BB_TOOLS_DIR}/.tmp
			[ $? -ne 0 ] && return 1
		fi
		# Clone in a temporary folder, to be sure to have the complete
		# clone in case of interruption, which is created from
		# temporary folder after successful clone
		bb_${SRC_PROTO}_clone ${SRC_URI} ${BB_TOOLS_DIR}/.tmp ${SRC_REVISION} "${SRC_PROTO_OPTIONS}"
		[ $? -ne 0 ] && return 1
		# Post-clone action, if specified
		if typeset -f SRC_POST_CLONE_HOOK > /dev/null; then
			echo "Running post-clone hook..."
			cd ${BB_TOOLS_DIR}/.tmp
			SRC_POST_CLONE_HOOK
			[ $? -ne 0 ] && return 1
		fi

		# If build mode is 'executable', we need to move the file to bin/
		if [ "${SRC_BUILD}" = "executable" ]; then
			local pkg_dir="${BB_TOOLS_DIR}/.tmp"
			local bin_dir="${BB_TOOLS_DIR}/.tmp/bin"
			mkdir -p "${bin_dir}"
			# Find the file and move it to bin/
			local file=$(find -L "${pkg_dir}" -maxdepth 1 -type f | head -n 1)
			if [ -n "${file}" ]; then
				local filename=$(basename "${file}")
				mv "${file}" "${bin_dir}/"
				chmod +x "${bin_dir}/${filename}"
			fi
		fi

		mv ${BB_TOOLS_DIR}/.tmp ${BB_TOOLS_DIR}/${tool_dir}
		[ $? -ne 0 ] && return 1
	fi
	return 0
)
bb_exportfn bb_clone_tool

## @fn bb_load_tools
## Load current target tools by running their (optional) `load.sh` script.
## Tools are loaded in order of appearance in target tools list file
## @env `BB_PROJECT`: current project
## @env `BB_TARGET`: current target
## @env `BB_TOOLS_DIR`: path where tools are installed
## @env `BB_DISABLE_TOOLS_SCRIPTS`: if set disables this feature, the function
## immediately returns
## @return 0 on success
function bb_load_tools {
	if [ -n "${BB_DISABLE_TOOLS_SCRIPTS}" ]; then
		return 0
	fi
	while read -r tool; do
		local tool_dir=${BB_TOOLS_DIR}/${tool}
		if [ -f "${tool_dir}/load.sh" ]; then
			source "${tool_dir}/load.sh"
			bb_restore_error_handler
		fi
	done < <(bb_get_tools)
	return 0
}
bb_exportfn bb_load_tools

## @fn bb_unload_tools
## Unload current target tools by running their (optional) `unload.sh` script.
## Tools are unloaded in inverse order of appearance in target tools list file.
## @env `BB_PROJECT`: current project
## @env `BB_TARGET`: current target
## @env `BB_TOOLS_DIR`: path where tools are installed
## @env `BB_DISABLE_TOOLS_SCRIPTS`: if set disables this feature, the function
## immediately returns
## @return 0 on success
function bb_unload_tools {
	if [ -z "${BB_PROJECT_DIR}" ] || [ -z ${BB_TARGET} ]; then
		return 0
	fi
	if [ -n "${BB_DISABLE_TOOLS_SCRIPTS}" ]; then
		return 0
	fi
	while read -r tool; do
		local tool_dir=${BB_TOOLS_DIR}/${tool}
		if [ -f "${tool_dir}/unload.sh" ]; then
			source "${tool_dir}/unload.sh"
			bb_restore_error_handler
		fi
	done < <(bb_get_tools | tac)
	return 0
}
bb_exportfn bb_unload_tools

## @fn bb_run_tools_cleanup_hook
## Run current target tools (optional) cleanup hook `cleanup.sh` script.
## Tools cleanup hooks are run in order of appearance in target tools list file
## @env `BB_PROJECT`: current project
## @env `BB_TARGET`: current target
## @env `BB_TOOLS_DIR`: path where tools are installed
## @return 0 on success
function bb_run_tools_cleanup_hook {
	while read -r tool; do
		local tool_dir=${BB_TOOLS_DIR}/${tool}
		if [ -f "${tool_dir}/cleanup.sh" ]; then
			source "${tool_dir}/cleanup.sh"
			bb_restore_error_handler
		fi
	done < <(bb_get_tools)
	return 0
}
bb_exportfn bb_run_tools_cleanup_hook
