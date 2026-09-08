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

function test_pkg_clone {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	clone bar_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	clone corge_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	clone quux_package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
	clone foo_http_package-1.0
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
}
bb_declare_test test_pkg_clone

function test_pkg_clone_partial_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_http_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_http_package-1.0"
	clone package
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/bar_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/bar_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/corge_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/corge_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package"
	assertl "${BB_TARGET_SRC_DIR}/subdir_quux_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/subdir_quux_package"
}
bb_declare_test test_pkg_clone_partial_filter

function test_pkg_clone_twice {
	bb_use_test_project foo_project
	asserteq $? 0
	assertnd ${BB_PROJECT_SRC_DIR}
	assertnd ${BB_TARGET_SRC_DIR}
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
	clone foo_package@1.0
	asserteq $? 0
	assertl "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	assertl "${BB_TARGET_SRC_DIR}/foo_package.sources"
	assertd "${BB_PROJECT_SRC_DIR}/foo_package@1.0"
}
bb_declare_test test_pkg_clone_twice

function test_pkg_clone_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clone unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clone_unknown

function test_pkg_clone_empty_filter {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clone 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_clone_empty_filter

function test_pkg_clone_project_not_set {
	out="$(clone bar_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_clone_project_not_set

## Tests for 'bbx fetch -u'. The remote lives in the test workspace, so the
## shared fixture repositories are never modified.

# Create a repository holding one commit, and its bare remote
# @param Remote name
# @print Bare remote path
function setup_fetch_remote {
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

# Add a commit on the master branch of a remote created above
# @param Remote name
function advance_fetch_remote {
	(
		cd "${BB_TEST_WORKSPACE}/${1}"
		echo "second" > CONTENT
		git commit -q -a -m "Second commit"
		git push -q origin master
	)
}

# Declare a package and a target using it in the current project profile
# @param Package name
# @param Remote path
# @param Target name
function declare_fetch_target {
	printf 'SRC_PROTO=git\nSRC_URI=%s\nSRC_REVISION=master\nSRC_BUILD=autotools\n' \
		"${2}" > "${BB_PROJECT_PROFILE_DIR}/packages/${1}"
	printf '%s\n' "${1}" > "${BB_PROJECT_PROFILE_DIR}/packages.${3}"
	printf 'CPU=x86\nPACKAGES=packages.%s\n' "${3}" \
		> "${BB_PROJECT_PROFILE_DIR}/target.${3}"
}

function test_pkg_fetch_update {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_fetch_remote fetch_upd)
	declare_fetch_target fetch_pkg "${bare}" fetchupd
	bb_set_project_current_target fetchupd
	asserteq $? 0

	# Not fetched yet: '-u' does a plain fetch
	clone -u fetch_pkg
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/fetch_pkg/CONTENT)" "first"

	# The branch moves: the sources follow
	advance_fetch_remote fetch_upd
	out=$(clone -u fetch_pkg)
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/fetch_pkg/CONTENT)" "second"
	assert "echo '${out}' | grep -q 'Updating'"
}
bb_declare_test test_pkg_fetch_update

function test_pkg_fetch_without_update_keeps_sources {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_fetch_remote fetch_noopt)
	declare_fetch_target fetch_pkg "${bare}" fetchnoopt
	bb_set_project_current_target fetchnoopt
	asserteq $? 0
	clone fetch_pkg
	asserteq $? 0
	advance_fetch_remote fetch_noopt
	# Without '-u' sources already there are left as they are
	clone fetch_pkg
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/fetch_pkg/CONTENT)" "first"
}
bb_declare_test test_pkg_fetch_without_update_keeps_sources

function test_pkg_fetch_update_keeps_local_work {
	bb_use_test_project foo_project
	asserteq $? 0
	bare=$(setup_fetch_remote fetch_local)
	declare_fetch_target fetch_pkg "${bare}" fetchlocal
	bb_set_project_current_target fetchlocal
	asserteq $? 0
	clone -u fetch_pkg
	asserteq $? 0
	echo "local work" > "${BB_TARGET_SRC_DIR}/fetch_pkg/CONTENT"
	advance_fetch_remote fetch_local
	clone -u fetch_pkg
	asserteq $? 0
	asserteq "$(cat ${BB_TARGET_SRC_DIR}/fetch_pkg/CONTENT)" "local work"
}
bb_declare_test test_pkg_fetch_update_keeps_local_work

function test_pkg_fetch_unknown_option {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(clone --nope foo_package 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_pkg_fetch_unknown_option
