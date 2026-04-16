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

function test_target_tools {
	bb_use_test_project foo_project
	asserteq $? 0
	# list tools for target bar
	target set bar
	asserteq $? 0
	list="$(target tools)"
	asserteq $? 0
	echo "${list}" | grep "foo_tool@1.0.2"
	asserteq $? 0
	echo "${list}" | grep "bar_tool"
	asserteq $? 0
	echo "${list}" | grep "baz_tool"
	asserteq $? 0
}
bb_declare_test test_target_tools

function test_target_tools_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target tools 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_tools_no_err_log

