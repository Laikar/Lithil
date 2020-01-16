#!/bin/sh

PROG=$(basename $0)

USER="lithil"
PROGRAM_PATH="/opt/lithil"
DATA_PATH="$PROGRAM_PATH/data"
LOG_FILE="$PROGRAM_PATH/lithil.log"

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
    echo "Starting..."
    clear_logs
    nohup ${PYTHON} ${PROGRAM_PATH}/Main.py &
    echo "Started"

}
stop_bot(){
    echo "Stopping..."
    PID=$(pgrep -u ${USER} python)
    kill -s 15 ${PID}
    sleep 2
    echo "Stopped"

}

restart_bot(){
    stop_bot
    start_bot
}
update_bot(){
    if [ pgrep -u ${USER} python ]; then
        stop_bot
    fi
    git -C "$PROGRAM_PATH" pull

}

show_logs(){
    less +F ${LOG_FILE}
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

        start_bot

        ;;
    stop)

        stop_bot
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