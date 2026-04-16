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

function test_bb_confirm {
	echo "y" | bb_confirm
	asserteq $? 1
	echo "Y" | bb_confirm
	asserteq $? 1
	echo "n" | bb_confirm
	asserteq $? 0
	echo "N" | bb_confirm
	asserteq $? 0
	echo "invalid" | bb_confirm
	asserteq $? 0
	prompt=$(echo "y" | bb_confirm "question ?")
	asserteq $? 1
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "Y" | bb_confirm "question ?")
	asserteq $? 1
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "n" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "N" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "invalid" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "

}
bb_declare_test test_bb_confirm
