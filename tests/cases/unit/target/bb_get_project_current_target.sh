function test_bb_get_project_current_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	asserteq bar ${target}
	bb_set_project_current_target foo
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	asserteq foo ${target}
}
bb_declare_test test_bb_get_project_current_target

function test_bb_get_project_current_target_default {
	bb_use_test_project foo_project
	asserteq $? 0
	target=$(bb_get_project_current_target)
	asserteq $? 0
	# default_target symlink points to target.bar in foo_project fixture
	asserteq bar ${target}
}
bb_declare_test test_bb_get_project_current_target_default

function test_bb_get_project_current_target_no_project {
	target=$(bb_get_project_current_target)
	asserteq $? 0
	assertz ${target}
}
bb_declare_test test_bb_get_project_current_target_no_project
