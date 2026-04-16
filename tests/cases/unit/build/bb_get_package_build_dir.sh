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

function test_bb_get_package_build_dir_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	build_dir=$(bb_get_package_build_dir "foo_package@1.0")
	asserteq $? 0
	assert_is_subpath_of ${BB_TARGET_DIR} ${build_dir}
	assertd ${build_dir}
}
bb_declare_test test_bb_get_package_build_dir_prebuilt

function test_bb_get_package_build_dir_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# doesn't exist yet, error
	bb_get_package_build_dir "bar_package"
	assertne $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	# exists now, no error
	build_dir=$(bb_get_package_build_dir "bar_package")
	asserteq $? 0
	assert_is_subpath_of ${BB_TARGET_DIR} ${build_dir}
	assertd ${build_dir}
}
bb_declare_test test_bb_get_package_build_dir_autotools

function test_bb_get_package_build_dir_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# doesn't exist yet, error
	bb_get_package_build_dir "baz_package"
	assertne $? 0
	bb_build_package "baz_package"
	asserteq $? 0
	# exists now, no error
	build_dir=$(bb_get_package_build_dir "baz_package")
	asserteq $? 0
	assert_is_subpath_of ${BB_TARGET_DIR} ${build_dir}
	assertd ${build_dir}
}
bb_declare_test test_bb_get_package_build_dir_make

function test_bb_get_package_build_dir_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	# doesn't exist yet, error
	bb_get_package_build_dir "baz_package"
	assertne $? 0
	bb_build_package "qux_package"
	asserteq $? 0
	build_dir=$(bb_get_package_build_dir "qux_package")
	asserteq "${build_dir}" "${BB_TARGET_SRC_DIR}/qux_package"
	asserteq $? 0
}
bb_declare_test test_bb_get_package_build_dir_custom

function test_bb_get_package_build_dir_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_get_package_build_dir "unknown"
	assertne $? 0
}
bb_declare_test test_bb_get_package_build_dir_unknown

function test_bb_get_package_build_dir_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz ## 2.x
	asserteq $? 0
	bb_get_package_build_dir "grault_package"
	assertne $? 0
}
bb_declare_test test_bb_get_package_build_dir_unsupported_build_mode

