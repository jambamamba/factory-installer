#!/bin/bash -xe
set -xe

function parseArgs(){
   for change in "$@"; do
      name="${change%%=*}"
      value="${change#*=}"
      eval $name="$value"
   done
}

function packageForWindows(){
    parseArgs $@
    mkdir -p factory-installer
    rm -fr factory-installer/*
    cp *dll factory-installer/
    cp app-factory-installer.exe factory-installer/
    cp ../config.json factory-installer/
    rm -f factory-installer/vcruntime*.dll
    rm -f factory-installer.zip
    zip factory-installer.zip factory-installer/*
    rm -fr factory-installer
}

function packageForUbuntu(){
    parseArgs $@
    mkdir -p factory-installer
    rm -fr factory-installer/*

    rsync -uav libpython*.so* factory-installer/
    rsync -uav libssh.so.4 factory-installer/
    rsync -uav utils/cJSON/libcjson.so.1 factory-installer/
    rsync -uav utils/curl/lib/libcurl-d.so.4 factory-installer/
    rsync -uav utils/openssl/libcrypto.so.1.1 factory-installer/
    rsync -uav utils/zlib/libz.so.1 factory-installer/
    rsync -uav utils/openssl/libssl.so.1.1 factory-installer/
    cp app-factory-installer factory-installer/
    cp ../config.json factory-installer/
    zip factory-installer.zip factory-installer/*
    rm -fr factory-installer
}

function main(){
    local target=""
    parseArgs $@

    if [ "$target" == "x86" ]; then #host linux, target linux
        local builddir="$(pwd)/x86-build/utils"
        mkdir -p x86-build
        if [ "$clean" == "true" ]; then
            rm -fr x86-build/*
        fi
        pushd utils
        ./install-libs.sh target="$target" builddir="${builddir}" clean="$clean"
        popd
        pushd x86-build
        cmake -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_MODULE_PATH=$(pwd)/../utils/cmake-modules \
            -DCMAKE_PREFIX_PATH=$(pwd)/../utils/cmake-modules \
            -G Ninja ..
        ninja --verbose
        ln -sf "../config.json" .
        ln -sf "../config.json" "/home/$USER/.local/share/app-factory-installer/config.json"
        ln -sf "../py/main.py" .
        ln -sf "../py/main.py" "/home/$USER/.local/share/app-factory-installer/main.py"
        rsync -uav utils/zlib/libz.so* .
        rsync -uav utils/cpython/libpython*.so* .
        rsync -uav utils/openssl/libcrypto.so* .
        rsync -uav utils/openssl/libssl.so* .
        rsync -uav lib/libssh.so* .
        packageForUbuntu
        popd
    elif [ "$target" == "mingw" ]; then #host linux, target windows
        local builddir="$(pwd)/mingw-build/utils"
        mkdir -p mingw-build
        if [ "$clean" == "true" ]; then
            rm -fr mingw-build/*
        fi
        pushd utils
        source ./toolchains/x86_64-w64-mingw32.sh
        ./install-libs.sh target="$target" builddir="${builddir}" clean="$clean"
        popd
        pushd mingw-build
        cmake -DCMAKE_TOOLCHAIN_FILE=$(pwd)/../utils/toolchains/x86_64-w64-mingw32.cmake \
            -DCMAKE_MODULE_PATH=$(pwd)/../utils/cmake-modules \
            -DCMAKE_PREFIX_PATH=$(pwd)/../utils/cmake-modules \
            -DCMAKE_INSTALL_BINDIR=$(pwd) \
            -DCMAKE_INSTALL_LIBDIR=$(pwd) \
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
            -DBUILD_CLAR=OFF \
            -DTHREADSAFE=ON \
            -DCMAKE_SYSTEM_NAME=Windows \
            -DCMAKE_C_COMPILER=$CC \
            -DCMAKE_RC_COMPILER=$RESCOMP \
            -DDLLTOOL=$DLLTOOL \
            -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_INSTALL_PREFIX=../install-win \
            -G "Ninja" ..
        ninja --verbose
        ln -sf "../config.json" .
        ln -sf "../config.json" "/home/$USER/.local/share/app-factory-installer/config.json"
        ln -sf "../py/main.py" .
        ln -sf "../py/main.py" "/home/$USER/.local/share/app-factory-installer/main.py"
        # do this if on Windows: 
        #  cp ../config.json /c/Users/oosman/AppData/Roaming/app-factory-installer/
        #  cp ../py/main.py /c/Users/oosman/AppData/Roaming/app-factory-installer/
        cp -f utils/zlib/libzlib1.dll libzlib.dll 
        cp -f utils/libssh/src/libssh.dll .
        cp -f utils/cJSON/libcjson.dll .
        cp -f utils/curl/lib/libcurl-d.dll .
        cp -f utils/openssl/libcrypto-1_1-x64.dll .
        cp -f utils/openssl/libssl-1_1-x64.dll .
        cp -f /usr/x86_64-w64-mingw32/lib/*dll.a .
        cp -f /usr/x86_64-w64-mingw32/lib/*dll .
        cp -f utils/cpython/*.dll .
        cp -f ../utils/SDL2-2.26.3/x86_64-w64-mingw32/bin/SDL2.dll .
        packageForWindows
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

time main $@
