function test_bb_get_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	tools=$(bb_get_tools)
	asserteq $? 0
	asserteq $(echo "${tools}"|wc -l) 3
	echo ${tools}|grep "foo_tool@1\.0\.0"
	echo ${tools}|grep "bar_tool"
	echo ${tools}|grep "baz_tool"
	bb_set_project_current_target foo
	asserteq $? 0
	tools=$(bb_get_tools)
	asserteq $? 0
	assertz ${tools}
}
bb_declare_test test_bb_get_tools

function test_bb_get_tools_only_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_clone_tool "subdir/bar_tool"
	asserteq $? 0
	tools=$(bb_get_tools 1)
	asserteq $? 0
	asserteq $(echo "${tools}"|wc -l) 2
	echo ${tools}|grep "foo_tool@1\.0\.0"
	echo ${tools}|grep "bar_tool"
	bb_set_project_current_target foo
	asserteq $? 0
	tools=$(bb_get_tools 1)
	asserteq $? 0
	assertz ${tools}
}
bb_declare_test test_bb_get_tools_only_cloned

function test_bb_get_tools_project_not_set {
	tools=$(bb_get_tools)
	assertne $? 0
}
bb_declare_test test_bb_get_tools_project_not_set
