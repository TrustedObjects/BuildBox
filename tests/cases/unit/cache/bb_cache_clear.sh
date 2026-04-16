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

function test_bb_cache_clear {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_CACHE_DIR}"
	echo "File1" > ${TMPDIR}/file1
	bb_cache_store_file ${TMPDIR}/file1
	asserteq $? 0
	echo "File2" > ${TMPDIR}/file2
	bb_cache_store_file ${TMPDIR}/file2
	asserteq $? 0
	cached_count=$(ls -1 ${BB_CACHE_DIR} | wc -l)
	asserteq ${cached_count} 2
	bb_cache_clear
	cached_count=$(ls -1 ${BB_CACHE_DIR} | wc -l)
	asserteq ${cached_count} 0
}
bb_declare_test test_bb_cache_clear
