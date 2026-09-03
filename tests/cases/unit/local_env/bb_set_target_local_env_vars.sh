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

function test_bb_set_target_local_env_vars {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	asserteq "${BB_TARGET_VAR_FOO}" "foo"
	asserteq "${BB_TARGET_VAR_BAR}" "bar"
	bb_unset_target_local_env_vars
	asserteq $? 0
	assertz "${BB_TARGET_VAR_FOO}"
	assertz "${BB_TARGET_VAR_BAR}"
	bb_set_target_local_env_vars
	asserteq $? 0
	asserteq "${BB_TARGET_VAR_FOO}" "foo"
	asserteq "${BB_TARGET_VAR_BAR}" "bar"
}
bb_declare_test test_bb_set_target_local_env_vars

function test_bb_set_target_local_env_vars_target_not_set {
	bb_set_target_local_env_vars
	assertne $? 0
}
bb_declare_test test_bb_set_target_local_env_vars_target_not_set

function test_bb_set_target_local_env_vars_expansion {
	bb_use_test_project foo_project
	asserteq $? 0
	{
		printf '_CONFIG=my_config\n'
		printf 'VAR_PLAIN=plain\n'
		printf 'VAR_QUOTED="quoted"\n'
		printf 'VAR_LOCAL="${_CONFIG}"\n'
		printf 'VAR_BUILDBOX="${BB_PROJECT}"\n'
		printf 'VAR_COMPOSED="${_CONFIG}/sub dir"\n'
		printf 'VAR_EQUAL="a=b"\n'
	} > "${BB_PROJECT_PROFILE_DIR}/target.expand"
	bb_set_project_current_target expand
	asserteq $? 0
	asserteq "${BB_TARGET_VAR_PLAIN}" "plain"
	# Quotes are not part of the value
	asserteq "${BB_TARGET_VAR_QUOTED}" "quoted"
	# A variable of the profile itself, and a BuildBox one
	asserteq "${BB_TARGET_VAR_LOCAL}" "my_config"
	asserteq "${BB_TARGET_VAR_BUILDBOX}" "foo_project"
	# A value may hold spaces, and '=' signs of its own
	asserteq "${BB_TARGET_VAR_COMPOSED}" "my_config/sub dir"
	asserteq "${BB_TARGET_VAR_EQUAL}" "a=b"
	assertz "${_CONFIG}"
}
bb_declare_test test_bb_set_target_local_env_vars_expansion
