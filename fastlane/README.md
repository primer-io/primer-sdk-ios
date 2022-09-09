fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios run_tests_and_generate_code_coverage

```sh
[bundle exec] fastlane ios run_tests_and_generate_code_coverage
```



### ios danger_check

```sh
[bundle exec] fastlane ios danger_check
```



### ios qa_release

```sh
[bundle exec] fastlane ios qa_release
```



### ios run_pod_install

```sh
[bundle exec] fastlane ios run_pod_install
```

Run pod install

### ios generate_code_coverage

```sh
[bundle exec] fastlane ios generate_code_coverage
```

This action generates the code coverage and as Cobertura XML

### ios tests

```sh
[bundle exec] fastlane ios tests
```

This action runs XCTests

### ios ui_tests

```sh
[bundle exec] fastlane ios ui_tests
```

This action run UITests

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
