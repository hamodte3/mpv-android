#!/bin/bash -e

# تحديد المسار بدقة لمنع تضارب مجلدات العمل والـ Segfault
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${SCRIPT_DIR}/depinfo.sh"

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET="wget --progress=bar:force"

# الانتقال إلى buildscripts/deps
mkdir -p "${SCRIPT_DIR}/../deps"
cd "${SCRIPT_DIR}/../deps"

# 1. mbedtls
if [ ! -d mbedtls ]; then
    echo "==> Downloading mbedtls"
    mkdir -p mbedtls
    $WGET "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-${v_mbedtls}/mbedtls-${v_mbedtls}.tar.bz2" -O - | \
        tar -xj -C mbedtls --strip-components=1
fi

# 2. ffmpeg
if [ ! -d ffmpeg ]; then
    echo "==> Cloning ffmpeg"
    args=()
    [ "$IN_CI" -eq 1 ] && args+=(--depth=1 -b "$v_ci_ffmpeg")
    git clone https://github.com/FFmpeg/FFmpeg ffmpeg "${args[@]}"
fi

# 3. libplacebo
if [ ! -d libplacebo ]; then
    echo "==> Cloning libplacebo"
    git clone --depth 1 --recursive https://code.videolan.org/videolan/libplacebo.git libplacebo
fi

# 4. curl
if [ ! -d curl ]; then
    echo "==> Downloading curl"
    mkdir -p curl
    $WGET "https://curl.se/download/curl-${v_curl}.tar.xz" -O - | \
        tar -xJ -C curl --strip-components=1
fi

echo "==> Dependencies downloaded successfully."
