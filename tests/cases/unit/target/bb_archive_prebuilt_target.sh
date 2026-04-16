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

function test_bb_archive_prebuilt_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_build_package "foo_package@1.0"
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	asserteq $? 0
	assertd "${archive}"
}
bb_declare_test test_bb_archive_prebuilt_target

function test_bb_archive_prebuilt_target_not_built {
	bb_use_test_project foo_project bar
	asserteq $? 0
	archive=$(bb_archive_prebuilt_target)
	assertne $? 0
}
bb_declare_test test_bb_archive_prebuilt_target_not_built
