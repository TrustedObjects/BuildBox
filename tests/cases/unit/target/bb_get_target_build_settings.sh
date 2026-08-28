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

function test_bb_get_target_build_settings {
	bb_use_test_project foo_project
	asserteq $? 0
	settings=$(bb_get_target_build_settings foo)
	asserteq $? 0
	# Fixture target only defines CPU
	asserteq "${settings}" "CPU=x86"
}
bb_declare_test test_bb_get_target_build_settings

function test_bb_get_target_build_settings_nothing_defined {
	bb_use_test_project foo_project
	asserteq $? 0
	# A target profile is allowed to define no build setting at all
	: > "${BB_PROJECT_PROFILE_DIR}/target.bare"
	settings=$(bb_get_target_build_settings bare)
	asserteq $? 0
	assertz "${settings}"
}
bb_declare_test test_bb_get_target_build_settings_nothing_defined

function test_bb_get_target_build_settings_all {
	bb_use_test_project foo_project
	asserteq $? 0
	cat > "${BB_PROJECT_PROFILE_DIR}/target.full" <<-EOT
		CPU=cortex-m33
		CPU_FAMILY=ARM
		CPU_DESCRIPTION="Cortex-M33 core"
		CPUDEF=MY_M33
		CHOST=arm-none-eabi
		CFLAGS="-mcpu=cortex-m33 -mthumb -DFOO=1"
		LDFLAGS="-specs=nosys.specs -Wl,--gc-sections"
		PACKAGES=packages.foo
		DESCRIPTION="Full target"
		VAR_FOO=foo
	EOT
	settings=$(bb_get_target_build_settings full)
	asserteq $? 0
	asserteq "$(echo "${settings}"|grep '^CPU='|cut -d= -f2-)" "cortex-m33"
	asserteq "$(echo "${settings}"|grep '^CPU_FAMILY='|cut -d= -f2-)" "ARM"
	asserteq "$(echo "${settings}"|grep '^CPU_DESCRIPTION='|cut -d= -f2-)" "Cortex-M33 core"
	asserteq "$(echo "${settings}"|grep '^CPUDEF='|cut -d= -f2-)" "MY_M33"
	asserteq "$(echo "${settings}"|grep '^CHOST='|cut -d= -f2-)" "arm-none-eabi"
	asserteq "$(echo "${settings}"|grep '^CFLAGS='|cut -d= -f2-)" "-mcpu=cortex-m33 -mthumb -DFOO=1"
	asserteq "$(echo "${settings}"|grep '^LDFLAGS='|cut -d= -f2-)" "-specs=nosys.specs -Wl,--gc-sections"
	# Only build settings are reported
	asserteq "$(echo "${settings}"|grep -c '^\(PACKAGES\|DESCRIPTION\|VAR_FOO\)=')" "0"
}
bb_declare_test test_bb_get_target_build_settings_all

function test_bb_get_target_build_settings_do_not_exist {
	# No project, no target
	settings=$(bb_get_target_build_settings dontexist)
	assertne $? 0
	# Project, but no matching target
	bb_use_test_project foo_project
	asserteq $? 0
	settings=$(bb_get_target_build_settings dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_build_settings_do_not_exist

function test_bb_get_target_build_settings_quoted_value {
	bb_use_test_project foo_project
	asserteq $? 0
	# Values are reported as they are, quotes and spaces included
	cat > "${BB_PROJECT_PROFILE_DIR}/target.quoted" <<-EOT
		CFLAGS='-DFOO="bar baz" -Wall'
	EOT
	settings=$(bb_get_target_build_settings quoted)
	asserteq $? 0
	asserteq "${settings}" 'CFLAGS=-DFOO="bar baz" -Wall'
}
bb_declare_test test_bb_get_target_build_settings_quoted_value
