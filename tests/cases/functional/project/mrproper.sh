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

function test_project_mrproper {
	bb_use_test_project foo_project
	asserteq $? 0
	# build foo and bar targets and ensure built files are present
	target set foo
	asserteq $? 0
	target build
	asserteq $? 0
	target set bar
	asserteq $? 0
	assertnf ${TMPDIR}/foo_test_tool_data
	target build
	asserteq $? 0
	${BB_TOOLS_DIR}/foo_tool@1.0.2/bin/foo_test_tool_create_data
	assertf ${TMPDIR}/foo_test_tool_data
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/foo/src/bar_package.build
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
	assertd ${BB_PROJECT_DIR}/bar/src/bar_package.build
	# mrproper and check sources and built files are removed
	echo "y" | bbx project mrproper
	asserteq $? 0
	assertnd ${BB_PROJECT_DIR}/foo
	assertnd ${BB_PROJECT_DIR}/bar
	assertnd ${BB_PROJECT_DIR}/src
	assertnf ${TMPDIR}/foo_test_tool_data
}
bb_declare_test test_project_mrproper

function test_project_mrproper_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(echo "y" | bbx project mrproper 2>&1 >/dev/null)
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_project_mrproper_no_err_log

function test_project_mrproper_project_not_set {
	out="$(echo "y" | bbx project mrproper 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_mrproper_project_not_set
