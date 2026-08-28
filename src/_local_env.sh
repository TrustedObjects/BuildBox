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

## @brief Local environment
## Local environment configuration, to set environment according to current
## project target

# DEFAULT_PATH and DEFAULT_XDG_DATA_DIRS are the baseline values restored by
# bb_reset_sys_env before applying per-project/target/tool overrides.  They
# should be set by the container entry point (usr/bin/bbx); if absent we
# capture the current values the first time this file is sourced.
if [ -z "${DEFAULT_PATH}" ]; then
	export DEFAULT_PATH="${PATH}"
fi
if [ -z "${DEFAULT_XDG_DATA_DIRS+x}" ]; then
	if [ -z "${XDG_DATA_DIRS}" ]; then
		export DEFAULT_XDG_DATA_DIRS="/usr/local/share/:/usr/share/"
	else
		export DEFAULT_XDG_DATA_DIRS="${XDG_DATA_DIRS}"
	fi
fi

# Used to optimize local env refresh, to be done only if something affecting
# the environment variables has changed
if [ -z "${PREFIX}" ] || [[ "${PREFIX}" == "/usr" ]] || [[ "${PREFIX}" == "/usr/local" ]]; then
	# Initialize only if not already done
	export BB_LOCAL_ENV_LAST_TARGET=""
	export BB_LOCAL_ENV_LAST_TOOLS=""
	export BB_LOCAL_ENV_LAST_TARGET_VARS=""
	export BB_LOCAL_ENV_LAST_TARGET_BUILD_SETTINGS=""
fi

unset BB_DISABLE_LOCAL_ENV_SET

## @fn bb_reset_sys_env
## Reset local environment to defaults for system variables.
## @resetenv `PATH`
## @resetenv `XDG_DATA_DIRS`
function bb_reset_sys_env {
	export PATH=$DEFAULT_PATH
	export XDG_DATA_DIRS=${DEFAULT_XDG_DATA_DIRS}
}

## @fn bb_unset_target_local_env_vars
## Unset all target variables from environment.
## @resetenv `BB_TARGET_VAR_xxx`: target variable xxx
## @return 0 on success
function bb_unset_target_local_env_vars {
	old_vars=$(bbenv | grep "^BB_TARGET_VAR_")
	if [ $? -eq 0 ]; then
		while IFS= read -r old_var; do
			var=$(echo ${old_var} | cut -d '=' -f1)
			unset ${var}
		done < <(echo -e "${old_vars}")
	fi
	return 0
}

## @fn bb_set_target_local_env_vars
## Set environment according to project current target variables.
## @env `BB_TARGET`, the target name
## @setenv: `BB_TARGET_VAR_xxx`: target variable xxx
## @return 0 on success
function bb_set_target_local_env_vars {
	bb_unset_target_local_env_vars
	if [ $? -ne 0 ]; then
		return 1
	fi
	target_vars=$(bb_get_target_vars ${BB_TARGET})
	if [ $? -ne 0 ]; then
		return 1
	fi
	while IFS= read -r declaration; do
		var=$(echo ${declaration} | cut -d '=' -f1)
		val=$(echo ${declaration} | cut -d '=' -f2)
		export BB_TARGET_${var}=${val}
	done < <(echo -e "${target_vars}\n")
	return 0
}

## @fn bb_set_target_build_local_env
## Set build environment according to project current target settings.
##
## Hardware specific settings are not known by BuildBox: they are read from the
## current target profile (see bb_get_target_build_settings()), which is the
## only place where they can be described. Each setting the target profile does
## not define falls back to a default matching a native x86 build:
## - `CPU` defaults to `x86`,
## - `CPUDEF` and `CPU_FAMILY` default to `CPU`, uppercased, with every
## character which is neither a letter nor a digit replaced by an underscore
## (for example `CPU=cortex-m33` gives `CORTEX_M33`),
## - `CPU_DESCRIPTION` defaults to `CPU`,
## - `CHOST` defaults to `x86_64-pc-linux-gnu`,
## - `CFLAGS` and `LDFLAGS` default to no architecture specific flag.
##
## `CFLAGS` and `LDFLAGS` are then completed with the target build directory
## include and library paths.
## @env `BB_TARGET`, the target name
## @env `BB_TARGET_BUILD_DIR`, the target build directory
## @setenv `CFLAGS`
## @setenv `LDFLAGS`
## @setenv `CHOST`
## @setenv `CPU`
## @setenv `CPUDEF`
## @setenv `CPU_FAMILY`
## @setenv `CPU_DESCRIPTION`
## @setenv `PREFIX`, to target build directory `${BB_TARGET_BUILD_DIR}`
## @setenv `PATH`, to `${PREFIX}/bin` and `${PREFIX}/sbin`
## @setenv `PKG_CONFIG_PATH`, to `${PREFIX}/share/pkgconfig` and
## `${PREFIX}/lib/pkgconfig`
## @setenv `LD_LIBRARY_PATH`, to `${PREFIX}/lib`
## @setenv `PYTHONPATH`, to `${PREFIX}/bin`,
## `${PREFIX}/lib/python.../site-packages` and `${PREFIX}/lib/python/site-packages`
## @setenv `ACLOCAL_PATH`, to `${PREFIX}/share/aclocal`
## @setenv `XDG_DATA_DIRS`, to `${PREFIX}/share`
## @return 0 on success
function bb_set_target_build_local_env {
	local settings=""
	settings=$(bb_get_target_build_settings ${BB_TARGET})
	if [ $? -ne 0 ]; then
		return 1
	fi
	# Start from a clean state: settings of a previously active target must not
	# survive
	unset CPU CPU_FAMILY CPU_DESCRIPTION CPUDEF CHOST CFLAGS LDFLAGS
	# Apply target profile settings as they are, they are not interpreted
	while IFS= read -r setting; do
		if [ -n "${setting}" ]; then
			export "${setting%%=*}=${setting#*=}"
		fi
	done < <(echo "${settings}")
	# Defaults for the settings the target profile does not define
	export CPU="${CPU:-x86}"
	local cpu_id=$(printf '%s' "${CPU}" | tr '[:lower:]' '[:upper:]' | tr -cs '[:alnum:]' '_')
	export CPU_FAMILY="${CPU_FAMILY:-${cpu_id}}"
	export CPUDEF="${CPUDEF:-${cpu_id}}"
	export CPU_DESCRIPTION="${CPU_DESCRIPTION:-${CPU}}"
	export CHOST="${CHOST:-x86_64-pc-linux-gnu}"
	export PREFIX=${BB_TARGET_BUILD_DIR}
	export CFLAGS="-I${PREFIX}/include ${CFLAGS}"
	export LDFLAGS="-L${PREFIX}/lib ${LDFLAGS}"
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig
	export LD_LIBRARY_PATH=$PREFIX/lib
	export XDG_DATA_DIRS=$PREFIX/share:${XDG_DATA_DIRS}
	export PYTHONPATH=$PREFIX/bin:$PREFIX/lib/$(basename $(readlink -f $(which python3)))/site-packages:$PREFIX/lib/python/site-packages
	export ACLOCAL_PATH=$PREFIX/share/aclocal
	export PATH=$PREFIX/bin:$PREFIX/sbin:${PATH}

	return 0
}

## @fn bb_set_tools_local_env
## Set environment according to project current target required tools.
## Only cloned tools are taken into account.
## @setenv `PATH`, to tools `bin` and `sbin` folder
## @setenv `PKG_CONFIG_PATH`, to tools `share/pkgconfig` and `lib/pkgconfig`
## folders
## @setenv `CFLAGS`
## @setenv `LD_LIBRARY_PATH`, to tools `lib` folder
## @setenv `LDFLAGS`
## @setenv `ACLOCAL_PATH`, to tools directory `share/aclocal` folder
## @setenv `XDG_DATA_DIRS`, to tools directory `share` folder
## @setenv `PYTHONPATH`, to tools `bin` and `lib/python/site-packages` folders
## @return 0 on success
function bb_set_tools_local_env {
	while read -r tool; do
		local tool_dir=${BB_TOOLS_DIR}/$(basename ${tool})
		export PATH=${tool_dir}/bin:${tool_dir}/sbin:${PATH}
		export PKG_CONFIG_PATH=${tool_dir}/lib/pkgconfig:${tool_dir}/share/pkgconfig:${PKG_CONFIG_PATH}
		export CFLAGS="-I${tool_dir}/include ${CFLAGS}"
		export LD_LIBRARY_PATH=${tool_dir}/lib:${LD_LIBRARY_PATH}
		export XDG_DATA_DIRS=${tool_dir}/share:${XDG_DATA_DIRS}
		export LDFLAGS="-L${tool_dir}/lib ${LDFLAGS}"
		export ACLOCAL_PATH=${tool_dir}/share/aclocal:${ACLOCAL_PATH}
		export PYTHONPATH=${tool_dir}/bin:${tool_dir}/lib/python/site-packages:${PYTHONPATH}
	done < <(bb_get_tools)
	return 0
}

## @fn bb_is_local_env_outdated
## Check if local env need to be refreshed.
## The following parameters are taken into account for this:
## - current target name,
## - required tools,
## - target variables,
## - and target build settings (CPU and toolchain settings, see
## bb_get_target_build_settings()).
##
## If one of them have changed, refresh is needed.
## @return 0 if refresh not needed
function bb_is_local_env_outdated {
	if [[ "${BB_LOCAL_ENV_LAST_TARGET}" != "${BB_TARGET}" ]]; then
		return 1
	fi
	local tools_list=$(bb_get_tools 1)
	if [[ "${BB_LOCAL_ENV_LAST_TOOLS}" != "${tools_list}" ]]; then
		return 1
	fi
	local target_vars=$(bb_get_target_vars ${BB_TARGET})
	if [[ "${BB_LOCAL_ENV_LAST_TARGET_VARS}" != "${target_vars}" ]]; then
		return 1
	fi
	local target_build_settings=$(bb_get_target_build_settings ${BB_TARGET})
	if [[ "${BB_LOCAL_ENV_LAST_TARGET_BUILD_SETTINGS}" != "${target_build_settings}" ]]; then
		return 1
	fi
	return 0
}

## @fn bb_local_env_updated
## To be called just after local env has been updated sucessfully, then the
## project is considered up-to-date. Just after call,
## bb_is_local_env_outdated() returns 0.
function bb_local_env_updated {
	export BB_LOCAL_ENV_LAST_TARGET=${BB_TARGET}
	export BB_LOCAL_ENV_LAST_TOOLS=$(bb_get_tools 1)
	export BB_LOCAL_ENV_LAST_TARGET_VARS=$(bb_get_target_vars ${BB_TARGET})
	export BB_LOCAL_ENV_LAST_TARGET_BUILD_SETTINGS=$(bb_get_target_build_settings ${BB_TARGET})
}

## @fn bb_set_local_env
## Set local environment according to current project and target.
## @env `BB_PROJECT_DIR`, project root path
## @env `BB_PROJECT_PROFILE_DIR`, project profile path (.bbx/)
## @env `BB_TARGET`, target name
## @env `BB_TARGET_BUILD_DIR`, target build directory
## @env `BB_TOOLS_DIR`, tools directory
## @env `BB_DISABLE_LOCAL_ENV_SET`, if set, makes the function skip
## immediately
## @setenv Variables set by bb_set_target_build_local_env()
## @setenv Variables set by bb_set_target_local_env_vars()
## @setenv Variables set by bb_set_tools_local_env() if target requires tools
##
## Environment variables precedence is: tools (from the last to the first in
## target tools list), target, BuildBox and system. For example, PATH entries
## are ordered following this rule.
## @return 0 on success, 1 if project is not defined.
## No error is returned if `BB_TARGET` is not set, but nothing is done.
function bb_set_local_env {
	if [ -n "${BB_DISABLE_LOCAL_ENV_SET}" ]; then
		return 0
	fi
	local tools_list=""
	if [ -z "${BB_PROJECT_DIR}" ]; then
		echo "Error: project is not defined"
		return 1
	fi
	if [ -z ${BB_TARGET} ]; then
		return 0
	fi
	bb_is_local_env_outdated
	if [ $? -eq 0 ]; then
		# Local env up-to-date, nothing to do except refreshing PATH,
		# making autocompletion take into account new executable files
		export PATH=${PATH}
		return 0
	fi
	bb_reset_sys_env
	bb_set_target_local_env_vars
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_set_target_build_local_env
	bb_set_tools_local_env
	# unload last target tools before loading the new target's tools
	if [ -n "${BB_LOCAL_ENV_LAST_TARGET}" ]; then
		BB_DISABLE_LOCAL_ENV_SET=1
		local saved_target=${BB_TARGET}
		bb_set_project_current_target "${BB_LOCAL_ENV_LAST_TARGET}"
		bb_unload_tools
		bb_set_project_current_target "${saved_target}"
		unset BB_DISABLE_LOCAL_ENV_SET
	fi
	# load current target tools
	bb_load_tools
	bb_local_env_updated
	return 0
}
bb_exportfn bb_set_local_env

## @fn bb_reset_local_env
## Reset local environment.
## @env `BB_DISABLE_LOCAL_ENV_SET`, if set, makes the function skip
## immediately
## @resetenv `CPU`
## @resetenv `CPUDEF`
## @resetenv `CPU_DESCRIPTION`
## @resetenv `CFLAGS`
## @resetenv `LDFLAGS`
## @resetenv `CHOST`
## @resetenv `CPU_FAMILY`
## @resetenv `PREFIX`
## @resetenv `PKG_CONFIG_PATH`
## @resetenv `LD_LIBRARY_PATH`
## @resetenv `PYTHONPATH`
## @resetenv `ACLOCAL_PATH`
## @resetenv Variables reset by bb_unset_target_local_env_vars()
## @resetenv bb_reset_sys_env() is called to restore default values for some
## variables
function bb_reset_local_env {
	if [ -n "${BB_DISABLE_LOCAL_ENV_SET}" ]; then
		return 0
	fi
	unset CPU
	unset CPUDEF
	unset CPU_FAMILY
	unset CPU_DESCRIPTION
	unset CFLAGS
	unset LDFLAGS
	unset CHOST
	unset PREFIX
	unset PKG_CONFIG_PATH
	unset LD_LIBRARY_PATH
	unset PYTHONPATH
	unset ACLOCAL_PATH
	bb_unset_target_local_env_vars
	bb_reset_sys_env
}
bb_exportfn bb_reset_local_env

