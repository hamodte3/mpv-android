#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/depinfo.sh"

PREFIX="${SCRIPT_DIR}/prefix"
BUILD_DIR="${SCRIPT_DIR}/build/mpv"
CROSS_FILE="${BUILD_DIR}/android_cross.txt"
MPV_SRC="${SCRIPT_DIR}/deps/mpv"

mkdir -p "${BUILD_DIR}" "${PREFIX}"

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="${PREFIX}/lib/pkgconfig"

# تحويل الأعلام إلى تنسيق يقبله Meson في مصفوفات Python
IFS=' ' read -r -a CFLAGS_ARR <<< "${EXTRA_CFLAGS:-}"
IFS=' ' read -r -a LDFLAGS_ARR <<< "${EXTRA_LDFLAGS:-}"

# تجهيز ملف الـ Cross بدقة
cat << EOF > "${CROSS_FILE}"
[binaries]
c = '${NDK_LLVM}/bin/${TARGET}-clang'
cpp = '${NDK_LLVM}/bin/${TARGET}-clang++'
ar = '${NDK_LLVM}/bin/llvm-ar'
strip = '${NDK_LLVM}/bin/llvm-strip'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8-a'
endian = 'little'

[built-in options]
c_args = ['-I${PREFIX}/include'] + $(printf '%s\n' "${CFLAGS_ARR[@]}" | jq -R . | jq -s . 2>/dev/null || echo "['-Os', '-flto']")
c_link_args = ['-L${PREFIX}/lib'] + $(printf '%s\n' "${LDFLAGS_ARR[@]}" | jq -R . | jq -s . 2>/dev/null || echo "['-flto']")
EOF

MESON_ARGS=(
  "--cross-file=${CROSS_FILE}"
  "--prefix=${PREFIX}"
  "--buildtype=release"
  "--default-library=shared"
  "-Doptimization=s"
  "-Db_lto=true"
  "-Dlibass=disabled"
  "-Dcplayer=false"
  "-Degl-android=enabled"
  "-Dlibplacebo=disabled"
  "-Dlcms2=disabled"
  "-Drubberband=disabled"
  "-Dfontconfig=disabled"
  "-Dexpat=disabled"
  "-Dlua=disabled"
  "-Djavascript=disabled"
  "-Dlibsmbclient=disabled"
  "-Duchardet=disabled"
  "-Dcdda=disabled"
  "-Ddvbin=disabled"
  "-Ddvdnav=disabled"
  "-Ddvdread=disabled"
  "-Dmanpage-build=disabled"
  "-Dhtml-build=disabled"
  "-Dtests=disabled"
  "-Ddocs=disabled"
)

echo "==> Configuring Minimal MPV with Meson..."
meson setup "${BUILD_DIR}" "${MPV_SRC}" "${MESON_ARGS[@]}" --wipe || meson setup "${BUILD_DIR}" "${MPV_SRC}" "${MESON_ARGS[@]}"

echo "==> Compiling libmpv..."
ninja -C "${BUILD_DIR}" -j"$(nproc)"
ninja -C "${BUILD_DIR}" install
