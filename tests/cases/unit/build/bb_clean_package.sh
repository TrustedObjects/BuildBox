function test_bb_clean_package_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	bb_clean_package "foo_package@1.0"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/foo_package"
}
bb_declare_test test_bb_clean_package_prebuilt

function test_bb_clean_package_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	assertf ${BB_TARGET_SRC_DIR}/bar_package.build/bar_package
	bb_clean_package "bar_package"
	asserteq $? 0
	assertnf ${BB_TARGET_SRC_DIR}/bar_package.build/bar_package
	assertf "${BB_TARGET_BUILD_DIR}/bin/bar_package"
}
bb_declare_test test_bb_clean_package_autotools

function test_bb_clean_package_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "baz_package"
	asserteq $? 0
	assertf ${BB_TARGET_SRC_DIR}/baz_package/baz_package
	bb_clean_package "baz_package"
	asserteq $? 0
	assertnf ${BB_TARGET_SRC_DIR}/baz_package/baz_package
	assertf "${BB_TARGET_BUILD_DIR}/bin/baz_package"
}
bb_declare_test test_bb_clean_package_make

function test_bb_clean_package_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_build_package "qux_package"
	asserteq $? 0
	assertf ${BB_TARGET_SRC_DIR}/qux_package/qux_package
	bb_clean_package "qux_package"
	asserteq $? 0
	assertnf ${BB_TARGET_SRC_DIR}/qux_package/qux_package
	assertf "${BB_TARGET_BUILD_DIR}/bin/qux_package"
}
bb_declare_test test_bb_clean_package_custom

function test_bb_clean_package_subdir {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "subdir/quux_package"
	asserteq $? 0
	bb_clean_package "subdir/quux_package"
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/quux_package"
}
bb_declare_test test_bb_clean_package_subdir

function test_bb_clean_package_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clean_package "unknown"
	assertne $? 0
}
bb_declare_test test_bb_clean_package_unknown

function test_bb_clean_package_not_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clean_package "foo_package@1.0"
	asserteq $? 0
}
bb_declare_test test_bb_clean_package_not_cloned

function test_bb_clean_package_not_built {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	bb_clean_package "foo_package@1.0"
	asserteq $? 0
}
bb_declare_test test_bb_clean_package_not_built

function test_bb_clean_package_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz ## 2.x
	asserteq $? 0
	bb_clone_package "grault_package"
	asserteq $? 0
	bb_clean_package "grault_package"
	assertne $? 0
}
bb_declare_test test_bb_clean_package_unsupported_build_mode

