function sub_bb_trap_errors_silent () (
	bb_trap_errors_silent
	asserteq "${BB_ERROR_HANDLER}" "bb_error_silent"
	false
)

function test_bb_trap_errors_silent {
	sub_bb_trap_errors_silent
	asserteq $? 1
}
bb_declare_test test_bb_trap_errors_silent
