#!/bin/sh

path=`dirname $0`

TARGET_NAME=gameNetwork
CONFIG=Release
DEVICE_TYPE=all
BUILD_TYPE=clean

#
# Checks exit value for error
# 
checkError() {
    if [ $? -ne 0 ]
    then
        echo "Exiting due to errors (above)"
        exit -1
    fi
}

if [ -z "$ANDROID_NDK" ]
then
	echo "ERROR: ANDROID_NDK environment variable must be defined"
	exit 0
fi

# Canonicalize paths
pushd $path > /dev/null
dir=`pwd`
path=$dir
popd > /dev/null

NDK_MODULE_PATH=$path/../../../plugins/
pushd $NDK_MODULE_PATH > /dev/null
dir=`pwd`
NDK_MODULE_PATH=$dir
popd > /dev/null

BIN_DIR=$path/../../../bin/mac
pushd $BIN_DIR > /dev/null
dir=`pwd`
BIN_DIR=$dir
popd > /dev/null


#####################
# Lua Bytecodes     #
#####################

$BIN_DIR/lua2c.sh $path/../../../plugins/gameNetwork/shared/gameNetwork.lua $path/. $CONFIG
checkError

$BIN_DIR/lua2c.sh $path/../../../plugins/gameNetwork/shared/CoronaProvider.gameNetwork.lua $path/. $CONFIG
checkError

######################
# Build .so          #
######################

pushd $path/jni > /dev/null

if [ "Release" == "$CONFIG" ]
then
	echo "Building RELEASE"
	OPTIM_FLAGS="release"
else
	echo "Building DEBUG"
	OPTIM_FLAGS="debug"
fi

if [ "clean" == "$BUILD_TYPE" ]
then
	echo "== Clean build =="
	rm -r $path/obj/ $path/libs/
	FLAGS="-B"
else
	echo "== Incremental build =="
	FLAGS=""
fi

CFLAGS=

if [ "$OPTIM_FLAGS" = "debug" ]
then
	CFLAGS="${CFLAGS} -DRtt_DEBUG -g"
	FLAGS="$FLAGS NDK_DEBUG=1"
fi

export NDK_MODULE_PATH=$NDK_MODULE_PATH
echo $NDK_MODULE_PATH

# Copy .so files
LIBS_SRC_DIR="$HOME/Library/Application Support/Corona/Native/Corona/android/lib/Corona/libs/armeabi-v7a"
LIBS_DST_DIR=$path
mkdir -p "$LIBS_DST_DIR"
checkError

cp -v "$LIBS_SRC_DIR"/libcorona.so "$LIBS_DST_DIR"/.
checkError

cp -v "$LIBS_SRC_DIR"/liblua.so "$LIBS_DST_DIR"/.
checkError

if [ -z "$CFLAGS" ]
then
	echo "----------------------------------------------------------------------------"
	echo "$ANDROID_NDK/ndk-build $FLAGS V=1 APP_OPTIM=$OPTIM_FLAGS"
	echo "----------------------------------------------------------------------------"

	$ANDROID_NDK/ndk-build $FLAGS V=1 APP_OPTIM=$OPTIM_FLAGS
	checkError
else
	echo "----------------------------------------------------------------------------"
	echo "$ANDROID_NDK/ndk-build $FLAGS V=1 MY_CFLAGS="$CFLAGS" APP_OPTIM=$OPTIM_FLAGS"
	echo "----------------------------------------------------------------------------"

	$ANDROID_NDK/ndk-build $FLAGS V=1 MY_CFLAGS="$CFLAGS" APP_OPTIM=$OPTIM_FLAGS
	checkError
fi

popd > /dev/null

######################
# Post-compile Steps #
######################

# Copy .so files over to the Android SDK (Java) side of things
cp -rv $path/libs/armeabi-v7a/libgameNetwork.so $path/../../build-core/$TARGET_NAME/android
checkError

