#!/bin/bash
trap "exit" INT
MODULE=$1
env=$2
index=$3

function usage() {
    echo "Usage: $0 module env index"
    if [ -n "$ALL_MODULES" ]; then
        echo "       modules: [${ALL_MODULES[@]}] "
    fi
}

if [ "$MODULE" == "" ] || [ "$env" == "" ] || [ "$index" == "" ]; then
    usage
    exit 1
fi

SERVICE_FILE=deploy/services
if [ ! -s "$SERVICE_FILE" ]; then
    echo "services file not found at $SERVICE_FILE"
    exit 1
fi

ALL_MODULES=( $(cat $SERVICE_FILE) )

if ! [ -d $MODULE ] && [ "$MODULE" != "mylife" ]; then
    usage
    exit 1
fi

function parse_locations() {
    local _module=$1
    local _env=$2
    local _location_file=deploy/${_env}/locations
    if [ ! -s $_location_file ]; then
        echo "location file not found at $_location_file"
        exit 1
    fi

    local _fields=( $(awk "/^$_module:/" $_location_file) )
    remote_path=${_fields[1]}
    hosts=(${_fields[@]:2})
    host_count=${#hosts[*]}

    if [[ "$index" =~ ^[0-9]+$ ]]; then
        if [[ $index -lt $host_count ]]; then
            host=${hosts[$index]}
        else
            echo "invalid host index $index, should be less than $host_count"
            exit 1
        fi
    elif [[ ${hosts[*]} =~ "$index" ]]; then
        host=$index
    else
        echo "invalid hostname $index"
        host=""
    fi
}

parse_locations $MODULE $env

if [ "$host" == "" ]; then
    echo "skip deploy to host $index!"
    exit 0
fi

function smart_run() {
    local _command=$1
    local _hostname=`hostname`
    if [ "$_hostname" == "$host" ] || [ "$host" == "localhost" ] ; then
        eval "$_command"
    else
        ssh root@$host /bin/bash <<EOF
        $_command
EOF
    fi
}

smart_run "
        cd $remote_path &&
        ./build.sh $env $MODULE $ALL_MODULES
    "
