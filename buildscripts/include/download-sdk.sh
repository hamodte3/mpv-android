#!/bin/bash -e

. ./include/depinfo.sh
. ./include/path.sh

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET="wget --progress=bar:force"

mkdir -p sdk && cd sdk

# 1. التحقق من ربط Android SDK
if [ ! -d "android-sdk-${os}" ]; then
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        echo "Linking existing Android SDK."
        ln -sfn "$ANDROID_SDK_ROOT" "android-sdk-${os}"
    fi
fi

# 2. تجهيز Android NDK المتوافق وتجاوز التحميل المكرر
if [ ! -d "android-ndk-${v_ndk}" ]; then
    # البحث عن أحدث NDK متوفر في بيئة السيرفر
    SYSTEM_NDK=$(ls -d ${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}/ndk/* 2>/dev/null | sort -V | tail -n 1 || true)
    if [ -n "$SYSTEM_NDK" ] && [ -d "$SYSTEM_NDK" ]; then
        echo "Linking system NDK: $SYSTEM_NDK"
        ln -sfn "$SYSTEM_NDK" "android-ndk-${v_ndk}"
    else
        echo "Downloading NDK ${v_ndk}..."
        $WGET "http://dl.google.com/android/repository/android-ndk-${v_ndk}-linux.zip" -O ndk.zip
        unzip -q ndk.zip
        rm ndk.zip
    fi
fi

# 3. تحميل gas-preprocessor
mkdir -p bin
if [ ! -f bin/gas-preprocessor.pl ]; then
    $WGET "https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl" \
        -O bin/gas-preprocessor.pl
    chmod +x bin/gas-preprocessor.pl
fi

cd ..
echo "==> SDK and NDK setup completed successfully."
