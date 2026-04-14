function test_target_pkg {
	bb_use_test_project foo_project
	asserteq $? 0
	# list packages for target bar
	target set bar
	asserteq $? 0
	list="$(target pkg)"
	asserteq $? 0
	echo "${list}" | grep "foo_package@1.0"
	asserteq $? 0
	echo "${list}" | grep "bar_package"
	asserteq $? 0
	echo "${list}" | grep "corge_package"
	asserteq $? 0
	echo "${list}" | grep "quux_package"
	asserteq $? 0
	echo "${list}" | grep "foo_http_package-1.0"
	asserteq $? 0
}
bb_declare_test test_target_pkg

function test_target_pkg_modified {
	bb_use_test_project foo_project
	asserteq $? 0
	# list packages for target bar
	target set bar
	asserteq $? 0
	target clone
	asserteq $? 0
	# modify a package and check it is the only returned by 'target pkg -m'
	echo "" >> ${BB_TARGET_SRC_DIR}/bar_package.sources/main.c
	list="$(target pkg -m)"
	asserteq $? 0
	echo "${list}" | grep "foo_package@1.0"
	assertne $? 0
	echo "${list}" | grep "bar_package"
	asserteq $? 0
	echo "${list}" | grep "corge_package"
	assertne $? 0
	echo "${list}" | grep "quux_package"
	assertne $? 0
	echo "${list}" | grep "foo_http_package-1.0"
	assertne $? 0
}
bb_declare_test test_target_pkg_modified

function test_target_pkg_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	target set bar
	asserteq $? 0
	out="$(target pkg 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_pkg_no_err_log

