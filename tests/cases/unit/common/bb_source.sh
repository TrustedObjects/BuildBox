success_script="echo 'sourced' >> ${TMPDIR}/script.log
return 0
"
fail_script="return 1
"

function test_bb_source {
	echo "${success_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	asserteq $? 0
}
bb_declare_test test_bb_source

function test_bb_source_fail {
	echo "${fail_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	assertne $? 0
}
bb_declare_test test_bb_source_fail

function test_bb_source_check_once {
	echo "${success_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	asserteq $? 0
	asserteq $(cat ${TMPDIR}/script.log | wc -l) 1
	bb_source ${TMPDIR}/script.sh
	asserteq $(cat ${TMPDIR}/script.log | wc -l) 1
}
bb_declare_test test_bb_source_check_once

