#!/bin/sh
# -*- tab-width:4;indent-tabs-mode:nil -*-
# ex: ts=4 sw=4 et

# installed by node_package (github.com/basho/node_package)

# /bin/sh on Solaris is not a POSIX compatible shell, but /usr/bin/ksh is.
if [ `uname -s` = 'SunOS' -a "${POSIX_SHELL}" != "true" ]; then
    POSIX_SHELL="true"
    export POSIX_SHELL
    # To support 'whoami' add /usr/ucb to path
    PATH=/usr/ucb:$PATH
    export PATH
    exec /usr/bin/ksh $0 "$@"
fi
unset POSIX_SHELL # clear it so if we invoke other scripts, they run as ksh as well

RUNNER_SCRIPT_DIR={{runner_script_dir}}
RUNNER_SCRIPT=${0##*/}

RUNNER_BIN_DIR={{runner_bin_dir}}
RUNNER_RUN_DIR={{runner_run_dir}}
RUNNER_ETC_DIR={{runner_etc_dir}}
RUNNER_LOG_DIR={{runner_log_dir}}
PIPE_DIR={{pipe_dir}}
RUNNER_USER={{runner_user}}
APP_VERSION={{app_version}}

# Threshold where users will be warned of low ulimit file settings
ULIMIT_WARN=4096

WHOAMI=$(whoami)

# Extract the target node name from node.args
NAME_ARG=`egrep '^\-s?name' $RUNNER_ETC_DIR/vm.args`
if [ -z "$NAME_ARG" ]; then
    echo "vm.args needs to have either -name or -sname parameter."
    exit 1
fi

# Learn how to specify node name for connection from remote nodes
echo "$NAME_ARG" | grep '^-sname' > /dev/null 2>&1
if [ "X$?" = "X0" ]; then
    NAME_PARAM="-sname"
    NAME_HOST=""
else
    NAME_PARAM="-name"
    echo "$NAME_ARG" | grep '@.*' > /dev/null 2>&1
    if [ "X$?" = "X0" ]; then
        NAME_HOST=`echo "${NAME_ARG}" | sed -e 's/.*\(@.*\)$/\1/'`
    else
        NAME_HOST=""
    fi
fi

# Extract the target cookie
COOKIE_ARG=`grep '^\-setcookie' $RUNNER_ETC_DIR/vm.args`
if [ -z "$COOKIE_ARG" ]; then
    echo "vm.args needs to have a -setcookie parameter."
    exit 1
fi

# Parse out release and erts info
START_ERL=`cat $RUNNER_BIN_DIR/releases/start_erl.data`
ERTS_VSN=${START_ERL% *}
APP_VSN=${START_ERL#* }

# Add ERTS bin dir to our path
ERTS_PATH=$RUNNER_BIN_DIR/erts-$ERTS_VSN/bin

# Setup command to control the node
NODETOOL="$ERTS_PATH/escript $ERTS_PATH/nodetool $NAME_ARG $COOKIE_ARG"
NODETOOL_LITE="$ERTS_PATH/escript $ERTS_PATH/nodetool"

# Ping node without stealing stdin
ping_node() {
    $NODETOOL ping < /dev/null
}

# Function to su into correct user
check_user() {
    # Validate that the user running the script is the owner of the
    # RUN_DIR.

    if ([ "$RUNNER_USER" ] && [ "x$WHOAMI" != "x$RUNNER_USER" ]); then
        type sudo > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "sudo doesn't appear to be installed and your EUID isn't $RUNNER_USER" 1>&2
            exit 1
        fi
        echo "Attempting to restart script through sudo -H -u $RUNNER_USER"
        exec sudo -H -u $RUNNER_USER -i $RUNNER_SCRIPT_DIR/$RUNNER_SCRIPT $@
    fi
}

# Function to validate the node is down
node_down_check() {
    RES=`ping_node`
    if [ "$RES" = "pong" ]; then
        echo "Node is already running!"
        exit 1
    fi
}

# Function to validate the node is up
node_up_check() {
    RES=`ping_node`
    if [ "$RES" != "pong" ]; then
        echo "Node is not running!"
        exit 1
    fi
}

# Function to check if the config file is valid
check_config() {
    RES=`$NODETOOL_LITE chkconfig $RUNNER_ETC_DIR/app.config`
    if [ "$RES" != "ok" ]; then
        echo "Error reading $RUNNER_ETC_DIR/app.config"
        echo $RES
        exit 1
    fi
    echo "config is OK"
}

# Function to check if ulimit is properly set
check_ulimit() {

    ULIMIT_F=`ulimit -n`
    if [ "$ULIMIT_F" -lt $ULIMIT_WARN ]; then
        echo "!!!!"
        echo "!!!! WARNING: ulimit -n is ${ULIMIT_F}; ${ULIMIT_WARN} is the recommended minimum."
        echo "!!!!"
    fi
}
