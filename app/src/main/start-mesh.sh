#!/usr/bin/env bash

# Resolve any links in $0 to get the real path
SELF="$0"
while [ -h "$SELF" ]; do
    LSLD=$(ls -ld "$SELF")
    LINK=$(expr "$LSLD" : '.*-> \(.*\)$')
    if expr "$LINK" : '/.*' > /dev/null; then
        SELF="$LINK"
    else
        SELF=$(dirname "$SELF")/"$LINK"
    fi
done

while [[ $# -gt 0 ]]
do
_KEY="$1"

case $_KEY in
    -fg|run)
    RUN=1
    ;;
    *)
    echo Unsupported argument: $1
    exit 1
    ;;
esac
shift
done

# BIN_DIR & INST_DIR will be fully qualified, not relative
pushd "$(dirname "$0")" > /dev/null || return

BIN_DIR=$(pwd)
export BIN_DIR

popd > /dev/null || return
INST_DIR=$(dirname "$BIN_DIR")

export INST_DIR

source $BIN_DIR/set-jre-home.sh &&
    source $BIN_DIR/set-mesh-home.sh &&
    source $BIN_DIR/set-mesh-user.sh
if [ $? -ne 0 ]; then
    # One of the setup scripts failed. Don't try to start any processes
    echo -e "\nStartup has been aborted"
    exit 1
fi

if [ "$RUN" = "1" ]; then
    LAUNCH_CMD=run
else
    LAUNCH_CMD=start
fi

if [ -z "$MESH_USER" ] || [ "$(id -un)" == "$MESH_USER" ]; then
    echo "Starting Atlassian Bitbucket Mesh as the current user"

    "$BIN_DIR"/_start-mesh.sh $LAUNCH_CMD

elif [ $UID -ne 0 ]; then
    echo Bitbucket Mesh has been installed to run as "$MESH_USER". Use "sudo -u $MESH_USER $0"
    echo to start as that user.
    exit 1
else
    echo "Starting Bitbucket Mesh as dedicated user $MESH_USER"

    if [ -x "/sbin/runuser" ]; then
        SU="/sbin/runuser"
    else
        SU="su"
    fi

    $SU -l "$MESH_USER" <<EOS
        # Copy over the environment, the poor man's way
        export BIN_DIR="$BIN_DIR"
        export MESH_HOME="$MESH_HOME"
        export INST_DIR="$INST_DIR"
        export JAVA_BINARY="$JAVA_BINARY"
        export JAVA_KEYSTORE="$JAVA_KEYSTORE"
        export JAVA_KEYSTORE_PASSWORD="$JAVA_KEYSTORE_PASSWORD"
        export JAVA_TRUSTSTORE="$JAVA_TRUSTSTORE"
        export JMX_PASSWORD_FILE="$JMX_PASSWORD_FILE"
        export JMX_REMOTE_AUTH="$JMX_REMOTE_AUTH"
        export JMX_REMOTE_PORT="$JMX_REMOTE_PORT"
        export JRE_HOME="$JRE_HOME"
        export JVM_MAXIMUM_MEMORY="$JVM_MAXIMUM_MEMORY"
        export JVM_MINIMUM_MEMORY="$JVM_MINIMUM_MEMORY"
        export JVM_SUPPORT_RECOMMENDED_ARGS="$JVM_SUPPORT_RECOMMENDED_ARGS"
        export RMI_SERVER_HOSTNAME="$RMI_SERVER_HOSTNAME"
        export JMX_REMOTE_RMI_PORT="$JMX_REMOTE_RMI_PORT"
        export LANG="$LANG"

        # Change working directory
        cd $PWD

        $BIN_DIR/_start-mesh.sh $LAUNCH_CMD

EOS
fi