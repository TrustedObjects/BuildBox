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

function test_commands_do_not_shadow_shell_builtins {
	# A command defining a function named after a shell builtin makes every use
	# of that builtin in the process land in the function, the API wrappers
	# included: they run 'set' to manage shell options
	shadowed=""
	for cmd in ${BB_DIR}/src/commands/*; do
		[ -L "${cmd}" ] && continue
		[ -f "${cmd}" ] || continue
		while read -r fn; do
			case " set test eval export exec trap shift unset source read cd local declare typeset printf command " in
				*" ${fn} "*)
					shadowed+="$(basename ${cmd}):${fn} "
					;;
			esac
		done < <(grep -ho '^function [a-zA-Z_][a-zA-Z_0-9]*' "${cmd}" | cut -d ' ' -f 2)
	done
	assertz "${shadowed}"
}
bb_declare_test test_commands_do_not_shadow_shell_builtins
