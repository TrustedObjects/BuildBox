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

function test_bb_lock_try_acquire {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	assertne $? 0
}
bb_declare_test test_bb_lock_try_acquire

function test_bb_lock_try_acquire_already_hold {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# Taking a lock already held, even by the current process, fails
	bb_lock_try_acquire "${lock}"
	asserteq $? 1
	bb_lock_release "${lock}"
	asserteq $? 0
}
bb_declare_test test_bb_lock_try_acquire_already_hold

try_acquire_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_lock_try_acquire \${1}
exit \$?
"

function test_bb_lock_try_acquire_held_by_another_process {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	echo "${try_acquire_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	# Nobody holds the lock yet
	${TMPDIR}/test.sh ${lock}
	asserteq $? 0
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# Lock held by the current process, the sub script can not acquire it
	${TMPDIR}/test.sh ${lock}
	asserteq $? 1
	bb_lock_release "${lock}"
	asserteq $? 0
	${TMPDIR}/test.sh ${lock}
	asserteq $? 0
}
bb_declare_test test_bb_lock_try_acquire_held_by_another_process

function test_bb_lock_try_acquire_error {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_PROJECT_DIR}/tmp"
	lock="${BB_PROJECT_DIR}/tmp/file/lock"
	touch "${BB_PROJECT_DIR}/tmp/file"
	bb_lock_try_acquire "${lock}"
	asserteq $? 2 # lock parent directory is a file
}
bb_declare_test test_bb_lock_try_acquire_error

function test_bb_lock_try_acquire_legacy_locks {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	mkdir -p "$(dirname ${lock})"
	# BuildBox up to 2.0.2 used a directory as lock
	mkdir "${lock}"
	assertd "${lock}"
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	assertl "${lock}"
	bb_lock_release "${lock}"
	# BuildBox 2.1.0 used a file, held with flock
	touch "${lock}"
	assertf "${lock}"
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	assertl "${lock}"
	bb_lock_release "${lock}"
	assertnl "${lock}"
}
bb_declare_test test_bb_lock_try_acquire_legacy_locks

concurrent_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_lock_try_acquire \${1}
rc=\$?
echo \${rc} >> \${2}
# The winner keeps the lock: exec leaves no shell to run the exit action
[ \${rc} -eq 0 ] && exec sleep 30
exit 0
"

function test_bb_lock_try_acquire_concurrent {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	results="${TMPDIR}/lock_results"
	rm -f "${results}"
	echo "${concurrent_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	# Creating the lock is an unitary operation, so a single process gets it,
	# and it keeps it for the whole race
	pids=""
	for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
		${TMPDIR}/test.sh ${lock} ${results} &
		pids="${pids} $!"
	done
	waited=0
	while [ "$(wc -l < ${results} 2>/dev/null || echo 0)" -lt 12 ] && [ ${waited} -lt 200 ]; do
		sleep 0.1
		waited=$((waited + 1))
	done
	asserteq "$(wc -l < ${results})" "12"
	asserteq "$(grep -c '^0$' ${results})" "1"
	asserteq "$(grep -c '^1$' ${results})" "11"
	# The lock is still held by the winner
	bb_lock_is_held "${lock}"
	asserteq $? 0
	kill -9 ${pids} > /dev/null 2>&1
	wait > /dev/null 2>&1
	return 0
}
bb_declare_test test_bb_lock_try_acquire_concurrent
