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

function test_bb_lock_try_acquire {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_try_acquire "${lock}"
	asserteq $? 0
	assertd "${lock}"
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_try_acquire

function test_bb_lock_try_acquire_already_hold {
	bb_use_test_project foo_project
	asserteq $? 0
	lock="${BB_PROJECT_DIR}/tmp/lock"
	bb_lock_acquire "${lock}"
	asserteq $? 0
	assertd "${lock}"
	bb_lock_try_acquire "${lock}"
	asserteq $? 1
	bb_lock_release "${lock}"
	asserteq $? 0
	assertnd "${lock}"
}
bb_declare_test test_bb_lock_try_acquire_already_hold

function test_bb_lock_try_acquire_error {
	bb_use_test_project foo_project
	asserteq $? 0
	mkdir -p "${BB_PROJECT_DIR}/tmp"
	lock="${BB_PROJECT_DIR}/tmp/file/lock"
	touch "${BB_PROJECT_DIR}/tmp/file"
	bb_lock_try_acquire "${lock}"
	asserteq $? 2 # lock parent directory is a file
}
bb_declare_test test_bb_lock_try_acquire_error

