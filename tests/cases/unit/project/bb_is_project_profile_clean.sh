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

function test_bb_is_project_profile_clean {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_is_project_profile_clean
	asserteq $? 0
}
bb_declare_test test_bb_is_project_profile_clean

function test_bb_is_project_profile_clean_not_clean {
	bb_use_test_project foo_project
	asserteq $? 0
	# Change a profile file
	dev_packages_file=${BB_PROJECT_PROFILE_DIR}/packages.foo
	assertf ${dev_packages_file}
	echo "fakepkg" >> ${dev_packages_file}
	bb_is_project_profile_clean
	asserteq $? 1
}
bb_declare_test test_bb_is_project_profile_clean_not_clean

function test_bb_is_project_profile_clean_not_clean_packages {
	bb_use_test_project foo_project
	asserteq $? 0
	# Change in packages
	package_file=${BB_PROJECT_PROFILE_DIR}/packages/foo_package
	assertf ${package_file}
	echo "newline" >> ${package_file}
	bb_is_project_profile_clean
	asserteq $? 1
}
bb_declare_test test_bb_is_project_profile_clean_not_clean_packages

function test_bb_is_project_profile_clean_non_existing_path {
	bb_is_project_profile_clean "/tmp/does_not_exist_bbx_project_$$"
	asserteq $? 0
}
bb_declare_test test_bb_is_project_profile_clean_non_existing_path
