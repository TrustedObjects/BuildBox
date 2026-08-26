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

## @brief Configuration
## BuildBox settings defaults can be overridden by `config` files, which are
## plain shell fragments only made of variable assignments.
##
## Three files are read, in increasing priority order:
## 1. the system one, shared by all the users of the machine
## 2. the user one, shared by all the projects of the user
## 3. the project one, stored in the project profile
##
## Each file therefore overrides the previous ones, and all of them override
## BuildBox built-in defaults.
##
## The system and user files are also the shell plugin configuration files, so
## they may hold `BBX_*` settings. These are only read by the host shell
## plugin: they have no effect in the project file.

## @fn bb_get_system_config_dir
## Get the BuildBox system configuration directory.
## `BB_SYSTEM_CONFIG_DIR` is honoured when set, mainly to isolate tests from
## the machine configuration. Else `/etc/buildbox` is used.
## @print System configuration directory absolute path
## @return 0 on success
function bb_get_system_config_dir () (
	if [ -n "${BB_SYSTEM_CONFIG_DIR}" ]; then
		echo "${BB_SYSTEM_CONFIG_DIR}"
	else
		echo "/etc/buildbox"
	fi
)
bb_exportfn bb_get_system_config_dir

## @fn bb_get_user_config_dir
## Get the BuildBox user configuration directory.
## `BB_USER_CONFIG_DIR` is honoured when set, which allows the host
## configuration directory to be bind-mounted at another path inside the
## container. Else the XDG location is used, which is `~/.config/buildbox`
## unless `XDG_CONFIG_HOME` is set.
## @print User configuration directory absolute path
## @return 0 on success
function bb_get_user_config_dir () (
	if [ -n "${BB_USER_CONFIG_DIR}" ]; then
		echo "${BB_USER_CONFIG_DIR}"
	else
		echo "${XDG_CONFIG_HOME:-${HOME}/.config}/buildbox"
	fi
)
bb_exportfn bb_get_user_config_dir

## @fn bb_apply_config_defaults
## Apply BuildBox settings defaults, for every setting left undefined by the
## configuration files.
## @setenv `BB_BUILD_JOBS`, `BB_TRASH_KEEP_DAYS`, `BB_PREBUILT_ONLY_TAGGED`
## @return 0 on success
function bb_apply_config_defaults {
	export BB_BUILD_JOBS="${BB_BUILD_JOBS:-9}"
	export BB_TRASH_KEEP_DAYS="${BB_TRASH_KEEP_DAYS:-15}"
	export BB_PREBUILT_ONLY_TAGGED="${BB_PREBUILT_ONLY_TAGGED:-1}"
	return 0
}
bb_exportfn bb_apply_config_defaults

## @fn bb_load_config
## Load BuildBox configuration files, then apply defaults for the settings they
## leave undefined.
## Files are sourced in increasing priority order:
## 1. `$BB_SYSTEM_CONFIG`: system configuration
## 2. `$BB_USER_CONFIG`: user configuration
## 3. `$BB_CONFIG`: project configuration, skipped when no project is set
## Every variable assigned by these files is exported.
## This function is called by bb_set_current_project() and
## bb_autodetect_project(), so it does not have to be called by hand.
## @setenv `BB_SYSTEM_CONFIG`: system configuration file path
## @setenv `BB_USER_CONFIG`: user configuration file path
## @setenv `BB_CONFIG`: project configuration file path
## @setenv and every variable assigned by the configuration files
## @return 0 on success
function bb_load_config {
	export BB_SYSTEM_CONFIG="$(bb_get_system_config_dir)/config"
	export BB_USER_CONFIG="$(bb_get_user_config_dir)/config"
	if [ -n "${BB_PROJECT_PROFILE_DIR}" ]; then
		export BB_CONFIG="${BB_PROJECT_PROFILE_DIR}/config"
	else
		unset BB_CONFIG
	fi
	# Backup 'allexport', which is turned on to export every setting assigned
	# by the configuration files
	local _bb_config_allexport=0
	case "$-" in
		*a*) _bb_config_allexport=1 ;;
	esac
	local _bb_config_file
	for _bb_config_file in "${BB_SYSTEM_CONFIG}" "${BB_USER_CONFIG}" "${BB_CONFIG}"; do
		[ -n "${_bb_config_file}" ] || continue
		[ -f "${_bb_config_file}" ] || continue
		set -a
		source "${_bb_config_file}"
		if [ ${_bb_config_allexport} -eq 0 ]; then
			set +a
		fi
	done
	# BB_DEBUG may have just been set, refresh the shell options list
	bb_update_shell_options
	bb_apply_config_defaults
	return 0
}
bb_exportfn bb_load_config
