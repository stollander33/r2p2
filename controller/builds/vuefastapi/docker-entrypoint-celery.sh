#!/bin/bash
set -e

echo "starting docker-entrypoint-celery... ¿who am i? $(whoami)"

if [[ ! -t 0 ]]; then
    /bin/bash /etc/banner.sh
fi

DEVID=$(id -u $APIUSER)
if [ "$DEVID" != "$CURRENT_UID" ]; then
    echo "Fixing uid of user $APIUSER from $DEVID to $CURRENT_UID..."
    # usermod -u $CURRENT_UID $APIUSER
fi

GROUPID=$(id -g $APIUSER)
if [ "$GROUPID" != "$CURRENT_GID" ]; then
    echo "Fixing gid of user $APIUSER from $GROUPID to $CURRENT_GID..."
    # groupmod -og $CURRENT_GID $APIUSER
fi

# fix permissions of flower db dir
if [ -d "$FLOWER_DBDIR" ]; then
    echo "> chown -R $APIUSER $FLOWER_DBDIR"
    chown -R $APIUSER $FLOWER_DBDIR
fi

# fix permissions of celery beat pid dir
if [ -d "/pids" ]; then
    echo "> chown -R $APIUSER /pids"
    chown -R $APIUSER /pids
fi

#echo "Waiting for services"
#HOME=$CODE_DIR su -p $APIUSER -c 'restapi wait'

# echo "Requested command: $@"

# $@
# exit 0
echo "Development mode"
echo "I'm $(whoami)"
init_file="/tmp/initialized_venv"

if [[ "${FORCE_INSTALL}" == '1' ]]; then
    if [[ -f "${init_file}" ]]; then
        rm -f ${init_file}
    fi
fi

if [[ ! -f "${init_file}" ]]; then
    echo "Installing app first time..."
    poetry config virtualenvs.create true
    poetry install 
    #poetry run python app/backend_pre_start.py
    # Run migrations
    #poetry run alembic -c alembic.ini upgrade head
    # Create initial data in DB
    #poetry run python app/initial_data.py                      
    touch ${init_file}
fi
    

if [[ "$1" == 'shell' ]]; then
    ##CUSTOM COMMAND
    echo "Requested shell: waiting..."
    sleep infinity            
else
    if [[ "$1" == 'worker' ]]; then
        echo "Requested celery: starting..."
        poetry run  celery --app app.core.celery_app  worker -Q main-queue  -E --concurrency=1 --pool=prefork -Ofair -n api-%h
    fi
    if [[ "$1" == 'beat' ]]; then
        echo "Requested beat: starting..."
        poetry run celery --app app.core.celery_app \
            beat --pidfile /tmp/celerybeat.pid \
            --loglevel DEBUG \
            --max-interval '30' \
            --scheduler  redbeat.RedBeatScheduler
    fi
    if [[ "$1" == 'flower' ]]; then
        echo "Requested flower: starting..."
        poetry run celery --app app.core.celery_app \
                flower --basic_auth=flower:D3vMode!\
                --port=5555 --persistent \
                --state_save_interval=10000 \
                --db=/var/flower/flower \
                -n flower_monitor

    else
        exec "$@" &
        pid="$!"
        # no success with wait...
        # trap "echo Sending SIGTERM to process ${pid} && kill -SIGTERM ${pid} && wait {$pid}" INT TERM
        trap "echo Sending SIGTERM to process ${pid} && kill -SIGTERM ${pid} && sleep 5" TERM
        trap "echo Sending SIGINT to process ${pid} && kill -SIGINT ${pid} && sleep 5" INT
        wait
    fi
fi




#exec gosu $APIUSER $@ &
#pid="$!"
# no success with wait...
# trap "echo Sending SIGTERM to process ${pid} && kill -SIGTERM ${pid} && wait {$pid}" INT TERM
#trap "echo Sending SIGTERM to process ${pid} && kill -SIGTERM ${pid} && sleep 5" TERM
#trap "echo Sending SIGINT to process ${pid} && kill -SIGINT ${pid} && sleep 5" INT
#wait
