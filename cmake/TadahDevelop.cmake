# ====================================================================
#  Developer helper: use local working copies of Tadah repositories
#
#  Enable by configuring with      -DTADAH_DEVELOP=ON
#  Environment variable required:  TADAH_PATH   (root that contains the repos)
#
#  Usage inside a project:
#
#     include(TadahDevelop)               # once
#     tadah_use_local_module(tadah_core core)
#     tadah_use_local_module(tadah_models models)
#
#  where the first argument is the *FetchContent name* (upper-/lower-case
#  doesn't matter) and the second is the directory name inside $TADAH_PATH.
# ====================================================================

option(TADAH_DEVELOP "Use local checkouts in \$TADAH_PATH" OFF)

function(tadah_use_local_module fetch_name subdir)
  if(NOT TADAH_DEVELOP)
    return()             # feature disabled → keep remote FetchContent
  endif()

  if(NOT DEFINED ENV{TADAH_PATH})
    message(FATAL_ERROR
      "TADAH_DEVELOP=ON but environment variable TADAH_PATH is not set.")
  endif()

  # Absolute path we expect
  set(local_path "$ENV{TADAH_PATH}/${subdir}")

  if(NOT IS_DIRECTORY "${local_path}")
    message(FATAL_ERROR
      "TADAH_DEVELOP=ON but directory '${local_path}' not found.")
  endif()

  # Convert fetch_name to upper case for the magic variable
  string(TOUPPER "${fetch_name}" _uc)
  set("FETCHCONTENT_SOURCE_DIR_${_uc}" "${local_path}" PARENT_SCOPE)

  message(STATUS "TADAH_DEVELOP: '${fetch_name}' will be taken from ${local_path}")
endfunction()

#--------------------------------------------------------------------
#  tadah_get_git_branch(<outVar>)
#
#  Returns the current Git branch in <outVar>.  The algorithm is
#  *exactly* the same that the projects used before:
#
#    • in CI  →  $CI_COMMIT_REF_NAME
#    • local  →  bash -c "git status | grep origin | sed …"
#--------------------------------------------------------------------
function(tadah_get_git_branch out_var)
  # Don't override an existing value (set in caller scope or via -D... cache)
  if(DEFINED ${out_var} AND NOT "${${out_var}}" STREQUAL "")
    message(STATUS "${out_var} already set to '${${out_var}}' — skipping detection")
    return()
  endif()

  message(STATUS "Getting branch name...")
  if(DEFINED ENV{CI_COMMIT_REF_NAME})
    set(_branch "$ENV{CI_COMMIT_REF_NAME}")
    message(STATUS "CI/CD branch: ${_branch}")
  elseif(DEFINED ENV{READTHEDOCS_VERSION})
    set(_branch "$ENV{READTHEDOCS_VERSION}")
    message(STATUS "RTD branch: ${_branch}")
  else()
    execute_process(
      COMMAND bash -c "git status | grep origin |sed -e 's/.*origin\\///' -e 's/[^a-zA-Z\/_-].*//'"
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE _branch
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()

  set(${out_var} "${_branch}" PARENT_SCOPE)
  message(STATUS "Getting branch done: ${_branch}")
endfunction()

