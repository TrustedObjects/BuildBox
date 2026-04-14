function test_target_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	# list tools for target bar
	target set bar
	asserteq $? 0
	list="$(target tools)"
	asserteq $? 0
	echo "${list}" | grep "foo_tool@1.0.2"
	asserteq $? 0
	echo "${list}" | grep "bar_tool"
	asserteq $? 0
	echo "${list}" | grep "baz_tool"
	asserteq $? 0
}
bb_declare_test test_target_tools

function test_target_tools_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target tools 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_tools_no_err_log

