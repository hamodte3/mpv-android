name: Build Ultra-Lean Libmpv (No-Subtitles)

on:
  workflow_dispatch:

jobs:
  build-mpv:
    runs-on: ubuntu-latest

    steps:
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y ninja-build meson autoconf automake libtool pkg-config clang llvm yasm nasm python3

      - name: Setup Android NDK
        run: |
          NDK_PATH=$(ls -d $ANDROID_SDK_ROOT/ndk/* | sort -V | tail -n 1)
          echo "ANDROID_NDK_HOME=$NDK_PATH" >> $GITHUB_ENV
          echo "NDK_LLVM=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin" >> $GITHUB_ENV
          echo "$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin" >> $GITHUB_PATH

      - name: Clone Source Code
        run: |
          git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
          git clone --depth 1 https://github.com/mpv-player/mpv.git mpv

      - name: Compile Ultra-Lean Binaries
        run: |
          set -euo pipefail
          WORKDIR=$(pwd)
          PREFIX="$WORKDIR/prefix"
          mkdir -p "$PREFIX"

          # خريطة عزل الرموز التامة
          cat << 'EOF' > mpv.map
          {
              global:
                  mpv_*;
                  Java_*;
                  JNI_OnLoad;
              local:
                  *;
          };
          EOF

          # رايات التحسين القصوى
          export EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
          export EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu -Wl,-z,max-page-size=16384 -Wl,--version-script=$WORKDIR/mpv.map"

          # 1. بناء FFmpeg مجرد من كوديكس وموزعات الترجمة
          mkdir -p build_ffmpeg && cd build_ffmpeg
          ../ffmpeg/configure \
            --target-os=android --arch=aarch64 --cpu=armv8-a --enable-cross-compile \
            --cross-prefix=aarch64-linux-android24- --cc=aarch64-linux-android24-clang \
            --prefix="$PREFIX" \
            --extra-cflags="$EXTRA_CFLAGS -I$PREFIX/include" \
            --extra-ldflags="$EXTRA_LDFLAGS -L$PREFIX/lib" \
            --disable-static --enable-shared --disable-everything --disable-doc --disable-programs \
            --disable-encoders --disable-muxers --disable-devices --disable-filters \
            --disable-iconv --disable-bzlib --disable-lzma --disable-xlib \
            --enable-jni --enable-mediacodec \
            --disable-hwaccels \
            --enable-hwaccel=h264_mediacodec --enable-hwaccel=hevc_mediacodec --enable-hwaccel=vp9_mediacodec \
            --enable-decoder=h264,hevc,vp8,vp9,mpeg4,aac,mp3 \
            --enable-demuxer=mov,matroska,flv,hls,dash,aac,mp3,mpegts \
            --enable-parser=h264,hevc,av1,vp9,aac,mpegaudio \
            --enable-protocol=file,http,https,tcp,udp,hls,tls
          make -j$(nproc)
          make install
          cd "$WORKDIR"

          # 2. ملف الـ Cross compilation لـ Meson
          export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
          export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"

          cat << EOF > android_cross.txt
          [binaries]
          c = '$NDK_LLVM/aarch64-linux-android24-clang'
          cpp = '$NDK_LLVM/aarch64-linux-android24-clang++'
          ar = '$NDK_LLVM/llvm-ar'
          strip = '$NDK_LLVM/llvm-strip'
          pkg-config = 'pkg-config'

          [host_machine]
          system = 'android'
          cpu_family = 'aarch64'
          cpu = 'armv8-a'
          endian = 'little'

          [built-in options]
          c_args = ['-Os', '-flto', '-fvisibility=hidden', '-I$PREFIX/include']
          c_link_args = ['-Wl,--gc-sections', '-Wl,-s', '-flto', '-Wl,--icf=all', '-L$PREFIX/lib']
          EOF

          # 3. بناء MPV مع إيقاف libass نهائياً
          meson setup build_mpv mpv \
            --cross-file=android_cross.txt \
            --prefix="$PREFIX" \
            --buildtype=release \
            --default-library=shared \
            -Doptimization=s -Db_lto=true -Dcplayer=false -Degl-android=enabled \
            -Dlibass=disabled \
            -Dlcms2=disabled -Drubberband=disabled -Dfontconfig=disabled -Dexpat=disabled \
            -Dlua=disabled -Djavascript=disabled -Dlibsmbclient=disabled -Duchardet=disabled \
            -Dcdda=disabled -Ddvbin=disabled -Ddvdnav=disabled -Ddvdread=disabled \
            -Dmanpage-build=disabled -Dhtml-build=disabled -Dtests=disabled -Ddocs=disabled

          ninja -C build_mpv -j$(nproc)
          ninja -C build_mpv install

          # تجريد المقاطع الداخلية والتعليقات
          llvm-strip --strip-debug --strip-unneeded -R .comment "$PREFIX/lib/libmpv.so"

      - name: Upload Ultra-Lean libmpv.so
        uses: actions/upload-artifact@v4
        with:
          name: libmpv-arm64-ultra-lean
          path: prefix/lib/libmpv.so
