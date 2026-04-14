function test_bb_cache_load_file {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	# Cache hit
	echo "File 1" > ${TMPDIR}/file1
	bb_cache_store_file ${TMPDIR}/file1
	asserteq $? 0
	digest1=$(sha256sum ${TMPDIR}/file1 | cut -d ' ' -f 1)
	bb_cache_load_file ${digest1} ${TMPDIR}/loaded_file1
	asserteq $? 0
	digest_loaded_file=$(sha256sum ${TMPDIR}/loaded_file1 | cut -d ' ' -f 1)
	asserteq ${digest1} ${digest_loaded_file}
	# Cache miss
	echo "File 2" > ${TMPDIR}/file2
	digest2=$(sha256sum ${TMPDIR}/file2 | cut -d ' ' -f 1)
	bb_cache_load_file ${digest2} ${TMPDIR}/loaded_file2
	assertne $? 0
	assertnf ${TMPDIR}/loaded_file2
}
bb_declare_test test_bb_cache_load_file
