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

function test_pkg_executable_build {
	bb_use_test_project foo_project
	asserteq $? 0

	# 1. Create a dummy script to be used as an executable package
	local script_path="${BB_TEST_WORKSPACE}/my_script.sh"
	echo '#!/bin/sh' > "${script_path}"
	echo 'echo "Hello from executable script"' >> "${script_path}"
	chmod +x "${script_path}"
	local sha256=$(sha256sum "${script_path}" | cut -d' ' -f 1)

	# 2. Create the package file in the project profile
	local pkg_file="${BB_PROJECT_PROFILE_DIR}/packages/executable_package"
	echo "SRC_PROTO=http" > "${pkg_file}"
	echo "SRC_URI=file://${script_path}" >> "${pkg_file}"
	echo "SRC_REVISION=${sha256}" >> "${pkg_file}"
	echo "SRC_BUILD=executable" >> "${pkg_file}"
	echo "SRC_PROTO_OPTIONS=-extract" >> "${pkg_file}"

	# 3. Add the package to the target packages list
	# We use the current target's package list
	target_profile=$(bb_get_target_profile_path ${BB_TARGET})
	bb_source ${target_profile}
	local packages_list="${BB_PROJECT_PROFILE_DIR}/${PACKAGES}"
	echo "executable_package" >> "${packages_list}"

	# 4. Build the package
	build executable_package
	asserteq $? 0

	# 5. Verify installation
	assertf "${BB_TARGET_BUILD_DIR}/bin/my_script.sh"
	test -x "${BB_TARGET_BUILD_DIR}/bin/my_script.sh"
	asserteq $? 0

	local out=$("${BB_TARGET_BUILD_DIR}/bin/my_script.sh")
	asserteq "${out}" "Hello from executable script"
}
bb_declare_test test_pkg_executable_build

function test_pkg_http_no_extract_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0

	# Test that -extract also works with 'prebuilt' build mode
	# even if 'executable' is the main use case.
	
	local data_path="${BB_TEST_WORKSPACE}/data.txt"
	echo "some data" > "${data_path}"
	local sha256=$(sha256sum "${data_path}" | cut -d' ' -f 1)

	local pkg_file="${BB_PROJECT_PROFILE_DIR}/packages/data_package"
	echo "SRC_PROTO=http" > "${pkg_file}"
	echo "SRC_URI=file://${data_path}" >> "${pkg_file}"
	echo "SRC_REVISION=${sha256}" >> "${pkg_file}"
	echo "SRC_BUILD=prebuilt" >> "${pkg_file}"
	echo "SRC_PROTO_OPTIONS=-extract" >> "${pkg_file}"

	target_profile=$(bb_get_target_profile_path ${BB_TARGET})
	bb_source ${target_profile}
	local packages_list="${BB_PROJECT_PROFILE_DIR}/${PACKAGES}"
	echo "data_package" >> "${packages_list}"

	build data_package
	asserteq $? 0

	# prebuilt mode copies everything to PREFIX
	assertf "${BB_TARGET_BUILD_DIR}/data.txt"
	asserteq "$(cat ${BB_TARGET_BUILD_DIR}/data.txt)" "some data"
}
bb_declare_test test_pkg_http_no_extract_prebuilt
