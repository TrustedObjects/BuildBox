#!/bin/bash
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
set -e

API_DIR=$(cd -- "${1}" &> /dev/null && pwd)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

cp ${SCRIPT_DIR}/api.md.template ${SCRIPT_DIR}/api.md
for source in $(find ${API_DIR} -name '*.sh'|sort -V); do
	echo -n "Processing $(basename ${source})... "
	${SCRIPT_DIR}/sh2md.sh ${source} ${SCRIPT_DIR}/api.md
	echo -e "\e[32mOK\e[0m"
done
