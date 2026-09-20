#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
NDK_BIN="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"
CXX="${NDK_BIN}/aarch64-linux-android24-clang++"

# مسار ملف الجسر في سورس المشروع
JNI_SRC="${SCRIPT_DIR}/../../app/src/main/jni/main.cpp"

echo "==> Compiling libplayer.so bridge..."

"${CXX}" -shared -fPIC \
  -Os -flto \
  -ffunction-sections -fdata-sections \
  -Wl,--gc-sections -Wl,-s \
  -Wl,-z,max-page-size=16384 \
  -I"${PREFIX}/include" \
  -L"${PREFIX}/lib" \
  "${JNI_SRC}" \
  -lmpv -landroid -llog -lOpenSLES -lEGL -lGLESv3 \
  -o "${PREFIX}/lib/libplayer.so"

echo "==> libplayer.so built successfully in ${PREFIX}/lib!"
