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
	bb_set_project_current_target bar
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
	bb_set_project_current_target bar
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

function test_bb_load_tools_revision_with_slashes {
	bb_use_test_project foo_project
	asserteq $? 0
	# A dedicated target, requiring a tool on a revision holding '/'
	printf 'foo_tool@branch/with/slashes\n' > "${BB_PROJECT_PROFILE_DIR}/tools.slashes"
	printf 'PACKAGES=packages.bar\nTOOLS=tools.slashes\n' > "${BB_PROJECT_PROFILE_DIR}/target.slashes"
	bb_set_project_current_target slashes
	asserteq $? 0
	bb_clone_tool "foo_tool@branch/with/slashes"
	asserteq $? 0
	# The '/' of the revision are escaped, so the tool stays in a single
	# directory, and the cloned revision is the requested one
	assertd "${BB_TOOLS_DIR}/foo_tool@branch_with_slashes"
	assertf "${BB_TOOLS_DIR}/foo_tool@branch_with_slashes/SLASH_BRANCH"
	# The hooks of that very directory are the ones which run
	mkdir -p ${BB_TARGET_DIR}
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
	bb_load_tools
	asserteq $? 0
	assertf ${BB_TARGET_DIR}/foo_test_tool_loaded
	bb_unload_tools
	asserteq $? 0
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
}
bb_declare_test test_bb_load_tools_revision_with_slashes

function test_bb_load_tools_path_prefixed_tool {
	bb_use_test_project foo_project
	asserteq $? 0
	# A tool referenced through a path prefix is installed under its base
	# name, so its hooks must be looked for there. The fixture tool holding
	# hooks is not path prefixed, hence this package file.
	printf 'SRC_PROTO=git\nSRC_URI=${BB_TEST_REPOSITORY_URI}/foo_tool.git\nSRC_REVISION=master\n' \
		> "${BB_PROJECT_PROFILE_DIR}/packages/subdir/prefixed_tool"
	printf 'subdir/prefixed_tool\n' > "${BB_PROJECT_PROFILE_DIR}/tools.prefixed"
	printf 'PACKAGES=packages.bar\nTOOLS=tools.prefixed\n' > "${BB_PROJECT_PROFILE_DIR}/target.prefixed"
	bb_set_project_current_target prefixed
	asserteq $? 0
	bb_clone_tool "subdir/prefixed_tool"
	asserteq $? 0
	assertd "${BB_TOOLS_DIR}/prefixed_tool"
	mkdir -p ${BB_TARGET_DIR}
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
	bb_load_tools
	asserteq $? 0
	assertf ${BB_TARGET_DIR}/foo_test_tool_loaded
	bb_unload_tools
	asserteq $? 0
	assertnf ${BB_TARGET_DIR}/foo_test_tool_loaded
}
bb_declare_test test_bb_load_tools_path_prefixed_tool
