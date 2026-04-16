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

## @brief Host tools
## These tools are available to deal with BuildBox container host machine to
## make it execute some commands outside of BuildBox, and then get back results
## and output in BuildBox.
##
## This mechanism is prepared by BuildBox launcher, which create the following
## resources:
## - a pipe where BuildBox can write the command (and its arguments) to run on
## the host, `workspace/tmp/launcher-ID_send.pipe`,
## - a pipe where host command returned code is written,
## `workspace/tmp/launcher-ID_ret.pipe`,
## - and a filename is reserved to write command output,
## `workspace/tmp/launcher-ID_send.out`.
##
## The launcher ID is the launcher instance process ID, so each launcher can
## run host commands without conflict with other launchers instances.
##
## Some commands are also available, relying on these tools.

## @fn bb_path_to_host
## Convert a path to its host-side form, suitable for use in commands sent
## via bb_host_send.
## The container is bind-mounted at the same absolute path as on the host, so
## no translation is needed.
## @param Path (relative or absolute)
## @print Quoted absolute path for use in eval'd host commands
## @return 0 on success
function bb_path_to_host {
	local path=${1}
	path=$(/usr/bin/realpath ${path})
	if [ $? -ne 0 ]; then
		return 1
	fi
	echo "\"${path}\""
	return 0
}
bb_exportfn bb_path_to_host

## @fn bb_host_send
## Send command to host.
## The BuildBox launcher creates two pipes reserved for its instance: one to
## send commands to host, and the other to get return codes.
## @param The command to run, followed by command arguments.
## @return 0 on success, else the returned code
function bb_host_send {
	local ret=0
	local cmd=$@
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		>&2 echo "BuildBox is not running in a container"
		return 1
	fi
	local pipe=${BB_WORKDIR}/tmp/launcher-${BB_LAUNCHER_ID}_send.pipe
	if [ ! -p ${pipe} ]; then
		>&2 echo "Unable to send command to host: no pipe"
		return 1
	fi
	echo ${cmd} > ${pipe}
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to send command to host: pipe write error"
		return 1
	fi
	local ret_pipe=${BB_WORKDIR}/tmp/launcher-${BB_LAUNCHER_ID}_ret.pipe
	read -r ret < ${ret_pipe}
	return $ret
}
bb_exportfn bb_host_send

## @fn bb_host_send_print_out
## Print out last host command output, started with bb_host_send().
## The BuildBox launcher reserves an output file name for its instance, to
## store commands output. The output file is removed after printing.
## @param Optional printing command (default: cat)
## @print Last host command output.
function bb_host_send_print_out {
	local print_cmd="cat"
	if [ ! -z "${1}" ]; then
		print_cmd="${1}"
	fi
	local out_file=${BB_WORKDIR}/tmp/launcher-${BB_LAUNCHER_ID}_send.out
	${print_cmd} ${out_file}
	rm ${out_file}
}
bb_exportfn bb_host_send_print_out

##
## **Below are listed available host commands**
##

## @fn code
## VS-code host command.
function code {
	local ret=0
	local cmd="code"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	if [ $# -eq 0 ]; then
		cmd+=" $(bb_path_to_host $(pwd))" > /dev/null 2>&1
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		-d | --diff)
			cmd+=" ${1}"
			cmd+=" $(bb_path_to_host ${2})" || return 1
			cmd+=" $(bb_path_to_host ${3})" || return 1
			shift 3 > /dev/null
			;;
		-a | --add | -g | --goto)
			cmd+=" ${1}"
			cmd+=" $(bb_path_to_host ${2})" || return 1
			shift 2 > /dev/null
			;;
		-n | --new-window | -r | --reuse-window | -w | --wait | -v | -h | --help)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn meld
## Meld host command.
function meld {
	local ret=0
	local cmd="meld"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		--* | -*)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn gitk
## Gitk host command.
function gitk {
	local ret=0
	local cmd="gitk"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	if [ $# -eq 0 ]; then
		cmd="cd $(bb_path_to_host $(pwd)) && gitk" > /dev/null 2>&1
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		--* | -*)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn nautilus
## Nautilus host command (gnome files browser).
function nautilus {
	local ret=0
	local cmd="nautilus"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	if [ $# -eq 0 ]; then
		cmd+=" $(bb_path_to_host $(pwd))" > /dev/null 2>&1
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		-w | --new-window | -h | --help | --version)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	cmd+=" &"
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn evince
## Evince host command (gnome PDF reader).
function evince {
	local ret=0
	local cmd="evince"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		-*)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn gedit
## Gedit host command.
function gedit {
	local ret=0
	local cmd="gedit"
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return 0
	fi
	while [ $# -ne 0 ]; do
		case "${1}" in
		--* | -*)
			cmd+=" ${1}"
			shift > /dev/null
			;;
		*)
			cmd+=" $(bb_path_to_host ${1})" || return 1
			shift > /dev/null
			;;
		esac
	done
	bb_host_send ${cmd}
	ret=$?
	bb_host_send_print_out
	return $ret
}

## @fn man
## Man host command, to have man pages installed out of BuildBox.
## First of all, the requested man page is looked for in BuildBox, and if not
## found, it is looked for host side.
function bbman {
	local ret=0
	local cmd="man"
	if [ $# -gt 0 ]; then
		# Try to use local man first
		local message
		{ message=$(\man $@ 2>&1 >&3 3>&-); } 3>&1
		local ret=$?
		if [ $ret -eq 0 ]; then
			return 0
		elif [ $ret -ne 16 ]; then # 16 = page not found
			>&2 echo "${message}"
			return 1
		fi
	fi
	# Page not found (or no page requested): forward to host man
	if [ -z "${BB_LAUNCHER_ID}" ]; then
		# BuildBox is not running in a container, direct call
		${cmd} $@
		return $?
	fi
	cmd+=" -P cat"
	bb_host_send "${cmd} $@"
	ret=$?
	if [ $ret -eq 0 ]; then
		bb_host_send_print_out less
	else
		bb_host_send_print_out
	fi
	return $ret
}

