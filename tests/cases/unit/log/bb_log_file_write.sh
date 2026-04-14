log_file_write_expected_content="Test 1
Test 2"

function test_bb_log_file_write {
	log_file=$(bb_get_current_log_file)
	bb_log_file_write "Test 1"
	asserteq $? 0
	bb_log_file_write "Test 2"
	asserteq $? 0
	asserteq "$(cat ${log_file})" "${log_file_write_expected_content}"
}
bb_declare_test test_bb_log_file_write

function test_bb_log_file_write_creates_missing_dir {
	local log_dir="${TMPDIR}/missing_dir_write_$$"
	local log_file="${log_dir}/test.log"
	assertnd "${log_dir}"
	BB_CURRENT_LOG_FILE="${log_file}"
	bb_log_file_write "Test"
	asserteq $? 0
	assertd "${log_dir}"
	assertf "${log_file}"
}
bb_declare_test test_bb_log_file_write_creates_missing_dir

function test_bb_log_file_write_fail {
	bb_set_current_log_file ${TMPDIR}/my_log_file.log
	asserteq $? 0
	# replace log file with a directory
	rm ${TMPDIR}/my_log_file.log
	mkdir ${TMPDIR}/my_log_file.log
	bb_log_file_write "Test" # fail, unable to write text in a directory
	assertne $? 0
}
bb_declare_test test_bb_log_file_write_fail
