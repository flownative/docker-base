#!/bin/bash
# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2046

# Load helper libraries

. "${FLOWNATIVE_LIB_PATH}/log.sh"
. "${FLOWNATIVE_LIB_PATH}/banner.sh"
. "${FLOWNATIVE_LIB_PATH}/packages.sh"

set -o errexit
set -o nounset
set -o pipefail

# ---------------------------------------------------------------------------------------
# Main routine

export FLOWNATIVE_LOG_PATH_AND_FILENAME=/dev/stdout
export DEBIAN_FRONTEND=noninteractive

banner_flownative 'Flownative Base Image'

# Keep daemons from being started by maintainer scripts, both in this build
# and in builds of images based on this one:
cat >/usr/sbin/policy-rc.d <<-EOM
	#!/bin/sh
	exit 101
EOM
chmod 0755 /usr/sbin/policy-rc.d

# Nightly builds must contain the latest security fixes, even when the
# upstream base image is lagging behind:
apt-get update -qq 1>$(debug_device)
apt-get dist-upgrade -y 1>$(debug_device)

# anacron satisfies logrotate's cron-daemon dependency; without it, apt would
# pull in cron along with its setuid crontab binary, cron-daemon-common and,
# through the sysusers dependency, the full systemd. The daemon itself is
# never started, logrotate runs through Supervisor. syslog-ng-core instead of
# syslog-ng avoids the SCL and database modules:
packages_install ca-certificates anacron supervisor syslog-ng-core logrotate

# With CA certificates in place, packages can be fetched via TLS:
sed -i 's|http://|https://|g' /etc/apt/sources.list.d/debian.sources

# APT defaults for this and derived images:
cat >/etc/apt/apt.conf.d/01-flownative <<-EOM
	APT::Install-Recommends "false";
	APT::Install-Suggests "false";
	Acquire::Retries "3";
EOM

# Remove packages which serve no purpose in a container; login.defs stays
# because useradd needs it, ncurses-base stays for usable interactive shells,
# sysvinit-utils must stay because it provides lsb-base, on which supervisor
# and syslog-ng depend, and diffutils must stay because dpkg requires diff:
apt-get purge -y --allow-remove-essential mount login ncurses-bin hostname 1>$(debug_device)
apt-get autoremove -y 1>$(debug_device)

# Remove Python byte-code caches and stdlib components Supervisor doesn't
# need; Python compiles imports in memory when the caches are missing, which
# does not measurably slow down the Supervisor start:
find /usr/lib/python3* -depth -name __pycache__ -type d -exec rm -rf {} +
rm -rf /usr/lib/python3.*/test /usr/lib/python3.*/pydoc_data /usr/lib/python3.*/_pyrepl

# Remove the setuid/setgid bits from all binaries; nothing running as an
# unprivileged user in these containers may escalate privileges. The
# statoverride makes sure that package upgrades in derived images do not
# restore the bits:
for f in $(find / -xdev -perm /6000 -type f); do
    dpkg-statoverride --update --add root root 0755 "$f" 1>$(debug_device)
done

# Clean up a few directories / files we don't need:
rm -rf \
    /etc/supervisor

# Create directories
mkdir -p \
    "${FLOWNATIVE_INIT_PATH}/etc/init.d" \
    "${FLOWNATIVE_LOG_PATH}" \
    "${SYSLOG_BASE_PATH}/etc" \
    "${SYSLOG_BASE_PATH}/sbin" \
    "${SYSLOG_BASE_PATH}/var" \
    "${SYSLOG_BASE_PATH}/tmp" \
    "${LOGROTATE_BASE_PATH}/etc/conf.d" \
    "${LOGROTATE_BASE_PATH}/log" \
    "${LOGROTATE_BASE_PATH}/sbin" \
    "${LOGROTATE_BASE_PATH}/var" \
    "${SUPERVISOR_BASE_PATH}/etc/conf.d" \
    "${SUPERVISOR_BASE_PATH}/bin" \
    "${SUPERVISOR_BASE_PATH}/tmp" \

# Move syslog-ng files to correct location
rm -f /etc/default/syslog-ng
mv /usr/sbin/syslog-ng* ${SYSLOG_BASE_PATH}/sbin/
ln -s ${SYSLOG_BASE_PATH}/tmp/syslog-ng.ctl /var/lib/syslog-ng/syslog-ng.ctl

# Move logrotate files to correct location
rm -rf /etc/logrotate.d
mv /usr/sbin/logrotate ${LOGROTATE_BASE_PATH}/sbin/
mv /etc/logrotate.conf ${LOGROTATE_BASE_PATH}/etc/

# Move Supervisor files to correct location
rm -f /etc/default/supervisor
mv /usr/bin/supervisord ${SUPERVISOR_BASE_PATH}/bin/
mv /usr/bin/supervisorctl ${SUPERVISOR_BASE_PATH}/bin/

chown -R 1000:1000 \
    "${FLOWNATIVE_INIT_PATH}" \
    "${FLOWNATIVE_LOG_PATH}" \
    "${SYSLOG_BASE_PATH}/etc" \
    "${SYSLOG_BASE_PATH}/var" \
    "${SYSLOG_BASE_PATH}/tmp" \
    "${LOGROTATE_BASE_PATH}/etc" \
    "${LOGROTATE_BASE_PATH}/log" \
    "${LOGROTATE_BASE_PATH}/sbin" \
    "${LOGROTATE_BASE_PATH}/var" \
    "${SUPERVISOR_BASE_PATH}/etc" \
    "${SUPERVISOR_BASE_PATH}/tmp"

# Clean up
packages_remove_docs_and_caches 1>$(debug_device)
rm -rf \
    /var/cache/* \
    /var/log/*
