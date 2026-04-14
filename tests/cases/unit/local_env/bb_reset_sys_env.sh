function test_bb_reset_sys_env {
	path_orig="${PATH}"
	xdg_data_dirs_orig="${XDG_DATA_DIRS}"
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	assertne "${PATH}" "${path_orig}"
	assertne "${XDG_DATA_DIRS}" "${xdg_data_dirs_orig}"
	bb_reset_sys_env
	asserteq $? 0
	asserteq "${PATH}" "${path_orig}"
	asserteq "${XDG_DATA_DIRS}" "${xdg_data_dirs_orig}"
}
bb_declare_test test_bb_reset_sys_env
