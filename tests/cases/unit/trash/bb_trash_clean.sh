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

function test_bb_trash_clean {
	bb_use_test_project foo_project
	asserteq $? 0
	BB_TRASH_KEEP_DAYS=10
	# Create some files and directories
	mkdir "${BB_PROJECT_DIR}/testdir1"
	touch "${BB_PROJECT_DIR}/testdir1/file1"
	touch "${BB_PROJECT_DIR}/testdir1/file2"
	mkdir "${BB_PROJECT_DIR}/testdir2"
	mkdir "${BB_PROJECT_DIR}/testdir3"
	touch "${BB_PROJECT_DIR}/testfile4"
	touch "${BB_PROJECT_DIR}/testfile5"
	touch "${BB_PROJECT_DIR}/testfile6"
	# Remove them
	trash_uuid1=$(bb_trash "${BB_PROJECT_DIR}/testdir1")
	asserteq $? 0
	trash_uuid2=$(bb_trash "${BB_PROJECT_DIR}/testdir2")
	asserteq $? 0
	trash_uuid3=$(bb_trash "${BB_PROJECT_DIR}/testdir3")
	asserteq $? 0
	trash_uuid4=$(bb_trash "${BB_PROJECT_DIR}/testfile4")
	asserteq $? 0
	trash_uuid5=$(bb_trash "${BB_PROJECT_DIR}/testfile5")
	asserteq $? 0
	trash_uuid6=$(bb_trash "${BB_PROJECT_DIR}/testfile6")
	asserteq $? 0
	# Check removed, and in trash
	assertnd "${BB_PROJECT_DIR}/testdir1"
	assertnd "${BB_PROJECT_DIR}/testdir2"
	assertnd "${BB_PROJECT_DIR}/testdir3"
	assertnf "${BB_PROJECT_DIR}/testfile4"
	assertnf "${BB_PROJECT_DIR}/testfile5"
	assertnf "${BB_PROJECT_DIR}/testfile6"
	assertd ${BB_TRASH_DIR}/${trash_uuid1}
	assertd ${BB_TRASH_DIR}/${trash_uuid2}
	assertd ${BB_TRASH_DIR}/${trash_uuid3}
	assertf ${BB_TRASH_DIR}/${trash_uuid4}
	assertf ${BB_TRASH_DIR}/${trash_uuid5}
	assertf ${BB_TRASH_DIR}/${trash_uuid6}
	# Change some dates
	touch -d "9 days ago" ${BB_TRASH_DIR}/${trash_uuid1}
	touch -d "10 days ago" ${BB_TRASH_DIR}/${trash_uuid2}
	touch -d "11 days ago" ${BB_TRASH_DIR}/${trash_uuid3}
	touch -d "100 days ago" ${BB_TRASH_DIR}/${trash_uuid6}
	# Clean trash, and check remaining files
	bb_trash_clean
	asserteq $? 0
	assertd ${BB_TRASH_DIR}/${trash_uuid1}
	assertd ${BB_TRASH_DIR}/${trash_uuid2}
	assertnd ${BB_TRASH_DIR}/${trash_uuid3}
	assertf ${BB_TRASH_DIR}/${trash_uuid4}
	assertf ${BB_TRASH_DIR}/${trash_uuid5}
	assertnf ${BB_TRASH_DIR}/${trash_uuid6}
}
bb_declare_test test_bb_trash_clean
