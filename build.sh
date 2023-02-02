#!/bin/bash -e
set -e

#git clone https://github.com/lvgl/lvgl.git
#git checkout v8.2.0
#cd lvgl

#globals:
PROJECT_DIR=$(pwd)
SDK_DIR=/opt/usr_data/sdk
SHA="$(sudo git config --global --add safe.directory $PROJECT_DIR;sudo git rev-parse --verify --short HEAD)"


function parseArgs()
{
   for change in "$@"; do
      name="${change%%=*}"
      value="${change#*=}"
      eval $name="$value"
   done
}


function pushBuildDir(){
	local workdir=$(mktemp -d);
	pushd $workdir
}

function popBuildDir(){
	popd
}
function buildX86(){
	parseArgs $@
	mkdir -p x86-build
	pushd x86-build
	SDK_DIR="$SDK_DIR" cmake -DCMAKE_BUILD_TYPE=Release CMAKE_SYSTEM_PROCESSOR="x86_64" -DBUILD_SHARED_LIBS=OFF  -GNinja ${PROJECT_DIR}
	ninja
	popd
}

function buildArm(){
	parseArgs $@
	mkdir -p arm-build
	pushd arm-build
        source $SDK_DIR/environment-setup-aarch64-fslc-linux
        SDK_DIR=$SDK_DIR cmake -DCMAKE_BUILD_TYPE=Release CMAKE_SYSTEM_PROCESSOR="aarch64" -DBUILD_SHARED_LIBS=OFF -GNinja ${PROJECT_DIR}
	ninja
	popd
}

function stripArchive()
{
	local strip="${SDK_DIR}/sysroots/x86_64-fslcsdk-linux/usr/bin/aarch64-fslc-linux/aarch64-fslc-linux-strip"
	find . -name "*.a" -exec $strip --strip-debug --strip-unneeded -p {} \;
	#find . -name "*.so*" -exec $strip --strip-all -p {} \;
}

function package(){
	parseArgs $@
	local workdir=installs
	mkdir -p $workdir/x86-build
	mkdir -p $workdir/arm-build
	mkdir -p $workdir/include
	
	cp -r $PROJECT_DIR/* $workdir/include/
	pushd $workdir/include/
	find . -name "*" ! -name "*.h" -exec rm -f {} \;
	popd
	find arm-build/ -name "*.a" -exec rsync -uav {} $workdir/arm-build/ \;
	find x86-build/ -name "*.a" -exec rsync -uav {} $workdir/x86-build/ \;
	
	pushd $workdir/arm-build/
	# stripArchive
	#patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:/usr/lib/:/usr/local/lib' *.so
	popd


	tar -cvJf lvgl.$SHA.tar.xz $workdir
	
	echo "Package is built at $(pwd)/$workdir/lvgl.$SHA.tar.xz"
	if [ -d /datadisk/nextgen/out/ ]; then
	   sudo cp -f lvgl.$SHA.tar.xz /datadisk/nextgen/out/
	   echo "Package can be downloaded from https://10.57.3.4/artifacts/lvgl.$SHA.tar.xz"
	fi
	if [ -d /home/$USER/Downloads ]; then
	   sudo cp -f lvgl.$SHA.tar.xz /home/$USER/Downloads/
	   echo "Package is availabled at /home/$USER/Downloads/lvgl.$SHA.tar.xz"
	fi
	sudo mkdir -p $PROJECT_DIR/out
	sudo cp -f lvgl.$SHA.tar.xz $PROJECT_DIR/out
}

function main(){
	parseArgs $@
	pushBuildDir
	buildX86
	buildArm
	package
	popBuildDir
}

time main $@

