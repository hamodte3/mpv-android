#!/usr/bin/env bash
# ==============================================================================
# Master NDK Build Script for MPV & FFmpeg (Zero-Config Minimal Architecture)
# Includes Function/Data sections (-ffunction-sections -fdata-sections),
# constant merging (-fmerge-all-constants), GNU hash table (-Wl,--hash-style=gnu),
# 16KB Page Alignment (-Wl,-z,max-page-size=16384) for Android 15+,
# symbol isolation (-Wl,--exclude-libs,ALL), symbol version map (-Wl,--version-script),
# symbolic binding (-Wl,-Bsymbolic-functions), LTO, ICF, and .comment stripping.
# ==============================================================================

set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/5] Cleaning old build & prefix artifacts..."
rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

echo "==> [2/5] Setting Global Size & Linker Optimization Flags..."
export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384 -Wl,--version-script=${SCRIPT_DIR}/mpv.map"

echo "EXTRA_CFLAGS: ${EXTRA_CFLAGS}"
echo "EXTRA_LDFLAGS: ${EXTRA_LDFLAGS}"

echo "==> [3/5] Running FFmpeg Minimal Build..."
if [ -f "${SCRIPT_DIR}/build_minimal_ffmpeg.sh" ]; then
  bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"
fi

echo "==> [4/5] Executing Component Scripts (Excluding Lua, Luajit, Uchardet)..."
# Disabled obsolete/legacy script engines & utilities to reduce binary size:
# "${SCRIPT_DIR}/lua.sh"
# "${SCRIPT_DIR}/luajit.sh"
# "${SCRIPT_DIR}/uchardet.sh"

if [ -f "${SCRIPT_DIR}/build_mpv.sh" ]; then
  echo "==> Building MPV..."
  bash "${SCRIPT_DIR}/build_mpv.sh"
fi

echo "==> [5/5] Post-Processing: Stripping .comment and unneeded sections from binaries..."
if command -v llvm-strip &> /dev/null; then
  find "${SCRIPT_DIR}/prefix" -name "*.so" -exec llvm-strip --strip-debug --strip-unneeded -R .comment {} + 2>/dev/null || true
  echo "==> Stripped .comment notes using llvm-strip."
fi

echo "==> Complete! Optimized NDK Build Finished Successfully."
