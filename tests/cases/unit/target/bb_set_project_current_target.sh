function test_bb_set_project_current_target {
	bb_use_test_project foo_project
	assertq $? 0
	asserteq ${BB_TARGET} bar
	asserteq ${BB_TARGET_DIR} ${BB_PROJECT_DIR}/bar
	asserteq ${BB_TARGET_SRC_DIR} ${BB_PROJECT_DIR}/bar/src
	asserteq ${BB_TARGET_BUILD_DIR} ${BB_PROJECT_DIR}/bar/build
	bb_set_project_current_target foo
	asserteq $? 0
	asserteq ${BB_TARGET} foo
	asserteq ${BB_TARGET_DIR} ${BB_PROJECT_DIR}/foo
	asserteq ${BB_TARGET_SRC_DIR} ${BB_PROJECT_DIR}/foo/src
	asserteq ${BB_TARGET_BUILD_DIR} ${BB_PROJECT_DIR}/foo/build
}
bb_declare_test test_bb_set_project_current_target

function test_bb_set_project_current_target_do_not_exist {
	bb_use_test_project foo_project
	assertq $? 0
	bb_set_project_current_target dontexist
	assertne $? 0
	asserteq ${BB_TARGET} bar
	asserteq ${BB_TARGET_DIR} ${BB_PROJECT_DIR}/bar
	asserteq ${BB_TARGET_SRC_DIR} ${BB_PROJECT_DIR}/bar/src
	asserteq ${BB_TARGET_BUILD_DIR} ${BB_PROJECT_DIR}/bar/build
}
bb_declare_test test_bb_set_project_current_target_do_not_exist

function test_bb_set_project_current_target_no_project {
	assertz ${BB_TARGET}
	assertz ${BB_TARGET_DIR}
	assertz ${BB_TARGET_SRC_DIR}
	assertz ${BB_TARGET_BUILD_DIR}
	echo "+${BB_TARGET_BUILD_DIR}+"
	bb_set_project_current_target abc
	assertne $? 0
	echo "+${BB_TARGET_BUILD_DIR}+"
	assertz ${BB_TARGET}
	assertz ${BB_TARGET_DIR}
	assertz ${BB_TARGET_SRC_DIR}
	assertz ${BB_TARGET_BUILD_DIR}
}
bb_declare_test test_bb_set_project_current_target_no_project

