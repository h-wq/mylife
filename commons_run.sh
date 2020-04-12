#!/bin/bash

function usage() {
    echo "Usage: "
    echo "  run.sh start [env]"
    echo "  run.sh restart [env]"
    echo "  run.sh status"
    echo "  run.sh stop"
}

source /etc/profile
cd target
PARAM_COUNT=$#
if [ $PARAM_COUNT -lt 3 ]; then
    usage
    exit 1
fi

NAME="$1"
APP="$2"
COMMAND="$3"
ENV="$4"

git checkout $env

if [ "$ENV" != "" ]; then
    shift 4
    OTHER_OPTS="$@"  #other opts, like jvm opts
fi

PID_FILE=RUNNING_PID
STATUS_RUNNING="running"
STATUS_STOPPED="stopped"

if [ "$ENV" == "online" ] || [[ "$ENV" = *-online ]]; then
    isProd=1
else
    isProd=0
fi

function status() {
    if [ -f $PID_FILE ]; then
        pid=$(< "$PID_FILE")
        if [ -z "`ps -A -o pid | grep -w ${pid}`" ]; then
            cstatus="${STATUS_STOPPED}"
        else
            cstatus="${STATUS_RUNNING}"
        fi
    else
        cstatus="$STATUS_STOPPED"
    fi
}

function start() {
    status
    if [ "$cstatus" = "$STATUS_RUNNING" ]; then
        echo "$APP is already running"
        exit 0
    fi

    if [ -z $ENV ]; then
        usage
        exit 1
    fi

    NEW_RELIC_OPT=""
    if [ -f newrelic.yml ] && [ -f newrelic/newrelic.jar ]; then
        NEW_RELIC_OPT="-Dnewrelic.environment=$ENV -Dnewrelic.config.file=newrelic.yml -javaagent:newrelic/newrelic.jar"
    fi

    nohup java $OTHER_OPTS $NEW_RELIC_OPT -jar $NAME.jar > /project/logs/mylife.log 2>&1 &
    new_pid=$!
    echo $new_pid > RUNNING_PID
    echo "$APP is started, pid = $new_pid"
}

function stop() {
    for i in {0..30}
    do
        status
        if [ "$cstatus" = "$STATUS_RUNNING" ]; then
            echo "stopping $APP, pid = $pid"
            if [ $i -lt 15 ]; then
                kill $pid
            else
                kill -9 $pid
            fi
            sleep 1
        else
            if [ -f $PID_FILE ]; then
                rm $PID_FILE
            fi
            echo "$APP is stopped"
            return 0
        fi
    done
    echo "ERROR: $APP cannot be killed in $count seconds"
    exit 1
}

function restart() {
    stop && start
}

case "$COMMAND" in
    status)
        status
        if [ "$cstatus" = "$STATUS_RUNNING" ]; then
            echo "$APP is running"
        else
            echo "$APP is stopped"
        fi
        ;;
    stop)
        stop
        ;;
    start)
        start
        ;;
    restart)
        restart
        ;;
    *)
        ENV=$COMMAND
        COMMAND="start"
        start
        ;;
esac
