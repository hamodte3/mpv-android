#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/depinfo.sh"

echo "==> [1/4] Cleaning build artifacts..."
rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

echo "==> [2/4] Setting Global Optimization Flags..."
export EXTRA_CFLAGS="-Os -flto -ffunction-sections -fdata-sections -fmerge-all-constants"
# دمج خريطة الرموز وحماية التوافق مع 16KB Page Size
export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384 -Wl,--version-script=${SCRIPT_DIR}/mpv.map"

echo "==> [3/4] Building FFmpeg..."
bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"

echo "==> [4/4] Building MPV..."
bash "${SCRIPT_DIR}/build_mpv.sh"

# تجريد المقاطع غير اللازمة
echo "==> Post-Processing: Stripping .comment sections..."
find "${SCRIPT_DIR}/prefix/lib" -name "*.so" -exec "${NDK_LLVM}/bin/llvm-strip" --strip-debug --strip-unneeded -R .comment -R .note.gnu.gold-version {} + 2>/dev/null || true

echo "==> Build finished successfully! Output libraries in: ${SCRIPT_DIR}/prefix/lib"
