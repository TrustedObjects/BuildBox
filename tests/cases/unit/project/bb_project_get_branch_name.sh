function test_bb_project_get_branch_name {
	bb_use_test_project foo_project
	asserteq $? 0
	name=$(bb_project_get_branch_name)
	asserteq $? 0
	# foo_project fixture has HEAD on its only commit (detached or main branch)
	assertn "${name}"
}
bb_declare_test test_bb_project_get_branch_name

function test_bb_project_get_branch_name_explicit_path {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	name=$(bb_project_get_branch_name "${project_dir}")
	asserteq $? 0
	assertn "${name}"
}
bb_declare_test test_bb_project_get_branch_name_explicit_path
