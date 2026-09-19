#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/ffmpeg"

mkdir -p "${BUILD_DIR}" "${PREFIX}"
cd "${BUILD_DIR}"

FFMPEG_MINIMAL_FLAGS=(
  --target-os=android
  --arch=aarch64
  --cpu=armv8-a
  --enable-cross-compile
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
  --enable-jni
  --enable-mediacodec
  --enable-mbedtls
  --enable-libdav1d
  --disable-hwaccels
  --enable-hwaccel=h264_mediacodec
  --enable-hwaccel=hevc_mediacodec
  --enable-hwaccel=vp9_mediacodec
  --enable-hwaccel=av1_mediacodec
  --enable-decoder=h264,hevc,vp8,vp9,mpeg4,libdav1d
  --enable-decoder=aac,flac,opus,mp3,ac3,eac3,vorbis
  --enable-parser=h264,hevc,av1,vp9,aac,mpegaudio,opus,flac,vorbis
  --enable-demuxer=mov,matroska,flv,hls,dash,aac,flac,mp3,ogg,mpegts
  --enable-protocol=file,http,https,tcp,udp,hls,tls
)

# تمرير راياتك المنحوتة ومسار التثبيت
../../ffmpeg/configure "${FFMPEG_MINIMAL_FLAGS[@]}" \
  --prefix="${PREFIX}" \
  --extra-cflags="${EXTRA_CFLAGS:-} -I${PREFIX}/include" \
  --extra-ldflags="${EXTRA_LDFLAGS:-} -L${PREFIX}/lib"

make -j$(nproc)
make install
