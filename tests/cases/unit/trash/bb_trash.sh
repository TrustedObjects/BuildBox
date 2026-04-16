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

function test_bb_trash {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir "${BB_PROJECT_DIR}/testdir1"
	touch "${BB_PROJECT_DIR}/testdir1/file1"
	touch "${BB_PROJECT_DIR}/testdir1/file2"
	mkdir "${BB_PROJECT_DIR}/testdir2"
	trash_uuid=$(bb_trash "${BB_PROJECT_DIR}/testdir1")
	asserteq $? 0
	assertnd "${BB_PROJECT_DIR}/testdir1"
	assertd "${BB_PROJECT_DIR}/testdir2"
	assertd ${BB_TRASH_DIR}/${trash_uuid}
	assertf ${BB_TRASH_DIR}/${trash_uuid}/file1
	assertf ${BB_TRASH_DIR}/${trash_uuid}/file2
}
bb_declare_test test_bb_trash
