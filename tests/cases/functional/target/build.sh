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

function test_target_build {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/target_build.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_build.log)"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/foo_package)"
	asserteq "${out}" "Hello from foo package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package !"
	assertf "${BB_TARGET_BUILD_DIR}/bin/corge_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/corge_package)"
	asserteq "${out}" "Hello from corge package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/quux_package)"
	asserteq "${out}" "Hello from quux package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/http_package_binary"
	out="$(${BB_TARGET_BUILD_DIR}/bin/http_package_binary)"
	asserteq "${out}" "Hello from HTTP prebuilt package"
}
bb_declare_test test_target_build

function test_target_build_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target build 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_build_no_err_log

function test_target_build_project_not_set {
	out="$(target build 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_build_project_not_set

function test_target_build_verbose {
	skip "test not implemented yet"
}
bb_declare_test test_target_build_verbose

function test_target_build_continue {
	skip "test not implemented yet"
}
bb_declare_test test_target_build_continue

