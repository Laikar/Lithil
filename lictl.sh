#!/bin/sh

PROG=$(basename $0)

PROGRAM_PATH="/opt/lithil"
DATA_PATH="$PROGRAM_PATH/data"
PID_FILE="$DATA_PATH/bot.pid"

PYTHON=$(which python3.8)

help_message(){
    cat <<EOF
Usage ${PROG} [action]

Actions:
    start:
        Starts the bot
    stop:
        Stops the bot
    restart:
        Restarts the bot
    update:
        Pulls the latest github commit into the local repo.
EOF
}

start(){
    ${PYTHON} ${PROGRAM_PATH}/Main.py &
    echo $! > ${DATA_PATH}/bot.pid
}
stop(){
    PID=$(cat ${PID_FILE})
    kill -SIGTERM -${PID}
    rm ${PID_FILE}
}
restart(){
    stop
    start
}
update(){
    if test -f "$PID_FILE"; then
        stop
    fi
    git -C "$PROGRAM_PATH" pull

}

if [ ! -e "$PYTHON" ]; then
  echo "ERROR: Python not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install python"
  exit 1
fi

COMMAND=$1

case "$COMMAND" in
    "start")
        start
        ;;
    "stop")
        stop
        ;;
    "restart")
        restart
        ;;
    "update")
        update
        ;;
esac
exit 0