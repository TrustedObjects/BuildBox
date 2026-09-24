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
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target build -v 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	# Packages are built
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/foo_package)" "Hello from foo package"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package !"
	# Build output, compiler warnings included, is shown on the console
	assertn "$(echo "${out}" | grep -E "Building bar_package, options: +\+ressource1_install\.\.\.")"
	assertn "$(echo "${out}" | grep "warning: #warning \"A warning\"")"
	assertn "$(echo "${out}" | grep "bar_package built with 2 warning(s)")"
	assertn "$(echo "${out}" | grep "OK, foo_package@1.0 built.")"
	# and still written to the log file
	assertn "$(grep "warning: #warning \"A warning\"" "${BB_TARGET_DIR}/target_build.log")"
	# Unlike a build without the option
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target build 2>&1)"
	asserteq $? 0
	assertz "$(echo "${out}" | grep "#warning")"
	assertn "$(grep "warning: #warning \"A warning\"" "${BB_TARGET_DIR}/target_build.log")"
}
bb_declare_test test_target_build_verbose

function test_target_build_continue {
	bb_use_test_project foo_project
	asserteq $? 0
	target clone > /dev/null
	asserteq $? 0
	# Break bar_package, which comes after foo_package@1.0
	main_c="${BB_TARGET_SRC_DIR}/bar_package.sources/main.c"
	sed -i '1i #error "broken on purpose"' "${main_c}"
	target build > /dev/null 2>&1
	assertne $? 0
	asserteq "$(cat "${BB_TARGET_DIR}/target_build.step")" "foo_package@1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	# Fix it, and remove what foo_package@1.0 installed: a package built again
	# would install it back
	sed -i '1d' "${main_c}"
	rm "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(target build -c 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	# Built up to the failed package is skipped, the rest is built
	assertn "$(echo "${out}" | grep "Building foo_package@1.0 ... skip")"
	assertnf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package !"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/corge_package)" "Hello from corge package"
	assertnf "${BB_TARGET_DIR}/target_build.step"
	# Nothing left to continue: the build starts over, with a warning
	out="$(target build --continue 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	assertn "$(echo "${out}" | grep "there is no build to continue")"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
}
bb_declare_test test_target_build_continue

