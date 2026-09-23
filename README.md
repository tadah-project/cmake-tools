# Tadah CMake Tools

Common CMake utilities for the *Tadah* family of repositories.

Add to a project with FetchContent:

```cmake
include(FetchContent)
FetchContent_Declare(tadah_cmake
  GIT_REPOSITORY https://git.ecdf.ed.ac.uk/tadah/cmake-tools.git
  GIT_TAG        v1-dev)          # the Tadah modules' development pin
FetchContent_MakeAvailable(tadah_cmake)

target_link_libraries(myexe PRIVATE tadah::compile_options)
```

The Tadah modules fetch cmake-tools at `v1-dev` during development; a
release pins a tag instead.

## Testing

Every Tadah module builds its Catch2 (v2) unit tests the same way. Tests are
built when `BUILD_TESTING` is ON (default OFF; see `cmake/TadahTesting.cmake`
for `tadah_declare_testing()` and `tadah_add_tests()`). A module's
`tests/CMakeLists.txt`:

```cmake
tadah_setup_tests()             # Catch2 target; testing/ on CMAKE_MODULE_PATH

file(GLOB tests_src CONFIGURE_DEPENDS "*.cpp")
add_executable(test_foo ${tests_src})
target_link_libraries(test_foo PRIVATE Catch2 tadah.foo)

include(Catch)                  # testing/Catch.cmake
catch_discover_tests(test_foo)  # one CTest entry per test case
```

- `tadah_setup_tests()` creates the `Catch2` INTERFACE target (once per
  build) with `testing/` as its include directory, so sources use
  `#include "catch2/catch.hpp"` (Catch2 v2.13.7, shipped here), and puts
  `testing/` on `CMAKE_MODULE_PATH` for `include(Catch)`. Modules do not
  vendor `catch.hpp`, `Catch.cmake` or `CatchAddTests.cmake`.
- `catch_discover_tests()` lists the executable's test cases after every link
  (`--list-test-names-only`) and registers one CTest entry per non-hidden
  case. The discovery script, `testing/CatchAddTests.cmake`, guarantees:
  - names are taken verbatim: `;`, `[`, `]`, `,`, `\`, quotes, leading
    whitespace and a leading `#`, `~` or `-` in a name neither merge nor
    split entries (CRLF output is accepted);
  - each entry's Catch test spec (the name in double quotes, with `\`, `,`,
    `"` and `@` escaped; the last keeps a tag alias `[@name]` in a name from
    being expanded) selects exactly its own test case;
  - each entry passes `--warn NoTests`, so a spec that matches nothing fails
    instead of passing silently. Catch accepts `--warn` only once, so
    `EXTRA_ARGS` containing `--warn` or `-w` stop the build;
  - the listing is checked against Catch's own count (its exit status,
    which the OS truncates modulo 256); a crash or a disagreement stops the
    build, and "no tests" is decided from the parsed names;
  - a name Catch v2 cannot select on its own stops the build with a message
    naming the test case: a leading or trailing `*` (always a wildcard), a
    blank name, or a name that differs from another test case's name only
    in letter case or surrounding whitespace. Hidden test cases count here,
    because a name spec also selects them. Rename the test case.
- `catch_discover_tests()` passes its options to the script exactly (a
  `TEST_PREFIX` may end in a space), and a change to the script relinks the
  test executables so their tests are discovered again.
- Hidden test cases (`[.]`, `[.tag]`, `[!benchmark]`) are not discovered. To
  run them under CTest, add an explicit entry, which also passes
  `--warn NoTests`:

  ```cmake
  add_test(NAME foo_slow COMMAND test_foo "[.slow]" --warn NoTests)
  ```

The regression tests for this machinery live in the umbrella repository,
`Tadah.MLIP/tests/catch_discovery` (`ctest -R tadah_catch`).
