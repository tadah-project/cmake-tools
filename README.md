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

## Removed build options

`cmake/TadahCompileOptions.cmake` stops the configure step when a removed
option is switched on. Every Tadah module fetches cmake-tools, and so runs
this file, before it declares any target of its own, so the check covers the
umbrella build, a standalone build of any module and the LAMMPS plugin build
alike. Setting a removed option to `OFF` (as older presets do) is accepted.

| Option | Removed in | Use instead |
|---|---|---|
| `TADAH_BUILD_MPI` | 1.5.1 (the legacy ScaLAPACK training build, `tadah_mpi`) | `TADAH_HPO_MPI` for MPI-parallel `TADAH:ANNEAL_PT` / `ANNEAL_PA` in HPO (needs `TADAH_ENABLE_NFP=ON` and an MPI build of LAMMPS); OpenMP threads for training |

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

### Skipped tests: the TADAH-SKIP marker

Catch2 v2 has no skip: a test case that returns early because an optional
input is absent (an external data file, an environment variable) passes,
and CTest counts a check that checked nothing. Such a guard calls
`TADAH_SKIP` from `testing/tadah_test_skip.hpp` (on the `Catch2` target's
include path) before the test case's first check, directly in the
`TEST_CASE` body and outside every `SECTION`:

```cpp
#include "tadah_test_skip.hpp"  // before (or instead of) catch2/catch.hpp

TEST_CASE("uses an optional database", "[db]") {
  std::ifstream in(path);
  if (!in.is_open()) {
    TADAH_SKIP("database not found at " << path);
  }
  ...
}
```

`TADAH_SKIP(<reason>)` records the reason as a Catch warning, records the
skip request and returns from the test case. When the test case ends
without a failed assertion, a Catch listener that the header registers
writes the line `TADAH-SKIP: <reason>` to standard error. Every test that
`catch_discover_tests()` registers has the `SKIP_REGULAR_EXPRESSION`
`TADAH_TEST_SKIP_REGULAR_EXPRESSION` (`testing/TadahTestSkip.cmake`), which
matches that line at the start of a line, so CTest reports the test as
**Skipped** although it exits with 0.

- A skip request never hides a failure of the same test case: a check that
  failed before `TADAH_SKIP`, in another `SECTION`, or after `TADAH_SKIP`
  returned from a helper function or lambda (it returns only from that
  function), leaves the test case *Failed*, and no marker is written.
  Checks that run after the request and pass are not reported: the test
  case is Skipped.
- Include `tadah_test_skip.hpp` before `catch2/catch.hpp`, or instead of it
  (it includes Catch itself): its listener needs Catch's external
  interfaces, which it switches on with `CATCH_CONFIG_EXTERNAL_INTERFACES`.
  Included after a plain `catch2/catch.hpp`, it stops the build with a
  message saying so. It registers its listener once per test binary,
  whatever the number of translation units that include it.
- The line is written through C stdio's `stderr`, which the Catch reporters
  that capture a test case's output (`junit`, `xml`) do not redirect, so
  the skip reaches CTest with any reporter.
- Nothing else may print a line that starts with `TADAH-SKIP: `: CTest
  reports an entry whose output has such a line as Skipped, whatever its
  exit status. The text inside a line, or quoted in a failed assertion,
  does not count.
- `PROPERTIES` of `catch_discover_tests()` that set
  `SKIP_REGULAR_EXPRESSION` would replace the marker's; they stop the
  build.
- An explicit `add_test()` entry that runs exactly **one** test case opts
  in after `include(Catch)`:

  ```cmake
  set_tests_properties(foo_oracle PROPERTIES
    SKIP_REGULAR_EXPRESSION "${TADAH_TEST_SKIP_REGULAR_EXPRESSION}")
  ```

  Never on an entry that runs several test cases (a tag): the marker of one
  would report the whole entry as Skipped, failures of the others included.
- A script entry (not Catch) either exits with a code of its own and sets
  `SKIP_RETURN_CODE`, as HPO's `hpo_strategy_matrix` does with 77, or
  prints a line that its own `SKIP_REGULAR_EXPRESSION` matches.

The regression tests for this machinery live in the umbrella repository,
`Tadah.MLIP/tests/catch_discovery` (`ctest -R tadah_catch`).
