function test_bb_project_target_name_from_file {
	bb_use_test_project foo_project
	assertq $? 0
	name=$(bb_project_target_name_from_file ${BB_PROJECT_PROFILE_DIR}/target.bar)
	asserteq $? 0
	asserteq bar ${name}
	name=$(bb_project_target_name_from_file ${BB_PROJECT_PROFILE_DIR}/target.foo)
	asserteq $? 0
	asserteq foo ${name}
}
bb_declare_test test_bb_project_target_name_from_file

