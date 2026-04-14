function test_bb_reset_current_project {
	bb_use_test_project foo_project
	asserteq $? 0
	assertn "${BB_PROJECT_DIR}"
	bb_reset_current_project
	asserteq $? 0
	assertz "${BB_PROJECT_DIR}"
	assertz "${BB_PROJECT_PROFILE_DIR}"
	assertz "${BB_PROJECT_SRC_DIR}"
	assertz "${BB_TARGET}"
	assertz "${BB_TARGET_DIR}"
	assertz "${BB_TARGET_SRC_DIR}"
	assertz "${BB_TARGET_BUILD_DIR}"
}
bb_declare_test test_bb_reset_current_project
