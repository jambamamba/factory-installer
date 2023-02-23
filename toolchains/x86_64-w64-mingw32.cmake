
set(MINGW TRUE)
set(PREFIX "x86_64-w64-mingw32")
set(CC "${PREFIX}-gcc")
set(CXX "${PREFIX}-g++")
set(CPP "${PREFIX}-cpp")
set(RANLIB "${PREFIX}-ranlib")
set(RC "${PREFIX}-windres")
set(CMAKE_RC_COMPILER "${PREFIX}-windres")
set(CMAKE_INSTALL_LIBDIR "/usr/lib")
set(CMAKE_USE_WIN32_THREADS_INIT TRUE)

set(CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES /usr/lib/gcc/${PREFIX}/9.3-posix/)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libstdc++ -static-libgcc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++ -static-libgcc")

if(MINGW)
    #needed to build libssh 
    add_compile_definitions(UNITY_INT_WIDTH=32 UNITY_LONG_WIDTH=64 UNITY_POINTER_WIDTH=32)
endif()

#set(CMAKE_CXX_COMPILER_WORKS 1)
#set(CMAKE_CROSSCOMPILING 1)
#set(CMAKE_SYSTEM_NAME Windows)
#set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
#set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

