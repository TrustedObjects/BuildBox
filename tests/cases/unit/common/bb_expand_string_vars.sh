function test_bb_expand_string_vars {
	var1="abc"
	var2=123
	str='var1=$var1 var2=$var2'
	result=$(bb_expand_string_vars "${str}")
	asserteq "${result}" "var1=abc var2=123"
}
bb_declare_test test_bb_expand_string_vars
