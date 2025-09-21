# from https://github.com/OsamaMazhar/iOS-framework-cmake/blob/main/README.md

#!/bin/bash
set -e

if [ -e "${ROOT_FOLDER}/symengine" ]; then
    echo "leetal's ios-cmake is already installed, skipping download."
else
    echo "Downloading Symengine..."
    git clone "https://github.com/symengine/symengine" ${ROOT_FOLDER}/symengine
fi

if [ -e "${ROOT_FOLDER}/ios-cmake" ]; then
    echo "leetal's ios-cmake is already installed, skipping download."
else 
    echo "Downloading leetal's ios-cmake..."
    git clone "https://github.com/leetal/ios-cmake.git" ${ROOT_FOLDER}/ios-cmake
fi

mkdir ${ROOT_FOLDER}/symengine/build_device && cd ${ROOT_FOLDER}/symengine/build_device

cmake -G Xcode \
    -B "${ROOT_FOLDER}/symengine/build_device" \
    -S "${ROOT_FOLDER}/symengine" \
    -DCMAKE_TOOLCHAIN_FILE="${ROOT_FOLDER}/ios-cmake/ios.toolchain.cmake" \
    -DPLATFORM=OS64 \
    -DCMAKE_INSTALL_PREFIX="${ROOT_FOLDER}/symengine/install_device" \
    -DCMAKE_CONFIGURATION_TYPES="Release" \
    -DGMP_INCLUDE_DIR="${ROOT_FOLDER}/gmp/device_build" \
    -DGMP_LIBRARY="${ROOT_FOLDER}/gmp/device_build/libgmp.a" \
    -DGMP_LIBRARIES="${ROOT_FOLDER}/gmp/device_build/libgmp.a" \
    -DCMAKE_C_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/device_build" \
    -DCMAKE_CXX_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/device_build" \
    ${ROOT_FOLDER}/symengine

cmake --build ${ROOT_FOLDER}/symengine/build_device --config Release --target install

echo "Device build finished.  Proceeding to simulator_x86 build."

mkdir ${ROOT_FOLDER}/symengine/build_simulator && cd ${ROOT_FOLDER}/symengine/build_simulator

cmake -G Xcode \
    -B "${ROOT_FOLDER}/symengine/build_simulator" \
    -S "${ROOT_FOLDER}/symengine" \
    -DCMAKE_TOOLCHAIN_FILE="${ROOT_FOLDER}/ios-cmake/ios.toolchain.cmake" \
    -DPLATFORM=SIMULATOR64 \
    -DCMAKE_OSX_SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path) \
    -DCMAKE_INSTALL_PREFIX="${ROOT_FOLDER}/symengine/install_simulator_x86" \
    -DCMAKE_CONFIGURATION_TYPES="Release" \
    -DGMP_INCLUDE_DIR="${ROOT_FOLDER}/gmp/device_build" \
    -DGMP_LIBRARY="${ROOT_FOLDER}/gmp/simulator_build/libgmp.a" \
    -DGMP_LIBRARIES="${ROOT_FOLDER}/gmp/simulator_build/libgmp.a" \
    -DCMAKE_C_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/simulator_build" \
    -DCMAKE_CXX_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/simulator_build" \
    ${ROOT_FOLDER}/symengine

cmake --build ${ROOT_FOLDER}/symengine/build_simulator --config Release --target install

echo "simulator_x86 build finished.  Proceeding to simulator_arm64 build."

cmake -G Xcode \
    -B "${ROOT_FOLDER}/symengine/build_simulator" \
    -S "${ROOT_FOLDER}/symengine" \
    -DCMAKE_TOOLCHAIN_FILE="${ROOT_FOLDER}/ios-cmake/ios.toolchain.cmake" \
    -DPLATFORM=SIMULATORARM64 \
    -DCMAKE_OSX_SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path) \
    -DCMAKE_INSTALL_PREFIX="${ROOT_FOLDER}/symengine/install_simulator_arm64" \
    -DCMAKE_CONFIGURATION_TYPES="Release" \
    -DGMP_INCLUDE_DIR="${ROOT_FOLDER}/gmp/device_build" \
    -DGMP_LIBRARY="${ROOT_FOLDER}/gmp/simulator_build/libgmp.a" \
    -DGMP_LIBRARIES="${ROOT_FOLDER}/gmp/simulator_build/libgmp.a" \
    -DCMAKE_C_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/simulator_build" \
    -DCMAKE_CXX_FLAGS="-I${ROOT_FOLDER}/symengine -I${ROOT_FOLDER}/gmp/simulator_build" \
    ${ROOT_FOLDER}/symengine

cmake --build ${ROOT_FOLDER}/symengine/build_simulator --config Release --target install


# Combine into a fat lib
mkdir -p ${ROOT_FOLDER}/symengine/install_simulator/lib/
lipo -create \
  ${ROOT_FOLDER}/symengine/install_simulator_x86/lib/libsymengine.a \
  ${ROOT_FOLDER}/symengine/install_simulator_arm64/lib/libsymengine.a \
  -output ${ROOT_FOLDER}/symengine/install_simulator/lib/libsymengine.a
