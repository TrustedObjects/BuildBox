# This file is part of BuildBox project
# Copyright (C) 2020-2026 Trusted Objects

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2, as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, see
# <https://www.gnu.org/licenses/>.

# Change the sources sharing a package declares, once it is cloned
# @param Package name
# @param Sharing support (0 or 1)
function set_package_sharing {
	printf 'SRC_SUPPORTS_SHARING=%s\n' "${2}" \
		>> "${BB_PROJECT_PROFILE_DIR}/packages/${1}"
}

function test_bb_apply_package_sources_sharing_not_cloned {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_apply_package_sources_sharing "bar_package"
	asserteq $? 2
}
bb_declare_test test_bb_apply_package_sources_sharing_not_cloned

function test_bb_apply_package_sources_sharing_unknown_package {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_apply_package_sources_sharing "unknown"
	assertne $? 0
}
bb_declare_test test_bb_apply_package_sources_sharing_unknown_package

function test_bb_apply_package_sources_sharing_shared_sources_unchanged {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	# 'autotools' supports sources sharing
	bb_clone_package "bar_package"
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	bb_apply_package_sources_sharing "bar_package"
	asserteq $? 2
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
}
bb_declare_test test_bb_apply_package_sources_sharing_shared_sources_unchanged

function test_bb_apply_package_sources_sharing_copied_sources_unchanged {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	# 'make' does not support sources sharing
	bb_clone_package "baz_package"
	asserteq $? 0
	assertnl "${BB_TARGET_SRC_DIR}/baz_package"
	bb_apply_package_sources_sharing "baz_package"
	asserteq $? 2
	assertnl "${BB_TARGET_SRC_DIR}/baz_package"
}
bb_declare_test test_bb_apply_package_sources_sharing_copied_sources_unchanged

function test_bb_apply_package_sources_sharing_copy_becomes_link {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	assertnl "${BB_TARGET_SRC_DIR}/baz_package"
	set_package_sharing "baz_package" 1
	bb_apply_package_sources_sharing "baz_package"
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/baz_package"
	asserteq "$(readlink ${BB_TARGET_SRC_DIR}/baz_package)" "../../src/baz_package"
	# The copy is not lost, it waits in the trash
	assert "ls ${BB_TRASH_DIR} | grep -q '^baz_package-'"
}
bb_declare_test test_bb_apply_package_sources_sharing_copy_becomes_link

function test_bb_apply_package_sources_sharing_link_becomes_copy {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "bar_package"
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	set_package_sharing "bar_package" 0
	bb_apply_package_sources_sharing "bar_package"
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/bar_package"
	assertnl "${BB_TARGET_SRC_DIR}/bar_package"
	# The project sources stay where they are, they are only copied
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	file_id_project=$(stat -c '%i' "${BB_PROJECT_SRC_DIR}/bar_package/README")
	file_id_target=$(stat -c '%i' "${BB_TARGET_SRC_DIR}/bar_package/README")
	assertne "${file_id_project}" "${file_id_target}"
}
bb_declare_test test_bb_apply_package_sources_sharing_link_becomes_copy

function test_bb_apply_package_sources_sharing_keeps_local_work {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	# Work the project sources do not have: sharing would discard it
	echo "local work" > "${BB_TARGET_SRC_DIR}/baz_package/README"
	set_package_sharing "baz_package" 1
	bb_apply_package_sources_sharing "baz_package"
	asserteq $? 3
	assertnl "${BB_TARGET_SRC_DIR}/baz_package"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/baz_package/README)" "local work"
}
bb_declare_test test_bb_apply_package_sources_sharing_keeps_local_work

function test_bb_apply_package_sources_sharing_keeps_untracked_files {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_package "baz_package"
	asserteq $? 0
	echo "notes" > "${BB_TARGET_SRC_DIR}/baz_package/NOTES"
	set_package_sharing "baz_package" 1
	bb_apply_package_sources_sharing "baz_package"
	asserteq $? 3
	assertnl "${BB_TARGET_SRC_DIR}/baz_package"
	assertf "${BB_TARGET_SRC_DIR}/baz_package/NOTES"
}
bb_declare_test test_bb_apply_package_sources_sharing_keeps_untracked_files
