cmake_minimum_required(VERSION 3.12)
project(tadah_cmake LANGUAGES CXX)

# define the interface target
include(cmake/TadahCompileOptions.cmake)

# --- OPTIONAL: installation so the helper can also be installed with `make install` ---
install(TARGETS tadah::compile_options EXPORT tadah_cmakeTargets)

install(EXPORT tadah_cmakeTargets
        NAMESPACE tadah::
        DESTINATION lib/cmake/tadah_cmake)

install(FILES cmake/TadahCompileOptions.cmake
        DESTINATION lib/cmake/tadah_cmake)