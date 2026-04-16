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

function test_bb_get_project_current_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	asserteq bar ${target}
	bb_set_project_current_target foo
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	asserteq foo ${target}
}
bb_declare_test test_bb_get_project_current_target

function test_bb_get_project_current_target_default {
	bb_use_test_project foo_project
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	# default_target symlink points to target.bar in foo_project fixture
	asserteq bar ${target}
}
bb_declare_test test_bb_get_project_current_target_default

function test_bb_get_project_current_target_no_project {
	target=$(bb_get_project_current_target)
	asserteq $? 0
	assertz ${target}
}
bb_declare_test test_bb_get_project_current_target_no_project
