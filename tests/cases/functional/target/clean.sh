function test_target_clean {
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
	# clean bar target and check only built files of this target are removed
	target clean
	asserteq $? 0
	assertnd ${BB_PROJECT_DIR}/bar/build
	assertd ${BB_PROJECT_DIR}/bar/src/foo_package@1.0
	assertnd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/corge_package
	assertd ${BB_PROJECT_DIR}/bar/src/subdir_quux_package
	assertd ${BB_PROJECT_SRC_DIR}/bar_package
	# foo target unchanged
	assertd ${BB_PROJECT_DIR}/foo/build
	assertd ${BB_PROJECT_DIR}/foo/src/foo_package
	assertf ${BB_PROJECT_DIR}/foo/build/bin/foo_package
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package.build
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
}
bb_declare_test test_target_clean

function test_target_clean_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(target clean 2>&1 >/dev/null)
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_clean_no_err_log

function test_target_clean_project_not_set {
	out="$(target clean 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_clean_project_not_set

