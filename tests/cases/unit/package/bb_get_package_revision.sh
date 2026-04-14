function test_bb_get_package_revision {
	# No revision
	revision=$(bb_get_package_revision "package")
	assertz "$revision"
	# Numeric revision after '-'
	revision=$(bb_get_package_revision "package-1.2.3")
	asserteq "$revision" "1.2.3"
	revision=$(bb_get_package_revision "package-test-1.2.3")
	asserteq "$revision" "1.2.3"
	# Revision after '@'
	revision=$(bb_get_package_revision "package@1.2.3")
	asserteq "$revision" "1.2.3"
	revision=$(bb_get_package_revision "package-test@rev1.2.3b")
	asserteq "$revision" "rev1.2.3b"
}

bb_declare_test test_bb_get_package_revision
