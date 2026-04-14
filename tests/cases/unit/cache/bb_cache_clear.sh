function test_bb_cache_clear {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	echo "File1" > ${TMPDIR}/file1
	bb_cache_store_file ${TMPDIR}/file1
	asserteq $? 0
	echo "File2" > ${TMPDIR}/file2
	bb_cache_store_file ${TMPDIR}/file2
	asserteq $? 0
	cached_count=$(ls -1 ${BB_CACHE_DIR} | wc -l)
	asserteq ${cached_count} 2
	bb_cache_clear
	cached_count=$(ls -1 ${BB_CACHE_DIR} | wc -l)
	asserteq ${cached_count} 0
}
bb_declare_test test_bb_cache_clear
