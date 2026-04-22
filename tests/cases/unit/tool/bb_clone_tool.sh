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

function test_bb_clone_tool {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	# we can clone a tool even if it is not required by current target
	bb_clone_tool foo_tool
	asserteq $? 0
	assertd "${BB_TOOLS_DIR}/foo_tool"
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	assertd "${BB_TOOLS_DIR}/foo_tool@1.0.2"
}
bb_declare_test test_bb_clone_tool

function test_bb_clone_tool_project_not_set {
	bb_clone_tool test_tool
	assertne $? 0
}
bb_declare_test test_bb_clone_tool_project_not_set

function test_bb_clone_tool_non_existing {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_clone_tool dontexist
	assertne $? 0
}
bb_declare_test test_bb_clone_tool_non_existing

function test_bb_clone_tool_and_use {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_clone_tool "subdir/bar_tool"
	asserteq $? 0
	out=$(foo_test_tool)
	asserteq $? 0
	asserteq "${out}" "Hello from FOO test tool"
	out=$(bar_test_tool)
	asserteq $? 0
	asserteq "${out}" "Hello from BAR test tool"
}
bb_declare_test test_bb_clone_tool_and_use
