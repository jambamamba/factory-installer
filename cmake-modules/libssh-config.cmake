
set(libssh_FOUND TRUE)
set(libssh_VERSION "0.10.90")
set(libssh_DIR "${CMAKE_SOURCE_DIR}/utils/libssh")
set(libssh_BINARY_DIR "${CMAKE_BINARY_DIR}/utils/libssh")
set(libssh_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/utils/libssh/include:${libssh_BINARY_DIR}/include")
set(libssh_SOURCE_DIR "${CMAKE_SOURCE_DIR}/utils/libssh")
set(libssh_LIB "${CMAKE_BINARY_DIR}/utils/libssh")

if(libssh_FOUND AND NOT TARGET libssh::libssh)
  add_library(libssh::libssh SHARED IMPORTED)
  set_target_properties(libssh::libssh PROPERTIES
    IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
    IMPORTED_LOCATION "${libssh_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES
      "${libssh_INCLUDE_DIR}"
    )
endif()
