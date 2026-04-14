function test_target_set {
	bb_use_test_project foo_project
	asserteq $? 0
	# check default target
	target=$(cat "${BB_PROJECT_PROFILE_DIR}/.state")
	asserteq "${target}" "bar"
	# foo target
	target set foo
	asserteq $? 0
	target=$(cat "${BB_PROJECT_PROFILE_DIR}/.state")
	asserteq "${target}" "foo"
	# bar target
	target set bar
	asserteq $? 0
	target=$(cat "${BB_PROJECT_PROFILE_DIR}/.state")
	asserteq "${target}" "bar"
	# switch to already set target
	target set bar
	asserteq $? 0
	target=$(cat "${BB_PROJECT_PROFILE_DIR}/.state")
	asserteq "${target}" "bar"
}
bb_declare_test test_target_set

function test_target_set_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target set foo 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_set_no_err_log

function test_target_set_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target set unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_set_unknown

