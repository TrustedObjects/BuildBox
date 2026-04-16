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

bb_get_current_log_file_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_get_current_log_file
"

function test_bb_get_current_log_file {
	echo "${bb_get_current_log_file_test_script}" > "${TMPDIR}/test.sh"
	chmod +x "${TMPDIR}/test.sh"
	log_file=$(echo -n|${TMPDIR}/test.sh)
	asserteq $? 0
	expected_log_file="${TMPDIR}/test.sh.log"
	asserteq "${log_file}" "${expected_log_file}"
}
bb_declare_test test_bb_get_current_log_file
