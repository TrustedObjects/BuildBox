function test_bb_build_package_fast_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# normal build
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	# fast build
	rm "${BB_TARGET_BUILD_DIR}/bin/foo_package"
	asserteq $? 0
	bb_build_package_fast "foo_package@1.0"
	asserteq $? 0
	out=$(foo_package)
	asserteq "${out}" "Hello from foo package"
}
bb_declare_test test_bb_build_package_fast_prebuilt

function test_bb_build_package_fast_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# normal build
	bb_build_package "bar_package"
	asserteq $? 0
	# fast build
	rm "${BB_TARGET_BUILD_DIR}/bin/bar_package"
	asserteq $? 0
	bb_build_package_fast "bar_package"
	asserteq $? 0
	out=$(bar_package)
	asserteq "${out}" "Hello from bar package !"

}
bb_declare_test test_bb_build_package_fast_autotools

function test_bb_build_package_fast_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	# normal build
	bb_build_package "baz_package"
	asserteq $? 0
	# fast build
	rm "${BB_TARGET_BUILD_DIR}/bin/baz_package"
	asserteq $? 0
	bb_build_package_fast "baz_package"
	asserteq $? 0
	out=$(baz_package)
	asserteq "${out}" "Hello from baz package !"
}
bb_declare_test test_bb_build_package_fast_make

function test_bb_build_package_fast_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	# normal build
	bb_build_package "qux_package"
	asserteq $? 0
	# fast build
	rm "${BB_TARGET_BUILD_DIR}/bin/qux_package"
	asserteq $? 0
	bb_build_package_fast "qux_package"
	asserteq $? 0
	out=$(qux_package)
	asserteq "${out}" "Hello from qux package !"
}
bb_declare_test test_bb_build_package_fast_custom

function test_bb_build_package_fast_subdir {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# normal build
	bb_build_package "subdir/quux_package"
	asserteq $? 0
	# fast build
	rm "${BB_TARGET_BUILD_DIR}/bin/quux_package"
	asserteq $? 0
	bb_build_package_fast "subdir/quux_package"
	asserteq $? 0
	out=$(quux_package)
	asserteq "${out}" "Hello from quux package"
}
bb_declare_test test_bb_build_package_fast_subdir

function test_bb_build_package_fast_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package_fast "unknown"
	assertne $? 0
}
bb_declare_test test_bb_build_package_fast_unknown

function test_bb_build_package_fast_first {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package_fast "bar_package"
	assertne $? 0
	assertnf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_bb_build_package_fast_first

