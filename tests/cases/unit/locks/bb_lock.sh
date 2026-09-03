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
	# The lock is a symbolic link to the PID of its owner, and to the scope
	# this PID is unique in
	assertl "${lock}"
	asserteq "$(readlink ${lock})" "$$:$(bb_lock_owner_scope)"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnl "${lock}"
	bb_lock_is_held "${lock}"
	assertne $? 0
}
bb_declare_test test_bb_lock

lock_wait_script="#!${SHELL_CMD}
source buildbox_utils.sh
>&2 echo 'Sub script start'
bb_lock_acquire \${1}
[ \$? -ne 0 ] && exit 1
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
	sleep 2
	>&2 echo "Releasing"
	bb_lock_release "${lock}" # allow script to acquire lock
	asserteq $? 0
	wait
	return 0
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
bb_lock_acquire \${1}
if [ \$? -ne 0 ]; then
	exit 2
fi
if bb_lock_is_held \${1}; then
	exit 0
else
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
	# Released by the exit action of the sub script
	bb_lock_is_held "${lock}"
	assertne $? 0
	assertnl "${lock}"
}
bb_declare_test test_bb_lock_auto_release

killed_holder_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_lock_acquire \${1}
[ \$? -ne 0 ] && exit 1
touch \${1}.acquired
exec sleep 60
"

function test_bb_lock_stale_after_kill {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	echo "${killed_holder_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	${TMPDIR}/test.sh ${lock} &
	holder_pid=$!
	waited=0
	while [ ! -f "${lock}.acquired" ] && [ ${waited} -lt 50 ]; do
		sleep 0.1
		waited=$((waited + 1))
	done
	assertf "${lock}.acquired"
	bb_lock_is_held "${lock}"
	asserteq $? 0
	# No exit action can run on SIGKILL: the lock stays, but as a stale one
	kill -9 ${holder_pid} > /dev/null 2>&1
	wait ${holder_pid} > /dev/null 2>&1
	assertl "${lock}"
	bb_lock_is_stale "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	assertne $? 0
	# And it is taken over
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	asserteq "$(readlink ${lock})" "$$:$(bb_lock_owner_scope)"
	bb_lock_release "${lock}"
	return 0
}
bb_declare_test test_bb_lock_stale_after_kill

function test_bb_lock_not_inherited_by_child_process {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	# No descriptor is involved, so nothing a build starts can hold the lock:
	# a child outliving its parent does not keep it
	sleep 30 &
	child_pid=$!
	bb_lock_release "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	assertne $? 0
	assertnl "${lock}"
	kill -9 ${child_pid} > /dev/null 2>&1
	wait ${child_pid} > /dev/null 2>&1
	return 0
}
bb_declare_test test_bb_lock_not_inherited_by_child_process

function test_bb_lock_release_not_held {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	# Releasing a lock which is not held does nothing
	bb_lock_release "${lock}"
	asserteq $? 0
	# A lock whose owner is not the caller is not released, whatever its target
	mkdir -p "$(dirname ${lock})"
	ln -s 1 "${lock}"
	bb_lock_release "${lock}"
	asserteq $? 0
	assertl "${lock}"
	rm -f "${lock}"
}
bb_declare_test test_bb_lock_release_not_held

function test_bb_lock_not_in_workspace {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="/tmp/lock"
	bb_lock_acquire "${lock}"
	assertne $? 0
	assertnl "${lock}"
}
bb_declare_test test_bb_lock_not_in_workspace

function test_bb_lock_stale_out_of_scope {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	mkdir -p "$(dirname ${lock})"
	# A PID only designates its owner inside the scope it was taken in. PID 1
	# is always alive, yet a lock recording it in another scope is stale: the
	# project directory outlives its container, so a leftover lock may hold a
	# PID which has been recycled since.
	ln -s -T "1:another_scope" "${lock}"
	bb_lock_is_stale "${lock}"
	asserteq $? 0
	bb_lock_is_held "${lock}"
	assertne $? 0
	# So it does not block the next process, which takes it over
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	asserteq "$(readlink ${lock})" "$$:$(bb_lock_owner_scope)"
	bb_lock_release "${lock}"
	asserteq $? 0
	# In the current scope, a lock recording a live PID is held
	ln -s -T "1:$(bb_lock_owner_scope)" "${lock}"
	bb_lock_is_stale "${lock}"
	assertne $? 0
	bb_lock_is_held "${lock}"
	asserteq $? 0
	bb_lock_try_acquire "${lock}"
	asserteq $? 1
	rm -f "${lock}"
}
bb_declare_test test_bb_lock_stale_out_of_scope

function test_bb_lock_stale_bare_pid_format {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	mkdir -p "$(dirname ${lock})"
	# A bare PID is the format of BuildBox 2.1.0: it carries no scope, so it
	# comes from another process and is stale, as the older formats are
	ln -s -T "1" "${lock}"
	bb_lock_is_stale "${lock}"
	asserteq $? 0
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnl "${lock}"
}
bb_declare_test test_bb_lock_stale_bare_pid_format
