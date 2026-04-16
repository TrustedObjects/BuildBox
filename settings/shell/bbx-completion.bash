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

#/usr/bin/env bash
## Host-side Bash completion for the bbx command.
## Source this file from your ~/.bashrc, or let bbx-prompt.sh source it
## automatically when it is placed in the same directory.

# Walk up from $PWD to find the nearest .bbx/ directory.
function __bbx_comp_project_root {
	local dir="${PWD}"
	while true; do
		[ -d "${dir}/.bbx" ] && echo "${dir}" && return 0
		[ "${dir}" = "/" ] && return 1
		dir="${dir%/*}"
		[ -z "${dir}" ] && dir="/"
	done
}

# List target names for the current project (reads target.* files in .bbx/).
function __bbx_comp_targets {
	local root f
	root="$(__bbx_comp_project_root)" || return
	for f in "${root}/.bbx/target."*; do
		[ -e "${f}" ] && printf '%s\n' "${f##*target.}"
	done
}

# List package names for the current project (reads .bbx/packages/).
function __bbx_comp_packages {
	local root f
	root="$(__bbx_comp_project_root)" || return
	[ -d "${root}/.bbx/packages" ] || return
	for f in "${root}/.bbx/packages/"*; do
		[ -f "${f}" ] && printf '%s\n' "${f##*/}"
	done
}

# Completion for: bbx target <subcmd> [args]
# Also used as the completion function for the bare 'target' command.
function _bbx_target_complete {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local cword="${COMP_CWORD}"
	# Offset: words[1] is the subcmd when bare ('target set'), words[2] when
	# prefixed ('bbx target set').
	local offset=1
	[ "${COMP_WORDS[0]}" = "bbx" ] && offset=2

	if [ "${cword}" -eq "${offset}" ]; then
		COMPREPLY=($(compgen -W \
			"help list set clone build fastbuild test dist dist-prebuilt clean mrproper pkg tools info goto" \
			-- "${cur}"))
	elif [ "${cword}" -gt "${offset}" ]; then
		case "${COMP_WORDS[${offset}]}" in
			set|info)
				COMPREPLY=($(compgen -W "$(__bbx_comp_targets)" -- "${cur}")) ;;
			build|fastbuild|test)
				COMPREPLY=($(compgen -W "--attach" -- "${cur}")) ;;
			pkg)
				COMPREPLY=($(compgen -W "-m -v" -- "${cur}")) ;;
		esac
	fi
}

# Completion for: bbx project <subcmd> [args]
# Also used as the completion function for the bare 'project' command.
function _bbx_project_complete {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local cword="${COMP_CWORD}"
	local offset=1
	[ "${COMP_WORDS[0]}" = "bbx" ] && offset=2

	if [ "${cword}" -eq "${offset}" ]; then
		COMPREPLY=($(compgen -W \
			"help init clone migrate update clean mrproper info goto" \
			-- "${cur}"))
	elif [ "${cword}" -gt "${offset}" ] && [ "${COMP_WORDS[${offset}]}" = "goto" ]; then
		COMPREPLY=($(compgen -W "-p" -- "${cur}"))
	fi
}

# Completion for: bbx pkg [<package>]
# Also used as the completion function for the bare 'pkg' alias.
function _bbx_pkg_complete {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=($(compgen -W "$(__bbx_comp_packages)" -- "${cur}"))
}

# Completion for: bbx goto <package> [-b]
# Also used as the completion function for the bare 'goto' command.
function _bbx_goto_complete {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local cword="${COMP_CWORD}"
	local offset=1
	[ "${COMP_WORDS[0]}" = "bbx" ] && offset=2

	if [ "${cword}" -eq "${offset}" ]; then
		COMPREPLY=($(compgen -W "$(__bbx_comp_packages)" -- "${cur}"))
	elif [ "${cword}" -gt "${offset}" ]; then
		COMPREPLY=($(compgen -W "-b" -- "${cur}"))
	fi
}

# Main completion function for the bbx command.
function _bbx_complete {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local cword="${COMP_CWORD}"

	if [ "${cword}" -eq 1 ]; then
		COMPREPLY=($(compgen -W \
			"init clone migrate stop image instance target project build fastbuild clean mrproper pkg goto fetch shell env tg pg pp help" \
			-- "${cur}"))
		return
	fi

	case "${COMP_WORDS[1]}" in
		target)    _bbx_target_complete ;;
		project)   _bbx_project_complete ;;
		pkg)       _bbx_pkg_complete ;;
		goto)      _bbx_goto_complete ;;
		image)
			if [ "${cword}" -eq 2 ]; then
				COMPREPLY=($(compgen -W "list fetch" -- "${cur}"))
			elif [ "${cword}" -gt 2 ] && [ "${COMP_WORDS[2]}" = "list" ]; then
				COMPREPLY=($(compgen -W "--all" -- "${cur}"))
			elif [ "${cword}" -gt 2 ] && [ "${COMP_WORDS[2]}" = "fetch" ]; then
				local tags
				tags=$(curl -sf \
					"https://hub.docker.com/v2/repositories/trustedobjects/buildbox/tags/?page_size=100" \
					| python3 -c "
import sys,json
[print(t['name']) for t in json.load(sys.stdin).get('results',[])]
" 2>/dev/null)
				COMPREPLY=($(compgen -W "${tags}" -- "${cur}"))
			fi
			;;
		instance)
			if [ "${cword}" -eq 2 ]; then
				COMPREPLY=($(compgen -W "list stop upgrade" -- "${cur}"))
			elif [ "${cword}" -gt 2 ] && [ "${COMP_WORDS[2]}" = "stop" ]; then
				local containers
				containers=$(docker ps \
					--filter "name=^${BBX_CONTAINER_PREFIX:-bbx}-" \
					--format "{{.Names}}" 2>/dev/null)
				COMPREPLY=($(compgen -W "--force ${containers}" -- "${cur}"))
			elif [ "${cword}" -gt 2 ] && [ "${COMP_WORDS[2]}" = "upgrade" ]; then
				local containers images
				containers=$(docker ps -a \
					--filter "name=^${BBX_CONTAINER_PREFIX:-bbx}-" \
					--format "{{.Names}}" 2>/dev/null)
				images=$(docker images buildbox \
					--format "{{.Repository}}:{{.Tag}}" 2>/dev/null)
				COMPREPLY=($(compgen -W "--image ${images} ${containers}" -- "${cur}"))
			fi
			;;
	esac
}

complete -F _bbx_complete bbx
