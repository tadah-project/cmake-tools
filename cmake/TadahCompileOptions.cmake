#------------------------------------------------------------------
#  Shared compile / link options used by every Tadah repository.
#
#  Cache options:
#    TADAH_USE_ASAN        ON/OFF  – add -fsanitize=address
#    TADAH_ENABLE_PROFILING ON/OFF – add -pg
#------------------------------------------------------------------
if(NOT DEFINED _TADAH_COMPILE_OPTS_INCLUDED)
  set(_TADAH_COMPILE_OPTS_INCLUDED 1)

  option(TADAH_USE_ASAN         "Add AddressSanitizer"            OFF)
  option(TADAH_ENABLE_PROFILING "Add -pg to compiler & linker"    OFF)

  add_library(tadah::compile_options INTERFACE)

  # compile options
  target_compile_options(tadah::compile_options INTERFACE
    -Wall -Wextra -Wpedantic -pedantic-errors
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>
    $<$<CONFIG:Debug>          : -g -Og>
    $<$<CONFIG:RelWithDebInfo> : -g -O2>
    $<$<CONFIG:Release>        : -O3>
    $<$<CONFIG:MinSizeRel>     : -Os>
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )

  # link options
  target_link_options(tadah::compile_options INTERFACE
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )
endif()