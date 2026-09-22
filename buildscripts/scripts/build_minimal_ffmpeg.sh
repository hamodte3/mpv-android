#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/depinfo.sh"

PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/ffmpeg"
FFMPEG_SRC="${SCRIPT_DIR}/deps/ffmpeg"
[ -d "${FFMPEG_SRC}" ] || FFMPEG_SRC="${SCRIPT_DIR}/../deps/ffmpeg"

mkdir -p "${BUILD_DIR}" "${PREFIX}"
cd "${BUILD_DIR}"

# 1. إعداد ملف mbedtls.pc لربط الأرشيفات الثابتة
mkdir -p "${PREFIX}/lib/pkgconfig"
cat << EOF > "${PREFIX}/lib/pkgconfig/mbedtls.pc"
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: mbedtls crypto and ssl
Version: 3.6.0
Libs: -L\${libdir} -lmbedtls -lmbedx509 -lmbedcrypto
Cflags: -I\${includedir}
EOF

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# إضافة -fPIC إجبارية حتى يمكن دمج الـ .a داخل libmpv.so لاحقاً
SAFE_CFLAGS="${EXTRA_CFLAGS:-} -I${PREFIX}/include -fPIC"
SAFE_LDFLAGS="-Wl,-z,max-page-size=16384 -Wl,--gc-sections -L${PREFIX}/lib"

FFMPEG_MINIMAL_FLAGS=(
  --target-os=android
  --arch=aarch64
  --cpu=armv8-a
  --enable-cross-compile
  --cc="${TARGET}-clang"
  --cxx="${TARGET}-clang++"
  --ar=llvm-ar
  --ranlib=llvm-ranlib
  --nm=llvm-nm
  --strip=llvm-strip
  --prefix="${PREFIX}"
  --pkg-config=pkg-config
  --pkg-config-flags="--static"
  --enable-version3
  --enable-mbedtls
  --enable-static
  --disable-shared
  --enable-pic
  --disable-everything
  --disable-doc
  --disable-programs
  --disable-encoders
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
  --enable-decoder=h264,hevc,vp8,vp9,mpeg4,aac,mp3,flac
  --enable-parser=h264,hevc,av1,vp9,aac,mpegaudio
  --enable-demuxer=mov,matroska,flv,hls,dash,aac,mp3,mpegts
  --enable-protocol=file,http,https,tcp,udp,hls,tls
)

"${FFMPEG_SRC}/configure" "${FFMPEG_MINIMAL_FLAGS[@]}" \
  --extra-cflags="${SAFE_CFLAGS}" \
  --extra-ldflags="${SAFE_LDFLAGS}" \
  --extra-libs="-lmbedtls -lmbedx509 -lmbedcrypto"

make -j"$(nproc)"
make install
echo "==> Minimal Static FFmpeg installed successfully."
