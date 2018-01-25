#FROM ubuntu:16.04
FROM phusion/baseimage:0.9.22
MAINTAINER Robert Lemke <robert@flownative.com>

# Install essentials:
RUN apt-get update \
 && apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
 && apt-get install -y ca-certificates sudo zip unzip zsh ntp curl wget libxml2 sudo netcat language-pack-en gettext-base --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate locales for English and German:
RUN echo "en_US UTF-8\nen_US.UTF-8 UTF-8\nen_US ISO-8859-1\nde_DE UTF-8\nde_DE.UTF-8 UTF-8\nde_DE ISO-8859-1\n" > /var/lib/locales/supported.d/local && locale-gen --purge

RUN wget https://github.com/zyedidia/micro/releases/download/v1.3.4/micro-1.3.4-linux64.tar.gz; \
    tar xfz micro-1.3.4-linux64.tar.gz; \
    mv micro-1.3.4/micro /usr/local/bin; \
    chmod 755 /usr/local/bin/micro; \
    rm -rf micro-1.3.4*
