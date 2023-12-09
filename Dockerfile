FROM ubuntu:20.04

ENV TZ=Asia/Jakarta \
    DEBIAN_FRONTEND=noninteractive

# Install required libraries
RUN apt-get update \
    && apt-get -y install sudo build-essential \
    && apt-get -y install unzip curl wget git nano python3 \
    && wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-Linux-x86_64.sh \
    -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && mkdir /opt/cmake-3.24.1 \
    && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.24.1 \
    && rm /tmp/cmake-install.sh \
    && ln -s /opt/cmake-3.24.1/bin/* /usr/local/bin \
    && apt-get -y install lsb-release ca-certificates apt-transport-https software-properties-common

RUN add-apt-repository ppa:ondrej/php

RUN apt-get -y install php8.1 php8.1-dev php8.1-xml php8.1-mbstring php8.1-curl php8.1-pgsql

RUN phpenmod dom && phpenmod mbstring && phpenmod curl && phpenmod pgsql

# Copy source codes
COPY ./codes/backend-api/ /home/ubuntu/backend-api/
COPY ./codes/api-bpjs/ /home/ubuntu/api-bpjs/
COPY ./codes/api-insurance /home/ubuntu/api-insurance

# Change working directory
WORKDIR /home/ubuntu

# Copy sapnwrfcsdk
COPY ./nwrfcsdk/ /usr/local/sap/nwrfcsdk/

# RUN export SAPNWRFC_HOME=/usr/local/sap/nwrfcsdk
RUN echo "export SAPNWRFC_HOME=/usr/local/sap/nwrfcsdk" >> /root/.bashrc

RUN echo "/usr/local/sap/nwrfcsdk/lib" >> /etc/ld.so.conf.d/nwrfcsdk.conf

RUN rm /etc/ld.so.cache && ldconfig && ldconfig -p | grep sap


# copy & compile sapnwrfc for php
COPY ./php7-sapnwrfc /home/ubuntu/php7-sapnwrfc
RUN cd php7-sapnwrfc/ && phpize && ./configure && make && make install
RUN echo "extension=sapnwrfc.so" >> /etc/php/8.1/cli/php.ini

# Installing Node
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN source /root/.bashrc && nvm install 18.16.1
SHELL ["/bin/bash", "--login", "-c"]

# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

EXPOSE 3333
EXPOSE 8000