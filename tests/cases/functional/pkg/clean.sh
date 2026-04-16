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

function test_pkg_clean {
	bb_use_test_project foo_project
	asserteq $? 0
	target set bar
	asserteq $? 0
	target build
	asserteq $? 0
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	# clean bar_package and check only built files of this package are removed
	clean bar_package
	asserteq $? 0
	assertd ${BB_PROJECT_DIR}/bar/src/foo_package@1.0
	assertnd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/corge_package
	assertd ${BB_PROJECT_DIR}/bar/src/subdir_quux_package
	assertd ${BB_PROJECT_SRC_DIR}/bar_package
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_pkg_clean

function test_pkg_clean_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	clean package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/http_package_binary"
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertnd "${BB_TARGET_SRC_DIR}/bar_package.build"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_pkg_clean_partial_filter

function test_pkg_clean_twice {
	bb_use_test_project foo_project
	asserteq $? 0
	build bar_package
	asserteq $? 0
	clean bar_package
	asserteq $? 0
	clean bar_package
	asserteq $? 0
}
bb_declare_test test_pkg_clean_twice

function test_pkg_clean_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	target clone
	asserteq $? 0
	out="$(clean unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clean_unknown

function test_pkg_clean_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clean 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clean_empty_filter

function test_pkg_clean_project_not_set {
	out="$(clean bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_clean_project_not_set

