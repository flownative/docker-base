FROM phusion/baseimage:0.11 AS baseimage

COPY conf/dpkg.conf /etc/dpkg/dpkg.cfg.d/01-flownative
COPY conf/apt.conf /etc/apt/apt.conf.d/99-flownative

# -----------------------------------------------------------------------------
# Install essentials

# For easier debugging, we execute a dedicated RUN for each package. This comes
# without a image size penalty, because we merge file layers of this image
# anyway.

RUN apt-get update
RUN apt-get upgrade

# CA certificates are needed by many applications dealing with networking,
# especially webservers and tools like cURL
RUN apt-get install ca-certificates

# Zip and unzip are useful in many cases and are also used by other tools
RUN apt-get install zip
RUN apt-get install unzip

# ZSH is our preferred shell
RUN apt-get install zsh

# cURL, wget and netcat come handy for debugging and other interactive sessions
RUN apt-get install curl
RUN apt-get install wget
RUN apt-get install netcat

# sshpass is needed for non-interactive logins via SSH, for example when scripting
# SFTP access
RUN apt-get install sshpass

# Sudo is helpful for low-level interactive sessions, for example when execing
# into a container
RUN apt-get install sudo

# Provider proper locales for English and German users
RUN apt-get install language-pack-en
RUN apt-get install gettext-base

RUN apt-get clean
RUN rm -rf \
        /root \
        /share/doc/* \
        /tmp/* \
        /var/cache/* \
        /var/tmp/* \
        /var/lib/apt/* \
        /var/lib/dpkg/status-old \
        /var/log/* \
    && mkdir /root

FROM scratch
MAINTAINER Robert Lemke <robert@flownative.com>

COPY --from=baseimage / /

COPY conf/zshrc.conf /etc/zsh/zshrc

ARG BUILD_DATE
LABEL org.label-schema.name="Flownative  Base Image"
LABEL org.label-schema.description="The base for most Docker images by Flownative. Will be replaced soon (early 2020)."
LABEL org.label-schema.vendor="Flownative GmbH"
LABEL com.flownative.base-image-build-date=$BUILD_DATE

ENV DEBIAN_FRONTEND="teletype" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

# Generate locales for English and German:
RUN echo "en_US UTF-8\nen_US.UTF-8 UTF-8\nen_US ISO-8859-1\nde_DE UTF-8\nde_DE.UTF-8 UTF-8\nde_DE ISO-8859-1\n" > /var/lib/locales/supported.d/local && \
    locale-gen --purge

## For Micro releases see https://github.com/zyedidia/micro/releases
ARG MICRO_VERSION
ENV MICRO_VERSION=${MICRO_VERSION}
RUN wget --no-hsts https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz; \
    tar xfz micro-${MICRO_VERSION}-linux64.tar.gz; \
    mv micro-${MICRO_VERSION}/micro /usr/local/bin; \
    chmod 755 /usr/local/bin/micro; \
    rm -rf micro-${MICRO_VERSION}* /var/log/* /var/lib/dpkg/status-old

# For Bat releases see https://github.com/sharkdp/bat/releases
ARG BAT_VERSION
ENV BAT_VERSION=${BAT_VERSION}
RUN wget --no-hsts  https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-musl_${BAT_VERSION}_amd64.deb; \
    dpkg -i bat-musl_${BAT_VERSION}_amd64.deb; \
    rm -rf bat-musl_${BAT_VERSION}_amd64.deb /var/log/* /usr/share/doc/bat /var/lib/dpkg/status-old

CMD ["/sbin/my_init"]
