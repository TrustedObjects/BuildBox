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

function test_pkg_verbose {
	bb_use_test_project foo_project
	asserteq $? 0
	info="$(pkg -v bar_package)"
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	# check revision
	revision=$(echo "${info}" | grep "Revision:")
	asserteq $? 0
	asserteq "$(echo ${revision} | cut -d ':' -f 2)" "master"
	# check build mode
	build=$(echo "${info}" | grep "Buildmode:")
	asserteq $? 0
	asserteq "$(echo ${build} | cut -d ':' -f 2)" "autotools"
	# check path
	pkg_path=$(echo "${info}" | grep "Path:")
	asserteq $? 0
	asserteq "$(echo ${pkg_path} | cut -d ':' -f 2)" "${BB_PROJECT_PROFILE_DIR}/packages/bar_package"
}
bb_declare_test test_pkg_verbose

function test_pkg_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(pkg bar_package 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_pkg_no_err_log

function test_pkg_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(pkg unknown 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}" # check there is an error log
}
bb_declare_test test_pkg_unknown

