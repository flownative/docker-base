![Nightly Builds](https://github.com/flownative/docker-base/workflows/Nightly%20Builds/badge.svg)
![Release to Docker Registries](https://github.com/flownative/docker-base/workflows/Release%20to%20Docker%20Registries/badge.svg)

# Flownative Docker Base Image

A Docker base image, derived from [bitnami/minideb](https://github.com/bitnami/minideb),
integrated into the build pipeline of Flownative Docker images.

## Init

This image contains a simple mechanism for automatic execution of
init-scripts when the container is started.

When included, the `init.sh` script is used as an ENTRYPOINT of your
Docker container, it scans the directory
`/opt/flownative/init/etc/init.d` for `.sh` files. The scripts are then
called in an alphabetical order, so it makes sense to prefix filenames
with a number, if the order is important.

The `init.d` directory might contain files like these:

```
3_test.sh
10_another_test.sh
20_yet_another_test.sh
```

## Supervisor

This image contains [Supervisor](http://supervisord.org/), a tool for
running and watching Linux processes. We use Supervisor in extensions of
this image for running services like Nginx, PHP-FPM, SSHD and the like.

Supervisor is started by calling the respective functions of the
`supervisor.sh` bash library:

```bash
. "${FLOWNATIVE_LIB_PATH}/supervisor.sh"

eval "$(supervisor_env)"
supervisor_initialize
supervisor_start

trap 'supervisor_stop' SIGINT SIGTERM
supervisor_pid=$(supervisor_get_pid)

# We can't use "wait" because supervisord is not a direct child of
# this shell:
while [ -e "/proc/${supervisor_pid}" ]; do sleep 1.1; done
```
Take a look at the `init.sh` script used as an ENTRYPOINT in this image
for more context.

Supervisor will look for configuration files in
`/opt/flownative/supervisor/etc/conf.d/`. Add your own files in order to
configure `supervisord` and use `supervisorctl` to control it.

## Building this image

Build this image with `docker build`.
