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

function test_bb_lock {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# The lock file materializes the lock, the lock itself is held on a file
	# descriptor
	assertf "${lock}"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	# The lock file is not removed on release, only the lock is released
	assertf "${lock}"
	bb_lock_is_held "${lock}"
	assertne $? 0
}
bb_declare_test test_bb_lock

lock_wait_script="#!${SHELL_CMD}
source buildbox_utils.sh
>&2 echo 'Sub script start'
bb_lock_acquire \${1}
[ $? -ne 0 ] && exit 1
>&2 echo 'Acquired by sub script'
"

function lock_wait {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	>&2 echo "Acquired"
	echo "${lock_wait_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	${TMPDIR}/test.sh ${lock} & # start script concurrently
	asserteq $? 0
	sleep 1
	>&2 echo "Releasing"
	bb_lock_release "${lock}" # allow script to acquire lock
	asserteq $? 0
	wait
}

lock_wait_expected_log="Acquired
Sub script start
Releasing
Acquired by sub script"

function test_bb_lock_wait {
	log=$(lock_wait 2>&1 > /dev/null)
	asserteq "${log}" "${lock_wait_expected_log}"
}
bb_declare_test test_bb_lock_wait

auto_release_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
echo \"Acquire \${1}\"
bb_lock_acquire \${1}
if [ $? -ne 0 ]; then
	echo \"Unable to acquire lock\"
	exit 2
fi
if bb_lock_is_held \${1}; then
	exit 0
else
	echo \"Lock not held\"
	exit 1
fi
"

function test_bb_lock_auto_release {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	echo "${auto_release_test_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	${TMPDIR}/test.sh ${lock}
	asserteq $? 0
	# Lock released when the holding process ended
	bb_lock_is_held "${lock}"
	assertne $? 0
}
bb_declare_test test_bb_lock_auto_release

killed_holder_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_lock_acquire \${1}
[ $? -ne 0 ] && exit 1
touch \${1}.acquired
exec sleep 60
"

function test_bb_lock_released_on_kill {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	echo "${killed_holder_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	${TMPDIR}/test.sh ${lock} &
	holder_pid=$!
	# Wait for the lock to be acquired by the sub script
	waited=0
	while [ ! -f "${lock}.acquired" ] && [ ${waited} -lt 50 ]; do
		sleep 0.1
		waited=$((waited + 1))
	done
	assertf "${lock}.acquired"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	# No exit action can run on SIGKILL: the lock is released by the kernel
	kill -9 ${holder_pid} > /dev/null 2>&1
	wait ${holder_pid} > /dev/null 2>&1
	bb_lock_is_held "${lock}"
	assertne $? 0
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	return 0
}
bb_declare_test test_bb_lock_released_on_kill

function test_bb_lock_release_not_held {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	# Releasing a lock which is not held by the current process does nothing
	bb_lock_release "${lock}"
	asserteq $? 0
}
bb_declare_test test_bb_lock_release_not_held

function test_bb_lock_not_in_workspace {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="/tmp/lock"
	bb_lock_acquire "${lock}"
	assertne $? 0
	assertnf "${lock}"
}
bb_declare_test test_bb_lock_not_in_workspace

function test_bb_lock_close_redirections {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	# Nothing to close while no lock is held
	asserteq "$(bb_lock_close_redirections)" ""
	bb_lock_acquire "${lock}"
	asserteq $? 0
	assertn "$(bb_lock_close_redirections)"
	# Locks are restored for the current process once the command is done
	eval "true $(bb_lock_close_redirections)"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	assertne $? 0
	return 0
}
bb_declare_test test_bb_lock_close_redirections

sourced_script="sleep 30 &
echo \$! > ${TMPDIR}/child_pid
"

function test_bb_lock_close_redirections_sourced_script {
	if [[ "${SHELL_CMD}" != "/bin/bash" ]]; then
		# ZSH keeps an internal duplicate of the redirected descriptors while a
		# builtin runs, so a process started by a sourced script may inherit the
		# lock. BuildBox commands, which are the ones acquiring locks, are bash
		# scripts.
		skip "descriptors hiding from sourced scripts is a bash guarantee"
		return 0
	fi
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# This is how tool load scripts are sourced (see _bb_tool_source_script)
	echo "${sourced_script}" > "${TMPDIR}/load.sh"
	eval "source \"${TMPDIR}/load.sh\" >&2 $(bb_lock_close_redirections)"
	child_pid=$(cat "${TMPDIR}/child_pid")
	assertn "${child_pid}"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	# The process started by the sourced script does not hold the lock
	bb_lock_is_held "${lock}"
	assertne $? 0
	kill -9 ${child_pid} > /dev/null 2>&1
	return 0
}
bb_declare_test test_bb_lock_close_redirections_sourced_script

function test_bb_lock_inherited_by_child_process {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# Without the redirections, a child process inherits the lock descriptor and
	# keeps the lock alive: this is what bb_lock_close_redirections() is for
	sleep 30 &
	child_pid=$!
	bb_lock_release "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	asserteq $? 0 # still held by the child
	kill -9 ${child_pid} > /dev/null 2>&1
	wait ${child_pid} > /dev/null 2>&1
	bb_lock_is_held "${lock}"
	assertne $? 0
	return 0
}
bb_declare_test test_bb_lock_inherited_by_child_process

function test_bb_lock_api_from_child_process {
	if [[ "${SHELL_CMD}" != "/bin/bash" ]]; then
		# ZSH does not export functions, a child gets the API by sourcing it
		skip "API export to child processes is a bash feature"
		return 0
	fi
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	# Export the API the way BuildBox does, and check a child process using the
	# locks needs nothing more: every function it relies on must be part of the
	# API, and the API must not need a variable which is not exported either
	for fn in ${BUILDBOX_INTERNAL_API}; do
		export -f "${fn}" > /dev/null 2>&1
		if declare -F "_inner_${fn}" > /dev/null 2>&1; then
			export -f "_inner_${fn}" > /dev/null 2>&1
		fi
	done
	output=$(${SHELL_CMD} -c "bb_lock_try_acquire ${lock}" 2>&1)
	asserteq $? 0
	assertz "${output}"
	# The child ended, so its lock is released
	bb_lock_is_held "${lock}"
	assertne $? 0
	output=$(${SHELL_CMD} -c "bb_lock_acquire ${lock} && bb_lock_close_redirections" 2>&1)
	asserteq $? 0
	# Only the redirections of the lock the child holds
	assert "[[ \"${output}\" =~ ^[0-9]+\>\&-$ ]]"
	return 0
}
bb_declare_test test_bb_lock_api_from_child_process
