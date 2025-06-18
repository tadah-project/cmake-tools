# Tadah CMake Tools

Common CMake utilities for the *Tadah* family of repositories.

Add to a project with FetchContent:

```cmake
include(FetchContent)
FetchContent_Declare(tadah_cmake
  GIT_REPOSITORY https://github.com/tadah/cmake-tools.git
  GIT_TAG        v1.1.0)          # use a released tag
FetchContent_MakeAvailable(tadah_cmake)

target_link_libraries(myexe PRIVATE tadah::compile_options)