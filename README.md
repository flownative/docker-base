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

## syslog-ng

This image contains [syslog-ng](https://github.com/syslog-ng/syslog-ng),
a tool for processing logs of Linux processes. We use syslog-ng for
collecting logs from the application(s) running in the container and
output them to the console. This way you can see all logs via `docker
logs` or through other tools fetching logs from STDOUT / STDERR and
further log files.

The application extending this image may add additional syslog-ng
configuration by adding a file to `$SYSLOG_BASE_PATH/etc/conf.d`. The
file should be named after the application (for example "nginx.conf").

Note that the include file must not be a complete syslog-ng
configuration file, which means that if it starts with a "@version"
statement, it will not be included (see
[documentation](https://www.syslog-ng.com/technical-documents/doc/syslog-ng-open-source-edition/3.26/administration-guide/16#TOPIC-1430957)).

Within configuration files you can easily use global environment
variables using the backtick syntax:

```
    source s_nginx_common {
           file("`FLOWNATIVE_LOG_PATH`/nginx_*.log");
    };
```

You can check the actual "rendered" configuration by running the
following command from a bash within the container:

```
    syslog-ng-ctl config -p
```

## Building this image

Build this image with `docker build`.
