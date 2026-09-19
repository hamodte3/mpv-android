#!/bin/bash -e

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
. ./include/depinfo.sh

mkdir -p deps
cd deps

# 1. تحميل mbedtls
if [ ! -d mbedtls ]; then
    echo "==> Fetching mbedtls"
    wget -qO- https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-${v_mbedtls}/mbedtls-${v_mbedtls}.tar.bz2 | tar -xjf -
    mv mbedtls-${v_mbedtls} mbedtls
fi

# 2. استنساخ FFmpeg
if [ ! -d ffmpeg ]; then
    echo "==> Cloning ffmpeg"
    git clone --depth 1 --branch ${v_ci_ffmpeg} https://github.com/FFmpeg/FFmpeg.git ffmpeg
fi

# 3. استنساخ libplacebo
if [ ! -d libplacebo ]; then
    echo "==> Cloning libplacebo"
    git clone --depth 1 --recursive https://code.videolan.org/videolan/libplacebo.git libplacebo
fi

# 4. تحميل curl
if [ ! -d curl ]; then
    echo "==> Fetching curl"
    wget -qO- https://curl.se/download/curl-${v_curl}.tar.xz | tar -xJf -
    mv curl-${v_curl} curl
fi

echo "==> Dependencies downloaded successfully (Ultra-Lean)."
