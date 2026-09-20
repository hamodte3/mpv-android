#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/mbedtls"

# تحديد مسار السورس سواء كان داخل scripts/deps أو buildscripts/deps
SRC_DIR="${SCRIPT_DIR}/deps/mbedtls"
[ -d "${SRC_DIR}" ] || SRC_DIR="${SCRIPT_DIR}/../deps/mbedtls"

echo "==> Building mbedtls for arm64-v8a..."
mkdir -p "${BUILD_DIR}" "${PREFIX}"

cmake -B "${BUILD_DIR}" -S "${SRC_DIR}" \
  -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DENABLE_TESTING=OFF \
  -DENABLE_PROGRAMS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-Os -flto -fPIC -ffunction-sections -fdata-sections"

ninja -C "${BUILD_DIR}" install

echo "==> mbedtls installed successfully into ${PREFIX}!"
