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

function test_bb_load_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_clone_tool "subdir/bar_tool"
	asserteq $? 0
	bb_clone_tool baz_tool
	asserteq $? 0
	mkdir -p ${BB_TARGET_DIR}
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
	assertnf ${BB_TARGET_DIR}/baz_test_tool_loaded
	bb_load_tools
	asserteq $? 0
	assertf ${BB_TARGET_DIR}/foo_test_tool_loaded
	assertf ${BB_TARGET_DIR}/baz_test_tool_loaded
	bb_unload_tools
	asserteq $? 0
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
	assertnf ${BB_TARGET_DIR}/baz_test_tool_loaded
}
bb_declare_test test_bb_load_tools

function main_error_handler {
	export ERROR_HANDLER="main"
}

function test_bb_load_tools_error_handler_restoration {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_tool baz_tool
	asserteq $? 0
	bb_trap_errors_custom main_error_handler
	asserteq $? 0
	assertz "${ERROR_HANDLER}"
	mkdir -p "${BB_TARGET_DIR}"
	# Load / unload tools (baz tool uses its own error handler), and check the main handler is restored
	bb_load_tools
	asserteq $? 0
	false
	asserteq "${ERROR_HANDLER}" "main"
	unset ERROR_HANDLER
	bb_unload_tools
	asserteq $? 0
	false
	asserteq "${ERROR_HANDLER}" "main"
}
bb_declare_test test_bb_load_tools_error_handler_restoration

