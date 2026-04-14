function test_bb_load_package {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# Custom revision
	bb_load_package "foo_package@1.0"
	asserteq $? 0
	asserteq "${SRC_PROTO}" "git"
	asserteq "${SRC_URI}" "${BB_TEST_REPOSITORY_URI}/foo_package.git"
	asserteq "${SRC_REVISION}" "1.0"
	asserteq "${SRC_BUILD}" "prebuilt"
	assertz "${SRC_CONFIG}"
	assertz "${SRC_POST_CLONE_HOOK}"
	# Original revision
	bb_load_package "corge_package"
	asserteq $? 0
	asserteq "${SRC_PROTO}" "git"
	asserteq "${SRC_URI}" "${BB_TEST_REPOSITORY_URI}/corge_package.git"
	asserteq "${SRC_REVISION}" "master"
	asserteq "${SRC_BUILD}" "prebuilt"
	asserteq "${SRC_CONFIG}" ""
	assertz "${SRC_POST_CLONE_HOOK}"
	# HTTP package
	bb_load_package "foo_http_package-1.0"
	asserteq $? 0
	asserteq "${SRC_PROTO}" "http"
	asserteq "${SRC_URI}" "file://${BB_DIR}/tests/archives/foo_http_package-1.0.tar.xz"
	asserteq "${SRC_REVISION}" "d9ccabe55920a8e4bad64b102ca97eacc8d8f93329024d4e1edc3f59f0a68470"
	asserteq "${SRC_BUILD}" "prebuilt"
	assertz "${SRC_CONFIG}"
	assertz "${SRC_POST_CLONE_HOOK}"
}
bb_declare_test test_bb_load_package

function test_bb_load_package_unknown {
	bb_load_package "unknown"
	assertne $? 0
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_load_package "unknown"
	assertne $? 0
}
bb_declare_test test_bb_load_package_unknown
