function test_bb_set_project_default_target {
	bb_use_test_project foo_project foo
	asserteq $? 0
	asserteq ${BB_TARGET} foo
	bb_set_project_default_target
	asserteq $? 0
	asserteq ${BB_TARGET} bar
	asserteq ${BB_TARGET_DIR} ${BB_PROJECT_DIR}/bar
	asserteq ${BB_TARGET_SRC_DIR} ${BB_PROJECT_DIR}/bar/src
	asserteq ${BB_TARGET_BUILD_DIR} ${BB_PROJECT_DIR}/bar/build
}
bb_declare_test test_bb_set_project_default_target

