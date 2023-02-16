#mkdir -p x86-build
#cd x86-build
#rm -fr *; cmake -GNinja ..; ninja
#on windows, msys2:
#cmake -G "MSYS Makefiles" ..; make -j
#PATH=$PATH:/c/repos/factory-installer/x86-build/libssh/src/ ./app-factory-installer.exe
#on linux, building for windows:
#cmake -DCMAKE_TOOLCHAIN_FILE=../x86_64-w64-mingw32.cmake -G Ninja ..

cmake_minimum_required(VERSION 3.10)
set (project "factory-installer")
project(${project})


OPTION(WITH_EXAMPLES "" OFF)
SET(WITH_EXAMPLES OFF CACHE BOOL "Dont build LibSSH Examples")
SET(BUILD_STATIC_LIB ON CACHE BOOL "Build static library")

if (MINGW)
find_package(SDL2 REQUIRED)
endif()
add_subdirectory(libssh)
add_subdirectory(lvgl-libraries)
add_subdirectory(utils)


set (SOURCES
   mainlib.cpp
   rendering_engine.c
   ssh_session.h
   ssh_session.cpp
   scp_session.h
   scp_session.cpp
)


set (INC_DIRS
   target/include/
   ${PROJECT_SOURCE_DIR}
   ${PROJECT_SOURCE_DIR}/.. 
   ${CMAKE_SOURCE_DIR}/utils
   #${CMAKE_SOURCE_DIR}/extlibs/lvgl/installs/include
   #${CMAKE_SOURCE_DIR}/extlibs/cJSON/installs/include
   #${CMAKE_SOURCE_DIR}/extlibs/cpython/installs/Include
   ${CMAKE_BINARY_DIR}//utils/cpython-prefix/include/python3.12/
   ${CMAKE_SOURCE_DIR}/lvgl-libraries/
   ${CMAKE_BINARY_DIR}/libssh/include/
   ${THIRD_PARTY_LIB_DIR}
   )
set (COMPILE_DEFINITIONS LV_CONF_INCLUDE_SIMPLE)

set(LIBS
   lvgl 
   utils
   ssh
#   cJSON
#   file_utils
#   mq_utils
#   rt
#   pthread
#   python3.12
#   dl
#   util
)
set(LINK_DIRECTORIES
   ${CMAKE_BINARY_DIR}
   ${CMAKE_BINARY_DIR}/libssh/src
   
)

if ((CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64") OR (CMAKE_SYSTEM_PROCESSOR MATCHES "AMD64"))
   set (INC_DIRS 
      ${INC_DIRS}
      /usr/include/SDL2/
      ${SDL_INCLUDE_DIR}
   )
   set (LIBS
      ${LIBS}
      SDL2
   )
   set(LINK_DIRECTORIES
      ${LINK_DIRECTORIES}
      ${SDL_LIB_DIR}
      ${OPENSSL_LIBRARIES}
      ${ZLIB_ROOT}
      /mingw64/bin/
      #${CMAKE_SOURCE_DIR}/../lvgl-libraries/build
   )
   set (COMPILE_DEFINITIONS 
      ${COMPILE_DEFINITIONS} 
      USE_SDL=1
      USE_MONITOR=1 
      MONITOR_HOR_RES=800 
      MONITOR_VER_RES=480
   )
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")  
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

