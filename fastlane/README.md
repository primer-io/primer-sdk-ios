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

### ios tests

```sh
[bundle exec] fastlane ios tests
```



### ios ui_tests

```sh
[bundle exec] fastlane ios ui_tests
```



### ios danger_check

```sh
[bundle exec] fastlane ios danger_check
```



### ios qa_release

```sh
[bundle exec] fastlane ios qa_release
```



### ios build_spm

```sh
[bundle exec] fastlane ios build_spm
```

This action builds the app using the SPM integration

### ios appetize_build_and_upload

```sh
[bundle exec] fastlane ios appetize_build_and_upload
```

This action runs Unit Tests, builds the app and uploads it to Appetize

### ios set_version_and_build_number

```sh
[bundle exec] fastlane ios set_version_and_build_number
```

This action sets the version and build number

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
