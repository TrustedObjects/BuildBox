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

function test_bb_unset_target_local_env_vars {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	asserteq "${BB_TARGET_VAR_FOO}" "foo"
	asserteq "${BB_TARGET_VAR_BAR}" "bar"
	bb_unset_target_local_env_vars
	asserteq $? 0
	assertz "${BB_TARGET_VAR_FOO}"
	assertz "${BB_TARGET_VAR_BAR}"
}
bb_declare_test test_bb_unset_target_local_env_vars
