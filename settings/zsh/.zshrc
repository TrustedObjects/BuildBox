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

HISTSIZE=1000
SAVEHIST=1000
bindkey -e

# Keys binding
typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
# setup key accordingly
[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" end-of-buffer-or-history
# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
        function zle-line-init () {
                printf '%s' "${terminfo[smkx]}"
        }
        function zle-line-finish () {
                printf '%s' "${terminfo[rmkx]}"
        }
        zle -N zle-line-init
        zle -N zle-line-finish
fi
# Workaround to avoid garbage to be printed on CTRL+ALT+UP and CTRL+ALT+DOWN
bindkey '\e[1;7A' redisplay
bindkey '\e[1;7B' redisplay

# Syntax highlighting
if [ -d /usr/share/zsh-syntax-highlighting ]; then
	source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
	source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
ZSH_HIGHLIGHT_HIGHLIGHTERS=(brackets)
alias ls='ls --color=auto'
alias ll='ls -al'

# History
# Prevent from putting duplicate lines in the history
setopt HIST_IGNORE_DUPS

# Python
export PYTHONPATH="/usr/lib/python3.6/site-packages"

# Misc
export VISUAL="vim"
export PREFIX=/usr/local
export CHOST=x86_64-pc-linux-gnu

# Buildbox stuff
source buildbox_utils.sh

function project_goto() {
	if [ ! -d "${BB_PROJECT_DIR}" ]; then
		echo "No current project defined !"
		return 1
	fi
	if [ "$1" != "-p" ]; then
		cd ${BB_PROJECT_DIR}
	else
		if [ ! -d "${BB_PROJECT_PROFILE_DIR}" ]; then
			echo "No project profile directory !"
			return 1
		fi
		cd ${BB_PROJECT_PROFILE_DIR}
	fi
	return 0
}

function target_goto() {
	if [ ! -d "${BB_PROJECT_DIR}" ]; then
		echo "No current project defined !"
		return 1
	fi
	if [ -z "${BB_TARGET}" ]; then
		echo "No current target defined !"
		return 1
	fi
	if [ ! -d "${BB_TARGET_DIR}" ]; then
		echo "Target ${BB_TARGET} not created yet !"
		return 1
	fi
	cd ${BB_TARGET_DIR}
	return 0
}

function pkg_goto() {
	if [ ! -d "${BB_PROJECT_DIR}" ]; then
		echo "No current project defined !"
		return 1
	fi
	if [ -z "${BB_TARGET}" ]; then
		echo "No current target defined !"
		return 1
	fi
	if [ ! -d "${BB_TARGET_DIR}" ]; then
		echo "Target ${BB_TARGET} not created yet !"
		return 1
	fi
	if [ $# -lt 1 ] || [ $# -gt 2 ]; then
		echo "Invalid use, please read man page"
		return 1
	fi
	goto_build=0
	if [ $# -eq 2 ]; then
		if [[ "$2" == "-b" ]]; then
			goto_build=1
		else
			echo "Invalid use, please read man page"
			return 1
		fi
	fi
	search=${1}
	packages=$(bb_find_matching_packages 0 ${search})
	if [ -z ${packages} ]; then
		echo "No matching package"
		return 1
	fi
	packages_arr=("${(@f)${packages}}")
	matches=${#packages_arr[@]}
	if [ $matches -ne 1 ]; then
		package=""
		# Try to find a perfect match
		for p in ${packages_arr}; do
			if [[ "$(basename ${p})" == "${search}" ]] \
				|| [[ "${p}" == "${search}" ]]; then
				package=${p}
				break
			fi
		done
		# Try to find a match without revision
		for p in ${packages_arr}; do
			p_no_rev=$(bb_get_package_name_no_revision ${p})
			if [[ "$(basename ${p_no_rev})" == "${search}" ]] \
				|| [[ "${p_no_rev}" == "${search}" ]]; then
				package=${p}
				break
			fi
		done
		# If no perfect match identified, then error
		if [ -z ${package} ]; then
			echo "Multiple matching packages !"
			echo "${packages}"
			return 1
		fi
	else
		package=${packages}
	fi
	if [ $goto_build -ne 1 ]; then
		goto_dir=$(bb_get_package_src_dir ${package})
		if [ $? -ne 0 ]; then
			echo "Package not cloned yet !"
			return 1
		fi
	else
		goto_dir=$(bb_get_package_build_dir ${package})
		if [ $? -ne 0 ]; then
			echo "Package not built yet !"
			return 1
		fi
	fi
	cd ${goto_dir}
	return 0
}

project() {
	if [[ $1 == "goto" ]]; then
		shift
		project_goto $@
		return $?
	fi
	command project "$@"
	ret=$?
	if [ $ret -ne 0 ]; then
		return $ret
	fi
	if [[ $1 == "del" ]]; then
		# If shell was inside project dir, goto projects root dir
		project_dir="${BB_PROJECTS_DIR}/$2"
		if [ ! -d "${project_dir}" ]; then
			cd ${BB_PROJECTS_DIR}
		fi
	elif [[ $1 == "update" ]]; then
		# If shell is inside project profile dir, goto project dir
		if bb_is_subpath_of "${BB_PROJECT_DIR}/profile" $(pwd); then
			cd ${BB_PROJECT_DIR}
		fi
	fi
	return 0
}

target() {
	if [[ $@ == "goto" ]]; then
		target_goto
		return $?
	fi
	command target "$@"
	ret=$?
	if [ $ret -ne 0 ]; then
		return $ret
	fi
	if [[ $1 == "mrproper" ]]; then
		# If shell was inside target dir, goto project dir
		if [ ! -d "${BB_TARGET_DIR}" ]; then
			cd ${BB_PROJECT_DIR}
		fi
	fi
	return 0
}

goto() {
	pkg_goto ${1} ${2}
}

# prompt
autoload -U promptinit
promptinit
autoload -U colors && colors
function precmd {
	local project_info=""
	if [ -n "${BB_PROJECT}" ]; then
		project_info+="%F{blue}${BB_PROJECT}%f"
		if [ -n "${BB_TARGET}" ]; then
			project_info+=":%F{green}${BB_TARGET}%f"
		fi
		project_info+=" "
	fi
	PROMPT="%F{yellow}Build%BBox%b%f ${project_info}[%~] %B%#%b "
}

# completion for BuildBox
ZCOMPDUMP=${BB_WORKDIR}/etc/zsh/zcompdump
mkdir -p $(dirname ${ZCOMPDUMP})
if [ -f ${ZCOMPDUMP} ]; then
	rm ${ZCOMPDUMP}
fi
fpath=(${BB_DIR}/settings/zsh/comp $fpath)
autoload -U compinit && compinit -d ${ZCOMPDUMP}
# exclude internal API library files from tab completion
if [ -d "${BB_DIR}/src" ]; then
	comp_exclude=$(find ${BB_DIR}/src -maxdepth 1 -type f -printf "%P ")
else
	comp_exclude=$(find ${BB_DIR}/lib -maxdepth 1 -type f -printf "%P ")
fi
zstyle ':completion:*' completer _complete
zstyle ':completion:*' ignored-patterns \
	${=BUILDBOX_INTERNAL_API} \
	${=comp_exclude} \
	project_goto \
	target_goto \
	pkg_goto

# 'cd' goto BuildBox root
function bbcd {
	if [ $# -ne 0 ]; then
		\cd $@
	else
		\cd ${BB_WORKDIR}
	fi
}
if ! (( ${+aliases[cd]} )); then
	alias cd=bbcd
fi

# man pages
if ! (( ${+aliases[man]} )); then
	alias man=bbman
fi

# GDB alias to workaround LD_LIBRARY_PATH miss after GDB start
alias gdb='gdb -ex "set environment LD_LIBRARY_PATH=$LD_LIBRARY_PATH"'

# Define URL to access debug info (for GDB and Valgrind), because we miss debuginfod service in BuildBox
export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"

# Make find follow symlinks
alias find='find -L'

# Mega-good aliases ;)
alias tfb='target fastbuild'
alias tb='target build'
alias ts='target set'
alias tg='target goto'
alias pp='project goto -p'

# Go to workspace
if [ -n "${BB_WORKDIR}" ]; then
	cd "${BB_WORKDIR}"
fi
