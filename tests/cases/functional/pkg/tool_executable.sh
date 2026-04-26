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

function test_tool_executable {
	bb_use_test_project foo_project
	asserteq $? 0

	# 1. Create a dummy script for the tool
	local script_path="${BB_TEST_WORKSPACE}/my_tool_script.sh"
	echo '#!/bin/sh' > "${script_path}"
	echo 'echo "Hello from executable tool"' >> "${script_path}"
	chmod +x "${script_path}"
	local sha256=$(sha256sum "${script_path}" | cut -d' ' -f 1)

	# 2. Create the tool package file
	local pkg_file="${BB_PROJECT_PROFILE_DIR}/packages/executable_tool"
	echo "SRC_PROTO=http" > "${pkg_file}"
	echo "SRC_URI=file://${script_path}" >> "${pkg_file}"
	echo "SRC_REVISION=${sha256}" >> "${pkg_file}"
	echo "SRC_BUILD=executable" >> "${pkg_file}"
	echo "SRC_PROTO_OPTIONS=-extract" >> "${pkg_file}"

	# 3. Add the tool to the target tools list
	target_profile=$(bb_get_target_profile_path ${BB_TARGET})
	bb_source ${target_profile}
	local tools_list="${BB_PROJECT_PROFILE_DIR}/${TOOLS}"
	echo "executable_tool" >> "${tools_list}"

	# 4. Clone tools (this triggers the installation of the tool)
	# Using target_clone or simply calling the command that triggers bb_clone_tool
	bbx target clone
	asserteq $? 0

	# 5. Verify installation in BB_TOOLS_DIR
	local tool_install_dir="${BB_TOOLS_DIR}/executable_tool"
	assertd "${tool_install_dir}"
	assertf "${tool_install_dir}/bin/my_tool_script.sh"
	test -x "${tool_install_dir}/bin/my_tool_script.sh"
	asserteq $? 0

	# 6. Verify it is in the PATH when loading tools
	# bb_load_tools is called by target_build, but we can call it manually or check PATH
	# In the test environment, we might need to refresh local env
	bb_set_local_env ${BB_TARGET_BUILD_DIR} ${CPU}
	
	local out=$(my_tool_script.sh)
	asserteq "${out}" "Hello from executable tool"
}
bb_declare_test test_tool_executable
