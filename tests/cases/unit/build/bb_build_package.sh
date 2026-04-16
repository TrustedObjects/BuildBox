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

function test_bb_build_package_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out=$(foo_package)
	asserteq "${out}" "Hello from foo package"
}
bb_declare_test test_bb_build_package_prebuilt

function test_bb_build_package_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "bar_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	bb_build_package "bar_package"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out=$(bar_package)
	asserteq "${out}" "Hello from bar package !"
}
bb_declare_test test_bb_build_package_autotools

function test_bb_build_package_autotools_with_option {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "bar_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	# text option
	bb_build_package "bar_package" "msg=Test"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out=$(bar_package)
	asserteq "${out}" "Test"
	# binary option
	bb_build_package "bar_package" "-output"
	asserteq $? 0
	out=$(bar_package)
	assertz "${out}"
	# binary + text option
	bb_build_package "bar_package" "+stderr-output msg=Test"
	asserteq $? 0
	out=$(bar_package)
	asserteq "${out}" "Test"
	out=$(bar_package 2>&1 > /dev/null)
	asserteq "${out}" "Test"
	# override default options defined in package file
	assertf "${BB_TARGET_BUILD_DIR}/share/ressource1"
	assertnf "${BB_TARGET_BUILD_DIR}/share/ressource2"
	rm "${BB_TARGET_BUILD_DIR}/share/ressource1"
	bb_build_package "bar_package" "-ressource1_install +ressource2_install"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/share/ressource1"
	assertf "${BB_TARGET_BUILD_DIR}/share/ressource2"
}
bb_declare_test test_bb_build_package_autotools_with_option

function test_bb_build_package_autotools_bug {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "bar_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	bb_build_package "bar_package" "+build-bug"
	assertne $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_bb_build_package_autotools_bug

function test_bb_build_package_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	bb_build_package "baz_package"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	out=$(baz_package)
	asserteq "${out}" "Hello from baz package !"
}
bb_declare_test test_bb_build_package_make

function test_bb_build_package_make_with_option {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	bb_build_package "baz_package" "msg=Test"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	out=$(baz_package)
	asserteq "${out}" "Test"
}
bb_declare_test test_bb_build_package_make_with_option

function test_bb_build_package_make_bug {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	bb_build_package "baz_package" "bug=1"
	assertne $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
}
bb_declare_test test_bb_build_package_make_bug

function test_bb_build_package_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_clone_package "qux_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	bb_build_package "qux_package"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	out=$(qux_package)
	asserteq "${out}" "Hello from qux package !"
}
bb_declare_test test_bb_build_package_custom

function test_bb_build_package_custom_with_option {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_clone_package "qux_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	bb_build_package "qux_package" "msg=Test"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	out=$(qux_package)
	asserteq "${out}" "Test"
}
bb_declare_test test_bb_build_package_custom_with_option

function test_bb_build_package_custom_bug {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_clone_package "qux_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	bb_build_package "qux_package" "build_bug=1"
	assertne $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
}
bb_declare_test test_bb_build_package_custom_bug

function test_bb_build_package_subdir {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "subdir/quux_package"
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	bb_build_package "subdir/quux_package"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	out=$(quux_package)
	asserteq "${out}" "Hello from quux package"
}
bb_declare_test test_bb_build_package_subdir

function test_bb_build_package_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "unknown"
	assertne $? 0
}
bb_declare_test test_bb_build_package_unknown

function test_bb_build_package_not_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out=$(foo_package)
	asserteq "${out}" "Hello from foo package"
}
bb_declare_test test_bb_build_package_not_cloned

function test_bb_build_package_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz ## 2.x
	asserteq $? 0
	bb_clone_package "grault_package"
	asserteq $? 0
	bb_build_package "grault_package"
	assertne $? 0
}
bb_declare_test test_bb_build_package_unsupported_build_mode

