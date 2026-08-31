#!/bin/bash
set -e

## Generate the releases news of the documentation home page from the BuildBox
## ChangeLog. The result is a markdown partial, included by src/index.md.
## Usage: generate_news.sh <changelog> <output markdown file> [releases count]

CHANGELOG="${1}"
OUTPUT="${2}"
RELEASES="${3:-3}"
# Items shown per release: the home page gives an overview, the full ChangeLog
# is one click away
ITEMS="${ITEMS:-4}"
REPOSITORY="https://github.com/TrustedObjects/BuildBox"

if [ ! -f "${CHANGELOG}" ]; then
	>&2 echo "ChangeLog not found: ${CHANGELOG}"
	exit 1
fi
if [ -z "${OUTPUT}" ]; then
	>&2 echo "Usage: $(basename "${0}") <changelog> <output markdown file> [releases count]"
	exit 1
fi

echo -n "Generating releases news from $(basename ${CHANGELOG})... "
mkdir -p "$(dirname "${OUTPUT}")"

awk -v releases="${RELEASES}" -v items="${ITEMS}" -v repository="${REPOSITORY}" '
function esc(s) {
	gsub(/&/, "\\&amp;", s)
	gsub(/</, "\\&lt;", s)
	gsub(/>/, "\\&gt;", s)
	return s
}
# Quoted parts of a ChangeLog entry are commands or file names: show them as code
function codespans(s,   out) {
	out = ""
	while (match(s, /'"'"'[^'"'"']+'"'"'/)) {
		out = out substr(s, 1, RSTART - 1) \
			"<code>" substr(s, RSTART + 1, RLENGTH - 2) "</code>"
		s = substr(s, RSTART + RLENGTH)
	}
	return out s
}
function pretty_date(date,   parts, month_names, month) {
	split("January February March April May June July August September October November December", month_names, " ")
	if (split(date, parts, "/") != 3) {
		return date
	}
	month = parts[1] + 0
	if (month < 1 || month > 12) {
		return date
	}
	return month_names[month] " " (parts[2] + 0) ", " parts[3]
}
function close_release() {  # uses release_url of the release being closed
	if (! in_release) {
		return
	}
	news = news "  </ul>\n"
	if (dropped > 0) {
		news = news sprintf("  <p class=\"bbx-news-rest\"><a href=\"%s\"" \
			" target=\"_blank\" rel=\"noreferrer\">and %d more</a></p>\n", \
			release_url, dropped)
	}
	news = news "</article>\n"
	in_release = 0
}
BEGIN {
	count = 0
	in_release = 0
	news = ""
}
# A release line is a version, optionally followed by its date
/^[0-9]+\.[0-9]+\.[0-9]+[-a-zA-Z0-9.]*([[:space:]]|$)/ {
	close_release()
	if (count >= releases) {
		next
	}
	count++
	shown = 0
	dropped = 0
	date = ""
	if (match($0, / - .*$/)) {
		date = substr($0, RSTART + 3)
		sub(/[[:space:]]+$/, "", date)
	}
	news = news "<article class=\"bbx-news-card\">\n"
	news = news "  <div class=\"bbx-news-meta\">\n"
	release_url = sprintf("%s/releases/tag/%s", repository, esc($1))
	news = news sprintf("    <a class=\"bbx-news-version\" href=\"%s\"" \
		" target=\"_blank\" rel=\"noreferrer\">%s</a>\n", release_url, esc($1))
	if (count == 1) {
		news = news "    <span class=\"bbx-news-latest\">latest</span>\n"
	}
	if (date != "") {
		news = news sprintf("    <time class=\"bbx-news-date\">%s</time>\n", esc(pretty_date(date)))
	}
	news = news "  </div>\n"
	news = news "  <ul>\n"
	in_release = 1
	next
}
/^[-*] / && in_release {
	entry = substr($0, 3)
	if (shown < items) {
		news = news sprintf("    <li>%s</li>\n", codespans(esc(entry)))
		shown++
	} else {
		dropped++
	}
	next
}
END {
	close_release()
	# No release found: no section at all rather than an empty one
	if (count == 0) {
		exit 0
	}
	print "<div class=\"bbx-news\">"
	print "<div class=\"bbx-news-head\">"
	print "<h2>Releases</h2>"
	printf "<a class=\"bbx-news-all\" href=\"%s/blob/master/ChangeLog\" target=\"_blank\" rel=\"noreferrer\">Full ChangeLog</a>\n", repository
	print "</div>"
	print "<div class=\"bbx-news-grid\">"
	printf "%s", news
	print "</div>"
	print "</div>"
}
' "${CHANGELOG}" > "${OUTPUT}"

echo -e "\e[32mOK\e[0m ($(grep -c 'bbx-news-card' "${OUTPUT}") releases)"
