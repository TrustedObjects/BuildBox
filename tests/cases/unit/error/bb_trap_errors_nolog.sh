function sub_bb_trap_errors_nolog () (
	bb_trap_errors_nolog
	asserteq "${BB_ERROR_HANDLER}" "bb_error_nolog"
	false
)

function test_bb_trap_errors_nolog {
	error_msg=$(sub_bb_trap_errors_nolog 2>&1 > /dev/null)
	asserteq $? 1
	assertn "${error_msg}"
}
bb_declare_test test_bb_trap_errors_nolog

