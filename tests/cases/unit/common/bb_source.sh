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

success_script="echo 'sourced' >> ${TMPDIR}/script.log
return 0
"
fail_script="return 1
"

function test_bb_source {
	echo "${success_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	asserteq $? 0
}
bb_declare_test test_bb_source

function test_bb_source_fail {
	echo "${fail_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	assertne $? 0
}
bb_declare_test test_bb_source_fail

function test_bb_source_check_once {
	echo "${success_script}" > ${TMPDIR}/script.sh
	bb_source ${TMPDIR}/script.sh
	asserteq $? 0
	asserteq $(cat ${TMPDIR}/script.log | wc -l) 1
	bb_source ${TMPDIR}/script.sh
	asserteq $(cat ${TMPDIR}/script.log | wc -l) 1
}
bb_declare_test test_bb_source_check_once

