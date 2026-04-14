function test_bb_unset_target_local_env_vars {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	asserteq "${BB_TARGET_VAR_FOO}" "foo"
	asserteq "${BB_TARGET_VAR_BAR}" "bar"
	bb_unset_target_local_env_vars
	asserteq $? 0
	assertz "${BB_TARGET_VAR_FOO}"
	assertz "${BB_TARGET_VAR_BAR}"
}
bb_declare_test test_bb_unset_target_local_env_vars
