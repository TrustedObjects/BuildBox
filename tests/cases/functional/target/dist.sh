function test_target_dist {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	out="$(target dist 2>&1)"
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/dist_out"
	assertn "${out}"
	assertf "${BB_TARGET_DIR}/dist.log"
	assertn "$(cat ${BB_TARGET_DIR}/dist.log)"
	# Log file must contain stdout and stderr
	cat "${BB_TARGET_DIR}/dist.log"
	grep "Dist" "${BB_TARGET_DIR}/dist.log"
	asserteq $? 0
	grep "Test stderr" "${BB_TARGET_DIR}/dist.log"
	asserteq $? 0
}
bb_declare_test test_target_dist

function test_target_dist_quiet {
	skip "test not implemented yet"
}
bb_declare_test test_target_dist_quiet

function test_target_dist_fail {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	target dist "fail"
	assertne $? 0
	assertnf "${BB_TARGET_DIR}/dist_out"
	assertf "${BB_TARGET_DIR}/dist.log"
	assertn "$(cat ${BB_TARGET_DIR}/dist.log)"
}
bb_declare_test test_target_dist_fail

function test_target_dist_project_not_set {
	out="$(target dist 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_dist_project_not_set

