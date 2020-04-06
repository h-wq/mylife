#!/bin/bash
trap "exit" INT
MODULE=$1
env=$2
index=$3

parse_locations $MODULE $env

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

if [ "$host" == "" ]; then
    echo "skip deploy to host $index!"
    exit 0
fi

SERVICE_FILE=deploy/services
if [ ! -s "$SERVICE_FILE" ]; then
    echo "services file not found at $SERVICE_FILE"
    exit 1
fi

ALL_MODULES=( $(cat $SERVICE_FILE) )

if [ "$MODULE" == "" ]; then
    MODULE="all"
fi
if [ "$MODULE" != "all" ] && ! [ -d $MODULE ]; then
    usage
    exit 1
fi

function usage() {
    echo "Usage: $0 [all ${ALL_MODULES[@]}]"
}

smart_run ""

function smart_run() {
    ssh root@$host /bin/bash <<EOF
EOF
}

cd $remote_path
git checkout $env
git pull

echo "
#######################################

clean and install all modules

#######################################
"
mvn clean install -DskipTests=true
ret=$?
if [ $ret != 0 ]; then
    echo ""
    echo "Maven install failed"
    echo ""
    exit 1
fi

if [ "$MODULE" == "all" ]; then
    MODULES=( "${ALL_MODULES[@]}" )
else
    MODULES=("$MODULE")
fi

for service in ${MODULES[@]}; do
    echo "
#######################################

packaging $service

#######################################
"
    cd $service
    mvn clean package -DskipTests=true
    ret=$?
    if [ $ret != 0 ]; then
        echo ""
        echo "Package $service failed"
        echo ""
        exit 1
    fi
    cd ..
done
