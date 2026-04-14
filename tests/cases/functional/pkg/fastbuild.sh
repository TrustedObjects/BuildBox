function test_pkg_fastbuild {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}

	build bar_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package !"

	# Modify package and do fast build
	sed -i 's/MESSAGE\"/MESSAGE\" updated/' ${BB_TARGET_SRC_DIR}/bar_package.sources/main.c
	fastbuild bar_package
	asserteq $? 0
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package ! updated"

}
bb_declare_test test_pkg_fastbuild

function test_pkg_fastbuild_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	target build
	asserteq $? 0
	fastbuild foo
	asserteq $? 0
	fastbuild package
	asserteq $? 0
}
bb_declare_test test_pkg_fastbuild_partial_filter

function test_pkg_fastbuild_first {
	bb_use_test_project foo_project
	asserteq $? 0
	fastbuild bar_package
	# fail because package requires configuration
	assertne $? 0
}
bb_declare_test test_pkg_fastbuild_first

function test_pkg_fastbuild_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(fastbuild unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_fastbuild_unknown

function test_pkg_fastbuild_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(fastbuild 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_fastbuild_empty_filter

function test_pkg_fastbuild_project_not_set {
	out="$(fastbuild bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_fastbuild_project_not_set

