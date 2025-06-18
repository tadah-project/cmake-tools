# --------------------------------------------------------------------
#  Shared compile / link options for the whole Tadah ecosystem
# --------------------------------------------------------------------
if(NOT DEFINED _TADAH_COMPILE_OPTS_INCLUDED)
  set(_TADAH_COMPILE_OPTS_INCLUDED 1)

  option(TADAH_USE_ASAN         "Add AddressSanitizer"            OFF)
  option(TADAH_ENABLE_PROFILING "Add -pg to compiler & linker"    OFF)

  # 1) real interface target (no namespace!)
  add_library(tadah_compile_options INTERFACE)

  # 2) convenient alias with namespace
  add_library(tadah::compile_options ALIAS tadah_compile_options)

  # ---------------- compile options --------------------------------
  target_compile_options(tadah_compile_options INTERFACE
    -Wall -Wextra -Wpedantic -pedantic-errors
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>
    $<$<CONFIG:Debug>          : -g -Og>
    $<$<CONFIG:RelWithDebInfo> : -g -O2>
    $<$<CONFIG:Release>        : -O3>
    $<$<CONFIG:MinSizeRel>     : -Os>
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )

  # ---------------- link options -----------------------------------
  target_link_options(tadah_compile_options INTERFACE
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )
endif()
