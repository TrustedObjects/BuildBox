function test_target_info {
	bb_use_test_project foo_project
	asserteq $? 0

	# default target info
	info="$(target info)"
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	# check name
	target=$(echo "${info}" | grep "Target:")
	asserteq $? 0
	asserteq "$(echo ${target} | cut -d ':' -f 2)" "bar"
	# check path
	target_path=$(echo "${info}" | grep "Path:")
	asserteq $? 0
	asserteq "$(echo ${target_path} | cut -d ':' -f 2)" "${BB_PROJECT_DIR}/bar"
	# check profile path
	profile_path=$(echo "${info}" | grep "Profilepath:")
	asserteq $? 0
	asserteq "$(echo ${profile_path} | cut -d ':' -f 2)" "${BB_PROJECT_PROFILE_DIR}/target.bar"
	# check testable
	testable=$(echo "${info}" | grep "Testable:")
	asserteq $? 0
	asserteq "$(echo ${testable} | cut -d ':' -f 2)" "yes"
	# check distributable
	distributable=$(echo "${info}" | grep "Distributable:")
	asserteq $? 0
	asserteq "$(echo ${distributable} | cut -d ':' -f 2)" "yes"

	# foo target info
	info=$(target info foo)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	# check name
	target=$(echo "${info}" | grep "Target:")
	asserteq $? 0
	asserteq "$(echo "${target}" | cut -d ':' -f 2)" "foo"
	# check path
	target_path=$(echo "${info}" | grep "Path:")
	asserteq $? 0
	asserteq "$(echo "${target_path}" | cut -d ':' -f 2)" "${BB_PROJECT_DIR}/foo"
	# check profile path
	profile_path=$(echo "${info}" | grep "Profilepath:")
	asserteq $? 0
	asserteq "$(echo "${profile_path}" | cut -d ':' -f 2)" "${BB_PROJECT_PROFILE_DIR}/target.foo"
	# check testable
	testable=$(echo "${info}" | grep "Testable:")
	asserteq $? 0
	asserteq "$(echo "${testable}" | cut -d ':' -f 2)" "no"
	# check distributable
	distributable=$(echo "${info}" | grep "Distributable:")
	asserteq $? 0
	asserteq "$(echo "${distributable}" | cut -d ':' -f 2)" "no"

}
bb_declare_test test_target_info

function test_target_info_is_cloned {
	bb_use_test_project foo_project
	asserteq $? 0

	# check not cloned
	info=$(target info)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	target=$(echo "${info}" | grep "Iscloned:")
	asserteq $? 0
	asserteq "$(echo ${target} | cut -d ':' -f 2)" "no"

	# check partially cloned
	clone bar_package
	asserteq $? 0
	info=$(target info)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	target=$(echo "${info}" | grep "Iscloned:")
	asserteq $? 0
	asserteq "$(echo ${target} | cut -d ':' -f 2)" "partially"

	# check completely cloned
	target clone
	asserteq $? 0
	info=$(target info)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	target=$(echo "${info}" | grep "Iscloned:")
	asserteq $? 0
	asserteq "$(echo "${target}" | cut -d ':' -f 2)" "yes"
}
bb_declare_test test_target_info_is_cloned

function test_target_info_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target info 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_info_no_err_log

function test_target_info_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target info unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_info_unknown

