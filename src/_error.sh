## @brief Error management

## @fn bb_error_silent
## Catch an error and disable log file.
##
## Exits with code 1
function bb_error_silent {
	bb_disable_log_file
	exit 1
}
bb_exportfn bb_error_silent

## @fn bb_trap_errors_silent
## Catch error signal to call bb_error_silent() function.
## @setenv `BB_ERROR_HANDLER`, set to bb_error_silent() function
function bb_trap_errors_silent {
	export BB_ERROR_HANDLER=bb_error_silent
	trap bb_error_silent ERR
}
bb_exportfn bb_trap_errors_silent

## @fn bb_error
## Catch an error: logs redirection is reset to stdout/stderr, and generic
## error log is printed out with log file path.
## Error log is written to standard error output.
##
## Exits with code 1
function bb_error {
	bb_disable_log_file
	bb_log_file_write "Error !"
	local log_file=$(bb_get_current_log_file)
	>&2 echo -e "\e[31merror !\e[0m see ${log_file} for more details"
	exit 1
}
bb_exportfn bb_error

## @fn bb_trap_errors
## Catch error signal to call bb_error() function.
## @setenv `BB_ERROR_HANDLER`, set to bb_error() function
function bb_trap_errors {
	export BB_ERROR_HANDLER=bb_error
	trap bb_error ERR
}
bb_exportfn bb_trap_errors

## @fn bb_error_nolog
## Catch an error: logs redirection is reset to stdout/stderr, and generic bb_error()
## log is printed out. No log file is used.
##
## Exits with code 1
function bb_error_nolog {
	bb_disable_log_file
	>&2 echo -e "\e[31merror !\e[0m"
	exit 1
}
bb_exportfn bb_error_nolog

## @fn bb_trap_errors_nolog
## Catch error signal to call bb_error_nolog() function.
## @setenv `BB_ERROR_HANDLER`, set to bb_error_nolog() function
function bb_trap_errors_nolog {
	export BB_ERROR_HANDLER=bb_error_nolog
	trap bb_error_nolog ERR
}
bb_exportfn bb_trap_errors_nolog

## @fn bb_trap_errors_custom
## Catch error signal to call custom error function.
## @param Custom error function
## @setenv `BB_ERROR_HANDLER`, set to custom error handler function name
function bb_trap_errors_custom {
	export BB_ERROR_HANDLER=$1
	trap $1 ERR
}
bb_exportfn bb_trap_errors_custom

## @fn bb_restore_error_handler
## Restore buildbox error handler to the last set one.
## This is useful when dealing with sourced scripts which may define their own
## error function, overwritting the BuildBox one.
## @env `BB_ERROR_HANDLER`, if set, use it as error handler, else, define error
## handler as 'true'
function bb_restore_error_handler {
	if [ ! -z "${BB_ERROR_HANDLER}" ]; then
		trap ${BB_ERROR_HANDLER} ERR
	else
		trap true ERR
	fi
}
bb_exportfn bb_restore_error_handler
