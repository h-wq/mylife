#!/bin/bash
env=$1
MODULE=$2
ALL_MODULES=$3

source /etc/profile
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
