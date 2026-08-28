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
##
## Locks rely on `flock` (from util-linux): a lock is held on a file descriptor
## opened on the lock file, and the kernel releases it as soon as every
## descriptor referring to it is closed. Consequences:
## - a lock is always released when the holding process ends, even if it is
## killed, so no stale lock can be left behind,
## - waiting for a lock costs nothing, the kernel wakes the waiting process up,
## - the lock file is only a support for the lock, it is never removed: its
## presence does not mean the lock is held,
## - a lock belongs to the process which acquired it, a process can not release
## a lock held by another one.

# Locks held by the current process, one "<fd> <lock file path>" entry per line
_BB_LOCKS=""

# A lock file descriptor is inherited by child processes, and the lock is
# released only once every inherited descriptor is closed. So, when BuildBox is
# entered by a child process, close the descriptors inherited from the parent:
# the parent keeps its own lock, and a process spawned by the child (a daemon
# started by a tool load script for example) can not keep the lock alive after
# the parent ended.
_bb_lock_inherited_fds="${BB_LOCK_HELD_FDS}"
while [ -n "${_bb_lock_inherited_fds}" ]; do
	_bb_lock_inherited_fd="${_bb_lock_inherited_fds%% *}"
	case "${_bb_lock_inherited_fds}" in
		*' '*) _bb_lock_inherited_fds="${_bb_lock_inherited_fds#* }" ;;
		*) _bb_lock_inherited_fds="" ;;
	esac
	case "${_bb_lock_inherited_fd}" in
		''|*[!0-9]*) continue ;;
	esac
	{ exec {_bb_lock_inherited_fd}>&-; } 2>/dev/null
done
unset _bb_lock_inherited_fds _bb_lock_inherited_fd
unset BB_LOCK_HELD_FDS

# Get the file descriptor holding a lock in the current process.
# @param Lock file path
# @print File descriptor number, nothing if the lock is not held here
# @return 0 if the lock is held by the current process
function bb_lock_get_fd {
	local lock_file="${1}"
	local entry=""
	while IFS= read -r entry; do
		if [ -n "${entry}" ] && [[ "${entry#* }" == "${lock_file}" ]]; then
			echo "${entry%% *}"
			return 0
		fi
	done < <(echo "${_BB_LOCKS}")
	return 1
}
bb_exportfn bb_lock_get_fd

# Export the descriptors of the locks held by the current process, so that
# BuildBox child processes close them (see the top of this file).
function bb_lock_export_fds {
	local fds=""
	local entry=""
	while IFS= read -r entry; do
		if [ -n "${entry}" ]; then
			fds="${fds}${entry%% *} "
		fi
	done < <(echo "${_BB_LOCKS}")
	export BB_LOCK_HELD_FDS="${fds% }"
}
bb_exportfn bb_lock_export_fds

# Record a lock acquired by the current process, and configure its automatic
# release on process end.
# @param Lock file path
# @param File descriptor holding the lock
function bb_lock_record {
	local lock_file="${1}"
	local fd="${2}"
	_BB_LOCKS="${_BB_LOCKS}${fd} ${lock_file}"$'\n'
	bb_lock_export_fds
	bb_add_exit_action "bb_lock_release ${lock_file}"
}
bb_exportfn bb_lock_record

# Forget a lock released by the current process.
# @param Lock file path
function bb_lock_forget {
	local lock_file="${1}"
	local remaining=""
	local entry=""
	while IFS= read -r entry; do
		if [ -n "${entry}" ] && [[ "${entry#* }" != "${lock_file}" ]]; then
			remaining="${remaining}${entry}"$'\n'
		fi
	done < <(echo "${_BB_LOCKS}")
	_BB_LOCKS="${remaining}"
	bb_lock_export_fds
}
bb_exportfn bb_lock_forget

# Open a lock file, without acquiring the lock.
# The allocated file descriptor is returned in `bb_lock_opened_fd`, as a
# function can not print it without running in a subshell (where the descriptor
# would be lost).
# @param Lock file path
# @return 0 on success, 2 if the lock file can not be opened
bb_lock_opened_fd=""
function bb_lock_open {
	local lock_file="${1}"
	local fd=""
	bb_lock_opened_fd=""
	mkdir -p "$(dirname "${lock_file}")" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 2
	fi
	# BuildBox up to 2.0.2 used a directory as lock: remove such a leftover
	# (rmdir only succeeds on an empty directory, which is what these locks
	# were)
	if [ -d "${lock_file}" ]; then
		rmdir "${lock_file}" > /dev/null 2>&1
	fi
	{ exec {fd}>>"${lock_file}"; } 2>/dev/null
	if [ $? -ne 0 ] || [ -z "${fd}" ]; then
		return 2
	fi
	bb_lock_opened_fd="${fd}"
	return 0
}
bb_exportfn bb_lock_open

## @fn bb_lock_close_redirections
## Print shell redirections closing every lock held by the current process.
##
## A lock file descriptor is inherited by child processes, and the lock is
## released only once every inherited descriptor is closed. BuildBox child
## processes close them by themselves, but any other command which may start a
## long living process (a tool load script starting a daemon for example) has to
## be run with these redirections, else the started process would keep the lock
## alive after the current process ended.
##
## Redirections must be applied to a simple command, which restores the locks
## once the command is done:
## ```
## eval "source script.sh $(bb_lock_close_redirections)"
## ```
## Descriptors are effectively hidden from the started processes when the current
## shell is bash. ZSH keeps an internal duplicate of the redirected descriptors
## while the command runs, so a process started by the command may still inherit
## the locks: BuildBox commands are bash scripts, which is where locks are
## acquired.
## @print Redirections, for example `11>&- 12>&-`, nothing if the current
## process holds no lock
## @return 0 on success
function bb_lock_close_redirections {
	local redirections=""
	local entry=""
	while IFS= read -r entry; do
		if [ -n "${entry}" ]; then
			redirections="${redirections}${entry%% *}>&- "
		fi
	done < <(echo "${_BB_LOCKS}")
	echo "${redirections% }"
	return 0
}
bb_exportfn bb_lock_close_redirections

## @fn bb_lock_acquire
## Acquire lock.
## Only one process can hold the lock at the same time.
## If the lock is already hold, block until released.
## The wait is handled by the kernel: the lock is granted as soon as the holding
## process releases it or ends.
## @param Lock file path (must be located somewhere in the project directory)
## @param Optional waiting message
## @return 0 on success, else error
function bb_lock_acquire {
	local lock_file=${1}
	bb_lock_try_acquire ${lock_file}
	local ret=$?
	if [ ${ret} -eq 0 ]; then
		return 0
	elif [ ${ret} -ne 1 ]; then
		return ${ret}
	fi
	local wait_message="${2}"
	if [ -n "${wait_message}" ]; then
		echo "${wait_message}"
	fi
	bb_lock_open "${lock_file}"
	if [ $? -ne 0 ]; then
		return 2
	fi
	local fd="${bb_lock_opened_fd}"
	if ! flock "${fd}" 2>/dev/null; then
		exec {fd}>&-
		return 2
	fi
	bb_lock_record "${lock_file}" "${fd}"
	return 0
}
bb_exportfn bb_lock_acquire

## @fn bb_lock_try_acquire
## Try to acquire lock.
## Only one process can hold the lock at the same time.
## Returns immediately.
## The lock is automatically released on process end, an exit action is also
## configured to release it as soon as the current process ends normally.
## @param Lock file path (must be located somewhere in BuildBox workspace
## directory)
## @return 0 on success, 1 if lock not acquired, 2 on error
function bb_lock_try_acquire {
	local lock_file=${1}
	if ! bb_is_subpath_of "${BB_PROJECT_DIR}" "${lock_file}"; then
		return 2
	fi
	bb_lock_open "${lock_file}"
	if [ $? -ne 0 ]; then
		return 2
	fi
	local fd="${bb_lock_opened_fd}"
	# flock is an unitary operation
	if flock -n "${fd}" 2>/dev/null; then
		bb_lock_record "${lock_file}" "${fd}"
		return 0
	fi
	exec {fd}>&-
	return 1
}
bb_exportfn bb_lock_try_acquire

## @fn bb_lock_release
## Release lock.
## Only a lock held by the current process can be released, releasing any other
## lock does nothing.
## @param Lock file path
## @return 0 on success
function bb_lock_release {
	local lock_file=${1}
	local fd=""
	fd=$(bb_lock_get_fd "${lock_file}")
	if [ -z "${fd}" ]; then
		return 0
	fi
	exec {fd}>&-
	bb_lock_forget "${lock_file}"
	return 0
}
bb_exportfn bb_lock_release

## @fn bb_lock_is_held
## Tell whether a lock is currently held, by any process.
## @param Lock file path
## @return 0 if the lock is held, else 1
function bb_lock_is_held {
	local lock_file=${1}
	if [ ! -e "${lock_file}" ]; then
		return 1
	fi
	if [ -n "$(bb_lock_get_fd ${lock_file})" ]; then
		return 0
	fi
	# Exit code 3 means the lock could not be acquired, so it is held
	flock -n -E 3 "${lock_file}" true > /dev/null 2>&1
	if [ $? -eq 3 ]; then
		return 0
	fi
	return 1
}
bb_exportfn bb_lock_is_held
