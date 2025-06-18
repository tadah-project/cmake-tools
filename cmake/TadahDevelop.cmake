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
