# Develop scripts using BuildBox

To use BuildBox, scripts can rely on [BuildBox API](api), and on [BuildBox environment variables](envvars).

These scripts should carefully cleanup temporary created resources on exit.
You can use `trap ... EXIT` to help to do this.

Temporary resources created by these scripts should be stored in a temporary folder under `$TMPDIR`.
For example, by using:
```
tmpdir=$(mktemp -d)
```

Example of script using BuildBox:

``` shell
#!/bin/bash
set -e # exit on error
function error {
	rm -r ${tmpdir} # cleanup
}
trap error EXIT # define cleanup function on exit
source buildbox_utils.sh # include BuildBox API
tmpdir=$(mktemp -d) # create unique temporary directory
report_file="${BB_TARGET_DIR}/my_script_report.txt" # use a BuildBox environment variable
[...]
package=$(bb_find_matching_packages 0 my_package) # call on BuildBox API
[...]
exit 0
```

