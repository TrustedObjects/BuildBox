function test_bb_reset_project_current_target {
	bb_use_test_project foo_project
	assertq $? 0
	asserteq ${BB_TARGET} bar
	assertn ${BB_TARGET_DIR}
	assertn ${BB_TARGET_SRC_DIR}
	assertn ${BB_TARGET_BUILD_DIR}
	bb_reset_project_current_target
	asserteq $? 0
	assertz ${BB_TARGET}
	assertz ${BB_TARGET_DIR}
	assertz ${BB_TARGET_SRC_DIR}
	assertz ${BB_TARGET_BUILD_DIR}
}
bb_declare_test test_bb_reset_project_current_target

function test_bb_reset_project_current_target_current_target_not_set {
	assertz ${BB_TARGET}
	bb_reset_project_current_target
	asserteq $? 0
}
bb_declare_test test_bb_reset_project_current_target_current_target_not_set

