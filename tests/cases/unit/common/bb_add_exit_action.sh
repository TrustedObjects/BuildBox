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

exit_action_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_add_exit_action \"echo Exit action start\"
bb_add_exit_action \"touch ${TMPDIR}/file1\"
bb_add_exit_action \"touch ${TMPDIR}/file2\"
bb_add_exit_action \"echo Exit action end\"
exit \$1
"
exit_action_expected_log="Exit action start
Exit action end"

function test_bb_add_exit_action {
	echo "${exit_action_test_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	assertnf "${TMPDIR}/file1"
	assertnf "${TMPDIR}/file2"
	# exit with success
	log=$(${TMPDIR}/test.sh 0)
	asserteq $? 0
	# check actions are executed in right order, from the first to the last added
	asserteq "${log}" "${exit_action_expected_log}"
	assertf "${TMPDIR}/file1"
	assertf "${TMPDIR}/file2"
	# exit with error
	rm "${TMPDIR}/file1" "${TMPDIR}/file2"
	${TMPDIR}/test.sh 1
	asserteq $? 1
	assertf "${TMPDIR}/file1"
	assertf "${TMPDIR}/file2"
}
bb_declare_test test_bb_add_exit_action
