function test_bb_stat_package_warning_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	count=$(bb_stat_package "foo_package@1.0" warning)
	asserteq $? 0
	asserteq $count 0
}
bb_declare_test test_bb_stat_package_warning_prebuilt

function test_bb_stat_package_warning_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	export WARNINGS="none" # workaround to disable unwanted autoconf warnings
	bb_build_package "bar_package"
	asserteq $? 0
	count=$(bb_stat_package "bar_package" warning)
	asserteq $? 0
	asserteq $count 2
}
bb_declare_test test_bb_stat_package_warning_autotools

function test_bb_stat_package_0_warning_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	export WARNINGS="none" # workaround to disable unwanted autoconf warnings
	bb_build_package "bar_package" "-warnings"
	asserteq $? 0
	count=$(bb_stat_package "bar_package" warning)
	asserteq $? 0
	asserteq $count 0
}
bb_declare_test test_bb_stat_package_0_warning_autotools

function test_bb_stat_package_installed_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	# get installed version
	version=$(bb_stat_package "bar_package" installed)
	asserteq $? 0
	asserteq "${version}" 1.0.0
}
bb_declare_test test_bb_stat_package_installed_autotools

function test_bb_stat_package_warning_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "baz_package"
	asserteq $? 0
	count=$(bb_stat_package "baz_package" warning)
	asserteq $? 0
	asserteq $count 3
}
bb_declare_test test_bb_stat_package_warning_make

function test_bb_stat_package_warning_custom {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "qux_package"
	asserteq $? 0
	# test through warning_count.sh provided script
	count=$(bb_stat_package "qux_package" warning)
	asserteq $? 0
	asserteq $count 2
	# test without warning_count.sh provided script
	rm ${BB_TARGET_DIR}/src/qux_package/warning_count.sh
	asserteq $? 0
	echo "warning:" >> ${BB_TARGET_DIR}/src/qux_package/build.log # +1 warning
	count=$(bb_stat_package "qux_package" warning)
	asserteq $count 3
}
bb_declare_test test_bb_stat_package_warning_custom

function test_bb_stat_package_unknown_stat {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	data=$(bb_stat_package "bar_package" unknown)
	assertne $? 0
}
bb_declare_test test_bb_stat_package_unknown_stat

function test_bb_stat_package_unknown_package {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	data=$(bb_stat_package "unknown" warning)
	assertne $? 0
}
bb_declare_test test_bb_stat_package_unknown_package

