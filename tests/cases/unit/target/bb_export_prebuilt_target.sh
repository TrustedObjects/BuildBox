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


function test_bb_export_prebuilt_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	bb_export_prebuilt_target "${archive}"
	asserteq $? 0
	exported="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/bar.tar.xz"
	assertf "${exported}"
	assert cmp -s "${exported}" "${archive}/master/v1.0.0/bar.tar.xz"
	# Sent with the configured server, user and path
	assertn "$(grep "^scp .* tester@prebuilt.test:/prebuilt/" "${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_bb_export_prebuilt_target

function test_bb_export_prebuilt_target_keeps_others {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	# Another release of the same project, and the same release of another target
	other_tag="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v0.9.0/bar.tar.xz"
	other_target="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/foo.tar.xz"
	mkdir -p "$(dirname "${other_tag}")" "$(dirname "${other_target}")"
	echo "v0.9.0" > "${other_tag}"
	echo "foo" > "${other_target}"
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	bb_export_prebuilt_target "${archive}"
	asserteq $? 0
	assertf "${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/bar.tar.xz"
	asserteq "$(cat "${other_tag}")" "v0.9.0"
	asserteq "$(cat "${other_target}")" "foo"
}
bb_declare_test test_bb_export_prebuilt_target_keeps_others

function test_bb_export_prebuilt_target_replace {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	exported="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/bar.tar.xz"
	mkdir -p "$(dirname "${exported}")"
	echo "outdated" > "${exported}"
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	bb_export_prebuilt_target "${archive}"
	asserteq $? 0
	assert cmp -s "${exported}" "${archive}/master/v1.0.0/bar.tar.xz"
}
bb_declare_test test_bb_export_prebuilt_target_replace

function test_bb_export_prebuilt_target_unreachable {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	export BB_PREBUILT_PATH="/missing"
	err="$(bb_export_prebuilt_target "${archive}" 2>&1 >/dev/null)"
	assertne $? 0
	assertn "$(echo "${err}" | grep "Unable to release archive")"
}
bb_declare_test test_bb_export_prebuilt_target_unreachable
