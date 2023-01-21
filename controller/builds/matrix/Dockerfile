
### Build Hardened Malloc
FROM alpine:latest as build-malloc

ARG RAPYDO_VERSION
RUN test -n "$RAPYDO_VERSION"

ARG CURRENT_UID
RUN test -n "$CURRENT_UID"
ARG CURRENT_GID
RUN test -n "$CURRENT_GID"

ARG SYNAPSE_VERSION
RUN test -n "$SYNAPSE_VERSION"

ARG HARDENED_MALLOC_VERSION
RUN test -n "$HARDENED_MALLOC_VERSION"

ARG CONFIG_NATIVE=false
ARG VARIANT=default

RUN apk --no-cache add build-base git gnupg && cd /tmp \
 && wget -q https://github.com/thestinger.gpg && gpg --import thestinger.gpg \
 && git clone --depth 1 --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
 && cd hardened_malloc && git verify-tag $(git describe --tags) \
 && make CONFIG_NATIVE=${CONFIG_NATIVE} VARIANT=${VARIANT}

### Build Synapse
FROM python:alpine as builder

ARG SYNAPSE_VERSION
RUN test -n "$SYNAPSE_VERSION"

RUN apk -U upgrade \
 && apk add -t build-deps \
        build-base \
        libffi-dev \
        libjpeg-turbo-dev \
        libxslt-dev \
        linux-headers \
        openssl-dev \
        postgresql-dev \
        rustup \
        zlib-dev \
 && rustup-init -y && source $HOME/.cargo/env \
 && pip install --upgrade pip \
 && pip install --prefix="/install" --no-warn-script-location \
        matrix-synapse[all]==${SYNAPSE_VERSION}

### Build Production

FROM python:alpine
#ARG CURRENT_UID=991
#ARG CURRENT_UID=991
ARG CURRENT_UID
RUN test -n "$CURRENT_UID"
ARG CURRENT_GID
RUN test -n "$CURRENT_GID"
#ARG UID=991
#ARG GID=991

RUN apk -U upgrade \
 && apk add -t run-deps \
        libffi \
        libgcc \
        libjpeg-turbo \
        libstdc++ \
        libxslt \
        libpq \
        openssl \
        zlib \
        tzdata \
        xmlsec \
        git \
        curl \
        icu-libs \
 && adduser -g ${CURRENT_GID} -u ${CURRENT_UID} --disabled-password --gecos "" synapse \
 && rm -rf /var/cache/apk/*

RUN pip install --upgrade pip \
 && pip install -e "git+https://github.com/matrix-org/mjolnir.git#egg=mjolnir&subdirectory=synapse_antispam"

COPY --from=build-malloc /tmp/hardened_malloc/out/libhardened_malloc.so /usr/local/lib/

COPY --from=builder /install /usr/local

COPY --chown=synapse:synapse rootfs /

ENV LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"

# VOLUME /data 

COPY --chown=synapse:synapse ./data /data

RUN chown -R $CURRENT_UID:synapse /data && \
    chmod -R 775  /data

#RUN addgroup  -S synapse develop
#RUN addgroup  -S synapse root 

USER synapse

EXPOSE 8008/tcp 8009/tcp 8448/tcp


ENTRYPOINT ["python3", "start.py"]

HEALTHCHECK --start-period=5s --interval=15s --timeout=5s \
    CMD curl -fSs http://localhost:8008/health || exit 1