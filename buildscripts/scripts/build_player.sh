#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
NDK_BIN="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"
CXX="${NDK_BIN}/aarch64-linux-android24-clang++"

# مجلد ملفات الجسر JNI
JNI_DIR="${SCRIPT_DIR}/../../app/src/main/jni"

echo "==> Compiling libplayer.so bridge..."

# جلب جميع ملفات C/C++ في مجلد JNI
JNI_FILES=$(find "${JNI_DIR}" -maxdepth 1 -type f \( -name "*.cpp" -o -name "*.c" \))

"${CXX}" -shared -fPIC \
  -static-libstdc++ \
  -Os -flto \
  -ffunction-sections -fdata-sections \
  -Wl,--gc-sections -Wl,-s \
  -Wl,--icf=safe \
  -Wl,-z,max-page-size=16384 \
  -I"${PREFIX}/include" \
  -L"${PREFIX}/lib" \
  ${JNI_FILES} \
  -lmpv -lavcodec -lavutil -landroid -llog -lOpenSLES -lEGL -lGLESv3 \
  -o "${PREFIX}/lib/libplayer.so"

echo "==> libplayer.so built successfully in ${PREFIX}/lib!"
