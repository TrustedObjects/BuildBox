# Test buildbox_utils.sh sourcing

function entrypoint_init() (
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
)

function test_buildbox_utils_sourcing {
	entrypoint_init
	# entrypoint_init is run in a subshell, so the environment should not be modified
	assertz "${BB_PROJECT_DIR}"
	assertz "${BB_TARGET}"
	# cd into the project workspace where entrypoint_init wrote .bbx/.state=bar
	cd "${BB_TEST_WORKSPACE}/foo_project"
	source buildbox_utils.sh
	asserteq $? 0
	asserteq "${BB_PROJECT_DIR}" "${BB_TEST_WORKSPACE}/foo_project"
	asserteq "${BB_TARGET}" "bar"
}
bb_declare_test test_buildbox_utils_sourcing
