#!/bin/bash
set -e
if [[ ! -t 0 ]]; then
    /bin/bash /etc/banner.sh
fi

NODE_USER="node"
NODE_HOME=$(eval echo ~$NODE_USER)

DEVID=$(id -u "$NODE_USER")
if [ "$DEVID" != "$CURRENT_UID" ]; then
    echo "Fixing uid of user ${NODE_USER} from $DEVID to $CURRENT_UID..."
    usermod -u "$CURRENT_UID" "$NODE_USER"
fi

GROUPID=$(id -g $NODE_USER)
if [ "$GROUPID" != "$CURRENT_GID" ]; then
    echo "Fixing gid of user $NODE_USER from $GROUPID to $CURRENT_GID..."
    groupmod -og "$CURRENT_GID" "$NODE_USER"
fi


echo "Running as ${NODE_USER} (uid $(id -u ${NODE_USER}))"

# Defaults
if [ -z APP_MODE ]; then
    APP_MODE="development"
fi

run_as_node() {
    HOME="${NODE_HOME}" su -p "${NODE_USER}" -c "${1}"
}


if [[ -d "/app" ]]; then
    chown -R node:node /app
fi


if [ "$APP_MODE" == "production" ]; then  
elif [ "$APP_MODE" == "development" ]; then

 
     sleep infinity

elif [ "$APP_MODE" == "test" ]; then

    sleep infinity

else
    echo "Unknown APP_MODE: ${APP_MODE}"
fi
