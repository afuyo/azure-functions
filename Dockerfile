FROM mcr.microsoft.com/azure-functions/python:2.0

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
RUN apt-get update \
&& apt-get install -y \
    build-essential \
    checkinstall \
    libreadline-gplv2-dev \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    openssl \
    curl \
    xml-twig-tools \
    git-all

COPY pip.conf /etc/pip.conf
RUN curl --fail -sk https://bootstrap.pypa.io/get-pip.py | python

RUN mkdir -p /usr/share/ca-certificates/extra /usr/lib/ssl/certs
COPY zscaler.crt /usr/share/ca-certificates/extra/zscaler.crt
COPY zscaler.crt /usr/lib/ssl/certs/zscaler.crt
COPY zscaler.crt /usr/lib/ssl/certs/zscaler.pem
RUN update-ca-certificates

COPY . /home/site/wwwroot

RUN cd /home/site/wwwroot && \
    pip install -r requirements.txt