function sub_bb_trap_errors () (
	bb_trap_errors
	asserteq "${BB_ERROR_HANDLER}" "bb_error"
	false
)

function test_bb_trap_errors {
	error_msg=$(sub_bb_trap_errors 2>&1 > /dev/null)
	asserteq $? 1
	assertn "${error_msg}"
}
bb_declare_test test_bb_trap_errors
