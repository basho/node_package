# -*- tab-width:4;indent-tabs-mode:nil -*-
# ex: ts=4 sw=4 et

RUNNER_SCRIPT_DIR={{runner_script_dir}}
RUNNER_SCRIPT=${0##*/}

RUNNER_BIN_DIR={{runner_bin_dir}}
RUNNER_RUN_DIR={{runner_run_dir}}
RUNNER_ETC_DIR={{runner_etc_dir}}
RUNNER_LOG_DIR={{runner_log_dir}}
PIPE_DIR={{pipe_dir}}
RUNNER_USER={{runner_user}}

# Extract the target node name from node.args
NAME_ARG=`grep '\-[s]*name' $RUNNER_ETC_DIR/vm.args`
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
COOKIE_ARG=`grep '\-setcookie' $RUNNER_ETC_DIR/vm.args`
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

# Function to su into correct user
function check_user() {
    # Validate that the user running the script is the owner of the
    # RUN_DIR.
    if [ "$RUNNER_RUN_DIR" -a ! -O "$RUNNER_RUN_DIR" ]; then
        if [ "$LOGNAME" == "root" ]; then
            su - $RUNNER_USER $RUNNER_SCRIPT_DIR/$RUNNER_SCRIPT -- $@
            exit $?
        else
            echo "You must be $RUNNER_USER or root to invoke this script!"
            exit 1
        fi
    fi
}

# Function to validate the node is down
function node_down_check() {
    RES=`$NODETOOL ping`
    if [ "$RES" = "pong" ]; then
        echo "Node is already running!"
        exit 1
    fi
}

# Function to validate the node is up
function node_up_check() {
    RES=`$NODETOOL ping`
    if [ "$RES" != "pong" ]; then
        echo "Node is not running!"
        exit 1
    fi
}