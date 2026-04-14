function test_bb_package_supports_sources_sharing_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "foo_package@1.0"
	asserteq $? 1
}
bb_declare_test test_bb_package_supports_sources_sharing_prebuilt

function test_bb_package_supports_sources_sharing_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "bar_package"
	asserteq $? 1
}
bb_declare_test test_bb_package_supports_sources_sharing_autotools

function test_bb_package_supports_sources_sharing_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "baz_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_make

function test_bb_package_supports_sources_sharing_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "baz_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_custom

function test_bb_package_supports_sources_sharing_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "unknown"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_unknown

function test_bb_package_supports_sources_sharing_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz ## 2.x
	asserteq $? 0
	bb_package_supports_sources_sharing "grault_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_unsupported_build_mode

