#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "ssh" for configuration "Debug"
set_property(TARGET ssh APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(ssh PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libssh.so.4.9.0"
  IMPORTED_SONAME_DEBUG "libssh.so.4"
  )

list(APPEND _cmake_import_check_targets ssh )
list(APPEND _cmake_import_check_files_for_ssh "${_IMPORT_PREFIX}/lib/libssh.so.4.9.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
