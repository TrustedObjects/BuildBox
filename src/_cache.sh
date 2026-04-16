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

## @brief File cache

## @fn bb_cache_store_file
## Store a file in the cache.
## The file is not copied, instead an hard-link is made to limit disk usage.
## Cached files are referenced according to their SHA256 sum, and are stored in
## `BB_CACHE_DIR` folder.
## @param File path
## @return 0 on success
function bb_cache_store_file {
	local file_path=${1}
	local file_name=$(basename ${file_path})
	local sha256=$(sha256sum ${file_path} | cut -d' ' -f 1)
	if [ ! -f ${BB_CACHE_DIR}/${sha256} ]; then
		ln ${file_path} ${BB_CACHE_DIR}/${sha256}
		if [ $? -ne 0 ]; then
			return 1
		fi
		echo "Cached ${file_path}"
	fi
}
bb_exportfn bb_cache_store_file

## @fn bb_cache_load_file
## Load a file from the cache, to the specified file destination path.
## On cache hit, the file is hard-linked to the destination.
## @param Requested file SHA256 sum
## @param File destination path
## @return 0 on cache hit, else cache miss
function bb_cache_load_file {
	local sha256=${1}
	local file_path=${2}
	if [ ! -f ${BB_CACHE_DIR}/${sha256} ]; then
		# cache miss
		echo "${file_path} not found in cache"
		return 1
	fi
	ln ${BB_CACHE_DIR}/${sha256} ${file_path}
	echo "${file_path} loaded from cache"
	return 0
}
bb_exportfn bb_cache_load_file

## @fn bb_cache_known_file
## Check if a file is known by the cache.
## @param File SHA256 sum
## @print Cached file path
## @return 0 if cache hit, 1 if cache miss
function bb_cache_known_file {
	local sha256=${1}
	if [ -f ${BB_CACHE_DIR}/${sha256} ]; then
		# cache hit
		echo "${BB_CACHE_DIR}/${sha256}"
		return 0
	fi
	return 1
}
bb_exportfn bb_cache_known_file

## @fn bb_cache_clear
## Remove all cached content.
function bb_cache_clear {
	rm -rf ${BB_CACHE_DIR}/*
}
bb_exportfn bb_cache_clear
