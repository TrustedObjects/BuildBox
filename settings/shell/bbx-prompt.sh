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

## BuildBox shell prompt plugin
## Source this file from your ~/.bashrc or ~/.zshrc to display the current
## BuildBox project target in your prompt.
##
## The prompt segment appears at the leftmost position when you are inside a
## BuildBox project directory and disappears when you leave.
##   ● BuildBox:target   (● green = container running, red = stopped)
##
## The following commands become available without the 'bbx' prefix when
## entering a BuildBox project directory, and are removed on exit:
##
##   bbx subcommand aliases:
##     fetch  build  fastbuild  clean  mrproper  pkg  shell
##     target <subcmd>    project <subcmd>
##
##   goto commands (host-side cd) — work with or without 'bbx' prefix:
##     goto <pkg> [-b]         go to package source dir (or build dir with -b)
##     target goto / tg        go to current target directory
##     project goto / pg       go to project root directory
##     project goto -p / pp    go to project .bbx profile directory
##
##   short aliases:
##     tb   target build        tg   target goto
##     tfb  target fastbuild    pg   project goto
##     ts   target set          pp   project goto -p
##
## 'env' is intentionally excluded as it conflicts with the system command.
## Existing aliases and functions with the same name are never overridden.
##
## To disable, set BBX_PROMPT_ENABLED=0 in ~/.config/buildbox/config
## (or $XDG_CONFIG_HOME/buildbox/config).

# Idempotency guard, safe to source multiple times
[ -n "${_BBX_PROMPT_LOADED}" ] && return 0
_BBX_PROMPT_LOADED=1

# Bash completion: source bbx-completion.bash (lives alongside this plugin).
if [ -n "${BASH_VERSION}" ]; then
	_bbx_plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
	[ -f "${_bbx_plugin_dir}/bbx-completion.bash" ] && \
		source "${_bbx_plugin_dir}/bbx-completion.bash"
	unset _bbx_plugin_dir
fi

# ZSH completion: source bbx-completion.zsh (lives alongside this plugin).
if [ -n "${ZSH_VERSION}" ]; then
	_bbx_plugin_dir="${${(%):-%x}:A:h}"
	if [[ -f "${_bbx_plugin_dir}/bbx-completion.zsh" ]]; then
		# Source directly so all helper functions (_bbx_target, _bbx_project, …)
		# are defined immediately — not deferred to the first TAB press.
		source "${_bbx_plugin_dir}/bbx-completion.zsh"
		# compdef is only available after compinit; skip silently if not yet ready.
		(( ${+functions[compdef]} )) && compdef _bbx bbx
	fi
	unset _bbx_plugin_dir
fi

# Defaults (overridable via user config)
BBX_PROMPT_ENABLED=1

# Load user config if present
_bbx_config="${XDG_CONFIG_HOME:-${HOME}/.config}/buildbox/config"
[ -f "${_bbx_config}" ] && source "${_bbx_config}"
unset _bbx_config

# BBX subcommands exposed as simple bbx-delegation aliases inside a project.
# 'target' and 'project' are excluded here: they are defined as functions
# below to intercept the 'goto' subcommand on the host side.
_BBX_SUBCMDS=(fetch build fastbuild clean mrproper pkg shell)
__BBX_PREV_ROOT=""
__BBX_DEFINED_SUBCMDS=()
__BBX_DEFINED_FUNCS=()

# Walk up from $PWD to find the nearest .bbx/ directory.
# Prints the project root and returns 0 if found, returns 1 otherwise.
function __bbx_find_project_root {
	local dir="${PWD}"
	while true; do
		[ -d "${dir}/.bbx" ] && echo "${dir}" && return 0
		[ "${dir}" = "/" ] && return 1
		dir="${dir%/*}"
		[ -z "${dir}" ] && dir="/"
	done
}

# Go to the current target directory (host-side cd).
function __bbx_target_goto {
	local root
	root="$(__bbx_find_project_root)" || { >&2 echo "Not in a BuildBox project directory"; return 1; }
	local target
	target="$(cat "${root}/.bbx/.state" 2>/dev/null)"
	if [ -z "${target}" ]; then
		>&2 echo "No current target defined"
		return 1
	fi
	local target_dir="${root}/${target}"
	if [ ! -d "${target_dir}" ]; then
		>&2 echo "Target ${target} not created yet"
		return 1
	fi
	cd "${target_dir}"
}

# Go to the project root (or with -p: the .bbx profile directory) (host-side cd).
function __bbx_project_goto {
	local root
	root="$(__bbx_find_project_root)" || { >&2 echo "Not in a BuildBox project directory"; return 1; }
	if [ "${1}" = "-p" ]; then
		cd "${root}/.bbx"
	else
		cd "${root}"
	fi
}

# Go to a package source or build directory (host-side cd).
# Delegates path resolution to the container-side 'goto' command.
function __bbx_pkg_goto {
	local dir
	dir="$(command bbx goto "$@")" || return 1
	dir="${dir%$'\r'}"   # strip \r from docker exec TTY output
	[ -n "${dir}" ] && cd "${dir}"
}

# Define aliases and functions for all bbx shortcut commands.
# Skips any name that is already aliased or defined as a function.
function __bbx_define_subcmds {
	local cmd

	# Simple bbx-delegation aliases
	for cmd in "${_BBX_SUBCMDS[@]}"; do
		if ! alias "${cmd}" > /dev/null 2>&1; then
			alias "${cmd}"="bbx ${cmd}"
			__BBX_DEFINED_SUBCMDS+=("${cmd}")
		fi
	done

	# Short aliases
	if ! alias tfb > /dev/null 2>&1; then
		alias tfb="bbx target fastbuild"
		__BBX_DEFINED_SUBCMDS+=(tfb)
	fi
	if ! alias tb > /dev/null 2>&1; then
		alias tb="bbx target build"
		__BBX_DEFINED_SUBCMDS+=(tb)
	fi
	if ! alias ts > /dev/null 2>&1; then
		alias ts="bbx target set"
		__BBX_DEFINED_SUBCMDS+=(ts)
	fi

	# 'target': intercept 'goto', delegate everything else to bbx
	if ! alias target > /dev/null 2>&1 && ! typeset -f target > /dev/null 2>&1; then
		function target {
			if [ "${1}" = "goto" ]; then __bbx_target_goto
			else bbx target "$@"; fi
		}
		__BBX_DEFINED_FUNCS+=(target)
	fi

	# 'project': intercept 'goto', delegate everything else to bbx
	if ! alias project > /dev/null 2>&1 && ! typeset -f project > /dev/null 2>&1; then
		function project {
			if [ "${1}" = "goto" ]; then __bbx_project_goto "${2}"
			else bbx project "$@"; fi
		}
		__BBX_DEFINED_FUNCS+=(project)
	fi

	# 'goto': package source/build directory navigation
	if ! alias goto > /dev/null 2>&1 && ! typeset -f goto > /dev/null 2>&1; then
		function goto { __bbx_pkg_goto "$@"; }
		__BBX_DEFINED_FUNCS+=(goto)
	fi

	# Short goto aliases
	if ! alias tg > /dev/null 2>&1 && ! typeset -f tg > /dev/null 2>&1; then
		function tg { __bbx_target_goto; }
		__BBX_DEFINED_FUNCS+=(tg)
	fi
	if ! alias pg > /dev/null 2>&1 && ! typeset -f pg > /dev/null 2>&1; then
		function pg { __bbx_project_goto; }
		__BBX_DEFINED_FUNCS+=(pg)
	fi
	if ! alias pp > /dev/null 2>&1 && ! typeset -f pp > /dev/null 2>&1; then
		function pp { __bbx_project_goto -p; }
		__BBX_DEFINED_FUNCS+=(pp)
	fi

	# Bash completion: bind completions to the bare command functions/aliases.
	# The _bbx_*_complete functions are defined in bbx-completion.bash.
	if [ -n "${BASH_VERSION}" ]; then
		declare -f _bbx_target_complete  > /dev/null && complete -F _bbx_target_complete  target
		declare -f _bbx_project_complete > /dev/null && complete -F _bbx_project_complete project
		declare -f _bbx_goto_complete    > /dev/null && complete -F _bbx_goto_complete    goto
		declare -f _bbx_pkg_complete     > /dev/null && complete -F _bbx_pkg_complete     pkg
	fi

	# ZSH completion: bind host-side completions to the bare functions defined above.
	# _bbx_target, _bbx_project, _bbx_goto are defined in the _bbx completion file.
	if [ -n "${ZSH_VERSION}" ] && (( ${+functions[compdef]} )); then
		(( ${+functions[_bbx_target]} ))  && compdef _bbx_target  target
		(( ${+functions[_bbx_project]} )) && compdef _bbx_project project
		(( ${+functions[_bbx_goto]} ))    && compdef _bbx_goto    goto
		(( ${+functions[_bbx_pkg]} ))     && compdef _bbx_pkg     pkg
	fi
}

# Remove all aliases and functions created by __bbx_define_subcmds.
function __bbx_undefine_subcmds {
	local cmd
	for cmd in "${__BBX_DEFINED_SUBCMDS[@]}"; do
		unalias "${cmd}" 2>/dev/null
	done
	__BBX_DEFINED_SUBCMDS=()
	for cmd in "${__BBX_DEFINED_FUNCS[@]}"; do
		unset -f "${cmd}" 2>/dev/null
	done
	__BBX_DEFINED_FUNCS=()
	# Bash: remove per-project completion bindings for bare command functions.
	if [ -n "${BASH_VERSION}" ]; then
		complete -r target project goto pkg 2>/dev/null
	fi
	# ZSH: remove per-project completion bindings for bare command functions.
	if [ -n "${ZSH_VERSION}" ] && (( ${+functions[compdef]} )); then
		compdef -d target project goto pkg 2>/dev/null
	fi
}

# Wrap the 'bbx' binary to intercept goto subcommands so they can cd in the
# current shell. All other subcommands are delegated to the real binary via
# 'command bbx'. Active globally (not just inside a project): the helpers
# already emit a proper error when called outside a project.
if ! typeset -f bbx > /dev/null 2>&1; then
	function bbx {
		case "${1}" in
			tg)      __bbx_target_goto ;;
			pg)      __bbx_project_goto ;;
			pp)      __bbx_project_goto -p ;;
			goto)    shift; __bbx_pkg_goto "$@" ;;
			target)
				if [ "${2}" = "goto" ]; then __bbx_target_goto
				else command bbx "$@"; fi
				;;
			project)
				if [ "${2}" = "goto" ]; then __bbx_project_goto "${3}"
				else command bbx "$@"; fi
				;;
			*)       command bbx "$@" ;;
		esac
	}
fi

# Update __BBX_INFO and manage alias/function visibility based on the current
# directory. Called before every prompt (via PROMPT_COMMAND / precmd hook).
function __bbx_prompt {
	[ "${BBX_PROMPT_ENABLED}" = "0" ] && __BBX_INFO="" && return 0
	local root
	root="$(__bbx_find_project_root)" || root=""

	# Detect project enter / leave transitions and update aliases/functions
	if [ -n "${root}" ] && [ "${root}" != "${__BBX_PREV_ROOT}" ]; then
		# Entered a project (or switched between projects)
		[ -n "${__BBX_PREV_ROOT}" ] && __bbx_undefine_subcmds
		__bbx_define_subcmds
		__BBX_PREV_ROOT="${root}"
	elif [ -z "${root}" ] && [ -n "${__BBX_PREV_ROOT}" ]; then
		# Left the project
		__bbx_undefine_subcmds
		__BBX_PREV_ROOT=""
	fi

	if [ -z "${root}" ]; then
		__BBX_INFO=""
		return 0
	fi

	local target=""
	[ -f "${root}/.bbx/.state" ] && target="$(cat "${root}/.bbx/.state")"
	local running=0
	local cid
	cid="$(docker ps --filter "label=bbx.project_root=${root}" --format "{{.ID}}" 2>/dev/null)"
	[ -n "${cid}" ] && running=1
	__bbx_set_info "${target}" "${running}"
}

if [ -n "${BASH_VERSION}" ]; then
	# Bash: use \001/\002 (RL_PROMPT_START/END_IGNORE) so readline correctly
	# measures the visible width of the prompt.
	function __bbx_set_info {
		local target="${1}" running="${2}"
		local dot
		if [ "${running}" = "1" ]; then
			dot=$'\001\e[32m\002''●'$'\001\e[0m\002'
		else
			dot=$'\001\e[31m\002''●'$'\001\e[0m\002'
		fi
		local label=$'\001\e[33m\002''Build'$'\001\e[1m\002''Box'$'\001\e[0m\002'
		if [ -n "${target}" ]; then
			label="${label}:"$'\001\e[34m\002'"${target}"$'\001\e[0m\002'
		fi
		__BBX_INFO="${dot} ${label} "
	}
	__BBX_INFO=""
	# Prepend ${__BBX_INFO} to PS1 once
	if [[ "${PS1}" != *'${__BBX_INFO}'* ]]; then
		PS1='${__BBX_INFO}'"${PS1}"
	fi
	# Prepend our hook so it runs before any existing PROMPT_COMMAND
	PROMPT_COMMAND="__bbx_prompt${PROMPT_COMMAND:+; }${PROMPT_COMMAND}"

elif [ -n "${ZSH_VERSION}" ]; then
	# ZSH: use native %F/%f colour sequences; requires PROMPT_SUBST.
	function __bbx_set_info {
		local target="${1}" running="${2}"
		local dot
		if [ "${running}" = "1" ]; then
			dot="%F{green}●%f"
		else
			dot="%F{red}●%f"
		fi
		local label="%F{yellow}Build%BBox%b%f"
		if [ -n "${target}" ]; then
			label="${label}:%F{blue}${target}%f"
		fi
		__BBX_INFO="${dot} ${label} "
	}
	__BBX_INFO=""
	setopt PROMPT_SUBST
	# Prepend ${__BBX_INFO} to PROMPT once
	if [[ "${PROMPT}" != *'${__BBX_INFO}'* ]]; then
		PROMPT='${__BBX_INFO}'"${PROMPT}"
	fi
	autoload -Uz add-zsh-hook
	add-zsh-hook precmd __bbx_prompt
fi
