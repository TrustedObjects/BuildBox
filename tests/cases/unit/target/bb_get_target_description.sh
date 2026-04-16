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

function test_bb_get_target_description {
	bb_use_test_project foo_project
	assertq $? 0
	description=$(bb_get_target_description foo)
	asserteq $? 0
	asserteq "${description}" "Foo target"
}
bb_declare_test test_bb_get_target_description

function test_bb_get_target_description_do_not_exist {
	# No project, no target
	targets=$(bb_get_target_description dontexist)
	assertne $? 0
	# Project, but no matching target
	bb_use_test_project foo_project
	assertq $? 0
	targets=$(bb_get_target_description dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_description_do_not_exist

