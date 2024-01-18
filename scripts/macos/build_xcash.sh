#!/bin/sh

. ./config.sh

XCASH_URL="https://github.com/minerjed/xcash-tech-core.git"
XCASH_DIR_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/xcash"
XCASH_VERSION=master
BUILD_TYPE=release
PREFIX=${EXTERNAL_MACOS_DIR}
DEST_LIB_DIR=${EXTERNAL_MACOS_LIB_DIR}/xcash
DEST_INCLUDE_DIR=${EXTERNAL_MACOS_INCLUDE_DIR}/xcash
ARCH=`uname -m`

echo "Cloning xcash from - $XCASH_URL to - $XCASH_DIR_PATH"		
git clone $XCASH_URL $XCASH_DIR_PATH
cd $XCASH_DIR_PATH
git checkout $XCASH_VERSION
git submodule update --init --force
mkdir -p build
cd ..

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $INSTALL_PREFIX ]; then
    INSTALL_PREFIX=${ROOT_DIR}/xcash
fi

echo "Building MACOS ${ARCH}"
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"
rm -r xcash/build > /dev/null

if [ "${ARCH}" == "x86_64" ]; then
	ARCH="x86-64"
fi

mkdir -p xcash/build/${BUILD_TYPE}
pushd xcash/build/${BUILD_TYPE}
cmake -DARCH=${ARCH} \
	-DBUILD_64=ON \
	-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	-DSTATIC=ON \
	-DBUILD_GUI_DEPS=ON \
	-DUNBOUND_INCLUDE_DIR=${EXTERNAL_MACOS_INCLUDE_DIR} \
	-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}  \
    -DUSE_DEVICE_TREZOR=OFF \
	../..
make wallet_api -j4
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;
cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
popd
