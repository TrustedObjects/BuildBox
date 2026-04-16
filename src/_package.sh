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

## @brief Packages

## @fn bb_get_packages
## Get packages list for a target of the current project.
## @param Target name
## @env `BB_PROJECT_PROFILE_DIR`
## @print Packages list. The name of each returned package is the full name
## (the path in packages repository).
## @return 0 on success
function bb_get_packages () (
	local target=${1}
	# Get PACKAGES var
	target_profile=$(bb_get_target_profile_path ${target})
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_source ${target_profile}
	[ $? -ne 0 ] && return 1
	while read -r line || [ -n "${line}" ]; do
		if [ -z "${line}" ]; then
			continue
		fi
		if [[ ${line} =~ ^#.* ]]; then
			continue
		fi
		local pkg_name=$(echo ${line} | cut -f 1 -d :)
		echo $(bb_expand_string_vars "${pkg_name}")
	done < ${BB_PROJECT_PROFILE_DIR}/${PACKAGES}
	return $?
)
bb_exportfn bb_get_packages

## @fn bb_get_packages_with_options
## Get packages list for a target of the current project, including packages
## options.
## @param Target name
## @env `BB_PROJECT_PROFILE_DIR`
## @print Packages list and their options, formatted like this:
## `pkg_name[:[option1] [option2] ...]`.
## The name of each returned package is the full name (the path in packages
## repository).
##
## For example:
## ```
##  package1: +logs -tests
##  package2:
##  package3
## ```
## @return 0 on success
function bb_get_packages_with_options () (
	local target=${1}
	# Get PACKAGES var
	target_profile=$(bb_get_target_profile_path ${target})
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_source ${target_profile}
	[ $? -ne 0 ] && return 1
	while read -r line || [ -n "${line}" ]; do
		if [ -z "${line}" ]; then
			continue
		fi
		if [[ ${line} =~ ^#.* ]]; then
			continue
		fi
		echo $(bb_expand_string_vars "${line}")
	done < ${BB_PROJECT_PROFILE_DIR}/${PACKAGES}
	return $?
)
bb_exportfn bb_get_packages_with_options

## @fn bb_find_matching_packages
## Given a filter list, find matching packages on current target.
## @param Include options in output (1 to include options)
## @param Filter list, separated by spaces
## @env `BB_TARGET`: current target
## @env `BB_PROJECT_PROFILE_DIR`: project directory
## @print Matching packages list, and their build options (if requested).
## If a filter does not match anything, nothing at all will be printed out.
## The name of each returned package is the full name (the path in packages
## repository).
## Packages are returned in their order of appearance in target packages list.
## Each package is returned once.
## @return 0 on success
function bb_find_matching_packages () (
	# Select packages matching given list, and make results unique
	include_options=${1}
	shift
	# Get packages list var
	bb_source $(bb_get_target_profile_path ${BB_TARGET})
	[ $? -ne 0 ] && return 1
	# Convert filter to array
	IFS=' '
	filter_list=( $(echo -e "${@}") )
	unset IFS
	if [ ${include_options} -eq 1 ]; then
		packages=$(bb_get_packages_with_options ${BB_TARGET})
	else
		packages=$(bb_get_packages ${BB_TARGET})
	fi
	# Find matches for every requested filter
	selected_packages=""
	for req in "${filter_list[@]}"; do
		req=${req/$'\n'/}
		matches=$(echo "${packages}" | grep -e "${req}")
		if [ -z "${matches}" ]; then
			return 0
		fi
		selected_packages+="${matches}"
		selected_packages+=$'\n'
	done
	# Only one occurence for each package
	selected_packages=$(echo "${selected_packages}"|sort|uniq)
	# Sort in target packages list order
	result=""
	while IFS= read -r package; do
		if grep -Fxq "${package}" <<< "${selected_packages}"; then
			result+="${package}"
			result+=$'\n'
		fi
	done <<< "${packages}"
	echo "${result}"
	return 0
)
bb_exportfn bb_find_matching_packages

## @fn bb_package_is_modified
## To know if a package sources has been locally modified in current target.
## A package is considered as modified if the content is not matching the
## original cloned revision.
##
## Only Git packages are supported, else this status is unknown. If the package
## is not found, the status is unknown too.
## @param Package name
## @return 1 if modified, 0 if not modified, 2 if unknown.
function bb_package_is_modified () (
	pkg_name="${1}"
	pkg_name_short=$(bb_escape_package_name "${pkg_name}")
	pkg_dir=${BB_TARGET_SRC_DIR}/${pkg_name_short}
	if [ ! -d ${pkg_dir} ]; then
		return 2
	fi
	cd ${pkg_dir}
	if [ ! -d .git ]; then
		return 2
	fi
	# Check if current revision is the original cloned revision
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && echo -1 && return 1
	current_hash=$(git rev-parse HEAD)
	[ $? -ne 0 ] && echo -1 && return 1
	original_hash=$(git rev-list -n 1 ${SRC_REVISION} 2> /dev/null)
	[ $? -ne 0 ] && echo -1 && return 1
	if [ "${current_hash}" != "${original_hash}" ]; then
		return 1
	fi
	# Check if there are changes
	git diff --quiet
	if [ $? -ne 0 ]; then
		return 1
	fi
	return 0
)
bb_exportfn bb_package_is_modified

## @fn bb_get_package_src_dir
## Get package source directory absolute path
## @param Package name
## @print Package source directory absolute path
## @return 0 on success, else error (the package may be not cloned yet)
function bb_get_package_src_dir {
	pkg_name=${1}
	if [ -z "${pkg_name}" ]; then
		return 1
	fi
	local pkg_dir=${BB_TARGET_SRC_DIR}/$(bb_escape_package_name ${pkg_name})
	if [ ! -d ${pkg_dir} ]; then
		return 1
	fi
	echo ${pkg_dir}
	return 0
}
bb_exportfn bb_get_package_src_dir

## @fn bb_get_package_name_no_revision
## Given a package name, extract the package name prefix, without revision.
## If package name include a path prefix, it is also returned.
## The revision can be:
## - a branch or a tag, starting with an `@` sign,
## - or a tag, starting with a dash immediately followed by a digit.
##
## @param Package name
## @print Package name prefix (without revision, if present)
function bb_get_package_name_no_revision {
	local pkg_name=${1}
	if [[ "${pkg_name}" == *"@"* ]]; then
		# The regex below returns everything from the beginning until @
		# sign
		echo ${pkg_name} | sed -E -n 's/(.*)@.*$/\1/p'
	else
		# The regex below returns everything from the beginning until
		# first dash followed by a digit
		ret=$(echo ${pkg_name} | sed -E -n 's/(.*)-[0-9].*$/\1/p')
		if [ -n "${ret}" ]; then
			echo ${ret}
		else
			echo ${pkg_name}
		fi
	fi
}
bb_exportfn bb_get_package_name_no_revision

## @fn bb_get_package_revision
## Given a package name, extract the revision suffix.
## The revision can be:
## - a branch or a tag, starting with an `@` sign,
## - or a tag, starting with a dash immediately followed by a digit.
##
## @param Package name
## @print Package revision suffix, or nothing if no revision is present in
## package name.
function bb_get_package_revision {
	local pkg_name=${1}
	if [[ "${pkg_name}" == *"@"* ]]; then
		# The regex below returns everything from the @ sign until the
		# end
		echo ${pkg_name} | sed -E -n 's/.*@(.*)$/\1/p'
	else
		# The regex below returns everything from the first dash
		# followed by a digit, until the end
		echo ${pkg_name} | sed -E -n 's/.*-([0-9].*)$/\1/p'
	fi
}
bb_exportfn bb_get_package_revision

## @fn bb_load_package
## Load a package file.
## Package data are defined in the current scope.
##
## If package name includes the package revision as suffix (after `-` or `@`),
## the complete package file name is looked for. If it doesn't exists, but the
## package file with no revision in its name exists, then this file is used and
## `SRC_REVISION` is overwritten with revision provided in package name
## parameter.
##
## For example, if `package-1.2.3` file exists in package repository, then it is
## used directly. Else, if `package-1.2.3` doesn't exists, but `package` exists,
## then this file is used and `SRC_REVISION` is overwritten with `1.2.3`.
## @param Package name
## @print Error message on error
## @setenv `SRC_PROTO`: protocol used to clone package sources
## @setenv `SRC_URI`: sources location
## @setenv `SRC_REVISION`: sources revision
## @setenv `SRC_BUILD`: build mode
## @setenv `SRC_CONFIG`: build settings
## @setenv `SRC_POST_CLONE_HOOK`: optional function to be executed after clonig sources
## @return 0 on success, else package not found
function bb_load_package {
	local pkg_name=${1}
	local pkg_path=${BB_PROJECT_PROFILE_DIR}/packages/${pkg_name}
	if [ -f ${pkg_path} ]; then
		# A package exists with the full name given in parameter
		source ${pkg_path}
		return 0
	fi
	local pkg_name_no_revision=$(bb_get_package_name_no_revision ${pkg_name})
	pkg_path=${BB_PROJECT_PROFILE_DIR}/packages/${pkg_name_no_revision}
	if [ -f ${pkg_path} ]; then
		# A package exists with the same name prefix
		source ${pkg_path}
		SRC_REVISION=$(bb_get_package_revision ${pkg_name})
		return 0
	fi
	# Package not found
	echo "Package ${1} not found !"
	return 1
}
bb_exportfn bb_load_package

## @fn bb_get_package_path
## Get package path.
## If package name includes the package revision as suffix (after `-` or `@`),
## the package file path is printed if it exists. If it doesn't exists, but the
## package file with no revision in its name exists, then this file path is
## printed.
##
## For example, if `package-1.2.3` file exists in package repository, then its
## path is printed. Else, if `package-1.2.3` doesn't exists, but `package`
## exists, then this file path is printed.
##
## The package doesn't need to be referenced in target package file, but it has
## to exists in project profile packages sub-module repository.
## @param package name
## @print package absolute path
## @return 0 on success, else package not found
function bb_get_package_path {
	local pkg_name=${1}
	local pkg_path=${BB_PROJECT_PROFILE_DIR}/packages/${pkg_name}
	if [ -f ${pkg_path} ]; then
		# A package exists with the full name given in parameter
		echo ${pkg_path}
		return 0
	fi
	pkg_name=$(bb_get_package_name_no_revision ${pkg_name})
	pkg_path=${BB_PROJECT_PROFILE_DIR}/packages/${pkg_name}
	if [ -f ${pkg_path} ]; then
		# A package exists with the same name prefix
		echo ${pkg_path}
		return 0
	fi
	# Package not found
	return 1
}
bb_exportfn bb_get_package_path

## @fn bb_escape_package_name
## Convenient function to espace package name by removing special characters
## which may be present in its revision.
## Escaped characters: '/', '\'.
## Escaped characters are replaced with '_'.
## @param package name
## @print escaped package name
function bb_escape_package_name {
	local pkg_name=${1}
	echo "${pkg_name}" | sed 's/[\/\\]/_/g'
}
