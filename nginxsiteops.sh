#!/bin/bash

set -e

: ${NOPROMPT=false}
: ${VERBOSE=false}

NL=$'\n'

msg() {
	echo ">>> $*" >&2
}

run() {
   	msg "Running: $@"
	"$@"
}

cmd_site_serve() {
	run mkdocs serve
}

cmd_site_build() {
	run mkdocs build
}

cmd_rclone_config() {
    if test -n "$NGINX_SHARE_URL"; then
        read ACCOUNT SHARE <<< $(echo "$NGINX_SHARE_URL" | sed -E 's|https://([^.]+)\.file\.core\.windows\.net/([^/]+)|\1 \2|')
        msg "Running: rclone config (URL)"
        rclone config create remote azurefiles env_auth true account "$ACCOUNT" share_name "$SHARE" > /dev/null
    elif test -n "$NGINX_SHARE_SAS_URL"; then
    	msg "Running: rclone config (SAS URL)"
    	rclone config create remote azurefiles sas_url "$NGINX_SHARE_SAS_URL" > /dev/null
    else
        msg "E: Missing NGINX_SHARE_URL or NGINX_SHARE_SAS_URL"
        exit 1
    fi
}

cmd_rclone_sync() {
	SITE_NAME=${1-default}
	msg "Syncing to remote site: $SITE_NAME"
	run rclone sync -v --filter-from rclone-filter.txt site/. remote:sites/$SITE_NAME/.
	run rclone sync -v templates/. remote:templates/.
}

cmd_help() {
	msg "Usage: $0 <command> [options...] [args...]"
	msg "Options":
	msg "  --help,-h                  - Show this help"
	msg "  --no-prompt                - Do not ask for confirmation"
	msg "  --verbose, -v              - Show detailed output"
	msg "Commands:"
	msg "  site-serve                 - Site: serve"
	msg "  site-build                 - Site: build"
	msg "  rclone-config              - Rclone: config"
	msg "  rclone-sync [site_name]    - Rclone: sync"
	exit $1
}

OPTIONS=$(getopt -o hqv -l help -l no-prompt -l verbose -- "$@")
if test $? -ne 0; then
	cmd_help 1
fi

eval set -- "$OPTIONS"

while true; do
	case "$1" in
		-h|--help)
			cmd_help 0
			;;			
		--no-prompt)
			NOPROMPT=true
			shift
			;;
		-v|--verbose)
			VERBOSE=true
			shift
			;;
		--)
			shift
			break
			;;
		*)
			msg "E: Invalid option: $1"
			cmd_help 1
			;;
	esac
done

if test $# -eq 0; then
	msg "E: Missing command"
	cmd_help 1
fi

case "$1" in
	site-serve)
		shift
		cmd_site_serve "$@"
		;;
	site-build)
		shift
		cmd_site_build "$@"
		;;
	rclone-config)
		shift
		cmd_rclone_config "$@"
		;;
	rclone-sync)
		shift
		cmd_rclone_sync "$@"
		;;
	*)
		msg "E: Invalid command: $1"
		cmd_help 1
		;;
esac
