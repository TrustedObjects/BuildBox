function sub_bb_error_silent () (
	bb_error_silent
)

function test_bb_error_silent {
	sub_bb_error_silent
	asserteq $? 1
}
bb_declare_test test_bb_error_silent
