function test_pkg_build {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	# foo_package
	build foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/foo_package)"
	asserteq "${out}" "Hello from foo package"
	# bar_package
	build bar_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package !"
	# corge_package
	build corge_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/corge_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/corge_package)"
	asserteq "${out}" "Hello from corge package"
	# quux_package
	build quux_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/quux_package)"
	asserteq "${out}" "Hello from quux package"
	# foo_http_package
	build foo_http_package-1.0
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/http_package_binary"
	out="$(${BB_TARGET_BUILD_DIR}/bin/http_package_binary)"
	asserteq "${out}" "Hello from HTTP prebuilt package"
}
bb_declare_test test_pkg_build

function test_pkg_build_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	build foo
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/foo_package)"
	asserteq "${out}" "Hello from foo package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/http_package_binary"
	out="$(${BB_TARGET_BUILD_DIR}/bin/http_package_binary)"
	asserteq "${out}" "Hello from HTTP prebuilt package"
	build package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package !"
	assertf "${BB_TARGET_BUILD_DIR}/bin/corge_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/corge_package)"
	asserteq "${out}" "Hello from corge package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/quux_package)"
	asserteq "${out}" "Hello from quux package"
}
bb_declare_test test_pkg_build_partial_filter

function test_pkg_build_twice {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	build foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	build foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/foo_package)"
	asserteq "${out}" "Hello from foo package"
}
bb_declare_test test_pkg_build_twice

function test_pkg_build_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(build unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_build_unknown

function test_pkg_build_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(build 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_build_empty_filter

function test_pkg_build_project_not_set {
	out="$(build bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_build_project_not_set

