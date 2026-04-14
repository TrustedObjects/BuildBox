function test_target_list {
	bb_use_test_project foo_project
	asserteq $? 0
	list="$(target list)"
	asserteq $? 0
	count=$(echo "${list}" | wc -l)
	asserteq ${count} 2
	list="$(unformat_string "${list}")"
	list="$(minspace_string "${list}")"
	echo "${list}" | grep "^foo"
	asserteq $? 0
	echo "${list}" | grep "^bar"
	asserteq $? 0
}
bb_declare_test test_target_list

function test_target_list_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target list 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_list_no_err_log

