FROM ubuntu:14.04

RUN apt-get update -y && apt-get upgrade -y && apt-get install nginx wget jq curl -y

#install confd
RUN wget https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 -O confd && \
    chmod +x confd && mv confd /usr/local/bin/ && mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates

#copy config & template file for confd
COPY confd/nginx.toml /etc/confd/conf.d/nginx.toml
COPY confd/nginx.tmpl /etc/confd/templates/nginx.tmpl

#install docker
RUN curl -sSL https://get.docker.com/ | sh

COPY haScripts /opt/hademo/bin
ENV PATH $PATH:/opt/hademo/bin
COPY startHaDemo.sh /root/startHaDemo.sh
