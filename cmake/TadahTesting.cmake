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

# ====================================================================
#  Tadah test-build switch
#
#  Every Tadah module builds its unit tests under one switch,
#  BUILD_TESTING, which is OFF by default. Configuring any Tadah
#  project with -DBUILD_TESTING=ON builds the tests of that project
#  AND of every Tadah module it consumes. External dependencies
#  (Eigen, Ceres, nlopt, dlib, ...) never build their own tests --
#  see tadah_begin_external_deps / tadah_end_external_deps.
#
#  Usage in a module's CMakeLists.txt:
#
#     FetchContent_MakeAvailable(tadah_cmake)
#     tadah_declare_testing()          # once, before any sub-module
#     ...
#     tadah_add_tests()                # at the end, after the targets
# ====================================================================

# Declare the BUILD_TESTING cache entry (default OFF). Must be called
# early -- before the FetchContent of any sub-module -- so the entry is
# settled before children configure and a parent's value propagates
# down to them. Idempotent: a no-op once the entry exists (created by a
# parent module, a -D on the command line, or a -C preset).
macro(tadah_declare_testing)
  set(BUILD_TESTING OFF CACHE BOOL "Build Tadah module unit tests")
endmacro()

# Add the module's tests/ subdirectory when BUILD_TESTING is ON. Call at
# the end of the module's CMakeLists, after its targets are defined.
#
# include(CTest) is called unconditionally so this directory's
# CTestTestfile.cmake is regenerated on every configure -- otherwise a
# stale one from an earlier BUILD_TESTING=ON configure would linger and
# ctest would still list now-disabled tests. option(BUILD_TESTING) run
# inside CTest is a harmless no-op: tadah_declare_testing() already
# created the cache entry.
macro(tadah_add_tests)
  include(CTest)
  if(BUILD_TESTING)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
      add_subdirectory(tests)
    endif()
  endif()
endmacro()

# Shield external (non-Tadah) dependencies from BUILD_TESTING. Libraries
# such as Ceres key their own test suites off BUILD_TESTING, and Tadah
# never wants those built. Wrap external FetchContent calls:
#
#     tadah_begin_external_deps()
#     FetchContent_MakeAvailable(ceres nlopt ...)
#     tadah_end_external_deps()
#
# The cache entry is force-set OFF for the duration and restored after.
# tadah_declare_testing() is invoked first so the saved value is always
# a real cache value -- never an empty string that would corrupt the
# entry on restore.
macro(tadah_begin_external_deps)
  tadah_declare_testing()
  set(_tadah_ext_build_testing "$CACHE{BUILD_TESTING}")
  set(BUILD_TESTING OFF CACHE BOOL "Build Tadah module unit tests" FORCE)
endmacro()

macro(tadah_end_external_deps)
  set(BUILD_TESTING "${_tadah_ext_build_testing}"
      CACHE BOOL "Build Tadah module unit tests" FORCE)
  unset(_tadah_ext_build_testing)
endmacro()
