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

## Set isolated system and user configuration directories for the running test.
## @setenv BB_SYSTEM_CONFIG_DIR, BB_USER_CONFIG_DIR
## @return 0 on success
function bb_setup_test_config_dirs {
	export BB_SYSTEM_CONFIG_DIR="${BB_TEST_WORKSPACE}/test_system_config"
	export BB_USER_CONFIG_DIR="${BB_TEST_WORKSPACE}/test_user_config"
	rm -rf "${BB_SYSTEM_CONFIG_DIR}" "${BB_USER_CONFIG_DIR}"
	mkdir -p "${BB_SYSTEM_CONFIG_DIR}" "${BB_USER_CONFIG_DIR}"
	return 0
}

function test_bb_get_system_config_dir {
	local saved="${BB_SYSTEM_CONFIG_DIR}"
	# BB_SYSTEM_CONFIG_DIR has precedence, it is how tests are isolated from
	# the machine configuration
	export BB_SYSTEM_CONFIG_DIR="/somewhere/buildbox"
	asserteq "$(bb_get_system_config_dir)" "/somewhere/buildbox"
	unset BB_SYSTEM_CONFIG_DIR
	asserteq "$(bb_get_system_config_dir)" "/etc/buildbox"
	export BB_SYSTEM_CONFIG_DIR="${saved}"
}
bb_declare_test test_bb_get_system_config_dir

function test_bb_get_user_config_dir {
	local saved="${BB_USER_CONFIG_DIR}"
	# BB_USER_CONFIG_DIR has precedence, it is how the host configuration
	# directory is located inside the container
	export BB_USER_CONFIG_DIR="/somewhere/buildbox"
	asserteq "$(bb_get_user_config_dir)" "/somewhere/buildbox"
	unset BB_USER_CONFIG_DIR
	local saved_xdg="${XDG_CONFIG_HOME}"
	export XDG_CONFIG_HOME="/xdg"
	asserteq "$(bb_get_user_config_dir)" "/xdg/buildbox"
	unset XDG_CONFIG_HOME
	asserteq "$(bb_get_user_config_dir)" "${HOME}/.config/buildbox"
	[ -n "${saved_xdg}" ] && export XDG_CONFIG_HOME="${saved_xdg}"
	export BB_USER_CONFIG_DIR="${saved}"
}
bb_declare_test test_bb_get_user_config_dir

function test_bb_load_config_defaults {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	bb_setup_test_config_dirs
	unset BB_BUILD_JOBS BB_TRASH_KEEP_DAYS BB_PREBUILT_ONLY_TAGGED
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	# No config at all: built-in defaults apply
	asserteq "${BB_BUILD_JOBS}" "9"
	asserteq "${BB_TRASH_KEEP_DAYS}" "15"
	asserteq "${BB_PREBUILT_ONLY_TAGGED}" "1"
	asserteq "${BB_SYSTEM_CONFIG}" "${BB_SYSTEM_CONFIG_DIR}/config"
	asserteq "${BB_USER_CONFIG}" "${BB_USER_CONFIG_DIR}/config"
	asserteq "${BB_CONFIG}" "${project_dir}/.bbx/config"
}
bb_declare_test test_bb_load_config_defaults

function test_bb_load_config_system {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	bb_setup_test_config_dirs
	cat > "${BB_SYSTEM_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=2
	BB_PREBUILT_SERVER=system.example.com
	EOC
	unset BB_BUILD_JOBS BB_TRASH_KEEP_DAYS BB_PREBUILT_SERVER
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	# System configuration overrides defaults, and is exported
	asserteq "${BB_BUILD_JOBS}" "2"
	asserteq "${BB_PREBUILT_SERVER}" "system.example.com"
	asserteq "${BB_TRASH_KEEP_DAYS}" "15"
	asserteq "$(env | grep '^BB_PREBUILT_SERVER=')" "BB_PREBUILT_SERVER=system.example.com"
}
bb_declare_test test_bb_load_config_system

function test_bb_load_config_user {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	bb_setup_test_config_dirs
	cat > "${BB_USER_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=3
	BB_PREBUILT_SERVER=user.example.com
	EOC
	unset BB_BUILD_JOBS BB_TRASH_KEEP_DAYS BB_PREBUILT_SERVER
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	# User configuration overrides defaults, and is exported
	asserteq "${BB_BUILD_JOBS}" "3"
	asserteq "${BB_PREBUILT_SERVER}" "user.example.com"
	asserteq "${BB_TRASH_KEEP_DAYS}" "15"
	asserteq "$(env | grep '^BB_PREBUILT_SERVER=')" "BB_PREBUILT_SERVER=user.example.com"
}
bb_declare_test test_bb_load_config_user

function test_bb_load_config_precedence {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	bb_setup_test_config_dirs
	cat > "${BB_SYSTEM_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=2
	BB_TRASH_KEEP_DAYS=10
	BB_PREBUILT_SERVER=system.example.com
	BB_PREBUILT_USERNAME=builder
	EOC
	cat > "${BB_USER_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=3
	BB_TRASH_KEEP_DAYS=42
	BB_PREBUILT_SERVER=user.example.com
	EOC
	cat > "${project_dir}/.bbx/config" <<-EOC
	BB_BUILD_JOBS=7
	BB_PREBUILT_PATH=/srv/prebuilt
	EOC
	unset BB_BUILD_JOBS BB_TRASH_KEEP_DAYS
	unset BB_PREBUILT_SERVER BB_PREBUILT_USERNAME BB_PREBUILT_PATH
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	# Project overrides user, which overrides system
	asserteq "${BB_BUILD_JOBS}" "7"
	asserteq "${BB_TRASH_KEEP_DAYS}" "42"
	asserteq "${BB_PREBUILT_SERVER}" "user.example.com"
	# Settings not redefined by a higher priority file are kept
	asserteq "${BB_PREBUILT_USERNAME}" "builder"
	asserteq "${BB_PREBUILT_PATH}" "/srv/prebuilt"
}
bb_declare_test test_bb_load_config_precedence

function test_bb_load_config_no_project {
	bb_setup_test_config_dirs
	cat > "${BB_SYSTEM_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=2
	BB_TRASH_KEEP_DAYS=11
	EOC
	cat > "${BB_USER_CONFIG_DIR}/config" <<-EOC
	BB_BUILD_JOBS=5
	EOC
	unset BB_PROJECT_DIR BB_PROJECT_PROFILE_DIR BB_BUILD_JOBS BB_TRASH_KEEP_DAYS
	bb_load_config
	asserteq $? 0
	# Without a project, only system and user configurations are loaded
	asserteq "${BB_BUILD_JOBS}" "5"
	asserteq "${BB_TRASH_KEEP_DAYS}" "11"
	assertz "${BB_CONFIG}"
}
bb_declare_test test_bb_load_config_no_project
