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

function bb_test1 {
	echo "test1"
}

function bb_test2 {
	echo "test2"
}

function test3 {
	echo "test3"
}

function test_bb_exportfn {
	bb_exportfn bb_test1
	asserteq $? 0
	bb_exportfn bb_test2
	asserteq $? 0
	bb_exportfn test3
	assertne $? 0
	bb_exportfn bb_test4
	assertne $? 0
}
bb_declare_test test_bb_exportfn

function test_exported_function_cant_change_cwd {
	bb_use_test_project foo_project
	asserteq $? 0
	cwd="$(pwd)"
	bb_project_get_tag "" 1
	asserteq $? 0
	asserteq "${cwd}" "$(pwd)"
	return 0
}
bb_declare_test test_exported_function_cant_change_cwd
