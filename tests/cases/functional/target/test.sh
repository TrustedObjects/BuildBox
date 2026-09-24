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
	bb_use_test_project foo_project
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	out="$(target test -q 2>&1)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	# Tests are run
	assertf "${BB_TARGET_DIR}/tests_out"
	assertn "$(echo "${out}" | grep "Testing ${BB_TARGET} target ... Success.")"
	# Their output, stdout and stderr, goes to the log file only
	assertz "$(echo "${out}" | grep -x "Testing")"
	assertz "$(echo "${out}" | grep "Test stderr")"
	assertn "$(grep -x "Testing" "${BB_TARGET_DIR}/tests.log")"
	assertn "$(grep "Test stderr" "${BB_TARGET_DIR}/tests.log")"
	# The option is not passed to the test script, the ones after it are
	rm "${BB_TARGET_DIR}/tests_out"
	out="$(target test -q fail 2>&1)"
	assertne $? 0
	assertnf "${BB_TARGET_DIR}/tests_out"
	assertz "$(echo "${out}" | grep -x "Fail")"
	assertn "$(grep -x "Fail" "${BB_TARGET_DIR}/tests.log")"
	# Unlike tests run without the option
	out="$(target test 2>&1)"
	asserteq $? 0
	assertn "$(echo "${out}" | grep -x "Testing")"
	assertn "$(echo "${out}" | grep "Test stderr")"
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

