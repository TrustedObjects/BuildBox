function test_bb_is_local_env_updated {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_set_local_env
	asserteq $? 0
	# After bb_set_local_env, bb_local_env_updated was called internally
	bb_is_local_env_outdated
	asserteq $? 0
	# Change target to make outdated
	export BB_TARGET="foo"
	bb_is_local_env_outdated
	assertne $? 0
	# Assume environment is updated (this is not really the case)
	bb_local_env_updated
	# Check environment up-to-date
	bb_is_local_env_outdated
	asserteq $? 0
}
bb_declare_test test_bb_is_local_env_updated
