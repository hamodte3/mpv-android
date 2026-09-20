# تحديث تسلسل buildall.sh
          cat << 'EOF' > "$CORE_DIR/scripts/buildall.sh"
          #!/usr/bin/env bash
          set -euo pipefail

          export PATH="${HOME}/.local/bin:${PATH}"
          SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

          echo "==> [1/7] Cleaning old build & prefix artifacts..."
          rm -rf "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/prefix"

          echo "==> [2/7] Building mbedtls (HTTPS support)..."
          bash "${SCRIPT_DIR}/build_mbedtls.sh"

          echo "==> [3/7] Setting Global Flags..."
          export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
          export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384"

          echo "==> [4/7] Running FFmpeg Minimal Build..."
          bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"

          echo "==> [5/8] Building libplacebo (Static)..."
          bash "${SCRIPT_DIR}/build_libplacebo.sh"

          echo "==> [6/8] Building libass & font stack (Static)..."
          bash "${SCRIPT_DIR}/build_libass.sh"

          echo "==> [7/8] Building MPV..."
          bash "${SCRIPT_DIR}/build_mpv.sh"

          echo "==> [8/8] Building libplayer.so (JNI Bridge)..."
          bash "${SCRIPT_DIR}/build_player.sh"

          if command -v llvm-strip &> /dev/null; then
            find "${SCRIPT_DIR}/prefix" -name "*.so" -exec llvm-strip --strip-debug --strip-unneeded -R .comment {} + 2>/dev/null || true
          fi

          echo "==> Complete! Native Build Finished Successfully."
          EOF
