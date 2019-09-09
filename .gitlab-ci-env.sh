BUILD_ARG_MICRO_VERSION=$(wget -qO- https://versions.flownative.io/projects/base/channels/stable/versions/micro.txt)
export BUILD_ARG_MICRO_VERSION

BUILD_ARG_BAT_VERSION=$(wget -qO- https://versions.flownative.io/projects/base/channels/stable/versions/bat.txt)
export BUILD_ARG_BAT_VERSION
