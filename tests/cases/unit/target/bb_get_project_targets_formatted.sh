function test_bb_get_project_targets_formatted {
	bb_use_test_project foo_project
	asserteq $? 0
	targets=$(bb_get_project_targets_formatted 0)
	asserteq $? 0
	assertn "${targets}"
	asserteq $(echo -e "${targets}"|wc -l) 1
	targets=$(bb_get_project_targets_formatted 1)
	asserteq $? 0
	assertn "${targets}"
	asserteq $(echo -e "${targets}"|wc -l) 2
}
bb_declare_test test_bb_get_project_targets_formatted

function test_bb_get_project_targets_formatted_no_project {
	targets=$(bb_get_project_targets_formatted 0)
	assertne $? 0
}
bb_declare_test test_bb_get_project_targets_formatted_no_project
