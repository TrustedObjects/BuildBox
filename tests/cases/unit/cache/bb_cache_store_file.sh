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

function test_bb_cache_store_file {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	echo "File" > ${TMPDIR}/file
	bb_cache_store_file ${TMPDIR}/file
	asserteq $? 0
	digest=$(sha256sum ${TMPDIR}/file | cut -d ' ' -f 1)
	assertf ${BB_CACHE_DIR}/${digest}
}
bb_declare_test test_bb_cache_store_file

function test_bb_cache_store_file_not_a_file {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	mkdir ${TMPDIR}/dir
	bb_cache_store_file ${TMPDIR}/dir
	assertne $? 0
}
bb_declare_test test_bb_cache_store_file_not_a_file

function test_bb_cache_store_file_does_not_exist {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	bb_cache_store_file ${TMPDIR}/does_not_exist
	assertne $? 0
}
bb_declare_test test_bb_cache_store_file_does_not_exist
