# Crossgrade: bitnami/minideb:bookworm → debian:trixie-slim

Plan and reference notes for the v4 line of this base image, built on the `trixie-slim` branch.

## Context

`flownative/docker-base` is the root of the Flownative Docker image tree. Up to v3.x it was
built on `bitnami/minideb:bookworm`; Bitnami's free image catalog is being wound down by
Broadcom, so the base moves to the official `debian:trixie-slim`. Along with the crossgrade,
non-critical packages are removed (see https://wiki.debian.org/ReduceDebian) and hardening
defaults are baked in.

Decisions:

- Docker tag: **`trixie-slim`** (next to the existing `bookworm` tag)
- Version line: **v4.0.0** (`bookworm` stays on v3.1.x; the floating `3` tag keeps pointing
  at Bookworm builds, `:latest` stays on Bookworm until Trixie becomes the default line)
- Package reduction: purge the verified non-critical set plus Python stdlib trims
  (see below; each removal was tested against the known consumer usages)
- Hardening: HTTPS APT sources, global APT defaults, policy-rc.d guard, and — added
  in a second iteration — setuid/setgid stripping with dpkg-statoverride and the
  cron→anacron swap that eliminates the setuid crontab binary

## Key findings from the analysis (September 2026)

- **Direct consumers** (all `FROM harbor.flownative.io/docker/base:bookworm`): docker-php,
  docker-nginx, docker-nodejs, docker-redis, docker-promtail, docker-beach-backup-worker,
  docker-beach-gateway-ssh. Indirect via docker-php: docker-beach-php, docker-beach-php-k8s,
  docker-composer.
- **`install_packages` shim required**: docker-nginx, docker-nodejs, docker-redis,
  docker-promtail, docker-beach-backup-worker, docker-composer and docker-ocr-watcher call
  minideb's `/usr/sbin/install_packages`, which `debian:trixie-slim` does not have. The base
  ships a compatible script (`root-files/usr/sbin/install_packages`) so those builds keep
  working unchanged. See todo in the script, can be optimized away.
- **No named UID-1000 user in the base**: docker-beach-gateway-ssh runs
  `groupadd --gid 1000 beach && useradd --uid 1000 beach` in its build, so the base keeps the
  bare `USER 1000`. `passwd` (useradd), `apt`, `dpkg`, `perl-base` and `tzdata` must all stay
  installed — consumer images install packages and create users during their builds.
  We should probably fix (part of this) in the future.
- Trixie package versions: syslog-ng 4.8.1 (Bookworm: 3.38), supervisor 4.2.5 (unchanged),
  logrotate 3.22. The syslog-ng config `@version` moves from 3.37 to 4.8; syslog-ng 4.x
  typed values slightly change `format-json` output (numbers become unquoted).
- **`sysvinit-utils` is NOT removable in Trixie**: the former `lsb-base` package was folded
  into it, and both supervisor and syslog-ng-core depend on `sysvinit-utils | lsb-base`.
- **Dependency traps in Trixie, worked around in build.sh**:
  - the `syslog-ng` metapackage pulls in the SCL plus SQL/MongoDB modules — the image
    installs `syslog-ng-core` instead (all Flownative configs only use core features)
  - `logrotate` depends on `cron | anacron | …`, and cron drags in `cron-daemon-common`
    (which depends on `systemd | systemd-standalone-sysusers | …` → the full systemd),
    `adduser`, `sensible-utils` and a setuid `crontab` binary. Installing `anacron`
    (depends only on libc6) in the same transaction satisfies logrotate and keeps that
    entire chain out; the daemon is never started, logrotate runs through Supervisor
  - **`diffutils` is NOT removable** although nothing declares a dependency on it:
    dpkg requires `diff` in PATH and aborts every package installation without it
    (`dpkg: error: 1 expected program not found`) — verified, would break all
    consumer builds
  - `tzdata`, `media-types` and `netbase` are hard dependencies of python3.13
    (→ supervisor) and cannot be removed either
- `debian:*-slim` already ships persistent doc/man dpkg path-excludes
  (`/etc/dpkg/dpkg.cfg.d/docker`) and the Docker APT tweaks (gzip indexes, auto-clean,
  no languages) — the same ground minideb covered.
- Trixie APT sources use the deb822 format at `/etc/apt/sources.list.d/debian.sources`.
- **Release-routing trap**: `flownative/action-git-latest-release` runs
  `git describe --tags --match='v*'` on the checked-out branch, but the old
  `docker.build.onpush.yaml` routed **every** `v*` tag push to the Bookworm workflow.
  Pushing `v4.0.0` with that in place would rebuild Bookworm code and publish it under the
  4.x semver tags. The onpush workflow therefore gates by tag major version:
  `v3.*` → Bookworm workflow, `v4.*` → Trixie workflow.
- **Nightly-schedule caveat**: scheduled workflows only run from the default branch
  (`bookworm`). `docker.build.trixie-slim.yaml` and the updated onpush workflow must be
  cherry-picked to `bookworm` for the Trixie nightly build to fire.
- **Bootstrap caveat**: until a `v4.*` tag exists, the Trixie workflow's "latest release"
  lookup would resolve to a v3.1.x tag reachable from the branch point and build Bookworm
  code under the `trixie-slim` tag. Tag `v4.0.0` before (or along with) activating the
  workflow on the default branch.

## Changes on the `trixie-slim` branch

1. **`Dockerfile`**: `FROM debian:trixie-slim`, plus an
   `org.opencontainers.image.base.name` label. Everything else unchanged.
2. **`root-files/usr/sbin/install_packages`** (new, 0755): POSIX-sh compat shim replicating
   minideb's script — up to 3 attempts of `apt-get update -qq && apt-get install -y
   --no-install-recommends "$@"`, then removal of the APT lists and archives.
3. **`root-files/build.sh`**, in order:
   1. policy-rc.d guard (`exit 101`) before any package work — keeps daemons from starting
      during this and consumer builds (minideb parity)
   2. `apt-get update && apt-get dist-upgrade` — nightly rebuilds pick up security fixes
      even when the upstream base image lags behind
   3. `packages_install ca-certificates anacron supervisor syslog-ng-core logrotate` —
      `dpkg` and `apt-utils` dropped from the list (dpkg is already there; apt-utils only
      silences a harmless debconf notice), `syslog-ng-core` instead of the full metapackage,
      `anacron` to keep the cron/systemd chain out (see above)
   4. switch `/etc/apt/sources.list.d/debian.sources` URIs to `https://` (needs
      ca-certificates first)
   5. `/etc/apt/apt.conf.d/01-flownative`: no Install-Recommends/Suggests,
      `Acquire::Retries "3"` — protects consumer builds that call apt-get directly
   6. purge non-critical packages: `mount login ncurses-bin hostname`
      (`--allow-remove-essential`), keeping `login.defs` (useradd needs it),
      `ncurses-base` (terminfo for `docker exec` shells), `sysvinit-utils`
      (provides lsb-base, see above) and `diffutils` (dpkg requires diff, see above)
   7. Python stdlib trim (≈ 18.5 MB): remove `__pycache__` (Python compiles imports in
      memory instead — supervisord start measured unchanged at 0.25 s), `test`,
      `pydoc_data` and `_pyrepl`; `venv` and `sqlite3` stay (consumers may need them)
   8. strip all setuid/setgid bits and pin them with `dpkg-statoverride` (su, the passwd
      suite, unix_chkpwd), so upgrades of those packages in derived images keep the bits
      off. Packages installed by derived images can bring their own setuid files
      (openssh-client's ssh-agent, mount as a dependency) — stripping those is the derived
      image's own clean-up step (candidate for a bash-library helper)
   9. `rm -f` instead of `rm` for `/etc/default/{syslog-ng,supervisor}` (Trixie packages may
      not ship them)
4. **`root-files/opt/flownative/syslog-ng/etc/syslog-ng.conf`**: `@version: 4.8`
5. **CI**: new `.github/workflows/docker.build.trixie-slim.yaml` (checkout `trixie-slim`,
   raw tag `trixie-slim`, `flavor: latest=false`, heartbeat metric `image=base-trixie-slim`
   as its own series); `docker.build.onpush.yaml` routes by tag major version.
6. **`README.md`**: updated origins, install_packages shim and APT defaults documented.

## Rollout

1. Merge/finish the `trixie-slim` branch, verify locally (see below).
2. Tag `v4.0.0` on `trixie-slim` — onpush builds and publishes
   `4.0.0 / 4.0 / 4 / trixie-slim` without touching `:latest` or `:3*`.
3. Cherry-pick `docker.build.trixie-slim.yaml` and the onpush change to `bookworm`
   (default branch) so the nightly Trixie build runs.
4. Add a Grafana alert for the `image=base-trixie-slim` heartbeat series.

## Verification checklist

All verified locally on arm64 (2026-09-01):

- ✅ `docker build -t base-test .` — 109 packages installed
- ✅ in the image: purged packages absent, no systemd/SCL modules, no cron chain;
  `apt`, `dpkg`, `bash`, `passwd`, `perl-base`, `tzdata`, `sysvinit-utils`, `diffutils`
  present; `apt-get check` clean; zero setuid/setgid files, statoverrides pinned;
  root account locked, no machine-id, no world-writable files;
  `install_packages curl` works as `--user root` (exercises HTTPS sources + shim);
  `groupadd --gid 1000 … && useradd --uid 1000 …` works (gateway-ssh pattern);
  policy-rc.d returns 101
- ✅ consumer install battery as `--user root`: openssh-server (creates its sshd user —
  adduser is pulled in on demand via its own dependency), curl, procps, nginx-extras,
  redis-server, libxml2-dev all install cleanly, `apt-get check` stays consistent
- ✅ `docker run base-test`: banner, syslog-ng and supervisor start as UID 1000, logs on
  stdout, no syslog-ng version warnings; `docker stop` ends gracefully ("Good bye 👋");
  supervisord start unaffected by the missing byte-code caches (0.25 s)
- ✅ consumer smoke test: docker-nginx built with its `FROM` pointed at the local image
  (nginx version pin updated to Trixie's `1.26.3-3+deb13u7`) — builds, and nginx runs
  under supervisord with syslog-ng, zero errors in the log
- ✅ size: 148 MB vs 248 MB for `flownative/base:bookworm` (uncompressed, arm64) — 40%
  smaller, thanks to syslog-ng-core, no systemd, no cron chain, the package purges and
  the Python stdlib trim

### Not removable — checked and rejected

- `diffutils` (dpkg aborts without `diff`), `tzdata`/`media-types`/`netbase` (python3.13
  hard deps), `sysvinit-utils` (lsb-base), `ncurses-base` (kept deliberately for
  terminfo), everything else in the image is a hard dependency of the apt/dpkg
  toolchain, passwd/useradd, ca-certificates, syslog-ng-core, supervisor's Python or
  logrotate.
- The single biggest remaining lever would be replacing supervisor: its Python runtime
  accounts for ≈ 55 MB (a third of the image). That is an architecture change across
  all consumer images, not part of this crossgrade.

## Follow-up work (separate repos)

- Each direct consumer needs its own migration branch: `FROM …/base:trixie-slim` plus Trixie
  compatibility (package renames such as libicu72 → libicu76, PHP build dependencies in
  docker-php, OpenSSH 10 configuration in docker-beach-gateway-ssh, syslog-ng 4.8 conf.d
  snippets).
- docker-borgbackup (minideb:bookworm) and docker-ocr-watcher (minideb:buster) use minideb
  directly — candidates for the same crossgrade.
- Retire the Bookworm workflow once all consumers have migrated (as done with Bullseye).
