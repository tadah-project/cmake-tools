# ====================================================================
#  Centralised Catch2 test setup for Tadah repositories
#
#  Usage in a test CMakeLists.txt:
#
#     tadah_setup_tests()       # creates Catch2 target if needed
#
#     add_executable(test_foo ${test_sources})
#     target_link_libraries(test_foo PRIVATE Catch2 tadah.core ...)
#
#     include(Catch)
#     catch_discover_tests(test_foo)
#
#  The Catch2 header and discovery scripts (Catch.cmake,
#  CatchAddTests.cmake) are bundled in cmake-tools/testing/.
# ====================================================================

# Directory containing Catch2 header and helpers (relative to this file)
get_filename_component(_TADAH_CMAKE_TOOLS_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(_TADAH_CMAKE_TOOLS_DIR "${_TADAH_CMAKE_TOOLS_DIR}" CACHE INTERNAL
    "Root of cmake-tools for locating testing helpers")

function(tadah_setup_tests)
  if(NOT TARGET Catch2)
    add_library(Catch2 INTERFACE)
    target_include_directories(Catch2 INTERFACE
      "${_TADAH_CMAKE_TOOLS_DIR}/testing")
  endif()

  # Make Catch.cmake discoverable via include(Catch)
  list(APPEND CMAKE_MODULE_PATH "${_TADAH_CMAKE_TOOLS_DIR}/testing")
  set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
endfunction()
