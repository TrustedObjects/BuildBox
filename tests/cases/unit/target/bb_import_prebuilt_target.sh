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


function test_bb_import_prebuilt_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	assertnd "${BB_TARGET_DIR}"
	bb_import_prebuilt_target
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/prebuilt_hello"
	asserteq "$(${BB_TARGET_BUILD_DIR}/bin/prebuilt_hello)" "Hello from prebuilt"
	assertn "$(grep "^scp .*tester@prebuilt.test:/prebuilt/v1.0.0/bar.tar.xz" \
		"${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_bb_import_prebuilt_target

function test_bb_import_prebuilt_target_keeps_cwd {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	cd "${BB_PROJECT_DIR}"
	bb_import_prebuilt_target
	asserteq $? 0
	asserteq "$(pwd)" "${BB_PROJECT_DIR}"
}
bb_declare_test test_bb_import_prebuilt_target_keeps_cwd

function test_bb_import_prebuilt_target_local_archive {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	# An archive already in the target directory is used as is, the server
	# not being asked for anything
	mkdir -p "${BB_TARGET_DIR}"
	bb_put_fake_prebuilt "${BB_TARGET_DIR}/bar.tar.xz" > /dev/null
	asserteq $? 0
	bb_import_prebuilt_target
	asserteq $? 0
	assertf "${BB_TARGET_BUILD_DIR}/bin/prebuilt_hello"
	assertz "$(cat "${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_bb_import_prebuilt_target_local_archive

function test_bb_import_prebuilt_target_missing {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_import_prebuilt_target 2> /dev/null
	assertne $? 0
	assertnd "${BB_TARGET_BUILD_DIR}"
}
bb_declare_test test_bb_import_prebuilt_target_missing

function test_bb_import_prebuilt_target_corrupted {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	archive="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/v1.0.0/bar.tar.xz"
	mkdir -p "$(dirname "${archive}")"
	echo "not an archive" > "${archive}"
	bb_import_prebuilt_target 2> /dev/null
	assertne $? 0
}
bb_declare_test test_bb_import_prebuilt_target_corrupted
