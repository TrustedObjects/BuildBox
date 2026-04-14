function sub_bb_error_nolog () (
	bb_error_nolog
)

function test_bb_error_nolog {
	error_msg=$(sub_bb_error_nolog 2>&1 > /dev/null)
	asserteq $? 1
	assertn "${error_msg}"
}
bb_declare_test test_bb_error_nolog
