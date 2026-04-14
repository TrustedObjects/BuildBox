function test_bb_set_tools_local_env {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo ## 2.x
	asserteq $? 0
	export BB_TARGET="bar"
	bb_set_tools_local_env
	asserteq $? 0
	# Check every tool has been taken into account
	assertn "${PATH}"
	assert "[[ "${PATH}" == *"foo_tool"* ]]"
	assert "[[ "${PATH}" == *"bar_tool"* ]]"
	assert "[[ "${PATH}" == *"baz_tool"* ]]"
	assertn "${PKG_CONFIG_PATH}"
	assert "[[ "${PKG_CONFIG_PATH}" == *"foo_tool"* ]]"
	assert "[[ "${PKG_CONFIG_PATH}" == *"bar_tool"* ]]"
	assert "[[ "${PKG_CONFIG_PATH}" == *"baz_tool"* ]]"
	assertn "${CFLAGS}"
	assertn "${LD_LIBRARY_PATH}"
	assert "[[ "${LD_LIBRARY_PATH}" == *"foo_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"bar_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"baz_tool"* ]]"
	assertn "${LDFLAGS}"
	assertn "${ACLOCAL_PATH}"
	assert "[[ "${LD_LIBRARY_PATH}" == *"foo_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"bar_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"baz_tool"* ]]"
	assertn "${XDG_DATA_DIRS}"
	assert "[[ "${LD_LIBRARY_PATH}" == *"foo_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"bar_tool"* ]]"
	assert "[[ "${LD_LIBRARY_PATH}" == *"baz_tool"* ]]"
	assertn "${PYTHONPATH}"
	assert "[[ "${PYTHONPATH}" == *"foo_tool"* ]]"
	assert "[[ "${PYTHONPATH}" == *"bar_tool"* ]]"
	assert "[[ "${PYTHONPATH}" == *"baz_tool"* ]]"
	# More detailed checks are performed in bb_set_local_env.sh
}
bb_declare_test test_bb_set_tools_local_env

