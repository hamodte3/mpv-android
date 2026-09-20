#!/usr/bin/env bash
set -euo pipefail

# مسارات بيئة العمل
export API_LEVEL="24"
export TARGET_ARCH="aarch64"
export TARGET="aarch64-linux-android${API_LEVEL}"

# تحديد مسار الـ NDK وأداة المترجم
if [ -z "${ANDROID_NDK_HOME:-}" ]; then
    echo "ERROR: ANDROID_NDK_HOME is not set." >&2
    exit 1
fi

export NDK_LLVM="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64"
export PATH="${NDK_LLVM}/bin:${PATH}"

# إصدارات المكتبات
export v_mbedtls="3.6.7"
export v_curl="8.21.0"
export v_ffmpeg="n7.1" # يفضل استخدام وسم مستقر
