function test_project_clean {
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
	# clean and check only built files are removed
	bbx project clean
	asserteq $? 0
	assertnd ${BB_PROJECT_DIR}/foo/build
	assertnd ${BB_PROJECT_DIR}/foo/src/bar_package.build
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package
	assertnd ${BB_PROJECT_DIR}/bar/build
	assertnd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package
	assertd ${BB_PROJECT_SRC_DIR}/bar_package
}
bb_declare_test test_project_clean

function test_project_clean_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project clean 2>&1 >/dev/null)
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_project_clean_no_err_log

function test_project_clean_project_not_set {
	out="$(bbx project clean 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_clean_project_not_set
