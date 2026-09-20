#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/mpv"
CROSS_FILE="${SCRIPT_DIR}/build/android_cross.txt"
MPV_SRC="${SCRIPT_DIR}/deps/mpv"

# تنظيف مجلد البناء
rm -rf "${BUILD_DIR}"
mkdir -p "${SCRIPT_DIR}/build" "${PREFIX}"

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export PKG_CONFIG_LIBDIR="${PREFIX}/lib/pkgconfig"

NDK_LLVM="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"
TARGET="aarch64-linux-android24"

# إعداد ملف الـ Cross
cat << EOF > "${CROSS_FILE}"
[binaries]
c = '${NDK_LLVM}/${TARGET}-clang'
cpp = '${NDK_LLVM}/${TARGET}-clang++'
ar = '${NDK_LLVM}/llvm-ar'
strip = '${NDK_LLVM}/llvm-strip'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8-a'
endian = 'little'

[built-in options]
c_args = ['-Os', '-flto', '-fvisibility=hidden', '-I${PREFIX}/include']
c_link_args = ['-Wl,--gc-sections', '-Wl,-s', '-flto', '-Wl,--icf=all', '-Wl,-z,max-page-size=16384', '-L${PREFIX}/lib']
EOF

# خيارات Meson الرسمية المتوافقة فقط
MESON_ARGS=(
  "--cross-file=${CROSS_FILE}"
  "--prefix=${PREFIX}"
  "--buildtype=release"
  "--default-library=shared"
  "-Doptimization=s"
  "-Db_lto=true"
  "-Dcplayer=false"
  "-Dlibmpv=true"
  "-Degl-android=enabled"
  "-Dlua=disabled"
  "-Djavascript=disabled"
  "-Dmanpage-build=disabled"
  "-Dhtml-build=disabled"
  "-Dtests=false"
  "-Dencoding=disabled"
)

echo "==> Configuring Minimal MPV with Meson..."
meson setup "${BUILD_DIR}" "${MPV_SRC}" "${MESON_ARGS[@]}"

echo "==> Compiling libmpv with Ninja..."
ninja -C "${BUILD_DIR}" -j$(nproc)

echo "==> Installing to prefix..."
ninja -C "${BUILD_DIR}" install

echo "==> MPV Build Complete! libmpv.so is ready in: ${PREFIX}/lib"
