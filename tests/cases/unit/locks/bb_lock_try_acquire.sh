function test_bb_lock_try_acquire {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/.bbx/tmp/lock"
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	assertd "${lock}"
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_try_acquire

function test_bb_lock_try_acquire_already_hold {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/.bbx/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	assertd "${lock}"
	bb_lock_try_acquire "${lock}"
	asserteq $? 1
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_try_acquire_already_hold

function test_bb_lock_try_acquire_error {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_PROJECT_DIR}/.bbx/tmp"
	lock="${BB_PROJECT_DIR}/.bbx/tmp/file/lock"
	touch "${BB_PROJECT_DIR}/.bbx/tmp/file"
	bb_lock_try_acquire "${lock}"
	asserteq $? 2 # lock parent directory is a file
}
bb_declare_test test_bb_lock_try_acquire_error

