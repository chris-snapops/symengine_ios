#!/bin/bash
set -e  # stop script on error

# Paths
export GMP_VERSION="6.3.0"
REQUIRED_VARS=("ROOT_FOLDER" "CODESIGN_IDENTITY")


# Load .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "Error: $VAR is not set in .env"
        echo "See README for required variables."
        exit 1
    fi
done

echo "Root Folder: $ROOT_FOLDER"
echo "Codesign ID: $CODESIGN_IDENTITY"
echo "All required environment variables are set!"
exit 0

brew unlink symengine
brew unlink gmp

./gmp_install.sh
./symengine_install.sh

OUT_DIR="${ROOT_FOLDER}/framework"
SYMENGINE_XCFRAMEWORK_PATH="$OUT_DIR/symengine.xcframework"
GMP_XCFRAMEWORK_PATH="$OUT_DIR/gmp.xcframework"

SYMENGINE_LIB_DEVICE="${ROOT_FOLDER}/symengine/install_device/lib/libsymengine.a"
SYMENGINE_LIB_SIM="${ROOT_FOLDER}/symengine/install_simulator/lib/libsymengine.a"
GMP_LIB_DEVICE="${ROOT_FOLDER}/gmp/device_build/libgmp.a"
GMP_LIB_SIM="${ROOT_FOLDER}/gmp/simulator_build/libgmp.a"

SYMENGINE_INCLUDE="${ROOT_FOLDER}/symengine/install_device/include/symengine"
GMP_INCLUDE="${ROOT_FOLDER}/gmp/device_build"

# Clean old frameworks
rm -rf "$SYMENGINE_XCFRAMEWORK_PATH" "$GMP_XCFRAMEWORK_PATH"
mkdir -p "$OUT_DIR"

##########################
# SymEngine XCFramework
##########################
TMP_HEADERS_SYMENGINE="$OUT_DIR/Headers_symengine"
rm -rf "$TMP_HEADERS_SYMENGINE"
mkdir -p "$TMP_HEADERS_SYMENGINE/symengine" "$TMP_HEADERS_SYMENGINE/Modules"

# Copy SymEngine headers (but NOT GMP headers)
cp -R "$SYMENGINE_INCLUDE"/* "$TMP_HEADERS_SYMENGINE/symengine/"

# Umbrella header
cat > "$TMP_HEADERS_SYMENGINE/symengine.h" <<EOL
#ifndef SYMENGINE_H
#define SYMENGINE_H

#include "basic.h"
#include "symbol.h"
#include "integer.h"
#include "rational.h"
#include "real_double.h"
#include "complex_double.h"
#include "add.h"
#include "mul.h"
#include "pow.h"
#include "div.h"
#include "neg.h"
#include "function.h"
#include "eval_double.h"
#include "derivative.h"
#include "printer.h"
#include "visitor.h"

#endif // SYMENGINE_H
EOL

# Module map
cat > "$TMP_HEADERS_SYMENGINE/Modules/symengine.modulemap" <<EOL
framework module symengine {
    umbrella header "symengine.h"
    export *
}
EOL

# Build SymEngine XCFramework
xcodebuild -create-xcframework \
    -library "$SYMENGINE_LIB_DEVICE" -headers "$TMP_HEADERS_SYMENGINE" \
    -library "$SYMENGINE_LIB_SIM" -headers "$TMP_HEADERS_SYMENGINE" \
    -output "$SYMENGINE_XCFRAMEWORK_PATH"

codesign --force --sign "$CODESIGN_IDENTITY" --timestamp=none "$SYMENGINE_XCFRAMEWORK_PATH"

##########################
# GMP XCFramework
##########################
TMP_HEADERS_GMP="$OUT_DIR/Headers_gmp"
rm -rf "$TMP_HEADERS_GMP"
mkdir -p "$TMP_HEADERS_GMP/Modules"

# Copy only GMP headers
cp "$GMP_INCLUDE"/*.h "$TMP_HEADERS_GMP/"

# Module map
cat > "$TMP_HEADERS_GMP/Modules/gmp.modulemap" <<EOL
framework module gmp {
    umbrella header "gmp.h"
    export *
}
EOL

# Build GMP XCFramework
xcodebuild -create-xcframework \
    -library "$GMP_LIB_DEVICE" -headers "$TMP_HEADERS_GMP" \
    -library "$GMP_LIB_SIM" -headers "$TMP_HEADERS_GMP" \
    -output "$GMP_XCFRAMEWORK_PATH"

codesign --force --sign "$CODESIGN_IDENTITY" --timestamp=none "$GMP_XCFRAMEWORK_PATH"

# Clean up temporary headers
rm -rf "$TMP_HEADERS_SYMENGINE" "$TMP_HEADERS_GMP"

echo "XCFrameworks created at $SYMENGINE_XCFRAMEWORK_PATH"
echo "and $GMP_XCFRAMEWORK_PATH"
echo "See README for the next steps."
