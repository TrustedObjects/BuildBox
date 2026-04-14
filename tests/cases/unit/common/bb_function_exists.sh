function existing_function {
	echo "I exist !"
}

function test_bb_function_exists {
	bb_function_exists existing_function
	asserteq $? 1
	bb_function_exists does_not_exist
	asserteq $? 0
}
bb_declare_test test_bb_function_exists
