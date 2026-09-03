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
## A lock is a symbolic link whose target is `<PID>:<SCOPE>`, the process holding
## it and the scope this PID belongs to. Creating a symbolic link is an unitary
## operation, and it carries the owner without any further write, so taking a
## lock can not race.
##
## No file descriptor is involved: a lock is never inherited by a child process,
## and nothing started during a build can keep it alive.
##
## A lock whose owner process is gone is stale: it is taken over by the next
## process asking for it, so a killed process leaves no lock behind.

# Scope a PID is unique in: the PID namespace of the caller, and the boot of the
# running kernel. A lock lives in the project directory, which outlives both, so
# it may hold a PID belonging to another scope, where that number designates
# nothing. Recording the scope is what tells a live owner from a PID which has
# been recycled since, typically after the project container was restarted.
# When neither value can be read, every process reads the same empty scope, so
# locks keep working, with the PID alone as before.
# @print Scope identifier of the calling process
function bb_lock_owner_scope {
	local ns=$(readlink /proc/self/ns/pid 2>/dev/null)
	# 'pid:[4026531836]' gives '4026531836'
	ns="${ns##*\[}"
	ns="${ns%%]*}"
	local boot=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)
	printf '%s.%s' "${ns}" "${boot//-/}"
}
bb_exportfn bb_lock_owner_scope

# Tell whether a lock is stale, which means present but not usable as it is: its
# owner process is gone, its owner belongs to another scope, or it was left by a
# BuildBox version using another lock format (a directory up to 2.0.2, a file or
# a bare PID in 2.1.0).
# @param Lock file path
# @return 0 if the lock is stale, 1 if it is held or absent
function bb_lock_is_stale {
	local lock_file="${1}"
	if [ ! -L "${lock_file}" ]; then
		# Not a symbolic link: absent, or left by another BuildBox version
		if [ -e "${lock_file}" ]; then
			return 0
		fi
		return 1
	fi
	local owner=$(readlink "${lock_file}" 2>/dev/null)
	local owner_pid="${owner%%:*}"
	local owner_scope="${owner#*:}"
	# No scope in the target: left by a BuildBox version recording the PID alone
	if [ "${owner_scope}" = "${owner}" ]; then
		return 0
	fi
	case "${owner_pid}" in
		''|*[!0-9]*)
			return 0
			;;
	esac
	# The PID only designates its owner inside the scope it was taken in: the
	# same number in another scope is another process, so the owner is gone
	if [ "${owner_scope}" != "$(bb_lock_owner_scope)" ]; then
		return 0
	fi
	if [ -d "/proc/${owner_pid}" ]; then
		return 1
	fi
	return 0
}
bb_exportfn bb_lock_is_stale

## @fn bb_lock_acquire
## Acquire lock.
## Only one process can hold the lock at the same time.
## If the lock is already hold, block until released, or until the process
## holding it is gone.
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
	while [ ${ret} -ne 0 ]; do
		sleep 1
		bb_lock_try_acquire ${lock_file}
		ret=$?
		if [ ${ret} -eq 2 ]; then
			return ${ret}
		fi
	done
	return 0
}
bb_exportfn bb_lock_acquire

## @fn bb_lock_try_acquire
## Try to acquire lock.
## Only one process can hold the lock at the same time.
## Returns immediately.
## A stale lock, whose owner process is gone, is taken over.
## An exit action is configured to release the lock when the process ends.
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
	local owner="$$:$(bb_lock_owner_scope)"
	# Creating a symbolic link is an unitary operation. -T makes it fail rather
	# than create the link inside a leftover lock directory
	if ln -s -T "${owner}" "${lock_file}" > /dev/null 2>&1; then
		bb_add_exit_action "bb_lock_release ${lock_file}"
		return 0
	fi
	if bb_lock_is_stale "${lock_file}"; then
		rm -rf "${lock_file}" > /dev/null 2>&1
		if ln -s -T "${owner}" "${lock_file}" > /dev/null 2>&1; then
			bb_add_exit_action "bb_lock_release ${lock_file}"
			return 0
		fi
	fi
	return 1
}
bb_exportfn bb_lock_try_acquire

## @fn bb_lock_release
## Release lock.
## Only the process holding the lock releases it: releasing a lock held by
## another process does nothing, such a lock is taken over once its owner is
## gone.
## @param Lock file path
## @return 0 on success
function bb_lock_release {
	local lock_file=${1}
	local owner=$(readlink "${lock_file}" 2>/dev/null)
	if [ -n "${owner}" ] && [[ "${owner}" != "$$:$(bb_lock_owner_scope)" ]]; then
		return 0
	fi
	rm -rf "${lock_file}" > /dev/null 2>&1
	return 0
}
bb_exportfn bb_lock_release

## @fn bb_lock_is_held
## Tell whether a lock is currently held, by any process.
## A stale lock is not held: it is taken over by the next process asking for it.
## @param Lock file path
## @return 0 if the lock is held, else 1
function bb_lock_is_held {
	local lock_file=${1}
	if [ ! -L "${lock_file}" ]; then
		return 1
	fi
	if bb_lock_is_stale "${lock_file}"; then
		return 1
	fi
	return 0
}
bb_exportfn bb_lock_is_held
