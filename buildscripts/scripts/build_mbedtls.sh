cmake -B "${BUILD_DIR}" -S "${SRC_DIR}" \
            -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI=arm64-v8a \
            -DANDROID_PLATFORM=android-24 \
            -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
            -DENABLE_TESTING=OFF \
            -DENABLE_PROGRAMS=OFF \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_FLAGS="-Os -flto -fPIC"

          ninja -C "${BUILD_DIR}" install
