#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/6] Cleaning old build & prefix artifacts..."
rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

echo "==> [2/6] Building mbedTLS (HTTPS backend)..."
bash "${SCRIPT_DIR}/build_mbedtls.sh"

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
