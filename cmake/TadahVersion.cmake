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
#    * If BLUEPRINT_FILE is given, parses that file.
#    * Otherwise searches a list of common locations:
#        - ${Tadah.CORE_SOURCE_DIR}/blueprint/blueprint_tadah.toml
#          (set by FetchContent when CORE is pulled in)
#        - ${PROJECT_SOURCE_DIR}/blueprint/blueprint_tadah.toml
#          (CORE itself)
#        - ${PROJECT_SOURCE_DIR}/../CORE/blueprint/blueprint_tadah.toml
#        - ${PROJECT_SOURCE_DIR}/../core/blueprint/blueprint_tadah.toml
#          (developer worktree sibling layouts)
#    * If REQUIRED is given and no version is found, the configure
#      step fails. Otherwise sets <output_var> to "0.0.0" and emits a
#      single STATUS message.
#
#  Call BEFORE project(... VERSION ...) so the result can be passed in.
# ====================================================================

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
    if(DEFINED Tadah.CORE_SOURCE_DIR)
      list(APPEND _candidates "${Tadah.CORE_SOURCE_DIR}/blueprint/blueprint_tadah.toml")
    endif()
    if(DEFINED PROJECT_SOURCE_DIR)
      list(APPEND _candidates "${PROJECT_SOURCE_DIR}/blueprint/blueprint_tadah.toml")
      list(APPEND _candidates "${PROJECT_SOURCE_DIR}/../CORE/blueprint/blueprint_tadah.toml")
      list(APPEND _candidates "${PROJECT_SOURCE_DIR}/../core/blueprint/blueprint_tadah.toml")
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
    if(_TVR_REQUIRED)
      message(FATAL_ERROR
        "tadah_read_version_from_blueprint: could not find blueprint_tadah.toml. "
        "Searched: ${_candidates}")
    endif()
    message(STATUS
      "tadah_read_version_from_blueprint: blueprint not found, defaulting version to 0.0.0")
    set(${output_var} "0.0.0" PARENT_SCOPE)
    return()
  endif()

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
    if(_TVR_REQUIRED)
      message(FATAL_ERROR
        "tadah_read_version_from_blueprint: 'version = \"...\"' not found in [TADAH] of ${_blueprint}")
    endif()
    message(STATUS
      "tadah_read_version_from_blueprint: version line missing in ${_blueprint}, defaulting to 0.0.0")
    set(${output_var} "0.0.0" PARENT_SCOPE)
    return()
  endif()

  set(_version "${CMAKE_MATCH_2}")

  # CMake project(VERSION) only accepts numeric M.m.p[.t]; strip any
  # SemVer pre-release / build-metadata tail (e.g. 1.3.0-beta.1+abc).
  # CMake regex does not support `{n,m}` quantifiers — use `*`.
  string(REGEX MATCH "^[0-9]+(\\.[0-9]+)*" _numeric "${_version}")
  if(NOT _numeric)
    set(_numeric "0.0.0")
  endif()

  set(${output_var}        "${_numeric}" PARENT_SCOPE)
  set(${output_var}_FULL   "${_version}" PARENT_SCOPE)
  set(${output_var}_SOURCE "${_blueprint}" PARENT_SCOPE)
endfunction()
