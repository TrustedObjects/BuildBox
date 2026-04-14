function test_target_clone {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd "${BB_TARGET_SRC_DIR}"
	assertnd "${BB_PROJECT_SRC_DIR}"
	target clone
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/target_clone.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_clone.log)"
	assertd "${BB_TARGET_SRC_DIR}"
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
}
bb_declare_test test_target_clone

function test_target_clone_prebuilt {
	skip "test not implemented yet"
}
bb_declare_test test_target_clone_prebuilt

function test_target_clone_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target clone 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_clone_no_err_log

function test_target_clone_project_not_set {
	out="$(target clone 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_clone_project_not_set

