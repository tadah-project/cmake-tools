# ====================================================================
#  Tadah version reader
#
#  Single-source-of-truth for the Tadah version is the [TADAH] table in
#  CORE's blueprint TOML:
#
#      core/blueprint/blueprint_tadah.toml
#
#  This module exposes one function:
#
#      tadah_read_version_from_blueprint(<output_var>
#          [BLUEPRINT_FILE <path>]
#          [REQUIRED])
#
#  Behaviour:
#    * If BLUEPRINT_FILE is given, parses exactly that file.
#    * Otherwise the blueprint is located through Tadah.CORE itself:
#        - the FetchContent source dir of Tadah.CORE (populated by
#          FetchContent_MakeAvailable(Tadah.CORE), including the
#          FETCHCONTENT_SOURCE_DIR_TADAH.CORE override used by
#          developer builds);
#        - ${Tadah.CORE_SOURCE_DIR}, set by CORE's own project() call.
#      Callers therefore read the version AFTER their Tadah dependencies
#      have been made available, then re-state project(... VERSION ...).
#    * A missing blueprint, a missing [TADAH].version line or a version
#      without a numeric M.m.p prefix is a configure error. There is no
#      default version. REQUIRED is accepted for backward compatibility
#      and has no further effect.
#    * The blueprint is added to CMAKE_CONFIGURE_DEPENDS of the calling
#      directory, so bumping the version re-runs the configure step.
#
#  Outputs (in the caller's scope):
#      <output_var>          numeric version for project(VERSION), e.g. 1.5.1
#      <output_var>_FULL     version string as written, e.g. 1.5.1-rc.1
#      <output_var>_SOURCE   path of the blueprint that was read
# ====================================================================

include(FetchContent)

function(tadah_read_version_from_blueprint output_var)
  set(_options REQUIRED)
  set(_oneValueArgs BLUEPRINT_FILE)
  set(_multiValueArgs)
  cmake_parse_arguments(_TVR "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})

  # ---- Build candidate list -------------------------------------
  set(_candidates "")
  if(_TVR_BLUEPRINT_FILE)
    list(APPEND _candidates "${_TVR_BLUEPRINT_FILE}")
  else()
    FetchContent_GetProperties(Tadah.CORE)
    if(tadah.core_POPULATED)
      list(APPEND _candidates "${tadah.core_SOURCE_DIR}/blueprint/blueprint_tadah.toml")
    endif()
    if(DEFINED Tadah.CORE_SOURCE_DIR)
      list(APPEND _candidates "${Tadah.CORE_SOURCE_DIR}/blueprint/blueprint_tadah.toml")
    endif()
  endif()

  # ---- Pick the first that exists -------------------------------
  set(_blueprint "")
  foreach(_c IN LISTS _candidates)
    if(EXISTS "${_c}")
      set(_blueprint "${_c}")
      break()
    endif()
  endforeach()

  if(NOT _blueprint)
    if(_candidates)
      set(_searched "Searched: ${_candidates}")
    else()
      string(CONCAT _searched
        "Tadah.CORE has not been made available yet: call "
        "FetchContent_MakeAvailable() for the Tadah dependencies "
        "before reading the version, or pass BLUEPRINT_FILE.")
    endif()
    message(FATAL_ERROR
      "tadah_read_version_from_blueprint: could not find "
      "blueprint_tadah.toml. ${_searched}")
  endif()

  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_blueprint}")

  # ---- Parse [TADAH] table ---------------------------------------
  file(STRINGS "${_blueprint}" _blueprintLines)
  set(_isTadah OFF)
  set(_tadahBlock "")
  foreach(_line IN LISTS _blueprintLines)
    # Begin section
    if(_line MATCHES "^[ \t]*\\[TADAH\\][ \t]*$")
      set(_isTadah ON)
      continue()
    endif()
    # End on next section header
    if(_isTadah AND (_line MATCHES "^[ \t]*\\["))
      set(_isTadah OFF)
      break()
    endif()
    if(_isTadah)
      set(_tadahBlock "${_tadahBlock}\n${_line}")
    endif()
  endforeach()

  # Match either double or single quotes around the version string
  string(REGEX MATCH
    "(^|\n)[ \t]*version[ \t]*=[ \t]*[\"']([^\"']+)[\"']"
    _match "${_tadahBlock}")
  if(NOT _match)
    message(FATAL_ERROR
      "tadah_read_version_from_blueprint: 'version = \"...\"' not found in [TADAH] of ${_blueprint}")
  endif()

  set(_version "${CMAKE_MATCH_2}")

  # CMake project(VERSION) only accepts numeric M.m.p[.t]; strip any
  # SemVer pre-release / build-metadata tail (e.g. 1.3.0-beta.1+abc).
  # CMake regex does not support `{n,m}` quantifiers — use `*`.
  string(REGEX MATCH "^[0-9]+(\\.[0-9]+)*" _numeric "${_version}")
  if(NOT _numeric)
    message(FATAL_ERROR
      "tadah_read_version_from_blueprint: version '${_version}' in ${_blueprint} "
      "does not start with a numeric M.m.p component")
  endif()

  set(${output_var}        "${_numeric}" PARENT_SCOPE)
  set(${output_var}_FULL   "${_version}" PARENT_SCOPE)
  set(${output_var}_SOURCE "${_blueprint}" PARENT_SCOPE)
endfunction()
