FROM bitnami/minideb:buster AS baseimage

ENV FLOWNATIVE_LIB_PATH="/opt/flownative/lib" \
    PHP_BASE_PATH="/opt/flownative/php" \
    PATH="/opt/flownative/php/bin:$PATH" \
    LOG_DEBUG=true

COPY --from=docker.pkg.github.com/flownative/bash-library/bash-library:1 /lib $FLOWNATIVE_LIB_PATH
COPY root-files /
RUN /build.sh
RUN rm -rf $FLOWNATIVE_LIB_PATH; rm /build.sh

FROM scratch
MAINTAINER Robert Lemke <robert@flownative.com>

ARG BUILD_DATE

LABEL org.label-schema.name="Flownative  Base Image"
LABEL org.label-schema.description="The base for most Docker images by Flownative"
LABEL org.label-schema.vendor="Flownative GmbH"
LABEL com.flownative.base-image-build-date=$BUILD_DATE

COPY --from=baseimage / /

