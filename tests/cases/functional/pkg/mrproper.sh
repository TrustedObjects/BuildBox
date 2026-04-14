function test_pkg_mrproper {
	bb_use_test_project foo_project
	asserteq $? 0
	target set bar
	asserteq $? 0
	target build
	asserteq $? 0
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	# wipe bar_package and check only built files of this package are removed
	echo "y" | mrproper bar_package
	asserteq $? 0
	assertnd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	assertnl ${BB_PROJECT_DIR}/bar/src/bar_package
	assertnd ${BB_PROJECT_DIR}/src/bar_package
	assertnl ${BB_TARGET_SRC_DIR}/bar_package.sources
	assertd ${BB_PROJECT_DIR}/bar/src/foo_package@1.0
	assertd ${BB_PROJECT_DIR}/bar/src/corge_package
	assertd ${BB_PROJECT_DIR}/bar/src/subdir_quux_package
	assertf ${BB_TARGET_BUILD_DIR}/bin/bar_package
}
bb_declare_test test_pkg_mrproper

function test_pkg_mrproper_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	echo "y" | mrproper package
	asserteq $? 0
	assertnl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertnl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertnd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertnd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertnl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertnd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/http_package_binary"
	assertnl "${BB_TARGET_SRC_DIR}/bar_package"
	assertnl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertnd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertnd "${BB_TARGET_SRC_DIR}/bar_package.build"
	assertnl "${BB_TARGET_SRC_DIR}/corge_package"
	assertnl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertnd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertnl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertnl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertnd "${BB_PROJECT_SRC_DIR}/subdir/subdir_quux_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_pkg_mrproper_partial_filter

function test_pkg_mrproper_twice {
	bb_use_test_project foo_project
	asserteq $? 0
	build bar_package
	asserteq $? 0
	echo "y" | mrproper bar_package
	asserteq $? 0
	echo "y" | mrproper bar_package
	asserteq $? 0
}
bb_declare_test test_pkg_mrproper_twice

function test_pkg_mrproper_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	target clone
	asserteq $? 0
	out="$(echo "y" | mrproper unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_mrproper_unknown

function test_pkg_mrproper_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(echo "y" | mrproper 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_mrproper_empty_filter

function test_pkg_mrproper_project_not_set {
	out="$(echo "y" | mrproper bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_mrproper_project_not_set

