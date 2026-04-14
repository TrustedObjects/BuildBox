function check_clone {
	package_name=${1}
	package_name_no_revision=${2}
	expected_readme_content="${3}"
	support_sources_sharing=${4}
	package_dir=$(bb_escape_package_name "${package_name}")

	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package ${package_name}
	asserteq $? 0
	# Project files check
	assertd "${BB_PROJECT_SRC_DIR}/${package_dir}"
	assertd "${BB_PROJECT_SRC_DIR}/${package_dir}/.git"
	assertf "${BB_PROJECT_SRC_DIR}/${package_dir}/README"
	readme_content="$(cat ${BB_PROJECT_SRC_DIR}/${package_dir}/README)"
	asserteq "${readme_content}" "${expected_readme_content}"
	# Target files check
	assertl "${BB_TARGET_SRC_DIR}/${package_name_no_revision}.sources"
	file_id_target=$(stat -c '%i' "${BB_TARGET_SRC_DIR}/${package_dir}/README")
	file_id_target_link=$(stat -c '%i' "${BB_TARGET_SRC_DIR}/${package_name_no_revision}.sources/README")
	asserteq "${file_id_target}" "${file_id_target_link}"
	if [ ${support_sources_sharing} -eq 1 ]; then
		assertl "${BB_TARGET_SRC_DIR}/${package_dir}"
		link_target=$(readlink ${BB_TARGET_SRC_DIR}/${package_dir})
		asserteq "${link_target}" "../../src/${package_dir}"
		file_id_project=$(stat -c '%i' "${BB_PROJECT_SRC_DIR}/${package_dir}/README")
		asserteq "${file_id_project}" "${file_id_target}"
	else
		assertd "${BB_TARGET_SRC_DIR}/${package_dir}"
		file_id_project=$(stat -c '%i' "${BB_PROJECT_SRC_DIR}/${package_dir}/README")
		assertne "${file_id_project}" "${file_id_target}"
	fi
}

function test_bb_clone_package_git_prebuilt {
	check_clone "foo_package@1.0" "foo_package" "This is foo pre-built package" 1
}
bb_declare_test test_bb_clone_package_git_prebuilt

function test_bb_clone_package_git_autotools {
	check_clone "bar_package" "bar_package" "Bar package README" 1
}
bb_declare_test test_bb_clone_package_git_autotools

function test_bb_clone_package_git_make {
	check_clone "baz_package" "baz_package" "Baz package README" 0
}
bb_declare_test test_bb_clone_package_git_make

function test_bb_clone_package_git_custom {
	check_clone "qux_package" "qux_package" "Qux package README" 0
}
bb_declare_test test_bb_clone_package_git_custom

function test_bb_clone_package_in_subdir {
	check_clone "subdir/quux_package" "subdir_quux_package" "This is quux pre-built package" 1
}
bb_declare_test test_bb_clone_package_in_subdir

function test_bb_clone_package_does_not_exist {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "unknown"
	assertne $? 0
}
bb_declare_test test_bb_clone_package_does_not_exist

function test_bb_clone_package_unsupported_protocol {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz ## 2.x
	asserteq $? 0
	bb_clone_package "garply_package"
	assertne $? 0
}
bb_declare_test test_bb_clone_package_unsupported_protocol

function test_bb_clone_package_git_tag {
	check_clone "bar_package@1.0.0" "bar_package" "Bar package README" 1
	cd "${BB_TARGET_DIR}/src/bar_package.sources"
	asserteq $? 0
	tag=$(git describe --tags)
	asserteq $? 0
	asserteq "${tag}" "1.0.0"
}
bb_declare_test test_bb_clone_package_git_tag

function test_bb_clone_package_git_changeset {
	check_clone "bar_package@8edfc5c62ea5601f6325519f7ae883fc81af2865" "bar_package" "Bar package README" 1
	cd "${BB_TARGET_DIR}/src/bar_package.sources"
	asserteq $? 0
	changeset=$(git rev-parse HEAD)
	asserteq $? 0
	asserteq "${changeset}" "8edfc5c62ea5601f6325519f7ae883fc81af2865"
}
bb_declare_test test_bb_clone_package_git_changeset

function test_bb_clone_package_git_branch {
	check_clone "bar_package@rb-1.0.0" "bar_package" "Bar package README 1.0.0 release branch" 1
	cd "${BB_TARGET_DIR}/src/bar_package.sources"
	asserteq $? 0
	branch=$(git branch --show-current)
	asserteq $? 0
	asserteq "${branch}" "rb-1.0.0"
}
bb_declare_test test_bb_clone_package_git_branch

function test_bb_clone_package_branch_with_slashes {
	check_clone "foo_package@branch/with/slashes" "foo_package" "This is foo package from branch with slashes" 1
}
bb_declare_test test_bb_clone_package_branch_with_slashes

