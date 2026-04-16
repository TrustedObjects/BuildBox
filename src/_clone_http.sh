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

## @brief Sources using HTTP
## Clone backend to get components archives from an HTTP server.

## @fn bb_http_clone
## Get a component archive from an HTTP server.
## If the archive SHA256 is specified, the archive may be cached for later use,
## and if it is present in the cache it may not be re-downloaded.
## @param Repository URI
## @param Destination directory (where to put the extracted archive)
## @param Archive SHA256 sum
## @return 0 on success
function bb_http_clone () (
	local uri=${1}
	local dest=${2}
	local sha256_ref=${3}
	local filename=$(basename ${uri})
	bb_trap_errors_silent
	mkdir -p ${dest}
	# Put the archive next to the destination directory
	cd $(dirname ${dest})
	# try to load it from cache
	local cache_hit=0
	if [ -n "${sha256_ref}" ]; then
		bb_cache_load_file ${sha256_ref} ${filename} && cache_hit=1
	fi
	if [ $cache_hit -eq 0 ]; then
		# not found in cache, download it
		case "${uri}" in
			file://*) cp "${uri#file://}" "${filename}" ;;
			*)        wget ${uri} ;;
		esac
		[ $? -ne 0 ] && return 1
	fi
	# Check file integrity, and cache it if correct
	local sha256=$(sha256sum ${filename} | cut -d' ' -f 1)
	if [ -n "${sha256_ref}" ]; then
		echo "Checking archive SHA256 sum..."
		if [ "${sha256}" != "${sha256_ref}" ]; then
			echo "Bad SHA256 sum for downloaded archive! ${sha256} != ${sha256_ref}"
			return 1
		fi
		bb_cache_store_file ${filename}
	else
		echo "Skipping SHA256 check"
	fi
	echo "Extracting archive..."
	cd ${dest}
	bb_extract ../${filename}
	return $?
)
bb_exportfn bb_http_clone
