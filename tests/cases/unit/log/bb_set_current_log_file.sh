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

function test_bb_set_current_log_file {
	orig_log_file=$(bb_get_current_log_file)
	assertnf "${orig_log_file}"
	bb_set_current_log_file ${TMPDIR}/my_log_file.log
	asserteq $? 0
	bb_log_file_write "Test 1"
	bb_log_file_write "Test 2"
	lines_count=$(cat ${TMPDIR}/my_log_file.log | wc -l)
	asserteq $? 0
	asserteq ${lines_count} 2
	assertnf "${orig_log_file}"
}
bb_declare_test test_bb_set_current_log_file

function test_bb_set_current_log_file_dont_move {
	orig_log_file=$(bb_get_current_log_file)
	bb_log_file_write "Test 1"
	bb_set_current_log_file ${TMPDIR}/my_log_file.log 0
	asserteq $? 0
	bb_log_file_write "Test 2"
	bb_log_file_write "Test 3"
	lines_count=$(cat ${TMPDIR}/my_log_file.log | wc -l)
	asserteq $? 0
	asserteq ${lines_count} 2
	lines_count=$(cat ${orig_log_file} | wc -l)
	asserteq $? 0
	asserteq ${lines_count} 1
}
bb_declare_test test_bb_set_current_log_file_dont_move

function test_bb_set_current_log_file_move {
	orig_log_file=$(bb_get_current_log_file)
	bb_log_file_write "Test 1"
	bb_set_current_log_file ${TMPDIR}/my_log_file.log 1
	asserteq $? 0
	bb_log_file_write "Test 2"
	bb_log_file_write "Test 3"
	lines_count=$(cat ${TMPDIR}/my_log_file.log | wc -l)
	asserteq $? 0
	asserteq ${lines_count} 3
	assertnf "${orig_log_file}"
}
bb_declare_test test_bb_set_current_log_file_move

function test_bb_set_current_log_file_fail {
	mkdir ${TMPDIR}/my_log_file.log
	bb_set_current_log_file ${TMPDIR}/my_log_file.log # log file is a folder: fail
	assertne $? 0
}
bb_declare_test test_bb_set_current_log_file_fail

