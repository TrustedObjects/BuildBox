function test_bb_is_local_env_outdated {
	bb_is_local_env_outdated
	asserteq $? 0
}
bb_declare_test test_bb_is_local_env_outdated


function test_bb_is_local_env_outdated_target {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_is_local_env_outdated
	asserteq $? 0
	export BB_TARGET="bar"
	bb_is_local_env_outdated
	assertne $? 0
}
bb_declare_test test_bb_is_local_env_outdated_target

function test_bb_is_local_env_outdated_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_is_local_env_outdated
	asserteq $? 0
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_is_local_env_outdated
	assertne $? 0
}
bb_declare_test test_bb_is_local_env_outdated_tools

function test_bb_is_local_env_outdated_target_vars {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_is_local_env_outdated
	asserteq $? 0
	target_profile="$(bb_get_target_profile_path ${BB_TARGET})"
	asserteq $? 0
	echo "VAR_TEST_OUTDATED=1" >> "${target_profile}"
	bb_is_local_env_outdated
	assertne $? 0
}
bb_declare_test test_bb_is_local_env_outdated_target_vars

function test_bb_is_local_env_outdated_target_cpu {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_is_local_env_outdated
	asserteq $? 0
	target_profile="$(bb_get_target_profile_path ${BB_TARGET})"
	asserteq $? 0
	sed -i 's/CPU=x86/CPU=cortex-m3/' "${target_profile}"
	bb_is_local_env_outdated
	assertne $? 0
}
bb_declare_test test_bb_is_local_env_outdated_target_cpu

