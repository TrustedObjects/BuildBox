## @brief Build packages with Makefile
## This build mode is used to build components using simple Makefile

## @fn bb_make_build
## Build with simple make.
## @param Package directory
## @param Build options
## @return 0 on success
function bb_make_build () (
	local pkg_dir=${1}
	shift
	local pkg_opts=$@
	cd ${pkg_dir}
	[ $? -ne 0 ] && return 1
	set -o pipefail
	eval make -j${BB_BUILD_JOBS} ${pkg_opts} |& tee -a build.log
	[ $? -ne 0 ] && return 1
	make install |& tee -a build.log
	[ $? -ne 0 ] && return 1
	return 0
)
bb_exportfn bb_make_build

## @fn bb_make_build_fast
## Build with make, fast mode (same as normal mode).
## @param package directory
## @return 0 on success
function bb_make_build_fast () (
	bb_make_build ${1}
	return $?
)
bb_exportfn bb_make_build_fast

## @fn bb_make_clean
## Clean make build.
## @param Package directory
## @return 0 on success
function bb_make_clean () (
	local pkg_dir=${1}
	cd ${pkg_dir}
	[ $? -ne 0 ] && return 1
	make clean
	[ $? -ne 0 ] && return 1
	if [ -f build.log ]; then
		rm build.log
	fi
	return 0
)
bb_exportfn bb_make_clean

## @fn bb_make_stat_warning
## Get make build warnings count.
## Uses bb_get_build_log_warning_count() to get warning count.
## @param Package directory
function bb_make_stat_warning {
	local pkg_dir=${1}
	if [ -d ${pkg_dir} ]; then
		cd ${pkg_dir}
		if [ -f build.log ]; then
			bb_get_build_log_warning_count "${pkg_dir}/build.log"
			return
		fi
	fi
}
bb_exportfn bb_make_stat_warning
