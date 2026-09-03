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

bb_get_target_vars_expected_vars='VAR_FOO=foo
VAR_BAR=bar'

function test_bb_get_target_vars {
	bb_use_test_project foo_project
	assertq $? 0
	vars=$(bb_get_target_vars bar)
	asserteq $? 0
	asserteq "${vars}" "${bb_get_target_vars_expected_vars}"
	vars=$(bb_get_target_vars foo)
	asserteq $? 0
	assertz "${vars}"
}
bb_declare_test test_bb_get_target_vars

function test_bb_get_target_vars_target_do_not_exist {
	bb_use_test_project foo_project
	assertq $? 0
	vars=$(bb_get_target_vars dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_vars_target_do_not_exist

function test_bb_get_target_vars_project_not_set {
	vars=$(bb_get_target_vars dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_vars_project_not_set

function test_bb_get_target_vars_expansion {
	bb_use_test_project foo_project
	asserteq $? 0
	# A target variable value may use a variable: one the profile defines for
	# its own needs, or a BuildBox one. Quotes around a value are shell
	# quotes, they are not part of it.
	{
		printf '_CONFIG=my_config\n'
		printf 'VAR_PLAIN=plain\n'
		printf 'VAR_QUOTED="quoted"\n'
		printf 'VAR_LOCAL="${_CONFIG}"\n'
		printf 'VAR_BUILDBOX="${BB_PROJECT}"\n'
		printf 'VAR_COMPOSED="${_CONFIG}/sub dir"\n'
		printf 'VAR_EQUAL="a=b"\n'
	} > "${BB_PROJECT_PROFILE_DIR}/target.expand"
	vars=$(bb_get_target_vars expand)
	asserteq $? 0
	expected='VAR_PLAIN=plain
VAR_QUOTED=quoted
VAR_LOCAL=my_config
VAR_BUILDBOX=foo_project
VAR_COMPOSED=my_config/sub dir
VAR_EQUAL=a=b'
	asserteq "${vars}" "${expected}"
	# The profile is sourced in a subshell, nothing leaks to the caller
	assertz "${_CONFIG}"
}
bb_declare_test test_bb_get_target_vars_expansion
