function test_bb_project_get_tag {
	bb_use_test_project foo_project
	asserteq $? 0
	# Create a tag on the test project to test retrieval
	git -C "${BB_PROJECT_DIR}" tag "foo_project-1.0" HEAD
	tag=$(bb_project_get_tag)
	asserteq $? 0
	asserteq "${tag}" "foo_project-1.0"
}
bb_declare_test test_bb_project_get_tag

function test_bb_project_get_tag_ignores_args {
	bb_use_test_project foo_project
	asserteq $? 0
	git -C "${BB_PROJECT_DIR}" tag "foo_project-2.0" HEAD
	# Arguments must be silently ignored; result is always from BB_PROJECT_DIR
	tag=$(bb_project_get_tag "ignored_arg" 1)
	asserteq $? 0
	asserteq "${tag}" "foo_project-2.0"
}
bb_declare_test test_bb_project_get_tag_ignores_args
