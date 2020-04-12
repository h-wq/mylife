#!/bin/bash

command=$1
service=$2
env=$3
index=$4

if [ "$env" == "online" ] || [[ "$env" = *-online ]]; then
    isProd=1
else
    isProd=0
fi

function usage() {
    echo "Usage: $0 command service env index"
    echo "       commands: status|restart|start|stop "
}

function parse_locations() {
    local _service=$1
    local _env=$2
    if [ "$_service" = "" ] || [ "$_env" == "" ]; then
        usage
        exit 1
    fi
    local _location_file=deploy/${_env}/locations
    if [ ! -s $_location_file ]; then
        echo "location file not found at $_location_file"
        usage
        exit 1
    fi

    local _fields=( $(awk "/^$_service:/" $_location_file) )
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

function status() {
    smart_run "
        cd $remote_path &&
        ./run.sh status
    "
}

function restart() {
    smart_run "
        cd $remote_path &&
        ./run.sh restart $env
    "
}

function start() {
    smart_run "
        cd $remote_path &&
        ./run.sh start $env
    "
}

function stop() {
    smart_run "
        cd $remote_path &&
        ./run.sh stop $env
    "
}

parse_locations $service $env $index
if [ "$host" == "" ]; then
    echo "skip deploy to host $index!"
    exit 0
fi

case "$command" in
    status)
        status
        ;;
    restart)
        restart
        ;;
    stop)
        stop
        ;;
    start)
        start
        ;;
    *)
        usage
        ;;
esac
