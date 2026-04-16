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

function sub_bb_error_nolog () (
	bb_error_nolog
)

function test_bb_error_nolog {
	error_msg=$(sub_bb_error_nolog 2>&1 > /dev/null)
	asserteq $? 1
	assertn "${error_msg}"
}
bb_declare_test test_bb_error_nolog
