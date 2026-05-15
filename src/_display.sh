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

## @brief Display helpers

## @fn bb_print_columns
## Print tab-separated rows as auto-sized, aligned columns.
## The first row is treated as a header and printed in bold.
## ANSI color codes in cell values are accounted for in width calculations.
## @param [--indent N] Number of spaces to prepend to each row (default: 0)
## @stdin Tab-separated rows; first row is the header
function bb_print_columns {
	local indent=0
	while [ $# -gt 0 ]; do
		case "${1}" in
			--indent) indent="${2}"; shift 2 ;;
			*) break ;;
		esac
	done
	local pad
	pad=$(printf '%*s' "${indent}" '')
	local esc
	esc=$(printf '\033')
	awk -v indent="${pad}" -v ESC="${esc}" '
	BEGIN { FS = "\t"; ncols = 0 }
	function strip_ansi(s,    tmp) {
		tmp = s
		gsub(ESC "[[][0-9;]*m", "", tmp)
		return tmp
	}
	{
		rows[NR] = $0
		if (NF > ncols) ncols = NF
		for (i = 1; i <= NF; i++) {
			len = length(strip_ansi($i))
			if (len > w[i]) w[i] = len
		}
	}
	END {
		for (r = 1; r <= NR; r++) {
			n = split(rows[r], f, "\t")
			printf "%s", indent
			for (i = 1; i <= n; i++) {
				if (r == 1) printf ESC "[1m"
				printf "%s", f[i]
				if (r == 1) printf ESC "[0m"
				if (i < ncols) {
					spaces = w[i] - length(strip_ansi(f[i])) + 2
					for (j = 1; j <= spaces; j++) printf " "
				}
			}
			printf "\n"
		}
	}
	'
}
type bb_exportfn > /dev/null 2>&1 && bb_exportfn bb_print_columns
