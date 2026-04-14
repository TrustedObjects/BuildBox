function test_bb_archive_prebuilt_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	assertd "${archive}"
}
bb_declare_test test_bb_archive_prebuilt_target

function test_bb_archive_prebuilt_target_not_built {
	bb_use_test_project foo_project bar
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	assertne $? 0
}
bb_declare_test test_bb_archive_prebuilt_target_not_built
