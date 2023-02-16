
set(MINGW TRUE)
set(PREFIX "x86_64-w64-mingw32")
set(CC "${PREFIX}-gcc")
set(CXX "${PREFIX}-g++")
set(CPP "${PREFIX}-cpp")
set(RANLIB "${PREFIX}-ranlib")
set(CMAKE_INSTALL_LIBDIR "/usr/lib")
set(CMAKE_USE_WIN32_THREADS_INIT TRUE)
#set(PATH="/usr/x86_64-w64-mingw32/bin:$PATH")

set(CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES /usr/lib/gcc/${PREFIX}/9.3-posix/)
#set(CMAKE_INSTALL_LIBDIR)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libstdc++ -static-libgcc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++ -static-libgcc")