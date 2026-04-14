function sub_bb_error () (
	bb_error
)

function test_bb_error {
	error_msg=$(sub_bb_error 2>&1 > /dev/null)
	asserteq $? 1
	assertn "${error_msg}"
}
bb_declare_test test_bb_error
