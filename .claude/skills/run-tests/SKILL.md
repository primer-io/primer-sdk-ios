---
name: run-tests
description: Run unit tests for changed files on the current branch
disable-model-invocation: true
argument-hint: "[optional-specific-test-class]"
---

Run unit tests for: $ARGUMENTS

## Workflow

1. **Determine what to test**:
   - If `$ARGUMENTS` specifies a test class, use that directly
   - Otherwise, find changed Swift source files: `git diff --name-only master...HEAD -- '*.swift'`
   - For each changed source file, search `Tests/` for matching test files (e.g. `CardValidator.swift` → `CardValidatorTests.swift`)
   - If no matching test files found, report which files have no tests
2. **Run discovered tests** using the xcodebuild command from CLAUDE.md "Building and Testing" section. Use multiple `-only-testing:"Tests/{TestClassName}"` flags for multiple test classes. Test target is `Tests` (not `PrimerSDKTests`).
3. **Report results**: List passed/failed test classes and any failures with details
