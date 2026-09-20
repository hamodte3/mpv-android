#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/6] Cleaning old build & prefix artifacts..."
rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

echo "==> [2/5] Setting Global Size & Linker Optimization Flags..."
export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384"

echo "==> [3/6] Running FFmpeg Minimal Build..."
bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"

echo "==> [4/6] Building libmpv..."
bash "${SCRIPT_DIR}/build_mpv.sh"

echo "==> [5/6] Building libplayer.so (Android JNI Bridge)..."
bash "${SCRIPT_DIR}/build_player.sh"

echo "==> [6/6] Stripping binaries..."
if command -v llvm-strip &> /dev/null; then
  find "${SCRIPT_DIR}/prefix/lib" -name "*.so" -exec llvm-strip --strip-unneeded -R .comment {} + 2>/dev/null || true
fi

echo "==> Complete! Ultra-lean NDK Build Finished Successfully."
