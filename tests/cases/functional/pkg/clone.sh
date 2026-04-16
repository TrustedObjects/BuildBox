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

function test_pkg_clone {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	clone bar_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	clone corge_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	clone quux_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	clone foo_http_package-1.0
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
}
bb_declare_test test_pkg_clone

function test_pkg_clone_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	clone package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
}
bb_declare_test test_pkg_clone_partial_filter

function test_pkg_clone_twice {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
}
bb_declare_test test_pkg_clone_twice

function test_pkg_clone_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clone unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clone_unknown

function test_pkg_clone_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clone 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clone_empty_filter

function test_pkg_clone_project_not_set {
	out="$(clone bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_clone_project_not_set

