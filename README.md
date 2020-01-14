# Flownative Docker Base Image

A Docker base image, derived from [phusion/baseimage-docker](https://github.com/phusion/baseimage-docker), 
brushed up with some tools and further fine-tuning.

## Building this image

Build this image with `docker build`. You need to specify the desired version for some
of the tools as build arguments:

```bash
docker build \
    --build-arg MICRO_VERSION=1.4.1 \
    --build-arg BAT_VERSION=0.12.1 \
    -t flownative/base:latest .
```

Check the latest stable release on the tool's respective websites:
 
- Micro: https://github.com/zyedidia/micro/releases
- Bat: https://github.com/sharkdp/bat/releases
