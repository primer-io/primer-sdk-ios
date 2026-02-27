---
paths:
  - "Tests/**/*.swift"
---

# Testing Patterns

## Naming Conventions
- Test files: `{Subject}Tests.swift`, mocks: `Mock{Protocol}.swift`, fixtures: `{Domain}TestData.swift`
- Test methods: `test_{context}_{condition}_result` (snake_case)
- Tests are `final class`, `@MainActor` when needed, `async throws`

## Mock Approach
Protocol-based mocking, no framework. Every mock has:
- Configurable return values and error injection
- `private(set) var ...CallCount` for call tracking
- Captured parameters for argument verification
- `reset()` method and static factory methods for common states

## Test Structure
- `sut` naming for system under test
- `// Given / When / Then` comment structure
- `setUp()` creates mocks + sut, `tearDown()` nils them

## Shared Utilities
- `SDKSessionHelper` — bootstraps global state for tests (`Tests/Utilities/Test Utilities/`)
- `XCTestCase+Async` — `collect()`, `awaitFirst()`, `awaitValue()`, `withTimeout()` for AsyncStream testing
- `JWTFactory` — generates valid JWT tokens for tests
- `ContainerTestHelpers` — pre-wired DI container with mocks for CheckoutComponents
- `TestData` + extensions — shared test constants (`Tests/Primer/CheckoutComponents/TestSupport/TestData*.swift`)
- `TestError` enum — shared error type for test assertions

## Running Specific Tests
Test target is `Tests` (not `PrimerSDKTests`). Use `-testPlan "UnitTestsTestPlan"`:
```bash
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  -testPlan "UnitTestsTestPlan" \
  -only-testing:"Tests/SomeClassTests" \
  test
```
