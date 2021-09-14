FROM bitnami/minideb:buster

MAINTAINER Robert Lemke <robert@flownative.com>

ARG BUILD_DATE

LABEL org.label-schema.name="Flownative  Base Image"
LABEL org.label-schema.description="The base for most Docker images by Flownative"
LABEL org.label-schema.vendor="Flownative GmbH"
LABEL com.flownative.base-image-build-date=$BUILD_DATE

ENV FLOWNATIVE_LIB_PATH="/opt/flownative/lib" \
    FLOWNATIVE_INIT_PATH="/opt/flownative/init" \
    FLOWNATIVE_LOG_PATH="/opt/flownative/log" \
    FLOWNATIVE_LOG_PATH_AND_FILENAME="/dev/stdout" \
    SYSLOG_BASE_PATH="/opt/flownative/syslog-ng" \
    LOGROTATE_BASE_PATH="/opt/flownative/logrotate" \
    SUPERVISOR_BASE_PATH="/opt/flownative/supervisor" \
    LOG_DEBUG=true

COPY --from=europe-docker.pkg.dev/flownative/docker/bash-library:1.13.3 /lib $FLOWNATIVE_LIB_PATH

# Workaround for https://github.com/docker/buildx/issues/495
RUN ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && ln -s /bin/tar /usr/sbin/tar

COPY root-files /
RUN /build.sh && rm /build.sh

USER 1000
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "run" ]
