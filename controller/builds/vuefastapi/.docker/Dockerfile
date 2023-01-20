FROM python:3.9.6-slim-buster

RUN apt-get update && apt-get install -y gcc &&\  
    apt-get autoremove --yes &&\
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
# used by print_versions
ENV ANGULAR_VERSION 15.0.3

ENV FASTAPI_VERSION 3.0.0

ARG CURRENT_UID
#RUN test -n "$CURRENT_UID"
ARG CURRENT_GID
#RUN test -n "$CURRENT_GID"

RUN apt-get update -qq \
    && apt-get dist-upgrade --yes -qq \
    && apt-get autoremove --yes && apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN groupmod -og $CURRENT_GID node && usermod -u $CURRENT_UID node

#ENV NODE_PATH /opt/node_modules


WORKDIR /app/


RUN pip install poetry==1.2.2
RUN pip install poetry --upgrade

# Copy poetry.lock* in case it doesn't exist in the repo
COPY ./app/pyproject.toml /app/

# Allow installing dev dependencies to run tests
#ARG INSTALL_DEV=false
#RUN bash -c "if [ $INSTALL_DEV == 'true' ] ; then poetry install --no-root ; else poetry install --no-root --no-dev ; fi"
RUN poetry config virtualenvs.create false

# For development, Jupyter remote kernel, Hydrogen
# Using inside the container:
# jupyter lab --ip=0.0.0.0 --allow-root --NotebookApp.custom_display_url=http://127.0.0.1:8888
ARG INSTALL_JUPYTER=false
RUN bash -c "if [ $INSTALL_JUPYTER == 'true' ] ; then pip install jupyterlab ; fi"

COPY ./app /app

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint
#COPY --chmod=777 ./reload-types.sh /usr/local/bin/reload-types
#COPY --chmod=740 reload-angular.sh /usr/local/bin/reload
COPY banner.sh print_versions.sh /etc/

RUN echo '/bin/bash /etc/banner.sh' >> /etc/bash.bashrc

ENTRYPOINT [ "tail","-f","/dev/null" ]

CMD ["docker-entrypoint"]