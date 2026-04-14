function test_bb_get_package_path {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	pkg_path=$(bb_get_package_path "foo_package")
	asserteq $? 0
	asserteq "${pkg_path}" "${BB_PROJECT_PROFILE_DIR}/packages/foo_package"
	pkg_path=$(bb_get_package_path "foo_package@1.0")
	asserteq $? 0
	asserteq "${pkg_path}" "${BB_PROJECT_PROFILE_DIR}/packages/foo_package"
	pkg_path=$(bb_get_package_path "subdir/quux_package")
	asserteq $? 0
	asserteq "${pkg_path}" "${BB_PROJECT_PROFILE_DIR}/packages/subdir/quux_package"
}

bb_declare_test test_bb_get_package_path
