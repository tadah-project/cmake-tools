cmake_minimum_required(VERSION 3.12)
project(tadah_cmake LANGUAGES CXX)

include(cmake/TadahCompileOptions.cmake)
include(cmake/TadahDevelop.cmake)

# install only the *real* target, ALIAS targets are never installable
install(TARGETS tadah_compile_options EXPORT tadah_cmakeTargets)

install(EXPORT tadah_cmakeTargets
        NAMESPACE tadah::
        DESTINATION lib/cmake/tadah_cmake)

install(FILES cmake/TadahCompileOptions.cmake
        DESTINATION lib/cmake/tadah_cmake)