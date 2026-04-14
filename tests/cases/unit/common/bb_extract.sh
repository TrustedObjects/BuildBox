function test_bb_extract_tar_bz2 {
	cd ${TMPDIR}
	echo "test" > file
	tar -cjf file.tar.bz2 file
	asserteq $? 0
	rm file
	bb_extract file.tar.bz2
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_tar_bz2

function test_bb_extract_tar_gz {
	cd ${TMPDIR}
	echo "test" > file
	tar -czf file.tar.gz file
	asserteq $? 0
	rm file
	bb_extract file.tar.gz
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_tar_gz

function test_bb_extract_tar_xz {
	cd ${TMPDIR}
	echo "test" > file
	tar -cJf file.tar.xz file
	asserteq $? 0
	rm file
	bb_extract file.tar.xz
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_tar_xz

function test_bb_extract_tgz {
	cd ${TMPDIR}
	echo "test" > file
	tar -czf file.tar.tgz file
	asserteq $? 0
	rm file
	bb_extract file.tar.tgz
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_tgz

function test_bb_extract_zip {
	cd ${TMPDIR}
	echo "test" > file
	zip file.zip file
	asserteq $? 0
	rm file
	bb_extract file.zip
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_zip

function test_bb_extract_tar_zst {
	cd ${TMPDIR}
	echo "test" > file
	tar --zstd -cf file.tar.zst file
	asserteq $? 0
	rm file
	bb_extract file.tar.zst
	asserteq $? 0
	assertf file
	asserteq "$(cat file)" "test"
}
bb_declare_test test_bb_extract_tar_zst

function test_bb_extract_tar_bz2_malformed {
	cd ${TMPDIR}
	echo "test" > file.tar.bz2
	bb_extract file.tar.bz2
	assertne $? 0
}
bb_declare_test test_bb_extract_tar_bz2_malformed

function test_bb_extract_tar_gz_malformed {
	cd ${TMPDIR}
	echo "test" > file.tar.gz
	bb_extract file.tar.gz
	assertne $? 0
}
bb_declare_test test_bb_extract_tar_gz_malformed

function test_bb_extract_tar_xz_malformed {
	cd ${TMPDIR}
	echo "test" > file.tar.xz
	bb_extract file.tar.xz
	assertne $? 0
}
bb_declare_test test_bb_extract_tar_xz_malformed

function test_bb_extract_tgz_malformed {
	cd ${TMPDIR}
	echo "test" > file.tar.tgz
	bb_extract file.tar.tgz
	assertne $? 0
}
bb_declare_test test_bb_extract_tgz_malformed

function test_bb_extract_zip_malformed {
	cd ${TMPDIR}
	echo "test" > file.zip
	bb_extract file.zip
	assertne $? 0
}
bb_declare_test test_bb_extract_zip_malformed

function test_bb_extract_tar_zst_malformed {
	cd ${TMPDIR}
	echo "test" > file.tar.zst
	bb_extract file.tar.zst
	assertne $? 0
}
bb_declare_test test_bb_extract_tar_zst_malformed

function test_bb_extract_format_not_supported {
	cd ${TMPDIR}
	echo "test" > file.unknown
	bb_extract file.unknown
	assertne $? 0
}
bb_declare_test test_bb_extract_format_not_supported

