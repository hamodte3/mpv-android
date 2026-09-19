#!/bin/bash -e

# الانتقال لمجلد buildscripts
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

. ./include/depinfo.sh

v_ci_archs="arm64"
## Dependency versions
v_sdk=11076708_latest
v_ndk=r30
v_ndk_n=30.0.16248370
v_sdk_platform=36
v_sdk_build_tools=36.0.0

v_mbedtls=3.6.7
v_curl=8.21.0

## Dependency tree (Ultra-Lean: no subtitles, no lua, no dead codecs)
dep_mbedtls=()
dep_dav1d=()
dep_libxml2=()
dep_ffmpeg=(mbedtls)
dep_freetype2=()
dep_fontconfig=()
dep_fribidi=()
dep_harfbuzz=()
dep_unibreak=()
dep_libass=()
dep_lua=()
dep_libplacebo=()
dep_curl=(mbedtls)
dep_mpv=(ffmpeg libplacebo curl)
dep_mpv_android=(mpv)

## CI Cache Tarball
v_ci_ffmpeg=n9.0
ci_tarball="prefix-n${v_ndk}-m${v_mbedtls}-c${v_curl}-ff${v_ci_ffmpeg}-arm64-ultralean.tgz"
