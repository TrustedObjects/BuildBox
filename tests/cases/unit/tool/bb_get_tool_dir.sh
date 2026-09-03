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

function test_bb_get_tool_dir {
	# No revision
	asserteq "$(bb_get_tool_dir foo_tool)" "foo_tool"
	# Revision after '@', and after a dash followed by a digit
	asserteq "$(bb_get_tool_dir foo_tool@1.0.2)" "foo_tool@1.0.2"
	asserteq "$(bb_get_tool_dir foo_tool-1.0.2)" "foo_tool-1.0.2"
	asserteq "$(bb_get_tool_dir foo_tool@master)" "foo_tool@master"
	# A path prefix locates the tool package file, it is not part of the
	# tool directory name
	asserteq "$(bb_get_tool_dir subdir/bar_tool)" "bar_tool"
	asserteq "$(bb_get_tool_dir subdir/bar_tool@1.0.2)" "bar_tool@1.0.2"
	# A revision holding '/' is escaped, so that the tool stays in a single
	# directory
	asserteq "$(bb_get_tool_dir foo_tool@branch/with/slashes)" "foo_tool@branch_with_slashes"
	asserteq "$(bb_get_tool_dir subdir/bar_tool@branch/with/slashes)" "bar_tool@branch_with_slashes"
}
bb_declare_test test_bb_get_tool_dir
