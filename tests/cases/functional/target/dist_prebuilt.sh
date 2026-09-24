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


function test_target_dist_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	out="$(target dist-prebuilt)"
	asserteq $? 0
	out="$(unformat_string "${out}")"
	assertn "$(echo "${out}" | grep "Archiving built files... ok")"
	assertn "$(echo "${out}" | grep "Releasing archive... ok")"
	exported="${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/${BB_TARGET}.tar.xz"
	assertf "${exported}"
	content="$(tar -tJf "${exported}")"
	asserteq $? 0
	assertn "$(echo "${content}" | grep -x "build/bin/foo_package")"
	assertn "$(echo "${content}" | grep -x "build/bin/bar_package")"
	# The local archive is removed once released
	assertz "$(find "${TMPDIR}" -name "${BB_TARGET}.tar.xz")"
}
bb_declare_test test_target_dist_prebuilt

function test_target_dist_prebuilt_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	out="$(target dist-prebuilt 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_dist_prebuilt_no_err_log

function test_target_dist_prebuilt_project_config {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	# Server settings read from the project configuration
	cat > "${BB_PROJECT_PROFILE_DIR}/config" <<- CONFIG
		BB_PREBUILT_SERVER=${BB_PREBUILT_SERVER}
		BB_PREBUILT_USERNAME=${BB_PREBUILT_USERNAME}
		BB_PREBUILT_PATH=${BB_PREBUILT_PATH}
	CONFIG
	unset BB_PREBUILT_SERVER BB_PREBUILT_USERNAME BB_PREBUILT_PATH
	target build > /dev/null
	asserteq $? 0
	target dist-prebuilt > /dev/null
	asserteq $? 0
	assertf "${BB_TEST_PREBUILT_SERVER_ROOT}/prebuilt/master/v1.0.0/${BB_TARGET}.tar.xz"
	assertn "$(grep "tester@prebuilt.test:/prebuilt/" "${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_target_dist_prebuilt_project_config

function test_target_dist_prebuilt_not_built {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	out="$(target dist-prebuilt 2>&1)"
	assertne $? 0
	assertn "$(echo "${out}" | grep "Target must be built")"
	assertz "$(cat "${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_target_dist_prebuilt_not_built

function test_target_dist_prebuilt_no_server_settings {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	# Checked before anything is archived, so the target build directory is enough
	mkdir -p "${BB_TARGET_BUILD_DIR}"
	for setting in BB_PREBUILT_SERVER BB_PREBUILT_USERNAME BB_PREBUILT_PATH; do
		out="$(unset ${setting}; target dist-prebuilt 2>&1)"
		assertne $? 0
		assertn "$(echo "${out}" | grep "Please define ${setting}")"
	done
	assertz "$(cat "${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_target_dist_prebuilt_no_server_settings

function test_target_dist_prebuilt_untagged {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	bb_commit_test_project_profile
	asserteq $? 0
	export BB_PREBUILT_ONLY_TAGGED=1
	out="$(target dist-prebuilt 2>&1)"
	assertne $? 0
	assertn "$(echo "${out}" | grep "have to be tagged")"
	assertz "$(cat "${BB_TEST_PREBUILT_SERVER_LOG}")"
	assertz "$(find "${BB_TEST_PREBUILT_SERVER_ROOT}" -type f)"
}
bb_declare_test test_target_dist_prebuilt_untagged

function test_target_dist_prebuilt_unreachable {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	target build > /dev/null
	asserteq $? 0
	export BB_PREBUILT_PATH="/missing"
	out="$(target dist-prebuilt 2>&1)"
	assertne $? 0
	assertn "$(echo "${out}" | grep "Unable to release archive")"
	# The local archive is removed on failure too
	assertz "$(find "${TMPDIR}" -name "${BB_TARGET}.tar.xz")"
}
bb_declare_test test_target_dist_prebuilt_unreachable

function test_target_dist_prebuilt_project_not_set {
	out="$(target dist-prebuilt 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_target_dist_prebuilt_project_not_set
