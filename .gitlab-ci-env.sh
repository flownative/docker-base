BUILD_ENV_MICRO_VERSION=$(wget -qO https://versions.flownative.io/projects/base/channels/stable/versions/micro.txt)
export BUILD_ENV_MICRO_VERSION

BUILD_ENV_BAT_VERSION=$(wget -qO https://versions.flownative.io/projects/base/channels/stable/versions/bat.txt)
export BUILD_ENV_BAT_VERSION
