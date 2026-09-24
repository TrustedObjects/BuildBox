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

function test_target_clone {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd "${BB_TARGET_SRC_DIR}"
	assertnd "${BB_PROJECT_SRC_DIR}"
	target clone
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/target_clone.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_clone.log)"
	assertd "${BB_TARGET_SRC_DIR}"
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
}
bb_declare_test test_target_clone

function test_target_clone_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	# Release the target as a prebuilt, then start again from a fresh copy
	# of the project, the server keeping what it received
	target build > /dev/null
	asserteq $? 0
	target dist-prebuilt > /dev/null
	asserteq $? 0
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd "${BB_TARGET_BUILD_DIR}"
	out="$(target clone -p)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	assertn "$(echo "${out}" | grep "Getting prebuilt files... ok")"
	# Built files are there without building anything
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/foo_package)" "Hello from foo package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package !"
	# Target specific build directories too, next to the shared sources
	assertd "${BB_TARGET_SRC_DIR}/bar_package.build"
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
}
bb_declare_test test_target_clone_prebuilt

function test_target_clone_prebuilt_not_available {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	out="$(target clone -p)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	assertn "$(echo "${out}" | grep "Getting prebuilt files... not available")"
	assertnd "${BB_TARGET_BUILD_DIR}"
	# Sources are cloned all the same
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
}
bb_declare_test test_target_clone_prebuilt_not_available

function test_target_clone_prebuilt_other_tag {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	# The prebuilt belongs to v1.0.0, the project is now past it
	bb_commit_test_project_profile
	asserteq $? 0
	out="$(target clone -p)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	assertn "$(echo "${out}" | grep "Getting prebuilt files... not available")"
	assertnd "${BB_TARGET_BUILD_DIR}"
}
bb_declare_test test_target_clone_prebuilt_other_tag

function test_target_clone_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target clone 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_clone_no_err_log

function test_target_clone_project_not_set {
	out="$(target clone 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_clone_project_not_set

