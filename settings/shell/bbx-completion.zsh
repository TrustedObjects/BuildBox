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

## Host-side ZSH completion for the bbx command.
## Reads project structure directly from the filesystem; no container needed.
## Source this file from your ~/.zshrc, or let bbx-prompt.sh source it
## automatically when it is placed in the same directory.

# Walk up from $PWD to find the nearest .bbx/ directory.
function __bbx_comp_project_root {
	local dir="${PWD}"
	while true; do
		[[ -d "${dir}/.bbx" ]] && echo "${dir}" && return 0
		[[ "${dir}" = "/" ]] && return 1
		dir="${dir%/*}"
		[[ -z "${dir}" ]] && dir="/"
	done
}

# List target names for the current project (reads target.* files in .bbx/).
function __bbx_comp_targets {
	local root
	root="$(__bbx_comp_project_root)" || return
	local -a targets
	local f
	for f in "${root}/.bbx/target."*(N); do
		targets+=("${f##*target.}")
	done
	echo "${targets[@]}"
}

# List package names for the current project (reads .bbx/packages/).
function __bbx_comp_packages {
	local root
	root="$(__bbx_comp_project_root)" || return
	[[ -d "${root}/.bbx/packages" ]] || return
	local -a pkgs
	local f
	for f in "${root}/.bbx/packages/"*(N); do
		[[ -f "${f}" ]] && pkgs+=("${f##*/}")
	done
	echo "${pkgs[@]}"
}

# Completion for: bbx target <subcmd> [args]
function _bbx_target {
	local state line
	_arguments -C \
		"1: :(help list set clone build fastbuild test dist dist-prebuilt clean mrproper pkg tools info goto)" \
		"*::arg:->args"
	case $state in
		args)
			case $line[1] in
				set|info)
					local -a targets=($(__bbx_comp_targets))
					_arguments "1: :(${targets[*]})"
					;;
				build|fastbuild|test)
					_arguments "1: :(--attach)"
					;;
				pkg)
					_arguments "1: :(-m -v)"
					;;
			esac
			;;
	esac
}

# Completion for: bbx project <subcmd> [args]
function _bbx_project {
	local state line
	_arguments -C \
		"1: :(help init clone migrate update clean mrproper info goto)" \
		"*::arg:->args"
	case $state in
		args)
			case $line[1] in
				goto) _arguments "1: :(-p)" ;;
			esac
			;;
	esac
}

# Completion for: bbx pkg [<package>]  /  bare: pkg, clone, build, fastbuild, clean, mrproper
function _bbx_pkg {
	local -a packages=($(__bbx_comp_packages))
	_sep_parts "(${packages[*]})"
}

# Completion for: bbx goto <package> [-b]
function _bbx_goto {
	local -a packages=($(__bbx_comp_packages))
	_arguments -C \
		"1: :(${packages[*]})" \
		"2: :(-b)"
}

# Completion for: bbx image <subcmd> [args]
function _bbx_image {
	local state line
	_arguments -C \
		"1: :(list fetch)" \
		"*::arg:->args"
	case $state in
		args)
			case $line[1] in
				list)  _arguments "(-a --all)" ;;
				fetch)
					local -a tags
					tags=($(curl -sf \
						"https://hub.docker.com/v2/repositories/trustedobjects/buildbox/tags/?page_size=100" \
						| python3 -c "
import sys,json
[print(t['name']) for t in json.load(sys.stdin).get('results',[])]
" 2>/dev/null))
					_arguments "1: :(${tags[*]})"
					;;
			esac
			;;
	esac
}

# Completion for: bbx instance <subcmd> [args]
function _bbx_instance {
	local state line
	_arguments -C \
		"1: :(list stop upgrade)" \
		"*::arg:->args"
	case $state in
		args)
			case $line[1] in
				stop)
					local -a containers=($(docker ps \
						--filter "name=^bbx-" \
						--format "{{.Names}}" 2>/dev/null))
					_arguments \
						"--force[stop busy instances too]" \
						"*: :(${containers[*]})"
					;;
				upgrade)
					local -a containers=($(docker ps -a \
						--filter "name=^bbx-" \
						--format "{{.Names}}" 2>/dev/null))
					local -a images=($(docker images buildbox \
						--format "{{.Repository}}:{{.Tag}}" 2>/dev/null))
					_arguments \
						"--image[image to upgrade to]:image:(${images[*]})" \
						"*: :(${containers[*]})"
					;;
			esac
			;;
	esac
}

# Main completion function for the bbx command.
function _bbx {
	local state line
	_arguments -C \
		"1: :->cmd" \
		"*::arg:->args"

	case $state in
		cmd)
			local -a cmds=(
				'init:Initialize a new BuildBox project'
				'clone:Clone a project repository'
				'migrate:Migrate a 1.x project to 2.x'
				'stop:Stop the container for the current project'
				'image:Manage BuildBox images'
				'instance:Manage running BuildBox containers'
				'target:Target management'
				'project:Project management'
				'build:Build all packages for the current target'
				'fastbuild:Fast-build all packages (incremental)'
				'clean:Remove build outputs'
				'mrproper:Remove all generated files'
				'pkg:Package operations'
				'goto:Go to a package source or build directory'
				'fetch:Fetch sources without building'
				'shell:Open an interactive shell in the container'
				'env:Print the build environment'
				'tg:Go to the current target directory'
				'pg:Go to the project root directory'
				'pp:Go to the project .bbx profile directory'
				'help:Show usage information'
			)
			_describe 'bbx subcommand' cmds
			;;
		args)
			case $line[1] in
				target)   _bbx_target ;;
				project)  _bbx_project ;;
				pkg)      _bbx_pkg ;;
				goto)     _bbx_goto ;;
				image)    _bbx_image ;;
				instance) _bbx_instance ;;
			esac
			;;
	esac
}

# When called by the ZSH completion system (via compdef), delegate to _bbx.
# When sourced directly (by bbx-prompt.sh), this line is skipped by the guard.
[[ "${ZSH_EVAL_CONTEXT}" == *:file* ]] || _bbx "$@"
