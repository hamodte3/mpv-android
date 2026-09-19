#!/bin/bash -e

## Dependency versions
# Make sure to keep v_ndk and v_ndk_n in sync, both are listed on the NDK download page

v_sdk=11076708_latest
v_ndk=r30
v_ndk_n=30.0.16248370
v_sdk_platform=36
v_sdk_build_tools=36.0.0

# تم الإبقاء فقط على حزم التشفير والشبكة الضرورية لروابط البث (HTTPS)
v_mbedtls=3.6.7
v_curl=8.21.0


## Dependency tree (Ultra-Lean Architecture)

dep_mbedtls=()
dep_dav1d=()
dep_libxml2=()

# FFmpeg يعتمد فقط على mbedtls لفتح روابط البث المشفرة (HTTPS/TLS)
dep_ffmpeg=(mbedtls)

# تم تصفير وتفريغ منظومة الترجمة والخطوط بالكامل
dep_freetype2=()
dep_fontconfig=()
dep_fribidi=()
dep_harfbuzz=()
dep_unibreak=()
dep_libass=()

# تم إيقاف محركات السكربتات
dep_lua=()

# محرك الرندر الأساسي والشبكة
dep_libplacebo=()
dep_curl=(mbedtls)

# مشغل MPV مصفى: فيديو + صوت + رندر + شبكة فقط
dep_mpv=(ffmpeg libplacebo curl)
dep_mpv_android=(mpv)


## for CI workflow

# pinned ffmpeg revision
v_ci_ffmpeg=n9.0

# بصمة الكاش الجديدة المصفاة من كل مكتبات الترجمة الميتة
ci_tarball="prefix-n${v_ndk}-m${v_mbedtls}-c${v_curl}-ff${v_ci_ffmpeg}-arm64-ultralean.tgz"
