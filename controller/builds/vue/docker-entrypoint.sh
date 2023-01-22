#!/bin/bash
set -e

#######################################
#                                     #
#             Entrypoint!             #
#                                     #
#######################################

if [[ ! -t 0 ]]; then
    /bin/bash /etc/banner.sh
fi

export NODE_PATH=/opt/node_modules
#export NODE_OPTIONS=--openssl-legacy-provider

NODE_USER="node"
# NODE_HOME=$(eval echo ~$NODE_USER)
NODE_HOME="/app"

echo "NODE_USER=$NODE_USER"
echo "NODE_HOME=$NODE_HOME"

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


# Defaults
if [ -z APP_MODE ]; then
    APP_MODE="development"
fi

echo "Running as ${NODE_USER} (uid $(id -u ${NODE_USER})) in ${APP_MODE}"

run_as_node() {
    HOME="${NODE_HOME}" su -p "${NODE_USER}" -c "${1}"
}

if [ "$APP_MODE" == "test" ]; then
    export BACKEND_HOST=${CYPRESS_BACKEND_HOST}
fi

run_as_node "env > /tmp/.env"

if [ "$ENABLE_YARN_PNP" == "0" ]; then
    NODE_LINKER="node-modules"
else
    NODE_LINKER="pnp"
fi

# https://github.com/yarnpkg/berry/tree/master/packages/plugin-typescript#yarnpkgplugin-typescript
#run_as_node "yarn plugin import typescript"
export 
if [ "$APP_MODE" == "production" ]; then
    echo "running in production mode"
    if [[ -z $FRONTEND_URL ]];
    then
        FRONTEND_URL="https://${BASE_HREF}${FRONTEND_PREFIX}"
    elif [[ $FRONTEND_URL != */ ]];
    then
        FRONTEND_URL="${FRONTEND_URL}/"
    fi
    run_as_node "yarn build"
    sleep infinity


elif [ "$APP_MODE" == "development" ]; then
    echo "running in development mode"
    run_as_node "yarn serve"    
    sleep infinity

elif [ "$APP_MODE" == "test" ]; then
    sleep infinity
else
    echo "Unknown APP_MODE: ${APP_MODE}"
    sleep infinity
fi

