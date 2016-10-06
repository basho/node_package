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

RUNNER_BASE_DIR={{runner_base_dir}}
RUNNER_ETC_DIR={{runner_etc_dir}}
RUNNER_LOG_DIR={{runner_log_dir}}
RUNNER_LIB_DIR={{runner_lib_dir}}
RUNNER_PATCH_DIR={{runner_patch_dir}}
PIPE_DIR={{pipe_dir}}
RUNNER_GROUP={{runner_user}}
APP_VERSION={{app_version}}

# Variables needed to support creation of .pid files
# PID directory and pid file name of this app
# ex: /var/run/riak & /var/run/riak/riak.pid
RUN_DIR="/var/run" # for now hard coded unless we find a platform that differs
PID_DIR=$RUN_DIR/$RUNNER_SCRIPT
PID_FILE=$PID_DIR/$RUNNER_SCRIPT.pid

# Threshold where users will be warned of low ulimit file settings
# default it if it is not set
ULIMIT_WARN={{runner_ulimit_warn}}
if [ -z "$ULIMIT_WARN" ]; then
    ULIMIT_WARN=4096
fi

# Common config file on Debian-like systems
[ -r /etc/default/$RUNNER_SCRIPT ] && . /etc/default/$RUNNER_SCRIPT
# Common config file on RPM-like systems
[ -r /etc/sysconfig/$RUNNER_SCRIPT ] && . /etc/sysconfig/$RUNNER_SCRIPT

# Registered process to wait for to consider start a success
WAIT_FOR_PROCESS={{runner_wait_process}}

WHOAMI=`whoami`

# Echo to stderr on errors
echoerr() { echo "$@" 1>&2; }

# Extract the target node name from node.args
NAME_ARG=`egrep '^\-name' $RUNNER_ETC_DIR/vm.args 2> /dev/null`
if [ -z "$NAME_ARG" ]; then
    NODENAME=`egrep '^[ \t]*nodename[ \t]*=[ \t]*' $RUNNER_ETC_DIR/{{cuttlefish_conf}} 2> /dev/null | tail -1 | cut -d = -f 2`
    if [ -z "$NODENAME" ]; then
        echoerr "vm.args needs to have a -name parameter."
        echoerr "  -sname is not supported."
        exit 1
    else
        NAME_ARG="-name ${NODENAME# *}"
    fi
fi

# Learn how to specify node name for connection from remote nodes
NAME_PARAM="-name"
echo "$NAME_ARG" | grep '@.*' > /dev/null 2>&1
if [ "X$?" = "X0" ]; then
    NAME_HOST=`echo "${NAME_ARG}" | sed -e 's/.*\(@.*\)$/\1/'`
else
    NAME_HOST=""
fi

# Extract the target cookie
COOKIE_ARG=`grep '^\-setcookie' $RUNNER_ETC_DIR/vm.args 2> /dev/null`
if [ -z "$COOKIE_ARG" ]; then
    COOKIE=`egrep '^[ \t]*distributed_cookie[ \t]*=[ \t]*' $RUNNER_ETC_DIR/{{cuttlefish_conf}} 2> /dev/null | tail -1 | cut -d = -f 2`
    if [ -z "$COOKIE" ]; then
        echoerr "vm.args needs to have a -setcookie parameter."
        exit 1
    else
        COOKIE_ARG="-setcookie $COOKIE"
    fi
fi

# Extract the target net_ticktime
NET_TICKTIME_ARG=`grep '^\-kernel net_ticktime' $RUNNER_ETC_DIR/vm.args 2> /dev/null`
if [ -z "$NET_TICKTIME_ARG" ]; then
    NET_TICKTIME=`egrep '^[ \t]*erlang.distribution.net_ticktime[ \t]*=[ \t]*' $RUNNER_ETC_DIR/{{cuttlefish_conf}} 2> /dev/null | tail -1 | cut -d = -f 2`
    if [ -z "$NET_TICKTIME" ]; then
        NET_TICKTIME_ARG=""
    else
        NET_TICKTIME_ARG="-kernel net_ticktime $NET_TICKTIME"
    fi
fi

# Optionally specify a NUMA policy
NUMACTL_ARG="{{numactl_arg}}"
if [ -z "$NUMACTL_ARG" ]; then
    NUMACTL=""
# Confirms `numactl` is in the path and validates $NUMACTL_ARG
elif which numactl > /dev/null 2>&1 && numactl $NUMACTL_ARG ls /dev/null > /dev/null 2>&1
then
    NUMACTL="numactl $NUMACTL_ARG"
else
    echoerr "NUMACTL_ARG is specified in env.sh but numactl is not installed or NUMACTL_ARG is invalid."
    exit 1
fi

# Parse out release and erts info
START_ERL=`cat $RUNNER_BASE_DIR/releases/start_erl.data`
ERTS_VSN=${START_ERL% *}
APP_VSN=${START_ERL#* }

# Add ERTS bin dir to our path
ERTS_PATH=$RUNNER_BASE_DIR/erts-$ERTS_VSN/bin

# Setup command to control the node
NODETOOL="$ERTS_PATH/escript $ERTS_PATH/nodetool $NAME_ARG $COOKIE_ARG $NET_TICKTIME_ARG"
NODETOOL_LITE="$ERTS_PATH/escript $ERTS_PATH/nodetool"


## Are we using cuttlefish (http://github.com/basho/cuttlefish)
## for configuration. This needs to come after the $ERTS_PATH
## definition
CUTTLEFISH="{{cuttlefish}}"
if [ -z "$CUTTLEFISH" ]; then
    CUTTLEFISH_COMMAND_PREFIX=""
else
    CUTTLEFISH_COMMAND_PREFIX="$ERTS_PATH/escript $ERTS_PATH/cuttlefish -e $RUNNER_ETC_DIR -s $RUNNER_LIB_DIR -d {{platform_data_dir}}/generated.configs -c $RUNNER_ETC_DIR/{{cuttlefish_conf}}"
fi

# Ping node without stealing stdin
ping_node() {
    $NODETOOL ping < /dev/null
}

check_dir() {
    DIR="$1"

    if [ -z "$RUNNER_GROUP" ]; then
        # If RUNNER_GROUP is not set this is probably a test setup (devrel) and does
        # not need to be checked. Just make sure it's there.
        mkdir -p "$DIR"
        return 0
    fi

    if [ -d $DIR ] && [ -w $DIR]; then
        return 0
    else
        echoerr "Unable to access $DIR, nonexistent or permission denied"
        echoerr "Please run the following commands as root:"
        echoerr "mkdir -p $DIR"
        echoerr "chown root:$RUNNER_GROUP $DIR"
        echoerr "chmod 2775 $DIR"
        return 1
    fi
}

check_dirs() {
    for DIR in "$PID_DIR" "$RUNNER_LIB_DIR" "$RUNNER_LOG_DIR"; do
        if ! check_dir "$DIR"; then
            return 1
        fi
    done
    return 0
}

# Attempt to create a pid file for the process
# This function assumes the process is already up and running and can
#    respond to a getpid call.  It also assumes that two processes
#    with the same name will not be run on the machine
# Do not print any error messages as failure to create a pid file because
#    pid files are strictly optional
# This function should really only be called in a "start" function
#    you have been warned
create_pid_file() {
    # Validate a pid directory even exists
    if [ -w $PID_DIR ]; then
        # Grab the proper pid from getpid
        get_pid
        ES=$?
        if [ "$ES" -ne 0 ]; then
            return $ES
        else
            # Remove pid file if it already exists since we do not
            # plan for multiple identical runners on a single machine
            rm -f $PID_FILE
            echo $PID > $PID_FILE
            return 0
        fi
    else
        return 1
    fi
}

# Function to validate the node is down
node_down_check() {
    MUTE=`ping_node 2> /dev/null`
    if [ "$?" -eq 0 ]; then
        echoerr "Node is already running!"
        exit 1
    fi
}

# Function to validate the node is up
node_up_check() {
    MUTE=`ping_node 2> /dev/null`
    if [ "$?" -ne 0 ]; then
        echoerr "Node is not running!"
        exit 1
    fi
}

# Function to check if the config file is valid
check_config() {
    if [ -z "$CUTTLEFISH" ]; then
        # Note: we have added a parameter '-vm_args' to this. It
        # appears redundant but it is not! the erlang vm allows us to
        # access all arguments to the erl command EXCEPT '-args_file',
        # so in order to get access to this file location from within
        # the vm, we need to pass it in twice.
        CONFIG_ARGS=" -config $RUNNER_ETC_DIR/app.config -args_file $RUNNER_ETC_DIR/vm.args -vm_args $RUNNER_ETC_DIR/vm.args "
    else
        CONFIG_ARGS=`$CUTTLEFISH_COMMAND_PREFIX generate`
        if [ "$?" -ne 0 ]; then
            echoerr "Error generating config with cuttlefish"
            echoerr "  run \`$RUNNER_SCRIPT config generate -l debug\` for more information."
            exit 1
        fi
    fi

    MUTE=`$NODETOOL_LITE chkconfig $CONFIG_ARGS`
    if [ "$?" -ne 0 ]; then
        echoerr "Error reading $CONFIG_ARGS"
        exit 1
    fi
    echo "config is OK"
    echo $CONFIG_ARGS
}

# Function to check if ulimit is properly set
check_ulimit() {
    if [ -n "$ULIMIT_WARN" ]; then
        ULIMIT_F=`ulimit -n`
        if [ "$ULIMIT_F" -lt $ULIMIT_WARN ]; then
            echo "!!!!"
            echo "!!!! WARNING: ulimit -n is ${ULIMIT_F}; ${ULIMIT_WARN} is the recommended minimum."
            echo "!!!!"
        fi
    fi
}

# Set the PID global variable, return 1 on error
get_pid() {
    PID=`$NODETOOL getpid < /dev/null`
    if [ "$?" -ne 0 ]; then
        echo "Node is not running!"
        return 1
    fi

    # don't allow empty or init pid's
    if [ -z $PID ] || [ "$PID" -le 1 ]; then
        return 1
    fi

    return 0
}
