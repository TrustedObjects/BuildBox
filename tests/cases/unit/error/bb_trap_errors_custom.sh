function custom_error_handler {
	>&2 echo "Custom error !"
}

function sub_bb_trap_errors_custom () (
	bb_trap_errors_custom custom_error_handler
	asserteq "${BB_ERROR_HANDLER}" "custom_error_handler"
	false
)

function test_bb_trap_errors_custom {
	error_msg=$(sub_bb_trap_errors_custom 2>&1 > /dev/null)
	asserteq $? 1
	asserteq "${error_msg}" "Custom error !"
}
bb_declare_test test_bb_trap_errors_custom

