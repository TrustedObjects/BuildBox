function test_bb_reset_local_env {
	path_orig="${PATH}"
	xdg_data_dirs_orig="${XDG_DATA_DIRS}"
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_reset_local_env
	asserteq $? 0
	# Check reset
	assertz "${CPU}"
	assertz "${CPUDEF}"
	assertz "${CHOST}"
	assertz "${CPU_FAMILY}"
	assertz "${PREFIX}"
	assertz "${PKG_CONFIG_PATH}"
	assertz "${CFLAGS}"
	assertz "${LD_LIBRARY_PATH}"
	assertz "${LDFLAGS}"
	assertz "${ACLOCAL_PATH}"
	assertz "${PYTHONPATH}"
	asserteq "${path_orig}" "${PATH}"
	asserteq "${xdg_data_dirs_orig}" "${XDG_DATA_DIRS}"
	env|grep -v "BB_TARGET_VAR_"
	asserteq $? 0
}
bb_declare_test test_bb_reset_local_env

