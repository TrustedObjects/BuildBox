function test_target_mrproper {
	bb_use_test_project foo_project
	asserteq $? 0
	# build foo and bar targets and ensure built files are present
	target set foo
	asserteq $? 0
	target build
	asserteq $? 0
	target set bar
	asserteq $? 0
	target build
	asserteq $? 0
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package.build
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	# make a tool to create data to later remove with its cleanup hook
	assertnf ${TMPDIR}/foo_test_tool_data
	foo_test_tool_create_data
	assertf ${TMPDIR}/foo_test_tool_data
	# clean bar target and check only built files of this target are removed
	echo "y" | target mrproper
	asserteq $? 0
	assertnd ${BB_PROJECT_DIR}/bar
	assertnd ${BB_PROJECT_SRC_DIR}/bar_package # shared sources, then removed
	assertnf ${TMPDIR}/foo_test_tool_data
	# foo target unchanged
	assertd ${BB_PROJECT_DIR}/foo/build
	assertd ${BB_PROJECT_DIR}/foo/src/foo_package
	assertf ${BB_PROJECT_DIR}/foo/build/bin/foo_package
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package.build
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
}
bb_declare_test test_target_mrproper

function test_target_mrproper_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(echo "y" | target mrproper 2>&1 >/dev/null)
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_mrproper_no_err_log

function test_target_mrproper_project_not_set {
	out="$(echo "y" | target mrproper 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_mrproper_project_not_set

