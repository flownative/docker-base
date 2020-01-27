FROM bitnami/minideb:buster AS baseimage


FROM scratch
MAINTAINER Robert Lemke <robert@flownative.com>

ARG BUILD_DATE

LABEL org.label-schema.name="Flownative  Base Image"
LABEL org.label-schema.description="The base for most Docker images by Flownative"
LABEL org.label-schema.vendor="Flownative GmbH"
LABEL com.flownative.base-image-build-date=$BUILD_DATE

COPY --from=baseimage / /
