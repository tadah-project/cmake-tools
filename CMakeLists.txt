# --------------------------------------------------------------------
#  Interface target that carries every compile / link option shared
#  by the organisation’s C++ modules.
#
#  User-visible cache options:
#    TADAH_USE_ASAN  – ON/OFF (default OFF) add AddressSanitizer to
#                      Debug and RelWithDebInfo builds
#
#  Build configurations handled:
#    Debug
#    RelWithDebInfo
#    Release
#    MinSizeRel
# --------------------------------------------------------------------
# --------------------------------------------------------------------
#  Common compile / link options
# --------------------------------------------------------------------
if(NOT DEFINED _TADAH_COMPILE_OPTS_INCLUDED)
  set(_TADAH_COMPILE_OPTS_INCLUDED 1)

  option(TADAH_USE_ASAN        "Add AddressSanitizer to Debug/RelWithDebInfo" OFF)
  option(TADAH_ENABLE_PROFILING "Add -pg to all objects and links"           OFF)

  add_library(tadah::compile_options INTERFACE)

  # ---------------- compile options --------------------------------
  target_compile_options(tadah::compile_options INTERFACE
    -Wall -Wextra -Wpedantic -pedantic-errors                # always-on warnings

    # Sanitiser (compiler side)
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>

    # Optimisation / debug info
    $<$<CONFIG:Debug>          : -g -Og>
    $<$<CONFIG:RelWithDebInfo> : -g -O2>
    $<$<CONFIG:Release>        : -O3>
    $<$<CONFIG:MinSizeRel>     : -Os>

    # Profiling
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )

  # ---------------- link options -----------------------------------
  target_link_options(tadah::compile_options INTERFACE
    # Sanitiser (linker side)
    $<$<AND:$<BOOL:${TADAH_USE_ASAN}>,
              $<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:-fsanitize=address>

    # Profiling
    $<$<BOOL:${TADAH_ENABLE_PROFILING}>:-pg>
  )
endif()

