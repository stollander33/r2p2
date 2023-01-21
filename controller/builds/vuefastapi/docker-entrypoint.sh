#!/bin/bash
set -e

echo "starting docker-entrypoint.sh in $(pwd)..."

if [[ ! -t 0 ]]; then
    /bin/bash /etc/banner.sh
fi

DEVID=$(id -u ${APIUSER})

if [[ "${DEVID}" != "${CURRENT_UID}" ]]; then
    echo "> Fix uid of user..."
    echo "Fixing uid of user ${APIUSER} from ${DEVID} to ${CURRENT_UID}..."
    #usermod -u ${CURRENT_UID} ${APIUSER}
fi

GROUPID=$(id -g ${APIUSER})
if [[ "${GROUPID}" != "${CURRENT_GID}" ]]; then
    echo "> Fix gid of user..."
    echo "Fixing gid user ${APIUSER} from ${GROUPID} to ${CURRENT_GID}..."
    #groupmod -og ${CURRENT_GID} ${APIUSER}
fi

if [[ -z APP_MODE ]]; then
    echo "> Mode: development"
    APP_MODE="development"
fi

if [[ -d "${APP_SECRETS}" ]]; then

    echo "> Fix permissions in secrets"
    echo "$ chown -R ${APIUSER} ${APP_SECRETS}"
    chown -R ${APIUSER} ${APP_SECRETS}

    echo "> Fix modes in secrets"
    echo "$ chmod u+w ${APP_SECRETS}"
    chmod u+w ${APP_SECRETS}
fi

# fix permissions on the main development folder
echo "> Fix permissions in ${CODE_DIR}"
echo "$ chown ${APIUSER} ${CODE_DIR}"
chown ${APIUSER} ${CODE_DIR}

if [[ -d "${CERTDIR}" ]]; then
    echo "chown -R ${APIUSER} ${CERTDIR}"
    chown -R ${APIUSER} ${CERTDIR}
fi

if [[ "${CRONTAB_ENABLE}" == "1" ]]; then
    if [[ "$(find /etc/cron.rapydo/ -name '*.cron')" ]]; then
        echo "Enabling cron..."

        # sed is needed to add quotes to env values and to escape quotes ( ' -> \\' )
        env | sed "s/'/\\'/" | sed "s/=\(.*\)/='\1'/" > /etc/rapydo-environment

        touch /var/log/cron.log
        chown ${APIUSER} /var/log/cron.log
        # Adding an empty line to cron log
        echo "" >> /var/log/cron.log
        cron
        # .cron extension is to avoid accidentally including backup files from editors
        cat /etc/cron.rapydo/*.cron | crontab -u ${APIUSER} -
        crontab -u ${APIUSER} -l
        echo "Cron enabled"
        # -n 1 will only print the empty line previously added
        tail -n 1 -f /var/log/cron.log &
    else
        echo "Found no cronjob to be enabled, skipping crontab setup"
    fi
fi

if [[ -d "${APP_SECRETS}" ]]; then
    init_file="${APP_SECRETS}/initialized"        
else
    init_file="/tmp/initialized_venv"
fi


if [[ "${FORCE_INSTALL}" == '1' ]]; then
    if [[ -f "${init_file}" ]]; then
        rm -f ${init_file}
    fi
fi

if [[ ! -f "${init_file}" ]]; then
    echo "Installing app first time..."
    poetry config virtualenvs.create true
    poetry install 
    poetry run python app/backend_pre_start.py
    # Run migrations
    poetry run alembic -c alembic.ini upgrade head
    # Create initial data in DB
    poetry run python app/initial_data.py                      
    touch ${init_file}
fi
    

if [[ "$1" == 'custom' ]]; then
    ##CUSTOM COMMAND
    echo "Requested custom command:"
    echo "\$ $@"
    $@
else
    ##NORMAL MODES
    echo "Backend server is ready to be launched"

    if [[ ${ALEMBIC_AUTO_MIGRATE} == "1" ]] && [[ ${AUTH_SERVICE} == "sqlalchemy" ]]; then

        if [[ ! -d "${PROJECT_NAME}/migrations" ]]; then
            echo "Skipping migrations check, ${PROJECT_NAME}/migrations does not exist";
        elif [[ $(HOME=$CODE_DIR su -p ${APIUSER} -c 'alembic current 2>&1 | tail -1 | grep "head"') ]]; then
            echo "All database migrations are already installed";
        else
            HOME=$CODE_DIR su -p ${APIUSER} -c 'restapi wait'

            # Please note that errors in the upgrade will not make fail the server startup due to the || true statement
            HOME=$CODE_DIR su -p ${APIUSER} -c 'alembic current || true';
            HOME=$CODE_DIR su -p ${APIUSER} -c 'alembic upgrade head || true';

            echo "Migration completed";
        fi

    fi

    if [[ "${APP_MODE}" == 'production' ]]; then

        echo "Waiting for services"
        HOME=$CODE_DIR su -p ${APIUSER} -c 'restapi wait'

        echo "Ready to launch production gunicorn"
        mygunicorn

    elif [[ "$APP_MODE" == 'test' ]]; then

        echo "Testing mode"

        if [[ "${API_AUTOSTART}" == "1" ]]; then
            HOME=$CODE_DIR su -p ${APIUSER} -c 'restapi wait'
            HOME=$CODE_DIR su -p ${APIUSER} -c 'restapi launch'
        fi

    else
        echo "Development mode"
        echo "I'm $(whoami)"
        if [[ "$1" == 'shell' ]]; then
            ##CUSTOM COMMAND
            echo "Requested shell: waiting..."
            sleep infinity            
        fi                
        if [[ "$1" == 'api' ]]; then
            echo "Requested api: starting..."
            poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload   
        fi                
        if [[ "$1" == 'worker' ]]; then
            echo "Requested celery: starting..."
            poetry run  celery --app app.core.celery_app  worker \            
                                -Q main-queue -E \
                                --concurrency=1 \
                                --pool=prefork \
                                -Ofair \
                                -n api-%h
        fi                      
                  
        if [[ "$1" == 'flower' ]]; then
            echo "Requested flower: starting..."
            poetry run celery --app app.core.celery_app beat \
                --pidfile /tmp/celerybeat.pid \
                --loglevel DEBUG \
                --max-interval '30' \
                --scheduler redbeat.RedBeatScheduler
        fi                                        
        # poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000
        # sleep infinity
    fi
    sleep infinity
fi

