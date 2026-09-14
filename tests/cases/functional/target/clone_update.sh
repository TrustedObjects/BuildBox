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

## Tests for 'target clone -u', which updates what is already cloned.
## The remote lives in the test workspace, so the shared fixture repositories
## are never modified.

# Create a repository holding one commit, and its bare remote.
# @param Remote name
# @print Bare remote path
function setup_update_remote {
	local name="${1}"
	local work="${BB_TEST_WORKSPACE}/${name}"
	local bare="${BB_TEST_WORKSPACE}/${name}.git"
	rm -rf "${work}" "${bare}"
	mkdir -p "${work}"
	(
		cd "${work}"
		git init -q -b master
		git config user.email test@buildbox
		git config user.name BuildBox
		echo "first" > CONTENT
		git add CONTENT
		git commit -q -m "First commit"
		git clone -q --bare . "${bare}"
		git remote add origin "${bare}"
	)
	echo "${bare}"
}

# Add a commit on the master branch of a remote created by
# setup_update_remote()
# @param Remote name
function advance_update_remote {
	local name="${1}"
	(
		cd "${BB_TEST_WORKSPACE}/${name}"
		echo "second" > CONTENT
		git commit -q -a -m "Second commit"
		git push -q origin master
	)
}

# Declare a package and a target using it in the current project profile
# @param Package name
# @param Remote path
# @param Revision
# @param Build mode
# @param Target name
# @param Extra package file line, if any
function declare_update_target {
	printf 'SRC_PROTO=git\nSRC_URI=%s\nSRC_REVISION=%s\nSRC_BUILD=%s\n' \
		"${2}" "${3}" "${4}" > "${BB_PROJECT_PROFILE_DIR}/packages/${1}"
	if [ -n "${6}" ]; then
		printf '%s\n' "${6}" >> "${BB_PROJECT_PROFILE_DIR}/packages/${1}"
	fi
	printf '%s\n' "${1}" > "${BB_PROJECT_PROFILE_DIR}/packages.${5}"
	printf 'CPU=x86\nPACKAGES=packages.%s\n' "${5}" \
		> "${BB_PROJECT_PROFILE_DIR}/target.${5}"
}

function test_target_clone_update_branch {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_branch)
	# autotools supports sources sharing: the target holds a symlink to the
	# sources shared at project level
	declare_update_target upd_pkg "${bare}" master autotools updbranch
	bb_set_project_current_target updbranch
	asserteq $? 0

	# Not cloned yet: '-u' does a plain clone
	target clone -u
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/upd_pkg"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"

	# The branch moves: the sources follow
	advance_update_remote upd_branch
	target clone -u
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "second"
	# The shared sources are updated too, being the very same repository
	asserteq "$(cat ${BB_PROJECT_SRC_DIR}/upd_pkg/CONTENT)" "second"
}
bb_declare_test test_target_clone_update_branch

function test_target_clone_update_without_option_keeps_sources {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_noopt)
	declare_update_target upd_pkg "${bare}" master autotools updnoopt
	bb_set_project_current_target updnoopt
	asserteq $? 0
	target clone
	asserteq $? 0
	advance_update_remote upd_noopt
	# Without '-u' an already cloned package is left as it is
	target clone
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"
}
bb_declare_test test_target_clone_update_without_option_keeps_sources

function test_target_clone_update_tag_is_untouched {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_tag)
	(
		cd "${BB_TEST_WORKSPACE}/upd_tag"
		git tag v1
		git push -q origin v1
	)
	# A tag designates a fixed commit, it can not move
	declare_update_target upd_pkg "${bare}" v1 autotools updtag
	bb_set_project_current_target updtag
	asserteq $? 0
	target clone -u
	asserteq $? 0
	advance_update_remote upd_tag
	out=$(target clone -u)
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"
	assert "echo '${out}' | grep -q 'up to date'"
}
bb_declare_test test_target_clone_update_tag_is_untouched

function test_target_clone_update_moved_tag {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_movedtag)
	(
		cd "${BB_TEST_WORKSPACE}/upd_movedtag"
		git tag v1
		git push -q origin v1
	)
	declare_update_target upd_pkg "${bare}" v1 autotools updmovedtag
	bb_set_project_current_target updmovedtag
	asserteq $? 0
	target clone -u
	asserteq $? 0

	# The tag moves upstream: fetching it would be refused, which is no
	# reason for the update to fail
	advance_update_remote upd_movedtag
	(
		cd "${BB_TEST_WORKSPACE}/upd_movedtag"
		git tag -f v1
		git push -q -f origin v1
	)
	out=$(target clone -u)
	asserteq $? 0
	assert "echo '${out}' | grep -q 'up to date'"
	# A tag designates a fixed commit: the sources stay where they are, and
	# the log says what happened upstream
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"
	assert "grep -q 'history of the remote repository changed' ${BB_TARGET_DIR}/target_clone.log"
}
bb_declare_test test_target_clone_update_moved_tag

function test_target_clone_update_keeps_local_work {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_local)
	declare_update_target upd_pkg "${bare}" master autotools updlocal
	bb_set_project_current_target updlocal
	asserteq $? 0
	target clone -u
	asserteq $? 0
	# Local modification: the update must not discard it
	echo "local work" > "${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT"
	advance_update_remote upd_local
	out=$(target clone -u)
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "local work"
	assert "echo '${out}' | grep -q 'kept'"
}
bb_declare_test test_target_clone_update_keeps_local_work

function test_target_clone_update_copied_sources {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_copy)
	# 'custom' does not support sources sharing: the target holds its own copy
	declare_update_target upd_pkg "${bare}" master custom updcopy
	bb_set_project_current_target updcopy
	asserteq $? 0
	target clone -u
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/upd_pkg"
	assertnl "${BB_TARGET_SRC_DIR}/upd_pkg"
	advance_update_remote upd_copy
	target clone -u
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "second"
}
bb_declare_test test_target_clone_update_copied_sources

function test_target_clone_update_shares_copied_sources {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_share)
	# 'custom' does not support sources sharing: the target holds its own copy
	declare_update_target upd_pkg "${bare}" master custom updshare
	bb_set_project_current_target updshare
	asserteq $? 0
	target clone
	asserteq $? 0
	assertnl "${BB_TARGET_SRC_DIR}/upd_pkg"

	# The package declares its sources shared: the copy gives way to a
	# symlink to the project sources, and is kept in the trash
	declare_update_target upd_pkg "${bare}" master custom updshare SRC_SUPPORTS_SHARING=1
	out=$(target clone -u)
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/upd_pkg"
	asserteq "$(readlink ${BB_TARGET_SRC_DIR}/upd_pkg)" "../../src/upd_pkg"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"
	assert "echo '${out}' | grep -q 'sharing fixed'"
	assert "ls ${BB_TRASH_DIR} | grep -q '^upd_pkg-'"

	# Sharing is what it means: the sources are updated once, for the
	# project and the target at the same time
	advance_update_remote upd_share
	target clone -u
	asserteq $? 0
	asserteq "$(cat ${BB_PROJECT_SRC_DIR}/upd_pkg/CONTENT)" "second"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "second"
}
bb_declare_test test_target_clone_update_shares_copied_sources

function test_target_clone_update_unshares_shared_sources {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_unshare)
	# 'autotools' supports sources sharing: the target holds a symlink
	declare_update_target upd_pkg "${bare}" master autotools updunshare
	bb_set_project_current_target updunshare
	asserteq $? 0
	target clone
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/upd_pkg"

	# The package declares its sources not shared: the target gets its own
	# copy, the project sources staying where they are
	declare_update_target upd_pkg "${bare}" master autotools updunshare SRC_SUPPORTS_SHARING=0
	out=$(target clone -u)
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/upd_pkg"
	assertnl "${BB_TARGET_SRC_DIR}/upd_pkg"
	assertd "${BB_PROJECT_SRC_DIR}/upd_pkg"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "first"
	assert "echo '${out}' | grep -q 'sharing fixed'"

	# The copy is now the target own sources: updating it leaves the project
	# sources where they were
	advance_update_remote upd_unshare
	target clone -u
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "second"
	asserteq "$(cat ${BB_PROJECT_SRC_DIR}/upd_pkg/CONTENT)" "first"
}
bb_declare_test test_target_clone_update_unshares_shared_sources

function test_target_clone_update_keeps_copy_holding_local_work {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_sharework)
	declare_update_target upd_pkg "${bare}" master custom updsharework
	bb_set_project_current_target updsharework
	asserteq $? 0
	target clone
	asserteq $? 0
	# A commit the project sources have never seen: sharing the sources
	# would discard it
	(
		cd "${BB_TARGET_SRC_DIR}/upd_pkg"
		git config user.email test@buildbox
		git config user.name BuildBox
		echo "local work" > CONTENT
		git commit -q -a -m "Local commit"
	)
	local_commit=$(git -C "${BB_TARGET_SRC_DIR}/upd_pkg" rev-parse HEAD)

	declare_update_target upd_pkg "${bare}" master custom updsharework SRC_SUPPORTS_SHARING=1
	out=$(target clone -u 2>&1)
	asserteq $? 0
	assertnl "${BB_TARGET_SRC_DIR}/upd_pkg"
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/upd_pkg/CONTENT)" "local work"
	asserteq "$(git -C ${BB_TARGET_SRC_DIR}/upd_pkg rev-parse HEAD)" "${local_commit}"
	assert "echo '${out}' | grep -q 'sharing kept'"
}
bb_declare_test test_target_clone_update_keeps_copy_holding_local_work

function test_target_clone_fetch_only_package_is_shared {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_fetchonly)
	# No build mode: sources are only fetched, and shared because the
	# package file says so
	declare_update_target upd_pkg "${bare}" master "" updfetchonly SRC_SUPPORTS_SHARING=1
	bb_set_project_current_target updfetchonly
	asserteq $? 0
	target clone
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/upd_pkg"
	asserteq "$(readlink ${BB_TARGET_SRC_DIR}/upd_pkg)" "../../src/upd_pkg"
}
bb_declare_test test_target_clone_fetch_only_package_is_shared

function test_target_clone_unknown_option {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target clone --nope 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_target_clone_unknown_option

# Declare a tool and a target requiring it in the current project profile
# @param Tool name
# @param Remote path
# @param Revision
# @param Target name
function declare_update_tool_target {
	printf 'SRC_PROTO=git\nSRC_URI=%s\nSRC_REVISION=%s\nSRC_BUILD=prebuilt\n' \
		"${2}" "${3}" > "${BB_PROJECT_PROFILE_DIR}/packages/${1}"
	printf '%s\n' "${1}" > "${BB_PROJECT_PROFILE_DIR}/tools.${4}"
	: > "${BB_PROJECT_PROFILE_DIR}/packages.${4}"
	printf 'CPU=x86\nPACKAGES=packages.%s\nTOOLS=tools.%s\n' "${4}" "${4}" \
		> "${BB_PROJECT_PROFILE_DIR}/target.${4}"
}

function test_target_clone_update_tool_branch {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_tool)
	declare_update_tool_target upd_tool_pkg "${bare}" master updtool
	bb_set_project_current_target updtool
	asserteq $? 0

	# Not cloned yet: '-u' installs the tool
	target clone -u
	asserteq $? 0
	assertd "${BB_TOOLS_DIR}/upd_tool_pkg"
	asserteq "$(cat ${BB_TOOLS_DIR}/upd_tool_pkg/CONTENT)" "first"

	# The branch moves: the tool follows
	advance_update_remote upd_tool
	out=$(target clone -u)
	asserteq $? 0
	asserteq "$(cat ${BB_TOOLS_DIR}/upd_tool_pkg/CONTENT)" "second"
	assert "echo '${out}' | grep -q 'updated'"
}
bb_declare_test test_target_clone_update_tool_branch

function test_target_clone_update_tool_without_option {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_tool_noopt)
	declare_update_tool_target upd_tool_pkg "${bare}" master updtoolnoopt
	bb_set_project_current_target updtoolnoopt
	asserteq $? 0
	target clone
	asserteq $? 0
	advance_update_remote upd_tool_noopt
	# Without '-u' an already installed tool is left as it is
	target clone
	asserteq $? 0
	asserteq "$(cat ${BB_TOOLS_DIR}/upd_tool_pkg/CONTENT)" "first"
}
bb_declare_test test_target_clone_update_tool_without_option

function test_target_clone_update_tool_keeps_local_work {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_update_remote upd_tool_local)
	declare_update_tool_target upd_tool_pkg "${bare}" master updtoollocal
	bb_set_project_current_target updtoollocal
	asserteq $? 0
	target clone -u
	asserteq $? 0
	echo "local work" > "${BB_TOOLS_DIR}/upd_tool_pkg/CONTENT"
	advance_update_remote upd_tool_local
	out=$(target clone -u)
	asserteq $? 0
	asserteq "$(cat ${BB_TOOLS_DIR}/upd_tool_pkg/CONTENT)" "local work"
	assert "echo '${out}' | grep -q 'kept'"
}
bb_declare_test test_target_clone_update_tool_keeps_local_work
