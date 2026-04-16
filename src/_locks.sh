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

## @brief Locks
## Locks are used to control access to ressources or to synchronize processes.

## @fn bb_lock_acquire
## Acquire lock.
## Only one process can hold the lock at the same time.
## If the lock is already hold, block until released.
## @param Lock file path
## @param Optional waiting message
## @return 0 on success, else error
function bb_lock_acquire {
	local lock_file=${1}
	bb_lock_try_acquire ${lock_file}
	local ret=$?
	if [ $ret -eq 0 ]; then
		return 0
	elif [ $ret -eq -1 ]; then
		return $ret
	else
		local wait_message="${2}"
		if [ -n "${wait_message}" ]; then
			echo "${wait_message}"
		fi
	fi
	while [ $ret -ne 0 ]; do
		inotifywait -e delete_self "${lock_file}" > /dev/null 2>&1
		bb_lock_try_acquire ${lock_file}
		ret=$?
		if [ $ret -eq 2 ]; then
			return $ret
		fi
	done
	return 0
}
bb_exportfn bb_lock_acquire

## @fn bb_lock_try_acquire
## Try to acquire lock.
## Only one process can hold the lock at the same time.
## Returns immediately.
## A trap is configured to automatically release the lock on process end.
## @param Lock file path (must be located somewhere in BuildBox workspace
## directory)
## @return 0 on success, 1 if lock not acquired, 2 on error
function bb_lock_try_acquire {
	local lock_file=${1}
	if ! bb_is_subpath_of "${BB_PROJECT_DIR}" "${lock_file}"; then
		return 2
	fi
	mkdir -p $(dirname "${lock_file}") > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 2
	fi
	# mkdir is an unitary operation
	mkdir "${lock_file}" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		bb_add_exit_action "bb_lock_release ${lock_file}"
		return 0
	fi
	return 1
}
bb_exportfn bb_lock_try_acquire

## @fn bb_lock_release
## Release lock.
## @param Lock file path
## @return 0 on success
function bb_lock_release {
	local lock_file=${1}
	rm -rf "${lock_file}"
}
bb_exportfn bb_lock_release
