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

function test_bb_xdg_find_folder {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_clone_tool "subdir/bar_tool"
	asserteq $? 0
	bb_clone_tool baz_tool
	asserteq $? 0
	res1=$(bb_xdg_find_folder ressource1)
	asserteq $? 0
	echo "$res1"
	echo "$XDG_DATA_DIRS"
	assertd "${res1}"
	res2=$(bb_xdg_find_folder ressource2)
	asserteq $? 0
	assertd "${res2}"
	bb_is_subpath_of ${BB_TOOLS_DIR}/foo_tool "${res2}"
	asserteq $? 0
}
bb_declare_test test_bb_xdg_find_folder
