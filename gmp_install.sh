#!/bin/bash
set -e

GMP_TAR=gmp-${GMP_VERSION}.tar.xz
GMP_DIR=${ROOT_FOLDER}/gmp/gmp-${GMP_VERSION}

mkdir -p "${ROOT_FOLDER}/gmp"
cd "${ROOT_FOLDER}/gmp"

# Download GMP if not already present
if [ ! -f "$GMP_TAR" ]; then
    echo "Downloading GMP $GMP_VERSION..."
    curl -O https://gmplib.org/download/gmp/$GMP_TAR
fi

# Extract
if [ ! -d "$GMP_DIR" ]; then
    tar -xf $GMP_TAR
fi

CPU_COUNT=$(sysctl -n hw.ncpu)

# SDK paths
DEVICE_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)

# # Output directories
DEVICE_BUILD=${ROOT_FOLDER}/gmp/device_build
SIM_BUILD=${ROOT_FOLDER}/gmp/simulator_build

mkdir -p $DEVICE_BUILD
mkdir -p $SIM_BUILD
cd $GMP_DIR

# -----------------------------
# 1) Build for iOS device (arm64)
# -----------------------------
echo "Building GMP for iOS device (arm64)..."
make distclean || true

export CC="$(xcrun --sdk iphoneos -f clang)"
export CFLAGS="-isysroot $DEVICE_SDK -arch arm64 -miphoneos-version-min=12.0"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="$CFLAGS"

${GMP_DIR}/configure --host=arm-apple-darwin --disable-shared --enable-static --disable-assembly
make -j$CPU_COUNT
cp ${GMP_DIR}/.libs/libgmp.a $DEVICE_BUILD/libgmp.a
cp ${GMP_DIR}/*.h $DEVICE_BUILD/

# -----------------------------
# 2) Build for iOS simulator (arm64)
# -----------------------------
echo "Building GMP for iOS simulator (arm64)..."
# Architectures for simulator
SIM_ARCHS=("x86_64" "arm64")

for ARCH in "${SIM_ARCHS[@]}"; do
    echo "Building GMP for iOS simulator ($ARCH)..."
    make distclean || true
    export CC="$(xcrun --sdk iphonesimulator -f clang)"
    export CFLAGS="-isysroot $SIM_SDK -arch $ARCH -mios-simulator-version-min=12.0"
    export CPPFLAGS="$CFLAGS"
    export LDFLAGS="$CFLAGS"

    # Adjust host for architecture
    if [ "$ARCH" == "x86_64" ]; then
        HOST="x86_64-apple-darwin"
    else
        HOST="arm-apple-darwin"
    fi

    ${GMP_DIR}/configure --host=$HOST --disable-shared --enable-static --disable-assembly
    make -j$CPU_COUNT

    cp ${GMP_DIR}/.libs/libgmp.a $SIM_BUILD/libgmp_$ARCH.a
done

# Combine simulator slices into one universal library
lipo -create -output $SIM_BUILD/libgmp.a $SIM_BUILD/libgmp_x86_64.a $SIM_BUILD/libgmp_arm64.a
rm $SIM_BUILD/libgmp_x86_64.a $SIM_BUILD/libgmp_arm64.a

echo "Done!"
echo "Device library: $DEVICE_BUILD/libgmp.a"
echo "Simulator library: $SIM_BUILD/libgmp.a"
echo "Headers are in device_build."