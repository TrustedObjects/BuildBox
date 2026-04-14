## @brief Build packages with Autotools
## This build mode is used to build components using Autotools

## @fn bb_autotools_build
## Build with autotools.
## @param Package directory
## @param Build options
function bb_autotools_build () (
	local pkg_dir=${1}
	local pkg_build_dir=${pkg_dir}.build
	shift
	local pkg_opts=" $@"
	pkg_opts=$(echo "${pkg_opts}" | sed -E 's/[[:space:]]-([^-])/ --disable-\1/g')
	pkg_opts=${pkg_opts//[[:space:]]+/ --enable-}
	rm -rf ${pkg_build_dir}
	[ $? -ne 0 ] && return 1
	mkdir -p ${pkg_build_dir}
	[ $? -ne 0 ] && return 1
	cd ${pkg_build_dir}
	[ $? -ne 0 ] && return 1
	set -o pipefail
	autoreconf -fi ${pkg_dir} |& tee build.log
	[ $? -ne 0 ] && return 1
	eval ${pkg_dir}/configure --prefix=$PREFIX --host=$CHOST ${pkg_opts} |& tee -a build.log
	[ $? -ne 0 ] && return 1
	make -j${BB_BUILD_JOBS} |& tee -a build.log
	[ $? -ne 0 ] && return 1
	make install |& tee -a build.log
	[ $? -ne 0 ] && return 1
	return 0
)
bb_exportfn bb_autotools_build

## @fn bb_autotools_build_fast
## Build with autotools, fast mode: only make install is called, then it is
## assumed configuration is already done. Build options changes are ignored at
## this step.
## @param Package directory
function bb_autotools_build_fast () (
	local pkg_dir=${1}
	local pkg_build_dir=${pkg_dir}.build
	if [ ! -d ${pkg_build_dir} ]; then
		>&2 echo "Please build the package in normal mode before using fast mode"
		return 1
	fi
	cd ${pkg_build_dir}
	[ $? -ne 0 ] && return 1
	set -o pipefail
	make -j${BB_BUILD_JOBS} |& tee build.log
	[ $? -ne 0 ] && return 1
	make install |& tee -a build.log
	[ $? -ne 0 ] && return 1
	return 0
)
bb_exportfn bb_autotools_build_fast

## @fn bb_autotools_clean
## Clean autotools build by removing package build sub-directory.
## @param Package directory
function bb_autotools_clean () (
	local pkg_dir=${1}
	local pkg_build_dir=${pkg_dir}.build
	if [ -d ${pkg_build_dir} ]; then
		rm -r ${pkg_build_dir}
	fi
	return $?
)
bb_exportfn bb_autotools_clean

## @fn bb_autotools_stat_warning
## Get autotools build warnings count.
## Uses bb_get_build_log_warning_count() to get warning count.
## @param Package directory
function bb_autotools_stat_warning {
	local pkg_dir=${1}
	local pkg_build_dir=${pkg_dir}.build
	if [ -d ${pkg_build_dir} ]; then
		cd ${pkg_build_dir}
		if [ -f build.log ]; then
			bb_get_build_log_warning_count "${pkg_build_dir}/build.log"
			return
		fi
	fi
}
bb_exportfn bb_autotools_stat_warning

## @fn bb_autotools_stat_installed
## Get package installed version
## @param package directory
function bb_autotools_stat_installed {
	local pkg_dir=${1}
	if [ -d ${pkg_dir} ]; then
		cd ${pkg_dir}
		local pkgconfig_file=$(find * -maxdepth 1 -name '*.pc.in'|head -n 1)
		pkgconfig_name=${pkgconfig_file%.pc.in}
		if [ -z ${pkgconfig_name} ]; then
			return 0
		fi
		local version=$(pkg-config -modversion ${pkgconfig_name} 2> /dev/null)
		if [ $? -ne 0 ]; then
			return 1
		fi
		echo ${version}
	fi
	return 0
}
bb_exportfn bb_autotools_stat_installed

## @fn bb_autotools_supports_sources_sharing
## Autotools build plugin supports sources sharing
## @return 1
function bb_autotools_supports_sources_sharing {
	return 1
}
bb_exportfn bb_autotools_supports_sources_sharing

## @fn bb_autotools_get_build_dir
## Get Autotools build directory for a given package
## @param package directory
## @print Build directory absolute path (may not exists if package not built yet)
## @return 0 on success
function bb_autotools_get_build_dir {
	local pkg_dir=${1}
	echo "${pkg_dir}.build"
	return 0
}
bb_exportfn bb_autotools_get_build_dir
