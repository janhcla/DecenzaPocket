#!/bin/bash

# Xcode Cloud checks out a CMake/Qt repository rather than a checked-in
# .xcodeproj. Generate the container project before Xcode starts its archive
# action. The workflow is configured to use build/ios/DecenzaPocket.xcodeproj.

set -euo pipefail

REPOSITORY_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
QT_VERSION='6.10.2'
QT_INSTALL_ROOT="$HOME/Qt"
PYTHON_ENV="$HOME/.decenza-pocket-xcode-cloud"
BUILD_DIR="$REPOSITORY_ROOT/build/ios"

python3 -m venv "$PYTHON_ENV"
PYTHON="$PYTHON_ENV/bin/python3"
CMAKE="$PYTHON_ENV/bin/cmake"

"$PYTHON" -m pip install --disable-pip-version-check \
  'aqtinstall==3.3.0' \
  'cmake==4.0.3'

"$PYTHON" -m aqt install-qt mac desktop "$QT_VERSION" clang_64 \
  --outputdir "$QT_INSTALL_ROOT" \
  --modules qtshadertools qtmultimedia qtwebsockets qtimageformats

"$PYTHON" -m aqt install-qt mac ios "$QT_VERSION" ios \
  --outputdir "$QT_INSTALL_ROOT" \
  --modules qtshadertools qtmultimedia qtwebsockets qtimageformats

test -n "${CI_BUILD_NUMBER:-}"

"$CMAKE" -S "$REPOSITORY_ROOT" -B "$BUILD_DIR" -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE="$QT_INSTALL_ROOT/$QT_VERSION/ios/lib/cmake/Qt6/qt.toolchain.cmake" \
  -DQT_HOST_PATH="$QT_INSTALL_ROOT/$QT_VERSION/macos" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE=Automatic \
  -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=ARQN5UD84L \
  -DDECENZA_BUILD_NUMBER="$CI_BUILD_NUMBER"

test -d "$BUILD_DIR/DecenzaPocket.xcodeproj"
