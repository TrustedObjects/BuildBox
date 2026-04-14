backup_log_file_expected_content="Test 1
Test 2"

function test_bb_backup_log_file {
	log_file=$(bb_get_current_log_file)
	bb_log_file_write "Test 1"
	asserteq $? 0
	bb_log_file_write "Test 2"
	asserteq $? 0
	bb_backup_log_file ${TMPDIR}/backup.log
	asserteq "$(cat ${log_file})" "${backup_log_file_expected_content}"
	asserteq "$(cat ${TMPDIR}/backup.log)" "${backup_log_file_expected_content}"
}
bb_declare_test test_bb_backup_log_file

