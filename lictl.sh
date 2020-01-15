#!/bin/sh

PROG=$(basename $0)

PROGRAM_PATH="/opt/lithil"
DATA_PATH="$PROGRAM_PATH/data"
PID_FILE="$DATA_PATH/bot.pid"
NOHUP_LOGS="$PROGRAM_PATH/nohup.out"
LOG_FILE="$PROGRAM_PATH/logs.txt"

PYTHON=$(which ${PROGRAM_PATH}/venv/bin/python)

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

start_bot(){
    clear_logs
    nohup ${PYTHON} -u ${PROGRAM_PATH}/Main.py > ${LOG_FILE} &
    echo $! > ${DATA_PATH}/bot.pid

}
stop_bot(){
    PID=$(cat ${PID_FILE})
    kill -s 15 ${PID}
    rm ${PID_FILE}
}

restart_bot(){
    stop_bot
    start_bot
}
update_bot(){
    if test -f "$PID_FILE"; then
        stop_bot
    fi
    git -C "$PROGRAM_PATH" pull

}

show_logs(){
    cat ${LOG_FILE}
}
clear_logs(){
    rm ${LOG_FILE}
}

if [ ! -e "$PYTHON" ]; then
  echo "ERROR: Python not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install python"
  exit 1
fi

COMMAND=$1

case "$COMMAND" in
    start)
        echo "Starting..."
        start_bot
        echo "Started"
        ;;
    stop)
        echo "Stopping..."
        stop_bot
        echo "Stopped"
        ;;
    restart)
        echo "Restarting..."
        restart_bot
        echo "Restarted"
        ;;
    update)
        echo "Updating..."
        update_bot
        echo "Updated, you should run sudo make update on $PROGRAM_PATH"
        ;;
    logs)
        show_logs
        ;;
esac
exit 0