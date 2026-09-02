FROM debian:trixie-slim

LABEL org.opencontainers.image.authors="Robert Lemke <robert@flownative.com>"
LABEL org.opencontainers.image.base.name="docker.io/library/debian:trixie-slim"

ARG BUILD_DATE

LABEL com.flownative.base-image-build-date=$BUILD_DATE

ENV FLOWNATIVE_LIB_PATH="/opt/flownative/lib" \
    FLOWNATIVE_INIT_PATH="/opt/flownative/init" \
    FLOWNATIVE_LOG_PATH="/opt/flownative/log" \
    FLOWNATIVE_LOG_PATH_AND_FILENAME="/dev/stdout" \
    SYSLOG_BASE_PATH="/opt/flownative/syslog-ng" \
    LOGROTATE_BASE_PATH="/opt/flownative/logrotate" \
    SUPERVISOR_BASE_PATH="/opt/flownative/supervisor" \
    LOG_DEBUG=true

COPY --from=harbor.flownative.io/docker/bash-library:1.13.5 /lib $FLOWNATIVE_LIB_PATH

COPY root-files /
RUN /build.sh && rm /build.sh

USER 1000
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "run" ]
