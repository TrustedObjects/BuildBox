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


function test_bb_archive_prebuilt_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	assertd "${archive}"
	# Laid out as on the server: <tag>/<target>.tar.xz
	assertf "${archive}/v1.0.0/bar.tar.xz"
	asserteq "$(cd "${archive}" && find . -type f)" "./v1.0.0/bar.tar.xz"
	assert_is_subpath_of "${TMPDIR}" "${archive}"
}
bb_declare_test test_bb_archive_prebuilt_target

function test_bb_archive_prebuilt_target_branches {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	# The tag alone designates the revision, whatever the branches holding it
	git -C "${BB_PROJECT_PROFILE_DIR}" branch zzz_release
	asserteq $? 0
	git -C "${BB_PROJECT_PROFILE_DIR}" checkout -q --detach
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	asserteq "$(cd "${archive}" && find . -type f)" "./v1.0.0/bar.tar.xz"
}
bb_declare_test test_bb_archive_prebuilt_target_branches

function test_bb_archive_prebuilt_target_content {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	bb_build_package "bar_package"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	content="$(tar -tJf "${archive}/v1.0.0/bar.tar.xz")"
	asserteq $? 0
	# Installed files
	assertn "$(echo "${content}" | grep -x "build/bin/foo_package")"
	assertn "$(echo "${content}" | grep -x "build/bin/bar_package")"
	assertn "$(echo "${content}" | grep -x "build/share/ressource1")"
	# Target specific directories of the target sources, such as build ones
	assertn "$(echo "${content}" | grep -x "src/bar_package.build/")"
	# Shared sources, linked from the target sources, are left out
	assertz "$(echo "${content}" | grep "^src/bar_package/")"
	assertz "$(echo "${content}" | grep "^src/bar_package$")"
	assertz "$(echo "${content}" | grep "^src/foo_package@1.0")"
	assertz "$(echo "${content}" | grep "\.sources")"
}
bb_declare_test test_bb_archive_prebuilt_target_content

function test_bb_archive_prebuilt_target_not_built {
	bb_use_test_project foo_project bar
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	assertne $? 0
}
bb_declare_test test_bb_archive_prebuilt_target_not_built

function test_bb_archive_prebuilt_target_untagged {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	bb_commit_test_project_profile
	asserteq $? 0
	export BB_PREBUILT_ONLY_TAGGED=1
	err="$(bb_archive_prebuilt_target 2>&1 >/dev/null)"
	assertne $? 0
	assertn "$(echo "${err}" | grep "have to be tagged")"
	# Nothing left behind
	assertz "$(find "${TMPDIR}" -name "bar.tar.xz")"
}
bb_declare_test test_bb_archive_prebuilt_target_untagged

function test_bb_archive_prebuilt_target_untagged_allowed {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	bb_commit_test_project_profile
	asserteq $? 0
	export BB_PREBUILT_ONLY_TAGGED=0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	# Named after the description of the commit from its last tag
	tag="$(git -C "${BB_PROJECT_PROFILE_DIR}" describe --tags)"
	assertne "${tag}" "v1.0.0"
	assertf "${archive}/${tag}/bar.tar.xz"
}
bb_declare_test test_bb_archive_prebuilt_target_untagged_allowed

function test_bb_archive_prebuilt_target_no_tag {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	git -C "${BB_PROJECT_PROFILE_DIR}" tag -l | xargs git -C "${BB_PROJECT_PROFILE_DIR}" tag -d > /dev/null
	asserteq $? 0
	# Even when untagged projects are allowed, a prebuilt needs a tag to be named after
	export BB_PREBUILT_ONLY_TAGGED=0
	err="$(bb_archive_prebuilt_target 2>&1 >/dev/null)"
	assertne $? 0
	assertn "$(echo "${err}" | grep "have to be tagged")"
}
bb_declare_test test_bb_archive_prebuilt_target_no_tag
