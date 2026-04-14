function test_target_fastbuild {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	# Modify a package and do fast build
	sed -i 's/MESSAGE\"/MESSAGE\" updated/' ${BB_TARGET_SRC_DIR}/bar_package.sources/main.c
	target fastbuild
	asserteq $? 0
	assertf "${BB_TARGET_DIR}/target_fastbuild.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_fastbuild.log)"
	out="$(${BB_TARGET_BUILD_DIR}/bin/bar_package)"
	asserteq "${out}" "Hello from bar package ! updated"
}
bb_declare_test test_target_fastbuild

function test_target_fastbuild_first {
	bb_use_test_project foo_project
	asserteq $? 0
	target fastbuild
	# fail because some packages on this target require configuration
	assertne $? 0
	assertf "${BB_TARGET_DIR}/target_fastbuild.log"
	assertn "$(cat ${BB_TARGET_DIR}/target_fastbuild.log)"
}
bb_declare_test test_target_fastbuild_first

function test_target_fastbuild_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	target build
	asserteq $? 0
	out="$(target fastbuild 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_fastbuild_no_err_log

function test_target_fastbuild_project_not_set {
	out="$(target fastbuild 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_fastbuild_project_not_set

function test_target_fastbuild_verbose {
	skip "test not implemented yet"
}
bb_declare_test test_target_fastbuild_verbose

function test_target_fastbuild_continue {
	skip "test not implemented yet"
}
bb_declare_test test_target_fastbuild_continue

