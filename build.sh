#!/bin/bash -xe
set -xe

function parseArgs(){
   for change in "$@"; do
      name="${change%%=*}"
      value="${change#*=}"
      eval $name="$value"
   done
}

function buildZlib(){
    if [ -f "/tmp/zlib-1.2.13/zlib1.dll" ]; then 
        export ZLIB_LIBRARY=/tmp/zlib-1.2.13/
        export ZLIB_INCLUDE_DIR=/tmp/zlib-1.2.13/
        return
    fi
    pushd /tmp
    wget https://www.zlib.net/zlib-1.2.13.tar.gz
    tar xfz zlib-1.2.13.tar.gz
    pushd zlib-1.2.13
    sed -e 's/^PREFIX =.*$/PREFIX = x86_64-w64-mingw32-/' -i win32/Makefile.gcc
    make -f win32/Makefile.gcc
    BINARY_PATH=$PWD/../mingw64/bin \
    INCLUDE_PATH=$PWD/../mingw64/include \
    LIBRARY_PATH=$PWD/../mingw64/lib \
    make -f win32/Makefile.gcc install SHARED_MODE=1
    popd
    popd
}

function buildOpenSSL(){
    if [ -f "/tmp/openssl-1.1.1t/apps/libssl-1_1-x64.dll" ] &&  [ -f "/tmp/openssl-1.1.1t/apps/libcrypto-1_1-x64.dll" ]; then return; fi
    pushd /tmp
    wget https://www.openssl.org/source/openssl-1.1.1t.tar.gz
    tar xfz openssl-1.1.1t.tar.gz
    pushd openssl-1.1.1t
    #CROSS_COMPILE="x86_64-w64-mingw32-" \
    ./Configure mingw64 \
                no-asm \
                shared \
                --openssldir=$PWD/../mingw64
    VERBOSE=1 make -j
    popd
    popd
}

function downloadSDL(){
    pushd /tmp
    if [ ! -f "SDL2-devel-2.26.3-mingw.tar.gz" ]; then
        wget https://github.com/libsdl-org/SDL/releases/download/release-2.26.3/SDL2-devel-2.26.3-mingw.tar.gz
    fi
    if [ ! -d "SDL2-2.26.3" ]; then
        tar xfz SDL2-devel-2.26.3-mingw.tar.gz
    fi
    popd
}

function main(){
    local target=""
    parseArgs $@

    if [ "$target" == "x86" ]; then #host linux, target linux
        mkdir -p x86-build
        pushd x86-build
        rm -fr *
        cmake -G Ninja ..
        ninja --verbose
        popd
    elif [ "$target" == "win64" ]; then #host linux, target windows
    	source ./x86_64-w64-mingw32.sh
        #sudo apt-get install -y mingw-w64 \
            # mingw-w64-common \
            # mingw-w64-tools \
            # mingw-w64-i686-dev \
            # mingw-w64-x86-64-dev

        downloadSDL
        #https://github.com/curl/curl/issues/1492
        buildZlib
        buildOpenSSL

        mkdir -p win64-build
        pushd win64-build
        # ninja --verbose -j1; exit 0

        rm -fr *
        cmake -DCMAKE_TOOLCHAIN_FILE=$(pwd)/../x86_64-w64-mingw32.cmake \
            -DCMAKE_MODULE_PATH=$(pwd)/../cmake-modules \
            -DCMAKE_SKIP_RPATH=TRUE \
            -DCMAKE_SKIP_INSTALL_RPATH=TRUE \
            -DWIN32=TRUE \
            -DWITH_GCRYPT=OFF \
            -DWITH_MBEDTLS=OFF \
            -DHAVE_STRTOULL=1 \
            -DHAVE_COMPILER__FUNCTION__=1 \
            -DHAVE_GETADDRINFO=1 \
            -DUSE_CPYTHON=OFF \
            -G "Ninja" ..
        ninja --verbose
        ln -sf lib/libssh.so.4.9.0 .
        popd
    elif [ "$target" == "msys" ]; then #host windows, target windows
        mkdir -p msys-build
        pushd msys-build
        cmake \
            -DUSE_CPYTHON=OFF \
            -G "MSYS Makefiles" ..
        VERBOSE=1 make -j
        popd
    fi
}

main $@