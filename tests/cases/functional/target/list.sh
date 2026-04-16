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

function test_target_list {
	bb_use_test_project foo_project
	asserteq $? 0
	list="$(target list)"
	asserteq $? 0
	count=$(echo "${list}" | wc -l)
	asserteq ${count} 2
	list="$(unformat_string "${list}")"
	list="$(minspace_string "${list}")"
	echo "${list}" | grep "^foo"
	asserteq $? 0
	echo "${list}" | grep "^bar"
	asserteq $? 0
}
bb_declare_test test_target_list

function test_target_list_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(target list 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_target_list_no_err_log

