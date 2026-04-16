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

backup_log_file_expected_content="Test 1
Test 2"

function test_bb_backup_log_file {
	log_file=$(bb_get_current_log_file)
	bb_log_file_write "Test 1"
	asserteq $? 0
	bb_log_file_write "Test 2"
	asserteq $? 0
	bb_backup_log_file ${TMPDIR}/backup.log
	asserteq "$(cat ${log_file})" "${backup_log_file_expected_content}"
	asserteq "$(cat ${TMPDIR}/backup.log)" "${backup_log_file_expected_content}"
}
bb_declare_test test_bb_backup_log_file

