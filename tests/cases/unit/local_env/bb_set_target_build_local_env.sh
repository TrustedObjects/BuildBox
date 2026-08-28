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

function test_bb_set_target_build_local_env {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	export BB_TARGET="bar"
	export BB_TARGET_BUILD_DIR="${BB_PROJECT_DIR}/bar/build"
	bb_set_target_build_local_env
	asserteq $? 0
	assertn "${CFLAGS}"
	assertn "${LDFLAGS}"
	assertn "${CHOST}"
	assertn "${CPU}"
	assertn "${CPUDEF}"
	assertn "${CPU_FAMILY}"
	assertn "${CPU_DESCRIPTION}"
	assertn "${PREFIX}"
	asserteq "${PREFIX}" "${BB_TARGET_BUILD_DIR}"
	assertn "${PATH}"
	assertn "${PKG_CONFIG_PATH}"
	assertn "${LD_LIBRARY_PATH}"
	assertn "${PYTHONPATH}"
	assertn "${ACLOCAL_PATH}"
	assertn "${XDG_DATA_DIRS}"
	# More detailed checks are performed in bb_set_local_env.sh
}
bb_declare_test test_bb_set_target_build_local_env

function test_bb_set_target_build_local_env_target_not_set {
	bb_set_target_build_local_env
	assertne $? 0
}
bb_declare_test test_bb_set_target_build_local_env_target_not_set

function test_bb_set_target_build_local_env_defaults {
	bb_use_test_project foo_project
	asserteq $? 0
	# A target profile defining nothing gets a native x86 build environment
	: > "${BB_PROJECT_PROFILE_DIR}/target.bare"
	bb_set_project_current_target bare
	asserteq $? 0
	bb_set_target_build_local_env
	asserteq $? 0
	asserteq "${CPU}" "x86"
	asserteq "${CPU_FAMILY}" "X86"
	asserteq "${CPUDEF}" "X86"
	asserteq "${CPU_DESCRIPTION}" "x86"
	asserteq "${CHOST}" "x86_64-pc-linux-gnu"
	# Only target build directory paths are added to the flags
	asserteq "${CFLAGS}" "-I${BB_TARGET_BUILD_DIR}/include "
	asserteq "${LDFLAGS}" "-L${BB_TARGET_BUILD_DIR}/lib "
}
bb_declare_test test_bb_set_target_build_local_env_defaults

function test_bb_set_target_build_local_env_unknown_cpu {
	bb_use_test_project foo_project
	asserteq $? 0
	# BuildBox knows no CPU: identifiers are derived from the CPU name
	echo "CPU=riscv-rv32imc" > "${BB_PROJECT_PROFILE_DIR}/target.bare"
	bb_set_project_current_target bare
	asserteq $? 0
	bb_set_target_build_local_env
	asserteq $? 0
	asserteq "${CPU}" "riscv-rv32imc"
	asserteq "${CPU_FAMILY}" "RISCV_RV32IMC"
	asserteq "${CPUDEF}" "RISCV_RV32IMC"
	asserteq "${CPU_DESCRIPTION}" "riscv-rv32imc"
	asserteq "${CHOST}" "x86_64-pc-linux-gnu"
}
bb_declare_test test_bb_set_target_build_local_env_unknown_cpu

function test_bb_set_target_build_local_env_target_settings {
	bb_use_test_project foo_project
	asserteq $? 0
	cat > "${BB_PROJECT_PROFILE_DIR}/target.full" <<-EOT
		CPU=cortex-m33
		CPU_FAMILY=ARM
		CPU_DESCRIPTION="Cortex-M33 core"
		CPUDEF=MY_M33
		CHOST=arm-none-eabi
		CFLAGS="-mcpu=cortex-m33 -mthumb"
		LDFLAGS="-specs=nosys.specs"
		PACKAGES=packages.foo
	EOT
	bb_set_project_current_target full
	asserteq $? 0
	bb_set_target_build_local_env
	asserteq $? 0
	asserteq "${CPU}" "cortex-m33"
	asserteq "${CPU_FAMILY}" "ARM"
	asserteq "${CPU_DESCRIPTION}" "Cortex-M33 core"
	asserteq "${CPUDEF}" "MY_M33"
	asserteq "${CHOST}" "arm-none-eabi"
	# Target flags are appended to the target build directory ones
	asserteq "${CFLAGS}" "-I${BB_TARGET_BUILD_DIR}/include -mcpu=cortex-m33 -mthumb"
	asserteq "${LDFLAGS}" "-L${BB_TARGET_BUILD_DIR}/lib -specs=nosys.specs"
}
bb_declare_test test_bb_set_target_build_local_env_target_settings

function test_bb_set_target_build_local_env_no_settings_leak {
	bb_use_test_project foo_project
	asserteq $? 0
	cat > "${BB_PROJECT_PROFILE_DIR}/target.full" <<-EOT
		CPU=cortex-m33
		CPU_FAMILY=ARM
		CPUDEF=MY_M33
		CHOST=arm-none-eabi
		CFLAGS="-mcpu=cortex-m33"
		LDFLAGS="-specs=nosys.specs"
		PACKAGES=packages.foo
	EOT
	: > "${BB_PROJECT_PROFILE_DIR}/target.bare"
	bb_set_project_current_target full
	asserteq $? 0
	bb_set_target_build_local_env
	asserteq $? 0
	# Switching to a target defining nothing must not keep previous settings
	bb_set_project_current_target bare
	asserteq $? 0
	bb_set_target_build_local_env
	asserteq $? 0
	asserteq "${CPU}" "x86"
	asserteq "${CPU_FAMILY}" "X86"
	asserteq "${CPUDEF}" "X86"
	asserteq "${CHOST}" "x86_64-pc-linux-gnu"
	asserteq "${CFLAGS}" "-I${BB_TARGET_BUILD_DIR}/include "
	asserteq "${LDFLAGS}" "-L${BB_TARGET_BUILD_DIR}/lib "
}
bb_declare_test test_bb_set_target_build_local_env_no_settings_leak
