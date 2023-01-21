#!/bin/bash
RAPYDO_VERSION=3.0
CURRENT_GID=1000
CURRENT_UID=$UID

docker build --build-arg RAPYDO_VERSION=$RAPYDO_VERSION \
        --build-arg CURRENT_UID=$CURRENT_UID \
        --build-arg CURRENT_GID=$CURRENT_GID \
        --build-arg SYNAPSE_VERSION=1.75.0 \
        --build-arg HARDENED_MALLOC_VERSION=11 \
        -t matrix:$RAPYDO_VERSION .