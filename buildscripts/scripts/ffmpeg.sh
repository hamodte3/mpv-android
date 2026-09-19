#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/ffmpeg"

mkdir -p "${BUILD_DIR}" "${PREFIX}"
cd "${BUILD_DIR}"

# إجبار FFmpeg على تصدير واجهاته البرمجية لكي يراها كود التطبيق في thumbnail.cpp
SAFE_CFLAGS="${EXTRA_CFLAGS:-} -I${PREFIX}/include -fvisibility=default"

FFMPEG_MINIMAL_FLAGS=(
  --target-os=android
  --arch=aarch64
  --cpu=armv8-a
  --enable-cross-compile
  --cross-prefix=aarch64-linux-android24-
  --cc=aarch64-linux-android24-clang
  --prefix="${PREFIX}"
  --disable-static
  --enable-shared
  --disable-everything
  --disable-doc
  --disable-programs
  --disable-encoders
  --disable-muxers
  --disable-devices
  --disable-filters
  --disable-iconv
  --disable-bzlib
  --disable-lzma
  --disable-xlib
  --enable-swscale
  --enable-jni
  --enable-mediacodec
  --disable-hwaccels
  --enable-hwaccel=h264_mediacodec
  --enable-hwaccel=hevc_mediacodec
  --enable-hwaccel=vp9_mediacodec
  --enable-hwaccel=av1_mediacodec
  --enable-decoder=h264,hevc,vp8,vp9,mpeg4,aac,mp3
  --enable-parser=h264,hevc,av1,vp9,aac,mpegaudio
  --enable-demuxer=mov,matroska,flv,hls,dash,aac,mp3,mpegts
  --enable-protocol=file,http,https,tcp,udp,hls,tls
)

../../ffmpeg/configure "${FFMPEG_MINIMAL_FLAGS[@]}" \
  --extra-cflags="${SAFE_CFLAGS}" \
  --extra-ldflags="${EXTRA_LDFLAGS:-} -L${PREFIX}/lib"

make -j$(nproc)
make install
