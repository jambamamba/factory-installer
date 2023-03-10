#mkdir -p x86-build
#cd x86-build
#rm -fr *; cmake -GNinja ..; ninja
#on windows, msys2:
#cmake -G "MSYS Makefiles" ..; make -j
#PATH=$PATH:/c/repos/factory-installer/x86-build/libssh/src/ ./app-factory-installer.exe
#on linux, building for windows:
#cmake -DCMAKE_TOOLCHAIN_FILE=../utils/toolchains/x86_64-w64-mingw32.cmake -G Ninja ..

cmake_minimum_required(VERSION 3.10)
set (project "factory-installer")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

##############################
set (USE_SDL 1)
set (USE_MONITOR 0)
set (MONITOR_HOR_RES 800)
set (MONITOR_VER_RES 480)
add_compile_definitions(USE_SDL=1)
##############################
# set_property(TARGET "app-${project}" PROPERTY CXX_STANDARD 20)
# set_property(TARGET ${project} PROPERTY CXX_STANDARD 20)
project(${project})

option(WITH_EXAMPLES "" OFF)
add_compile_definitions(
   APP_NAME="${project}"
   MONITOR_HOR_RES=${MONITOR_HOR_RES}
   MONITOR_VER_RES=${MONITOR_VER_RES}
)
add_subdirectory(utils)

if (MINGW)
   add_compile_definitions(DATA_DIR="c:/repos/factory-installer" MINGW=1)
else()
   add_compile_definitions(DATA_DIR="/home/oosman/repos/factory-installer")
endif()

set (SOURCES
   mainlib.cpp
   my_device.h
   my_device.cpp
   rendering_engine.c
)

set (INC_DIRS
   target/include/
   ${PROJECT_SOURCE_DIR}
   ${PROJECT_SOURCE_DIR}/.. 
   ${CMAKE_SOURCE_DIR}/utils
   ${CMAKE_SOURCE_DIR}/utils/lvgl-libraries/
   ${CMAKE_BINARY_DIR}/utils/cpython/
   ${CMAKE_BINARY_DIR}/utils/cpython/include/
  )
if (MINGW)
   set (INC_DIRS ${INC_DIRS} 
      ${CMAKE_SOURCE_DIR}/utils/SDL2-2.26.3/x86_64-w64-mingw32/include
      )
endif()

set (COMPILE_DEFINITIONS LV_CONF_INCLUDE_SIMPLE)

set(LIBS
   lvgl 
   ssh
   utils
   pthread
)

if (MINGW)
   set (LIBS ${LIBS} python312 )
else()
   set (LIBS ${LIBS} python3.12)
endif()

find_package(OpenSSL REQUIRED)
set(LINK_DIRECTORIES
   ${CMAKE_BINARY_DIR}
   ${OPENSSL_LIBRARY_DIR}
   ${ZLIB_ROOT}
   ${CMAKE_BINARY_DIR}/utils/cpython/
)

if (MINGW)
   set (LINK_DIRECTORIES 
      ${LINK_DIRECTORIES} 
      ${SDL2_LIB_DIR}
      /mingw64/bin/ 
      )
else()
   # set (LINK_DIRECTORIES ${LINK_DIRECTORIES} 
   #    ${CMAKE_SOURCE_DIR}/utils/cpython/build/x86-build
   #    )
endif()

if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
   set (INC_DIRS 
      ${INC_DIRS}
      ${SDL2_INCLUDE_DIRS}
   )
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")  
endif()

if(USE_SDL)
   find_package(SDL2 REQUIRED SDL2)
   set(LIBS
    ${LIBS}
    SDL2::SDL2
    )
endif()

##############################
add_library(${project} STATIC ${SOURCES})
target_include_directories(${project} PRIVATE ${INC_DIRS})
target_link_directories(${project} PRIVATE ${LINK_DIRECTORIES})
target_link_libraries(${project} PRIVATE ${LIBS})
target_compile_definitions(${project} PRIVATE ${COMPILE_DEFINITIONS}) 
target_compile_options(${project} PRIVATE -mwindows) 
target_link_options(${project} PRIVATE -mwindows) 
#set_target_properties(${project} PROPERTIES WIN32_EXECUTABLE FALSE)

add_executable("app-${project}" ${SOURCES} main.c)
target_include_directories("app-${project}" PRIVATE ${INC_DIRS})
target_link_directories("app-${project}" PRIVATE ${LINK_DIRECTORIES})
target_link_libraries("app-${project}" PRIVATE ${LIBS})
target_compile_definitions("app-${project}" PRIVATE ${COMPILE_DEFINITIONS}) 
target_compile_options("app-${project}" PRIVATE -mwindows) 
target_link_options("app-${project}" PRIVATE -mwindows)
#set_target_properties("app-${project}" PROPERTIES WIN32_EXECUTABLE FALSE)
