bb_get_target_vars_expected_vars='VAR_FOO=foo
VAR_BAR=bar'

function test_bb_get_target_vars {
	bb_use_test_project foo_project
	assertq $? 0
	vars=$(bb_get_target_vars bar)
	asserteq $? 0
	asserteq "${vars}" "${bb_get_target_vars_expected_vars}"
	vars=$(bb_get_target_vars foo)
	asserteq $? 0
	assertz "${vars}"
}
bb_declare_test test_bb_get_target_vars

function test_bb_get_target_vars_target_do_not_exist {
	bb_use_test_project foo_project
	assertq $? 0
	vars=$(bb_get_target_vars dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_vars_target_do_not_exist

function test_bb_get_target_vars_project_not_set {
	vars=$(bb_get_target_vars dontexist)
	assertne $? 0
}
bb_declare_test test_bb_get_target_vars_project_not_set

