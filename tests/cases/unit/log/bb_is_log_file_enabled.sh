# We are using a sub-script below to avoid test suite disrupt when using
# bb_enable_log_file(), which is changing stdout file descriptors

bb_is_log_file_enabled_test_script="#!${SHELL_CMD}
source buildbox_utils.sh
bb_is_log_file_enabled
ret=\$?
bb_enable_log_file
bb_is_log_file_enabled
ret=\$ret\$?
bb_disable_log_file
bb_is_log_file_enabled
ret=\$ret\$?
echo \$ret
"

disable_log_file_expected_content="Test3
Test4"

function test_bb_is_log_file_enabled {
	echo "${bb_is_log_file_enabled_test_script}" > "${TMPDIR}/test.sh"
	chmod +x "${TMPDIR}/test.sh"
	result=$(echo -n | ${TMPDIR}/test.sh) # echo avoids stdin consuming when enabling log file
	asserteq "${result}" "010"
}
bb_declare_test test_bb_is_log_file_enabled
