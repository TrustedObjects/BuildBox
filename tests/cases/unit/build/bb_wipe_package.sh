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

function test_bb_wipe_package_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	bb_wipe_package "foo_package@1.0"
	asserteq $? 0
	assert_does_not_exists "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertnl "${BB_TARGET_SRC_DIR}/foo_package.sources"
}
bb_declare_test test_bb_wipe_package_prebuilt

function test_bb_wipe_package_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_TARGET_SRC_DIR}/bar_package.build"
	bb_wipe_package "bar_package"
	asserteq $? 0
	assert_does_not_exists "${BB_PROJECT_SRC_DIR}/bar_package"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/bar_package"
	assertnl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/bar_package.build"
}
bb_declare_test test_bb_wipe_package_autotools

function test_bb_wipe_package_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_build_package "baz_package"
	asserteq $? 0
	assertd "${BB_PROJECT_SRC_DIR}/baz_package"
	assertd "${BB_TARGET_SRC_DIR}/baz_package"
	assertl "${BB_TARGET_SRC_DIR}/baz_package.sources"
	bb_wipe_package "baz_package"
	asserteq $? 0
	assert_does_not_exists "${BB_PROJECT_SRC_DIR}/baz_package"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/baz_package"
	assertnl "${BB_TARGET_SRC_DIR}/baz_package.sources"
}
bb_declare_test test_bb_wipe_package_make

function test_bb_wipe_package_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	bb_build_package "qux_package"
	asserteq $? 0
	assertd "${BB_PROJECT_SRC_DIR}/qux_package"
	assertd "${BB_TARGET_SRC_DIR}/qux_package"
	assertl "${BB_TARGET_SRC_DIR}/qux_package.sources"
	bb_wipe_package "qux_package"
	asserteq $? 0
	assert_does_not_exists "${BB_PROJECT_SRC_DIR}/qux_package"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/qux_package"
	assertnl "${BB_TARGET_SRC_DIR}/qux_package.sources"
}
bb_declare_test test_bb_wipe_package_custom

function test_bb_wipe_package_subdir {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "subdir/quux_package"
	asserteq $? 0
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertd "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	bb_wipe_package "subdir/quux_package"
	asserteq $? 0
	assert_does_not_exists "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assert_does_not_exists "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertnl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
}
bb_declare_test test_bb_wipe_package_subdir

function test_bb_wipe_package_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_wipe_package "unknown"
	assertne $? 0
}
bb_declare_test test_bb_wipe_package_unknown

function test_bb_wipe_package_not_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_wipe_package "foo_package@1.0"
	asserteq $? 0
}
bb_declare_test test_bb_wipe_package_not_cloned

function test_bb_wipe_package_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz
	asserteq $? 0
	bb_clone_package "grault_package"
	asserteq $? 0
	bb_wipe_package "grault_package"
	assertne $? 0
}
bb_declare_test test_bb_wipe_package_unsupported_build_mode

