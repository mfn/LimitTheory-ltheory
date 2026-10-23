cmake_minimum_required (VERSION 3.13)
project (LTheory)
if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set (CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build configuration" FORCE)
endif ()
include (libphx/script/build/Shared.cmake)

add_subdirectory (libphx)

add_executable (lt "src/Main.cpp")
phx_configure_output_dir (lt)
phx_configure_target_properties (lt)

target_compile_definitions (lt PRIVATE DEBUG=0)
target_compile_definitions (lt PRIVATE PHX_LIBRARY_NAME="$<TARGET_FILE_NAME:phx>")
target_link_libraries (lt phx)
if (APPLE)
  set_target_properties (lt PROPERTIES BUILD_RPATH "@loader_path")
endif ()

set_target_properties (lt PROPERTIES
  OUTPUT_NAME_DEBUG "lt${ARCH}d"
  OUTPUT_NAME_RELEASE "lt${ARCH}r"
  OUTPUT_NAME_RELWITHDEBINFO "lt${ARCH}"
  OUTPUT_NAME_MINSIZEREL "lt${ARCH}rm")

file (GENERATE OUTPUT "${CMAKE_BINARY_DIR}/executable-$<CONFIG>.txt"
  CONTENT "$<TARGET_FILE:lt>\n")
