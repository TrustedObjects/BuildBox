## @brief Log files

## Log file defaults to .bbx/.logs/ if a project is active, else /tmp
_bb_log_dir="${BB_PROJECT_PROFILE_DIR:+${BB_PROJECT_PROFILE_DIR}/.logs}"
_bb_log_dir="${_bb_log_dir:-${TMPDIR:-/tmp}}"
BB_CURRENT_LOG_FILE="${_bb_log_dir}/${BB_API_CALLER}.log"
unset _bb_log_dir
BB_LOG_FILE_ENABLED=0

## @fn bb_get_current_log_file
## Get current log file path.
## If bb_set_current_log_file() was not called, log file is by default stored
## in session directory and named according to the running command,
## `COMMAND_NAME.log`.
## @print Log file path
function bb_get_current_log_file {
	echo "${BB_CURRENT_LOG_FILE}"
}
bb_exportfn bb_get_current_log_file

## @fn bb_set_current_log_file
## Set current log file path.
## If parent dir does not exists, it is created.
## @param Log file path
## @param Move log file to new log file path (1 = yes, 0 = no) (optional, default no)
## @return 0 on success
function bb_set_current_log_file {
	file_path=${1}
	move=${2}
	file_dir=$(dirname ${file_path})
	if [ ! -d "${file_dir}" ]; then
		mkdir -p "${file_dir}"
		if [ $? -ne 0 ]; then
			echo "Unable to create log file parent directory"
			return 1
		fi
	fi
	if [ -e "${file_path}" ] && [ -d "${file_path}" ]; then
		echo "Log file already exists and is a directory"
		return 1
	fi
	if [ ! -z ${move} ] && [ ${move} -eq 1 ] && [ -f ${BB_CURRENT_LOG_FILE} ]; then
		mv ${BB_CURRENT_LOG_FILE} ${file_path}
		if [ $? -ne 0 ]; then
			echo "Unable to move log file to new location"
			return 1
		fi
	fi
	BB_CURRENT_LOG_FILE=${file_path}
	return 0
}
bb_exportfn bb_set_current_log_file

## @fn bb_enable_log_file
## Enable log file: redirect stdout and stderr to it and enable every expanded
## shell command logging.
## @return 0 on success, else log file creation failed
function bb_enable_log_file {
	[ ${BB_LOG_FILE_ENABLED} -ne 0 ] && return 0
	local log_file=$(bb_get_current_log_file)
	mkdir -p "$(dirname "${log_file}")"
	touch ${log_file}
	[ $? -ne 0 ] && return 1
	# backup stdout (1) and stderr (2) into 8 and 9 file descriptors
	exec 8>&1 9>&2
	# make stdout (1) and stderr (2) to point to log_file file descriptor
	exec 1>>${log_file} 2>&1
	# shell command logging
	set -x
	BB_LOG_FILE_ENABLED=1
	return 0
}
bb_exportfn bb_enable_log_file

## @fn bb_log_file_write
## Write in log file
## @param message to write (if no message, writes an empty newline)
## @return 0 on success, else log file write failed
function bb_log_file_write {
	local log_file=$(bb_get_current_log_file)
	mkdir -p "$(dirname "${log_file}")"
	touch ${log_file}
	[ $? -ne 0 ] && return 1
	echo -e "${1}" >> ${log_file}
	return $?
}
bb_exportfn bb_log_file_write

## @fn bb_disable_log_file
## Disable log file and command logging.
## Reverse of bb_enable_log_file() actions.
function bb_disable_log_file {
	[ ${BB_LOG_FILE_ENABLED} -eq 0 ] && return
	set +x
	# check if backup file descriptor 8 and 9 exists to restore and close
	if { >&8; } 2<> /dev/null; then
		# restore stdout (1) from backup file descriptor 8
		exec 1>&8
		# close backup file descriptor 8
		exec 8>&-
	fi
	if { >&9; } 2<> /dev/null; then
		# restore stderr (2) from backup file descriptor 9
		exec 2>&9
		# close backup file descriptor 9
		exec 9>&-
	fi
	BB_LOG_FILE_ENABLED=0
}
bb_exportfn bb_disable_log_file

## @fn bb_is_log_file_enabled
## Check if log file is enabled
## @return 1 if enabled, 0 if disabled
function bb_is_log_file_enabled {
	return ${BB_LOG_FILE_ENABLED}
}
bb_exportfn bb_is_log_file_enabled

## @fn bb_backup_log_file
## Backup log file.
## @param Backup destination
function bb_backup_log_file {
	local dest=${1}
	log_file=$(bb_get_current_log_file)
	if [ -f ${log_file} ]; then
		cp -a ${log_file} ${dest}
		return $?
	fi
	return 0
}
bb_exportfn bb_backup_log_file

## @fn bb_clear_log_file
## Clear log file
## @return 0 on success
function bb_clear_log_file {
	local log_file=$(bb_get_current_log_file)
	rm -f ${log_file}
	return $?
}
bb_exportfn bb_clear_log_file
