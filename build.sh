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
        if [ "$clean" == "true" ]; then
            rm -fr *
        fi
        cmake -G Ninja ..
        ninja --verbose
        popd
    elif [ "$target" == "mingw" ]; then #host linux, target windows
    	source ./toolchains/x86_64-w64-mingw32.sh
        #sudo apt-get install -y mingw-w64 \
            # mingw-w64-common \
            # mingw-w64-tools \
            # mingw-w64-i686-dev \
            # mingw-w64-x86-64-dev

        downloadSDL
        #https://github.com/curl/curl/issues/1492
        buildZlib
        buildOpenSSL

        mkdir -p mingw-build
        pushd mingw-build
        # ninja --verbose -j1; exit 0

        if [ "$clean" == "true" ]; then
            rm -fr *
        fi
        cmake -DCMAKE_TOOLCHAIN_FILE=$(pwd)/../toolchains/x86_64-w64-mingw32.cmake \
            -DCMAKE_MODULE_PATH=$(pwd)/../cmake-modules \
            -DCMAKE_SKIP_RPATH=TRUE \
            -DCMAKE_SKIP_INSTALL_RPATH=TRUE \
            -DWIN32=TRUE \
            -DMINGW64=${MINGW64} \
            -DWITH_GCRYPT=OFF \
            -DWITH_MBEDTLS=OFF \
            -DHAVE_STRTOULL=1 \
            -DHAVE_COMPILER__FUNCTION__=1 \
            -DHAVE_GETADDRINFO=1 \
            -DENABLE_CUSTOM_COMPILER_FLAGS=OFF \
            -DBUILD_SHARED_LIBS=OFF -DBUILD_CLAR=OFF -DTHREADSAFE=ON -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_RC_COMPILER="$(which x86_64-w64-mingw32-windres)" -DDLLTOOL="$(which x86_64-w64-mingw32-dlltool)" -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_INSTALL_PREFIX=../install-win \
            -G "Ninja" ..
        ninja --verbose
        cp -f ../utils/python311/python311.dll .
        cp -f /tmp/zlib-1.2.13/zlib1.dll .
        cp -f /tmp/openssl-1.1.1t/libcrypto-1_1-x64.dll .
        cp -f /tmp/openssl-1.1.1t/libssl-1_1-x64.dll .
        cp -f /tmp/SDL2-2.26.3/x86_64-w64-mingw32/bin/SDL2.dll .
        cp -f /usr/x86_64-w64-mingw32/lib/*dll.a .
        cp -f /usr/x86_64-w64-mingw32/lib/*dll .
        popd
    elif [ "$target" == "msys" ]; then #host windows, target windows
        mkdir -p msys-build
        pushd msys-build
        if [ "$clean" == "true" ]; then
            rm -fr *
        fi
        cmake \
            -DMSYS=TRUE \
            -G "MSYS Makefiles" ..
        VERBOSE=1 make -j
        ln -sf libssh/src/libssh.dll .
        popd
    else
        set +x
        echo "Usage: ./builds.h target=<x86|mingw|msys> [clean=true]"
        echo "Possible targets are x86, mingw, msys. "
        echo "Use only one target depending on your host machine (where you are building), and target machine (where you will run the compiled code)"
        echo "  x86:    build machine is x86-linux and target machine is x86-linux"
        echo "  mingw:  build machine is x86-linux and target machine is x86-windows - you will need to install mingw on linux for this"
        echo "  msys:   build machine is x86-windows and target machine is x86-windows - you will need to install msys2 on Windows for this"
        echo "          https://www.msys2.org/wiki/MSYS2-installation/"
        echo "   "
        set -x
    fi
}

main $@