function main_error_handler {
	export ERROR_HANDLER="main"
}

function sub_error_handler {
	export ERROR_HANDLER="sub"
}

function test_bb_restore_error_handler {
	bb_trap_errors_custom main_error_handler
	asserteq $? 0
	assertz "${ERROR_HANDLER}"
	# Test if main error handler is called
	false
	asserteq "${ERROR_HANDLER}" "main"
	# Define a sub error handler and test if it is called
	trap sub_error_handler ERR
	false
	asserteq "${ERROR_HANDLER}" "sub"
	# Restore, and test if main error handler is called
	bb_restore_error_handler
	false
	asserteq "${ERROR_HANDLER}" "main"
}
bb_declare_test test_bb_restore_error_handler

