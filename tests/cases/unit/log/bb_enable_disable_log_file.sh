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

# We are using a sub-script below to avoid test suite disrupt when using
# bb_enable_log_file(), which is changing stdout file descriptors

bb_enable_disable_log_file_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
echo 'Test1'
>&2 echo 'Test2'
bb_enable_log_file
[ \$? -ne 0 ] && exit 1
echo 'Test3'
>&2 echo 'Test4'
bb_disable_log_file
[ \$? -ne 0 ] && exit 1
echo 'Test5'
>&2 echo 'Test6'
exit 0
"

disable_log_file_expected_content="Test3
Test4"

bb_enable_log_file_missing_dir_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
BB_CURRENT_LOG_FILE=${TMPDIR}/missing_dir_enable_$$/test.log
bb_enable_log_file
[ \$? -ne 0 ] && exit 1
bb_disable_log_file
exit 0
"

function test_bb_enable_log_file_creates_missing_dir {
	local log_dir="${TMPDIR}/missing_dir_enable_$$"
	assertnd "${log_dir}"
	echo "${bb_enable_log_file_missing_dir_test_script}" > "${TMPDIR}/test_enable_mkdir.sh"
	chmod +x "${TMPDIR}/test_enable_mkdir.sh"
	echo | ${TMPDIR}/test_enable_mkdir.sh
	asserteq $? 0
	assertd "${log_dir}"
}
bb_declare_test test_bb_enable_log_file_creates_missing_dir

function test_bb_enable_disable_log_file {
	echo "${bb_enable_disable_log_file_test_script}" > "${TMPDIR}/test.sh"
	chmod +x "${TMPDIR}/test.sh"
	echo | ${TMPDIR}/test.sh # echo avoids stdin consuming when enabling log file
	asserteq $? 0
	log_file="${TMPDIR}/test.sh.log"
	content="$(cat ${log_file} | tail -n 2)"
	asserteq "${content}" "${disable_log_file_expected_content}"
}
bb_declare_test test_bb_enable_disable_log_file
