---
name: write-tests
description: Write unit tests following project patterns and conventions
disable-model-invocation: true
argument-hint: "[class-or-file-to-test]"
---

Write unit tests for: $ARGUMENTS

## Workflow

1. **Read the source**: Understand the class/file to test — its public API, dependencies, and edge cases
2. **Find similar tests**: Search `Tests/` for existing tests that cover related functionality. Use the most similar test file as a structural template
3. **Follow project patterns** (see `.claude/rules/testing.md`):
   - File name: `{Subject}Tests.swift`
   - Test class: `final class {Subject}Tests: XCTestCase`
   - Method naming: `test_{context}_{condition}_result`
   - Structure: `// Given / When / Then`
   - `sut` for system under test, `setUp()` / `tearDown()` lifecycle
4. **Create protocol-based mocks** (`Mock{Protocol}.swift`):
   - Configurable return values and error injection
   - `private(set) var ...CallCount` for call tracking
   - Captured parameters for argument verification
   - `reset()` method and static factory methods
5. **Reuse shared utilities**:
   - `SDKSessionHelper` for global state bootstrapping
   - `XCTestCase+Async` for AsyncStream testing (`collect()`, `awaitFirst()`, `awaitValue()`, `withTimeout()`)
   - `JWTFactory` for JWT tokens
   - `ContainerTestHelpers` for DI container setup
   - `TestData` extensions for test constants
   - `TestError` for shared error assertions
6. **Run tests**:
   ```bash
   xcodebuild -workspace PrimerSDK.xcworkspace \
     -scheme "PrimerSDKTests" \
     -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
     -testPlan "UnitTestsTestPlan" \
     -only-testing:"Tests/{TestClassName}" \
     test
   ```
