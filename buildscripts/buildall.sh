# تحديث تسلسل buildall.sh المتكامل
          cat << 'EOF' > "$CORE_DIR/scripts/buildall.sh"
          #!/usr/bin/env bash
          set -euo pipefail

          export PATH="${HOME}/.local/bin:${PATH}"
          SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
          . "${SCRIPT_DIR}/depinfo.sh"

          PREFIX="${SCRIPT_DIR}/prefix"
          BUILD_DIR="${SCRIPT_DIR}/build"

          echo "==> [1/8] Cleaning and preparing build & prefix directories..."
          rm -rf "${BUILD_DIR}" "${PREFIX}"
          mkdir -p "${BUILD_DIR}" "${PREFIX}"

          echo "==> [2/8] Generating Shared Meson Cross File..."
          cat << CROSS_EOF > "${BUILD_DIR}/android_cross.txt"
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
c_args = ['-Os', '-flto', '-fvisibility=hidden', '-I${PREFIX}/include']
c_link_args = ['-Wl,--gc-sections', '-Wl,-s', '-flto', '-Wl,--icf=safe', '-Wl,-z,max-page-size=16384', '-static-libstdc++', '-L${PREFIX}/lib']
cpp_args = ['-Os', '-flto', '-fvisibility=hidden', '-I${PREFIX}/include']
cpp_link_args = ['-Wl,--gc-sections', '-Wl,-s', '-flto', '-Wl,--icf=safe', '-Wl,-z,max-page-size=16384', '-static-libstdc++', '-L${PREFIX}/lib']
CROSS_EOF

          echo "==> [3/8] Building mbedtls (HTTPS support)..."
          bash "${SCRIPT_DIR}/build_mbedtls.sh"

          echo "==> [4/8] Running FFmpeg Minimal Build..."
          export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
          export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=safe -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384"
          bash "${SCRIPT_DIR}/build_minimal_ffmpeg.sh"

          echo "==> [5/8] Building libplacebo (Static)..."
          bash "${SCRIPT_DIR}/build_libplacebo.sh"

          echo "==> [6/8] Building libass & font stack (Static)..."
          bash "${SCRIPT_DIR}/build_libass.sh"

          echo "==> [7/8] Building MPV..."
          bash "${SCRIPT_DIR}/build_mpv.sh"

          echo "==> [8/8] Building libplayer.so (JNI Bridge)..."
          bash "${SCRIPT_DIR}/build_player.sh"

          echo "==> Post-Processing: Safe stripping of .so binaries..."
          if command -v llvm-strip &> /dev/null; then
            find "${PREFIX}/lib" -name "*.so" -exec llvm-strip --strip-unneeded -R .comment {} + 2>/dev/null || true
          fi

          echo "==> Complete! Native Build Finished Successfully."
          EOF
