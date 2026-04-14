## Tests for 'bbx project update' (project_update sbin command).
## In 2.x, update pulls changes into .bbx/ (if it is a submodule or has a remote).
## Since test fixtures don't have a remote, this tests the error path.

function test_project_update_no_project {
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_project

function test_project_update_no_remote {
	# The test fixture has no remote, so update should report an error
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_remote
