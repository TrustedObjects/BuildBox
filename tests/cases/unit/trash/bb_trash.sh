function test_bb_trash {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir "${BB_PROJECT_DIR}/testdir1"
	touch "${BB_PROJECT_DIR}/testdir1/file1"
	touch "${BB_PROJECT_DIR}/testdir1/file2"
	mkdir "${BB_PROJECT_DIR}/testdir2"
	trash_uuid=$(bb_trash "${BB_PROJECT_DIR}/testdir1")
	asserteq $? 0
	assertnd "${BB_PROJECT_DIR}/testdir1"
	assertd "${BB_PROJECT_DIR}/testdir2"
	assertd ${BB_TRASH_DIR}/${trash_uuid}
	assertf ${BB_TRASH_DIR}/${trash_uuid}/file1
	assertf ${BB_TRASH_DIR}/${trash_uuid}/file2
}
bb_declare_test test_bb_trash
