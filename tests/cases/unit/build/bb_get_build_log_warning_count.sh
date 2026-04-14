function test_bb_get_build_log_warning_count_gcc {
	echo "This is a build log line
warning: This is a warning
This is another build log line
warning: This is another warning
warning: This is a last warning
" > ${TMPDIR}/build.log
	count=$(bb_get_build_log_warning_count ${TMPDIR}/build.log)
	asserteq $? 0
	asserteq $count 3
}
bb_declare_test test_bb_get_build_log_warning_count_gcc

function test_bb_get_build_log_warning_count_mbed {
	echo "This is a build log line
[Warning] This is a warning
This is another build log line
[Warning] This is another warning
" > ${TMPDIR}/build.log
	count=$(bb_get_build_log_warning_count ${TMPDIR}/build.log)
	asserteq $? 0
	asserteq $count 2
}
bb_declare_test test_bb_get_build_log_warning_count_mbed

function test_bb_get_build_log_warning_count_file_not_found {
	bb_get_build_log_warning_count ${TMPDIR}/build.log
	assertne $? 0
}
bb_declare_test test_bb_get_build_log_warning_count_file_not_found

