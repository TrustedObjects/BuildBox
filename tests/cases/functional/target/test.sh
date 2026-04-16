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

function test_target_test {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	out="$(target test 2>&1)"
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/tests_out"
	assertn "${out}"
	assertf "${BB_TARGET_DIR}/tests.log"
	assertn "$(cat ${BB_TARGET_DIR}/tests.log)"
	# Log file must contain stdout and stderr
	cat "${BB_TARGET_DIR}/tests.log"
	grep "Testing" "${BB_TARGET_DIR}/tests.log"
	asserteq $? 0
	grep "Test stderr" "${BB_TARGET_DIR}/tests.log"
	asserteq $? 0
}
bb_declare_test test_target_test

function test_target_test_quiet {
	skip "test not implemented yet"
}
bb_declare_test test_target_test_quiet

function test_target_test_fail {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	target test "fail"
	assertne $? 0
	assertnf "${BB_TARGET_DIR}/tests_out"
	assertf "${BB_TARGET_DIR}/tests.log"
	assertn "$(cat ${BB_TARGET_DIR}/tests.log)"
}
bb_declare_test test_target_test_fail

function test_target_test_project_not_set {
	out="$(target test 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_test_project_not_set

