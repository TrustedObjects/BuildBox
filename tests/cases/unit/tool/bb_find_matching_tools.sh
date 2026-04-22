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

function test_bb_find_matching_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	# search test_tool
	tools=$(bb_find_matching_tools foo)
	asserteq $? 0
	asserteq $(echo "${tools}"|wc -l) 1
	echo ${tools}|grep "foo_tool@1\.0\.2"
	asserteq $? 0
	# search foo_tool and bar_tool
	tools=$(bb_find_matching_tools foo bar)
	asserteq $? 0
	asserteq $(echo "${tools}"|wc -l) 2
	echo ${tools}|grep "foo_tool"
	asserteq $? 0
	echo ${tools}|grep "bar_tool"
	asserteq $? 0
	tools=$(bb_find_matching_tools dontexist)
	asserteq $? 0
	assertz ${tools}
}
bb_declare_test test_bb_find_matching_tools

function test_bb_find_matching_tools_no_target_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	tools=$(bb_find_matching_tools test)
	asserteq $? 0
	assertz ${tools}
}
bb_declare_test test_bb_find_matching_tools_no_target_tools

function test_bb_find_matching_tools_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	tools=$(bb_find_matching_tools)
	asserteq $? 1
	assertz "${tools}"
}
bb_declare_test test_bb_find_matching_tools_empty_filter

function test_bb_find_matching_tools_project_not_set {
	tools=$(bb_find_matching_tools test)
	assertne $? 0
	assertz ${tools}
}
bb_declare_test test_bb_find_matching_tools_project_not_set

