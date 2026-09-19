#!/bin/bash -e

. ../../include/path.sh

if [ "$1" == "build" ]; then
    true
elif [ "$1" == "clean" ]; then
    rm -rf _build$ndk_suffix
    exit 0
else
    exit 255
fi

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

cpu=armv7-a
[[ "$ndk_triple" == "aarch64"* ]] && cpu=armv8-a
[[ "$ndk_triple" == "x86_64"* ]] && cpu=generic
[[ "$ndk_triple" == "i686"* ]] && cpu="i686 --disable-asm"

cpuflags=
[[ "$ndk_triple" == "arm"* ]] && cpuflags="$cpuflags -mfpu=neon -mcpu=cortex-a8"

# --- الرايات القوية لتحسين الحجم والربط ---
EXTRA_CFLAGS="-Os -flto -fvisibility=hidden -ffunction-sections -fdata-sections -fmerge-all-constants"
EXTRA_LDFLAGS="-Wl,--gc-sections -Wl,-s -flto -Wl,--icf=all -Wl,--pack-dyn-relocs=android+relr -Wl,--exclude-libs,ALL -Wl,-Bsymbolic-functions -Wl,--hash-style=gnu"

args=(
    --target-os=android --enable-cross-compile
    --cross-prefix=$ndk_triple- --cc=$CC --pkg-config=pkg-config --nm=llvm-nm
    --arch=${ndk_triple%%-*} --cpu=$cpu

    # دمج رايات الـ CFLAGS والـ LDFLAGS مع مسارات المكتبات الأصلية
    --extra-cflags="-I$prefix_dir/include $cpuflags $EXTRA_CFLAGS"
    --extra-ldflags="-L$prefix_dir/lib $EXTRA_LDFLAGS"

    --disable-static --enable-shared --enable-{gpl,version3}
    --disable-vulkan
    --disable-{stripping,doc,programs}

    # --- بداية القص الصارم (تصفير كل الحشو) ---
    --disable-everything
    --disable-encoders
    --disable-muxers
    --disable-devices
    --disable-filters

    # تعطيل مكتبات النظام غير المطلوبة
    --disable-iconv
    --disable-bzlib
    --disable-lzma
    --disable-xlib

    # الأمان والتسريع العتادي
    --enable-jni
    --enable-mediacodec
    --enable-mbedtls
    --enable-libdav1d
    --disable-hwaccels
    --enable-hwaccel=h264_mediacodec
    --enable-hwaccel=hevc_mediacodec
    --enable-hwaccel=vp9_mediacodec
    --enable-hwaccel=av1_mediacodec

    # كوديكس الفيديو والصوت الأساسية
    --enable-decoder=h264,hevc,vp8,vp9,mpeg4
    --enable-decoder=libdav1d
    --enable-decoder=aac,flac,opus,mp3,ac3,eac3,vorbis

    # دعم الترجمة (ضروري للأنمي والـ Softsubs)
    --enable-decoder=ass,ssa,subrip,webvtt,mov_text
    --enable-demuxer=ass,srt,webvtt

    # الـ Parsers الأساسية
    --enable-parser=h264,hevc,av1,vp9,aac,mpegaudio,opus,flac,vorbis

    # الـ Demuxers الأساسية
    --enable-demuxer=mov,matroska,flv,hls,dash,aac,flac,mp3,ogg,mpegts

    # بروتوكولات الشبكة والملفات المحلية
    --enable-protocol=file,http,https,tcp,udp,hls,tls
)

../configure "${args[@]}"

make -j$cores
make DESTDIR="$prefix_dir" install
