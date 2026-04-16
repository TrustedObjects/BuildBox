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

## @brief Projects

## @fn bb_detect_project_root
## Detect the BuildBox project root by walking up from the current directory
## looking for a .bbx/ directory.
## @print Absolute path of the project root, or nothing if not found
## @return 0 if found, 1 if not found
function bb_detect_project_root () (
	local dir
	dir=$(pwd)
	while true; do
		if [ -d "${dir}/.bbx" ]; then
			echo "${dir}"
			return 0
		fi
		local parent
		parent=$(dirname "${dir}")
		if [ "${parent}" == "${dir}" ]; then
			return 1
		fi
		dir="${parent}"
	done
)
bb_exportfn bb_detect_project_root

## @fn bb_autodetect_project
## Detect and set current project environment.
## First checks if BB_PROJECT_DIR is already set in the environment (allows
## subprocesses to inherit the project context set by the parent). If not set,
## walks up from the current working directory to find a .bbx/ directory.
## If no project is found, environment is left undefined. No error is raised.
## @setenv Like bb_set_current_project(), plus target env from .bbx/.state
## @return 0 on success (including "no project found")
function bb_autodetect_project {
	# If BB_PROJECT_DIR is already exported and valid, honour it
	if [ -n "${BB_PROJECT_DIR}" ] && [ -d "${BB_PROJECT_DIR}/.bbx" ]; then
		bb_set_current_project "${BB_PROJECT_DIR}"
		return $?
	fi
	local project_root
	project_root=$(bb_detect_project_root)
	if [ $? -ne 0 ]; then
		return 0
	fi
	bb_set_current_project "${project_root}"
}
bb_exportfn bb_autodetect_project

## @fn bb_set_current_project
## Set current project by absolute path.
## @param Project root absolute path
## @setenv `BB_PROJECT_DIR`: project root absolute path
## @setenv `BB_PROJECT`: project folder name (basename of BB_PROJECT_DIR, for 1.x compatibility)
## @setenv `BB_PROJECT_PROFILE_DIR`: .bbx/ directory path
## @setenv `BB_PROJECT_SRC_DIR`: shared package sources path
## @setenv `BB_CACHE_DIR`: per-project cache directory
## @setenv `BB_TOOLS_DIR`: per-project tools directory
## @setenv `BB_TRASH_DIR`: per-project trash directory
## @setenv and env set by bb_set_project_current_target() via .bbx/.state
## @return 0 on success
function bb_set_current_project {
	local project_root=${1}
	if [ -z "${project_root}" ] || [ ! -d "${project_root}/.bbx" ]; then
		>&2 echo "Not a BuildBox project: ${project_root}"
		return 1
	fi
	export BB_PROJECT_DIR="${project_root}"
	export BB_PROJECT="$(basename "${project_root}")"
	export BB_PROJECT_PROFILE_DIR="${BB_PROJECT_DIR}/.bbx"
	export BB_PROJECT_SRC_DIR="${BB_PROJECT_DIR}/src"
	export BB_CACHE_DIR="${BB_PROJECT_PROFILE_DIR}/.cache"
	export BB_TOOLS_DIR="${BB_PROJECT_PROFILE_DIR}/.tools"
	export BB_TRASH_DIR="${BB_PROJECT_PROFILE_DIR}/.trash"
	mkdir -p "${BB_CACHE_DIR}" "${BB_TOOLS_DIR}" "${BB_TRASH_DIR}"
	# Restore target from .bbx/.state
	if [ -f "${BB_PROJECT_PROFILE_DIR}/.state" ]; then
		local target
		target=$(cat "${BB_PROJECT_PROFILE_DIR}/.state")
		if [ -n "${target}" ] && [ -f "${BB_PROJECT_PROFILE_DIR}/target.${target}" ]; then
			bb_set_project_current_target "${target}"
		else
			bb_set_project_default_target
		fi
	else
		bb_set_project_default_target
	fi
	return $?
}
bb_exportfn bb_set_current_project

## @fn bb_reset_current_project
## Reset current project environment.
## @resetenv `BB_PROJECT_DIR`, `BB_PROJECT`, `BB_PROJECT_PROFILE_DIR`, `BB_PROJECT_SRC_DIR`
## @resetenv `BB_CACHE_DIR`, `BB_TOOLS_DIR`, `BB_TRASH_DIR`
function bb_reset_current_project {
	unset BB_PROJECT_DIR
	unset BB_PROJECT
	unset BB_PROJECT_PROFILE_DIR
	unset BB_PROJECT_SRC_DIR
	unset BB_CACHE_DIR
	unset BB_TOOLS_DIR
	unset BB_TRASH_DIR
	bb_reset_project_current_target
	bb_reset_local_env
}
bb_exportfn bb_reset_current_project

## @fn bb_is_project_profile_clean
## Check if the project profile (.bbx/) has no uncommitted changes.
## If .bbx/ is not a git repository (plain folder), it is considered clean.
## @param Project root path (optional, defaults to BB_PROJECT_DIR)
## @return 0 if profile is clean, else 1
function bb_is_project_profile_clean () (
	local project_root=${1:-${BB_PROJECT_DIR}}
	local profile_dir="${project_root}/.bbx"
	if [ ! -d "${profile_dir}" ]; then
		return 0
	fi
	# Check if .bbx is a submodule or has its own git tracking
	if git -C "${profile_dir}" rev-parse --git-dir > /dev/null 2>&1; then
		git -C "${profile_dir}" diff --quiet
		return $?
	fi
	# .bbx is a plain folder, check if there are changes in the project root
	git -C "${project_root}" diff --quiet -- .bbx
	return $?
)
bb_exportfn bb_is_project_profile_clean

## @fn bb_project_get_branch_name
## Get current project git branch name.
## @param Project root path (optional, defaults to BB_PROJECT_DIR)
## @print Branch name
## @return 0 on success, else error
function bb_project_get_branch_name () {
	local project_root=${1:-${BB_PROJECT_DIR}}
	if [ ! -d "${project_root}/.git" ] && ! git -C "${project_root}" rev-parse --git-dir > /dev/null 2>&1; then
		return 1
	fi
	local branch
	branch=$(git -C "${project_root}" branch --contains "$(git -C "${project_root}" rev-parse HEAD)" 2>/dev/null | grep -v HEAD | awk 'END {print $NF}')
	if [ $? -eq 0 ]; then
		echo "${branch}"
	fi
	return 0
}
bb_exportfn bb_project_get_branch_name

## @fn bb_project_get_tag
## Get current project git tag.
## @print Tag name
## @return 0 on success, else error
function bb_project_get_tag () {
	if ! git -C "${BB_PROJECT_DIR}" rev-parse --git-dir > /dev/null 2>&1; then
		return 1
	fi
	local tag
	tag="$(git -C "${BB_PROJECT_DIR}" describe --tags 2>/dev/null)"
	if [ $? -eq 0 ]; then
		echo "${tag}"
	fi
	return 0
}
bb_exportfn bb_project_get_tag

## @fn bb_archive_prebuilt_target
## Archive current target built files.
## The following is archived:
## - target `build` directory
## - all inside target `src` directory, except shared sources
## @env `BB_PREBUILT_ONLY_TAGGED`: 1 to restrict prebuilt generation to tagged
## projects, else 0
## @print Archive directory path, to be deleted after use.
## @return 0 on success, else error
function bb_archive_prebuilt_target {
	local project=$(bb_project_get_branch_name)
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to get project branch name"
		return 1
	fi
	local tag=$(bb_project_get_tag)
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to get project tag"
		return 1
	fi
	if [ -n "${BB_PREBUILT_ONLY_TAGGED}" ] && [ "${BB_PREBUILT_ONLY_TAGGED}" -eq 1 ]; then
		if ! git -C "${BB_PROJECT_DIR}" describe --exact-match --tags > /dev/null 2>&1; then
			>&2 echo "The project have to be tagged to make a prebuilt"
			return 1
		fi
	fi
	if [ -z "${tag}" ]; then
		>&2 echo "The project have to be tagged to make a prebuilt"
		return 1
	fi
	if [ ! -d "${BB_TARGET_DIR}" ]; then
		>&2 echo "Missing target directory"
		return 1
	fi
	local archive_dir=$(mktemp -d)
	local workdir="${archive_dir}/${project}/${tag}"
	mkdir -p ${workdir}
	pushd ${BB_TARGET_DIR} > /dev/null
	if [ $? -ne 0 ]; then
		return 1
	fi
	find src -mindepth 1 -maxdepth 1 -type d -xtype d -print0 | tar cf ${workdir}/${BB_TARGET}.tar --null --files-from=-
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to archive packages built files"
		return 1
	fi
	tar rf ${workdir}/${BB_TARGET}.tar build
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to archive built files"
		return 1
	fi
	popd > /dev/null
	xz ${workdir}/${BB_TARGET}.tar
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to compress archive"
		return 1
	fi
	echo ${archive_dir}
	return 0
}
bb_exportfn bb_archive_prebuilt_target

## @fn bb_export_prebuilt_target
## Export current target pre-built archive, made by bb_archive_prebuilt_target().
## @param Archive directory path, from bb_archive_prebuilt_target().
## @env `BB_PREBUILT_SERVER`: pre-built targets server
## @env `BB_PREBUILT_USERNAME`: server user name
## @env `BB_PREBUILT_PATH`: pre-built targets location path on server
## @return 0 on success, else error
function bb_export_prebuilt_target {
	local archive_dir="${1}"
	scp -q -r ${archive_dir}/* ${BB_PREBUILT_USERNAME}@${BB_PREBUILT_SERVER}:${BB_PREBUILT_PATH}/.
	if [ $? -ne 0 ]; then
		>&2 echo "Unable to release archive"
		return 1
	fi
	return 0
}
bb_exportfn bb_export_prebuilt_target

## @fn bb_target_has_prebuilt
## Check on the pre-built targets server if this target has an available
## pre-built archive.
## @return 0 if there is a pre-built archive for this target
function bb_target_has_prebuilt {
	local project=$(bb_project_get_branch_name)
	local tag=$(bb_project_get_tag)
	rsync --size-only ${BB_PREBUILT_USERNAME}@${BB_PREBUILT_SERVER}:${BB_PREBUILT_PATH}/${project}/${tag}/${BB_TARGET}.tar.xz > /dev/null 2>&1
}
bb_exportfn bb_target_has_prebuilt

## @fn bb_import_prebuilt_target
## @return 0 on success, else error
function bb_import_prebuilt_target {
	local project=$(bb_project_get_branch_name)
	local tag=$(bb_project_get_tag)
	if [ ! -d ${BB_TARGET_DIR} ]; then
		mkdir -p ${BB_TARGET_DIR}
	fi
	if [ ! -f "${BB_TARGET_DIR}/${BB_TARGET}.tar.xz" ]; then
		scp -q ${BB_PREBUILT_USERNAME}@${BB_PREBUILT_SERVER}:${BB_PREBUILT_PATH}/${project}/${tag}/${BB_TARGET}.tar.xz ${BB_TARGET_DIR} || true
	fi
	if [ -f "${BB_TARGET_DIR}/${BB_TARGET}.tar.xz" ]; then
		cd ${BB_TARGET_DIR}
		tar -xf ${BB_TARGET_DIR}/${BB_TARGET}.tar.xz
		if [ $? -ne 0 ]; then
			return 1
		fi
	else
		return 1
	fi
	return 0
}
bb_exportfn bb_import_prebuilt_target
