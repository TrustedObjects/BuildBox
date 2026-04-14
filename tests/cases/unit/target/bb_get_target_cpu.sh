function test_bb_get_target_cpu {
	bb_use_test_project foo_project
	assertq $? 0
	cpu=$(bb_get_target_cpu foo)
	asserteq $? 0
	asserteq "${cpu}" "x86"
}
bb_declare_test test_bb_get_target_cpu

function test_bb_get_target_cpu_do_not_exist {
	# No project, no target
	targets=$(bb_get_target_cpu dontexist)
	assertne $? 0
	# Project, but no matching target
	bb_use_test_project foo_project
	assertq $? 0
	targets=$(bb_get_target_cpu dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_cpu_do_not_exist

