function test_bb_get_target_description {
	bb_use_test_project foo_project
	assertq $? 0
	description=$(bb_get_target_description foo)
	asserteq $? 0
	asserteq "${description}" "Foo target"
}
bb_declare_test test_bb_get_target_description

function test_bb_get_target_description_do_not_exist {
	# No project, no target
	targets=$(bb_get_target_description dontexist)
	assertne $? 0
	# Project, but no matching target
	bb_use_test_project foo_project
	assertq $? 0
	targets=$(bb_get_target_description dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_description_do_not_exist

