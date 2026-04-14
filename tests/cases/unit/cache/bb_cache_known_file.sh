function test_bb_cache_known_file {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	# Cache hit
	echo "File 1" > ${TMPDIR}/file1
	bb_cache_store_file ${TMPDIR}/file1
	asserteq $? 0
	digest1=$(sha256sum ${TMPDIR}/file1 | cut -d ' ' -f 1)
	path=$(bb_cache_known_file ${digest1})
	asserteq $? 0
	asserteq ${BB_CACHE_DIR}/${digest1} ${path}
	assertf ${path}
	# Cache miss
	echo "File 2" > ${TMPDIR}/file2
	digest2=$(sha256sum ${TMPDIR}/file2 | cut -d ' ' -f 1)
	path=$(bb_cache_known_file ${digest2})
	assertne $? 0
	assertz ${path}
}
bb_declare_test test_bb_cache_known_file
