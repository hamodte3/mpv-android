cat << 'EOF' > buildall
#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/5] Cleaning old build & prefix artifacts..."
rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

echo "==> [2/5] Setting Global Size & Linker Optimization Flags..."
export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384 -Wl,--version-script=${SCRIPT_DIR}/mpv.map"

echo "==> [3/5] Running FFmpeg Minimal Build..."
if [ -f "${SCRIPT_DIR}/build_minimal_ffmpeg.sh" ]; then
  bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"
fi

echo "==> [4/5] Building MPV..."
if [ -f "${SCRIPT_DIR}/build_mpv.sh" ]; then
  bash "${SCRIPT_DIR}/build_mpv.sh"
fi

echo "==> [5/5] Post-Processing: Stripping .comment notes..."
if command -v llvm-strip &> /dev/null; then
  find "${SCRIPT_DIR}/prefix" -name "*.so" -exec llvm-strip --strip-debug --strip-unneeded -R .comment {} + 2>/dev/null || true
  echo "==> Stripped .comment notes using llvm-strip."
fi

echo "==> Complete! Optimized NDK Build Finished Successfully."
EOF
