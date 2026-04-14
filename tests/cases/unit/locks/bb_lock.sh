function test_bb_lock {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/.bbx/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	assertd "${lock}"
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnd "${lock}"
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
	lock="${BB_PROJECT_DIR}/.bbx/tmp/lock"
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
	assertnd "${lock}"
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
if [ -d \${1} ]; then
	exit 0
else
	echo \"Lock not created\"
	exit 1
fi
"

function test_bb_lock_auto_release {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/.bbx/tmp/lock"
	echo "${auto_release_test_script}" > "${TMPDIR}/test.sh"
	chmod +x ${TMPDIR}/test.sh
	${TMPDIR}/test.sh ${lock}
	asserteq $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_auto_release

function test_bb_lock_not_in_workspace {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="/tmp/lock"
	bb_lock_acquire "${lock}"
	assertne $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_not_in_workspace
