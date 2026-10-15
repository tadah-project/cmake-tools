# Text check of a source tree (tadah_add_text_check, cmake/TadahTesting.cmake).
#
#   cmake -DTADAH_TEXT_ROOT=<dir> -P tadah_text_check.cmake
#
# Reads every text file under TADAH_TEXT_ROOT and fails on each line that
# matches one of the rules below, printing
#
#   <path relative to the root>: <rule>: <the line>
#
# for every such line and the number of them; it prints "0 lines" and
# succeeds when there is none.
#
# Rules (each pattern writes one letter in brackets, so this file does not
# match itself):
#   a person's initials       the initials of a person as a word: what a
#                             line says is stated by the text, not by who
#                             asked for it
#   a co-worker reference     the word for co-workers
#   a decision note           a decision attributed to the code's owner
#   an AI tool                the name of an AI tool or company, an
#                             attribution trailer or the state directory
#                             of such a tool
#   a workspace note          a path or name of a note kept outside the
#                             repository (follow-up records, issue
#                             registers, feature requests, development
#                             lanes and their scripts), which a reader of
#                             the repository cannot open
#   a stock phrase            filler wording (the patterns of _ttc_rule_5)
#
# Text files: the names ending in .c .cc .cpp .cxx .h .hh .hpp .hxx .ipp
# .inl .in .txt .md .rst .toml .py .cmake .cff .yml .yaml .sh .bash .cfg
# .ini .hpo .tadah, .gitignore and .gitattributes, and files without an
# extension of at most 1 MiB (configuration files, LICENSE, Makefile; data
# such as OUTCAR files is larger). Not read: the directories .git,
# external, third_party, _deps and catch2 (vendored code and git's own
# files) and every directory whose name starts with build or
# cmake-build- (build trees inside the source tree), at any depth.
cmake_minimum_required(VERSION 3.15)

if(NOT DEFINED TADAH_TEXT_ROOT OR "${TADAH_TEXT_ROOT}" STREQUAL "")
  message(FATAL_ERROR "tadah_text_check.cmake: -DTADAH_TEXT_ROOT=<dir> is required")
endif()
get_filename_component(_ttc_root "${TADAH_TEXT_ROOT}" ABSOLUTE)
if(NOT IS_DIRECTORY "${_ttc_root}")
  message(FATAL_ERROR "tadah_text_check.cmake: ${_ttc_root} is not a directory")
endif()

set(_ttc_rule_names
  "a person's initials"
  "a co-worker reference"
  "a decision note"
  "an AI tool"
  "a workspace note"
  "a stock phrase")
set(_ttc_rule_0 "(^|[^A-Za-z0-9_])M[K]([^A-Za-z0-9_]|$)")
set(_ttc_rule_1 "[Cc]o[l]league")
set(_ttc_rule_2 "[Oo]w[n]er('s)? decision")
set(_ttc_rule_3 "C[l]aude|A[n]thropic|Chat[G]PT|[Cc]o-[Aa]u[t]hored-[Bb]y|[.]c[l]aude")
set(_ttc_rule_4 "R[E]LEASE-[0-9.]+-FOLLOWUPS|B[U]GS-unified|F[E]ATURE-REQUEST-|(^|[^A-Za-z])l[a]nes/[A-Za-z]|t[m]p/autonomous|U[D]M-[0-9]")
set(_ttc_rule_5 "[Dd]e[l]ve|[Ss]ea[m]less|worth [n]oting|important to [n]ote")
set(_ttc_any "${_ttc_rule_0}|${_ttc_rule_1}|${_ttc_rule_2}|${_ttc_rule_3}|${_ttc_rule_4}|${_ttc_rule_5}")

set(_ttc_text_name "\\.(c|cc|cpp|cxx|h|hh|hpp|hxx|ipp|inl|in|txt|md|rst|toml|py|cmake|cff|yml|yaml|sh|bash|cfg|ini|hpo|tadah)$|^\\.git(ignore|attributes)$")
set(_ttc_skip_dir "^(\\.git|external|third_party|_deps|catch2|build.*|cmake-build-.*)$")

file(GLOB_RECURSE _ttc_files LIST_DIRECTORIES false RELATIVE "${_ttc_root}"
     "${_ttc_root}/*")
list(SORT _ttc_files)

set(_ttc_count 0)
set(_ttc_read 0)
foreach(_ttc_rel IN LISTS _ttc_files)
  # The directories on the path, the file name last.
  string(REPLACE "/" ";" _ttc_parts "${_ttc_rel}")
  list(LENGTH _ttc_parts _ttc_n)
  math(EXPR _ttc_last "${_ttc_n} - 1")
  list(GET _ttc_parts ${_ttc_last} _ttc_name)
  set(_ttc_skip FALSE)
  if(_ttc_n GREATER 1)
    list(REMOVE_AT _ttc_parts ${_ttc_last})
    foreach(_ttc_dir IN LISTS _ttc_parts)
      if(_ttc_dir MATCHES "${_ttc_skip_dir}")
        set(_ttc_skip TRUE)
        break()
      endif()
    endforeach()
  endif()
  if(_ttc_skip)
    continue()
  endif()
  set(_ttc_path "${_ttc_root}/${_ttc_rel}")
  if(NOT _ttc_name MATCHES "${_ttc_text_name}")
    if(_ttc_name MATCHES "\\.")
      continue()
    endif()
    file(SIZE "${_ttc_path}" _ttc_size)
    if(_ttc_size GREATER 1048576)
      continue()
    endif()
  endif()
  math(EXPR _ttc_read "${_ttc_read} + 1")
  file(STRINGS "${_ttc_path}" _ttc_lines REGEX "${_ttc_any}" ENCODING UTF-8)
  # The matching lines are one CMake list. A ';' in a line splits it into
  # several elements, and a '[' without its ']' in an element keeps the
  # next ';' from splitting, which would merge lines: the brackets are
  # reported as parentheses so that every line stays an element of its own.
  string(REPLACE "[" "(" _ttc_lines "${_ttc_lines}")
  string(REPLACE "]" ")" _ttc_lines "${_ttc_lines}")
  foreach(_ttc_line IN LISTS _ttc_lines)
    set(_ttc_rule "")
    foreach(_ttc_i RANGE 5)
      if(_ttc_line MATCHES "${_ttc_rule_${_ttc_i}}")
        list(GET _ttc_rule_names ${_ttc_i} _ttc_rule)
        break()
      endif()
    endforeach()
    # A line that a ';' split into list elements: only its matching parts
    # are reported, each on its own line.
    if(_ttc_rule STREQUAL "")
      continue()
    endif()
    string(STRIP "${_ttc_line}" _ttc_line)
    string(LENGTH "${_ttc_line}" _ttc_len)
    if(_ttc_len GREATER 200)
      string(SUBSTRING "${_ttc_line}" 0 200 _ttc_line)
      string(APPEND _ttc_line " ...")
    endif()
    message(NOTICE "${_ttc_rel}: ${_ttc_rule}: ${_ttc_line}")
    math(EXPR _ttc_count "${_ttc_count} + 1")
  endforeach()
endforeach()

if(_ttc_count GREATER 0)
  message(FATAL_ERROR "${_ttc_count} lines in ${_ttc_read} text files of "
                      "${_ttc_root} match a rule of tadah_text_check.cmake")
endif()
message(NOTICE "0 lines in ${_ttc_read} text files of ${_ttc_root} match a "
               "rule of tadah_text_check.cmake")
