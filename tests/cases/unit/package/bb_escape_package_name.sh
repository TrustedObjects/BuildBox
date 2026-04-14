function test_bb_escape_package_name {
	name=$(bb_escape_package_name "test/with\\special_chars")
	asserteq "${name}" "test_with_special_chars"
}

bb_declare_test test_bb_escape_package_name
