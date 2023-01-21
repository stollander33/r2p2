#!/bin/bash
RAPYDO_VERSION=3.0
CURRENT_GID=1000
CURRENT_UID=$UID

docker build --build-arg RAPYDO_VERSION=$RAPYDO_VERSION \
        --build-arg VUE_APP_NAME="Supuestamente"  \
        --build-arg CURRENT_UID=$CURRENT_UID \
        --build-arg CURRENT_GID=$CURRENT_GID \
        --build-arg INSTALL_JUPYTER=$INSTALL_JUPYTER \
        --build-arg INSTALL_DEV=$INSTALL_DEV \
        -t vue:$RAPYDO_VERSION .