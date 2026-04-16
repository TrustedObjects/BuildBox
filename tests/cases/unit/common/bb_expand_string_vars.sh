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

function test_bb_expand_string_vars {
	var1="abc"
	var2=123
	str='var1=$var1 var2=$var2'
	result=$(bb_expand_string_vars "${str}")
	asserteq "${result}" "var1=abc var2=123"
}
bb_declare_test test_bb_expand_string_vars
