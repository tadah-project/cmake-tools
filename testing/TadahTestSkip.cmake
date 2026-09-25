# The TADAH-SKIP marker: how a Catch2 (v2) test case reports "skipped" to
# CTest. Catch2 v2 has no skip; a test case that returns early passes. A
# test case whose optional input is absent calls TADAH_SKIP(<reason>)
# (testing/tadah_test_skip.hpp) before its first check, directly in the
# TEST_CASE body and outside every SECTION. When the test case ends without
# a failed assertion, the header's Catch listener writes the line
#
#   TADAH-SKIP: <reason>
#
# to the process's standard error; a test case that asked to be skipped and
# failed writes nothing. CTest reports a test whose output matches
# TADAH_TEST_SKIP_REGULAR_EXPRESSION (the marker at the start of a line) as
# Skipped, whatever its exit status, so nothing else may print such a line.
#
# Used by:
#  * CatchAddTests.cmake, which gives every test catch_discover_tests()
#    registers this SKIP_REGULAR_EXPRESSION (it includes this file from its
#    own directory);
#  * Catch.cmake, which includes this file, so after include(Catch) an
#    explicit add_test() entry that runs exactly ONE test case can opt in:
#
#      set_tests_properties(foo PROPERTIES
#        SKIP_REGULAR_EXPRESSION "${TADAH_TEST_SKIP_REGULAR_EXPRESSION}")
#
#    Never on an entry that runs several test cases (a tag): the marker of
#    one of them would report the whole entry as Skipped, failures included.
#
# The C++ side spells the marker in tadah_test_skip.hpp (kSkipMarker); the
# regression test Tadah.MLIP/tests/catch_discovery/check_skip.cmake checks
# that both agree through a real CTest run.

set(TADAH_TEST_SKIP_MARKER "TADAH-SKIP: ")
set(TADAH_TEST_SKIP_REGULAR_EXPRESSION "(^|\n)${TADAH_TEST_SKIP_MARKER}")
