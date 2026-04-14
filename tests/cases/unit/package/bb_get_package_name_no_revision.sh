function test_bb_get_package_name_no_revision {
	# No revision
	name=$(bb_get_package_name_no_revision "package")
	asserteq "$name" "package"
	# Numeric revision after '-'
	name=$(bb_get_package_name_no_revision "package-1.2.3")
	asserteq "$name" "package"
	name=$(bb_get_package_name_no_revision "package-test-1.2.3")
	asserteq "$name" "package-test"
	# Revision after '@'
	name=$(bb_get_package_name_no_revision "package@1.2.3")
	asserteq "$name" "package"
	name=$(bb_get_package_name_no_revision "package-test@rev1.2.3b")
	asserteq "$name" "package-test"
}

bb_declare_test test_bb_get_package_name_no_revision
