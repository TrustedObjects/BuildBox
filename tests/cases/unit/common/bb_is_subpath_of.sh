function test_bb_is_subpath_of {
	bb_is_subpath_of "/abc/def" "/abc/def/ghi"
	asserteq $? 0
	bb_is_subpath_of "/abc/def/" "/abc/def/ghi"
	asserteq $? 0
	bb_is_subpath_of "/abc/def" "/abc/def/ghi/"
	asserteq $? 0
	bb_is_subpath_of "/abc/def/" "/abc/def/ghi/"
	asserteq $? 0
	bb_is_subpath_of "/abc/def/ghi" "/abc/def"
	assertne $? 0
	bb_is_subpath_of "/abc/def"
	assertne $? 0
	bb_is_subpath_of
	assertne $? 0
}
bb_declare_test test_bb_is_subpath_of
