#!/bin/sh

# $FreeBSD$
#
# PROVIDE: {{package_install_name}}
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name={{package_install_name}}
command={{platform_base_dir}}/%ERTS_PATH%/bin/beam.smp
rcvar={{package_install_name}}_enable
start_cmd="{{platform_bin_dir}}/${name} start"
stop_cmd="{{platform_bin_dir}}/${name} stop"
pidfile="/var/run/${name}/${name}.pid"

load_rc_config $name
run_rc_command "$1"
