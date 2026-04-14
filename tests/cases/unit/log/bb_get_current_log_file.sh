bb_get_current_log_file_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_get_current_log_file
"

function test_bb_get_current_log_file {
	echo "${bb_get_current_log_file_test_script}" > "${TMPDIR}/test.sh"
	chmod +x "${TMPDIR}/test.sh"
	log_file=$(echo -n|${TMPDIR}/test.sh)
	asserteq $? 0
	expected_log_file="${TMPDIR}/test.sh.log"
	asserteq "${log_file}" "${expected_log_file}"
}
bb_declare_test test_bb_get_current_log_file
