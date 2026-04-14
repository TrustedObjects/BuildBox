function test_bb_get_target_profile_path {
	bb_use_test_project foo_project
	assertq $? 0
	path=$(bb_get_target_profile_path bar)
	asserteq $? 0
	asserteq ${BB_PROJECT_PROFILE_DIR}/target.bar ${path}
	path=$(bb_get_target_profile_path foo)
	asserteq $? 0
	asserteq ${BB_PROJECT_PROFILE_DIR}/target.foo ${path}
}
bb_declare_test test_bb_get_target_profile_path

function test_bb_get_target_profile_path_project_not_set {
	path=$(bb_get_target_profile_path bar)
	assertne $? 0
}
bb_declare_test test_bb_get_target_profile_path_project_not_set

