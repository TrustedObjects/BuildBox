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

function test_target_fastbuild {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	# Modify a package and do fast build
	sed -i 's/MESSAGE\"/MESSAGE\" updated/' ${BB_TARGET_SRC_DIR}/bar_package.sources/main.c
	target fastbuild
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/target_fastbuild.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_fastbuild.log)"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package ! updated"
}
bb_declare_test test_target_fastbuild

function test_target_fastbuild_first {
	bb_use_test_project foo_project
	asserteq $? 0
	target fastbuild
	# fail because some packages on this target require configuration
	assertne $? 0
	assertf "${BB_TARGET_DIR}/target_fastbuild.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_fastbuild.log)"
}
bb_declare_test test_target_fastbuild_first

function test_target_fastbuild_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	out="$(target fastbuild 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_fastbuild_no_err_log

function test_target_fastbuild_project_not_set {
	out="$(target fastbuild 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_fastbuild_project_not_set

function test_target_fastbuild_verbose {
	bb_use_test_project foo_project
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	main_c="${BB_TARGET_SRC_DIR}/bar_package.sources/main.c"
	sed -i 's/MESSAGE\"/MESSAGE\" updated/' "${main_c}"
	out="$(target fastbuild -v 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	# The package is built again
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package ! updated"
	# Build output, compiler warnings included, is shown on the console
	assertn "$(echo "${out}" | grep "warning: #warning \"A warning\"")"
	assertn "$(echo "${out}" | grep "bar_package built with 2 warning(s)")"
	# and still written to the log file
	assertn "$(grep "warning: #warning \"A warning\"" "${BB_TARGET_DIR}/target_fastbuild.log")"
	# Unlike a fast build without the option
	sed -i 's/ updated/ updated again/' "${main_c}"
	out="$(target fastbuild 2>&1)"
	asserteq $? 0
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package ! updated again"
	assertz "$(echo "${out}" | grep "#warning")"
	assertn "$(grep "warning: #warning \"A warning\"" "${BB_TARGET_DIR}/target_fastbuild.log")"
}
bb_declare_test test_target_fastbuild_verbose

function test_target_fastbuild_continue {
	bb_use_test_project foo_project
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	# Break bar_package, which comes after foo_package@1.0
	main_c="${BB_TARGET_SRC_DIR}/bar_package.sources/main.c"
	sed -i '1i #error "broken on purpose"' "${main_c}"
	target fastbuild > /dev/null 2>&1
	assertne $? 0
	asserteq "$(cat "${BB_TARGET_DIR}/target_build.step")" "foo_package@1.0"
	# Fix it, and remove what foo_package@1.0 installed: a package built again
	# would install it back
	sed -i '1d' "${main_c}"
	sed -i 's/MESSAGE\"/MESSAGE\" updated/' "${main_c}"
	rm "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(target fastbuild -c 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	# Built up to the failed package is skipped, the rest is built
	assertn "$(echo "${out}" | grep "Building foo_package@1.0 ... skip")"
	assertnf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/bar_package)" "Hello from bar package ! updated"
	assertnf "${BB_TARGET_DIR}/target_build.step"
}
bb_declare_test test_target_fastbuild_continue

