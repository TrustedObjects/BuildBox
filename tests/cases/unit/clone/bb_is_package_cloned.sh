function test_bb_is_package_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# clone some packages
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	# check cloned
	bb_is_package_cloned "bar" "foo_package@1.0"
	asserteq $? 1
	bb_is_package_cloned "bar" "baz_package"
	asserteq $? 1
	# check not cloned
	bb_is_package_cloned "bar" "bar_package"
	asserteq $? 0
	# check not cloned, clone, and check cloned
	bb_is_package_cloned "bar" "subdir/quux_package"
	asserteq $? 0
	bb_clone_package "subdir/quux_package"
	asserteq $? 0
	bb_is_package_cloned "bar" "subdir/quux_package"
	asserteq $? 1
	# check on another target than current one
	bb_is_package_cloned "foo" "foo_package"
	asserteq $? 0
	bb_set_project_current_target "foo"
	asserteq $? 0
	bb_is_package_cloned "bar" "foo_package@1.0"
	asserteq $? 1
	bb_is_package_cloned "bar" "bar_package"
	asserteq $? 0
}
bb_declare_test test_bb_is_package_cloned

function test_bb_is_package_cloned_unknown_package {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_is_package_cloned "bar" "unknown"
	asserteq $? 0
}
bb_declare_test test_bb_is_package_cloned_unknown_package

function test_bb_is_package_cloned_unknown_target {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_is_package_cloned "unknown" "foo_package"
	asserteq $? 0
}
bb_declare_test test_bb_is_package_cloned_unknown_target

function test_bb_is_package_cloned_project_not_set {
	bb_is_package_cloned "bar" "foo_package@1.0"
	asserteq $? 0
}
bb_declare_test test_bb_is_package_cloned_project_not_set

