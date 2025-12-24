# Research: CheckoutComponents Coverage Improvement

**Feature**: 003-coverage-improvement
**Date**: 2025-12-24
**Status**: Complete

## Research Questions

### 1. What test patterns should we follow?

**Decision**: Use existing test patterns from Spec 002 (XCTest + async/await, @MainActor isolation)

**Rationale**:
- Spec 002 successfully established 36 test files with 93% test coverage
- Patterns already proven to work with CheckoutComponents architecture
- Team familiar with existing approach
- Async/await works well with actor-based DI container
- No learning curve or tooling changes required

**Alternatives Considered**:
- ❌ Quick/Nimble testing framework - Unnecessary dependency, XCTest already works
- ❌ Custom test base classes - Spec 002 determined these weren't needed, tests use XCTest directly
- ❌ Behavior-driven testing (BDD) - Overkill for SDK unit tests

**Evidence**:
- Existing tests in `/Tests/Primer/CheckoutComponents/` demonstrate successful async/await usage
- Example from `DefaultCheckoutScopeTests.swift`: All 1334 lines at 99.18% coverage using XCTest
- `ProcessCardPaymentInteractorTests.swift`: 210 lines at 99.05% coverage with async test methods

---

### 2. How should we mock repositories and services?

**Decision**: Protocol-based mocks extending existing mock infrastructure

**Rationale**:
- `MockHeadlessRepository.swift` already exists and demonstrates the pattern
- Protocol-based allows easy test configuration (configurable returns, error injection)
- Call tracking enables verification of interactions
- Follows dependency injection principles already in CheckoutComponents

**Pattern to Follow**:
```swift
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {
    // Configurable returns
    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var errorToThrow: Error?

    // Call tracking
    var getPaymentMethodsCallCount = 0

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        getPaymentMethodsCallCount += 1
        if let error = errorToThrow { throw error }
        return paymentMethodsToReturn
    }
}
```

**Alternatives Considered**:
- ❌ Subclass-based mocks - Harder to configure, couples to implementation
- ❌ Third-party mocking frameworks (Mockingbird, Cuckoo) - Unnecessary complexity, adds build dependency
- ❌ Record/replay mocking - Overkill for unit tests; better suited for integration tests

**Evidence**:
- Existing mocks: `MockHeadlessRepository`, `MockValidationService`, `MockConfigurationService`, `MockAnalyticsInteractor`
- All follow same pattern: configurable returns + call tracking
- Coverage data shows mocks work well: `MockHeadlessRepository.swift` at 75.45% coverage

---

### 3. Should we target 80% or 90% coverage?

**Decision**: Start with pragmatic 80% target (skip Presentation refactoring), escalate to 90% only if required

**Rationale**:
- Presentation layer (7,368 lines, 0.15% coverage) accounts for 40% of untested code
- Refactoring SwiftUI views to extract ViewModels is HIGH RISK:
  - May break working UI
  - Requires extensive manual testing
  - Time-consuming (5-7 days estimated)
- 80% coverage achievable in ~7-11 days without high-risk changes
- 90% coverage requires ~13-20 days including risky Presentation refactoring

**Coverage Math**:
- **80% target**: 14,424 lines covered (11,005 additional lines needed)
- **90% target**: 16,228 lines covered (12,809 additional lines needed)
- **Difference**: 1,804 lines (mostly Presentation layer ViewModels)

**Recommendation**:
1. Complete Phases 1-4 (Data, Payment, Quick Wins, Utilities)
2. Evaluate at Phase 5 decision point
3. If 80%+ achieved without Presentation: declare success
4. If 90% required: proceed with ViewModel extraction in Phase 6

**Alternatives Considered**:
- ❌ Go straight for 90% - High risk, longer timeline
- ❌ Accept current 18.96% - Too low, doesn't meet quality gates
- ❌ Target 70% - Insufficient for critical payment code

**Evidence**:
- Coverage analysis from Spec 002 completion shows Presentation at 0.15%
- SwiftUI views inherently difficult to unit test (need snapshot/UI tests)
- Data (16.82%) and Payment (13.17%) layers more critical for revenue

---

### 4. How should we prioritize test implementation?

**Decision**: P1 Data/Payment layers first (revenue-critical), P2 quick wins, P3 utilities last

**Priority Order**:
1. **Phase 1: Quick Wins** (Days 1-2)
   - Navigation: 88.52% → 90% (~3 lines)
   - Validation: 72.14% → 90% (~158 lines)
   - Core: 70.23% → 90% (~87 lines)
   - DI Container: 56.90% → 90% (~405 lines)
   - **Why first**: Low effort, high coverage gain, demonstrates progress

2. **Phase 2: Data Layer** (Days 3-5)
   - Target: +958 lines
   - **Why P1**: Data layer bridges SDK to backend; bugs cause payment failures

3. **Phase 3: Payment Layer** (Days 6-8)
   - Target: +899 lines
   - **Why P1**: Payment orchestration is core business value; bugs impact revenue

4. **Phase 4: Scope & Utilities** (Days 9-11)
   - Target: +3,364 lines
   - **Why P3**: Important for customization/observability but lower business impact

5. **Phase 5: Decision Point**
   - Evaluate 80% vs 90% target

6. **Phase 6: Presentation** (Days 12-18, OPTIONAL)
   - Target: +5,150 lines
   - **Why P4/Optional**: High risk, questionable ROI

**Rationale**:
- Revenue-critical code (Data/Payment) tested first
- Quick wins build momentum and demonstrate progress
- Utilities deferred as nice-to-have
- Presentation optional based on target decision

**Alternatives Considered**:
- ❌ Bottom-up (start with utilities) - Delays testing critical code
- ❌ Top-down (start with Presentation) - High risk upfront
- ❌ Random order - No strategic value

**Evidence**:
- Spec 002 used iterative approach successfully (Phases 0-6)
- Industry best practice: test critical paths first

---

### 5. What test data fixtures do we need?

**Decision**: Extend existing `TestData.swift` with repository responses and payment results

**New Test Data Categories**:
```swift
extension TestData {
    // API Response Fixtures
    enum APIResponses {
        static let validPaymentMethodsJSON: String = "..."
        static let emptyPaymentMethodsJSON: String = "..."
        static let malformedJSON: String = "..."
        static let merchantConfigJSON: String = "..."
    }

    // Payment Result Fixtures
    enum PaymentResults {
        static let successResult: PaymentResult = ...
        static let failureResult: PaymentResult = ...
        static let threeDSRequiredResult: PaymentResult = ...
        static let cancelledResult: PaymentResult = ...
    }

    // 3DS Flow Fixtures
    enum ThreeDSFlows {
        static let challengeRequired: ThreeDSAuthData = ...
        static let frictionless: ThreeDSAuthData = ...
        static let failed: ThreeDSAuthData = ...
    }

    // Error Fixtures
    enum Errors {
        static let networkError: Error = ...
        static let validationError: PrimerError = ...
        static let paymentDeclined: PrimerError = ...
    }
}
```

**Rationale**:
- Centralized test data prevents duplication across test files
- Reusable fixtures ensure consistency
- Existing `TestData.swift` demonstrates the pattern works

**Alternatives Considered**:
- ❌ Inline test data in each test file - Leads to duplication
- ❌ Factory pattern for test data - Overkill for stateless data
- ❌ JSON files on disk - Harder to maintain, slower to load

**Evidence**:
- Existing `TestData.swift` provides: `CardNumbers`, `ExpiryDates`, `CVV`, `CardholderNames`, `BillingAddress`
- Currently at 41.18% coverage - needs more usage to justify its value

---

### 6. How do we measure and track coverage progress?

**Decision**: Use `xcodebuild -enableCodeCoverage YES` + `xcrun xccov` after each phase

**Command**:
```bash
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Extract coverage by area
xcrun xccov view --report TestResults.xcresult | \
  grep "Sources/PrimerSDK/Classes/CheckoutComponents"
```

**Tracking**:
- Run coverage after each phase (1-6)
- Document results in phase summary
- Compare against targets

**Rationale**:
- Built-in Xcode tooling, no additional dependencies
- Already used successfully in Spec 002 completion
- Provides line-level coverage data

**Alternatives Considered**:
- ❌ Third-party coverage tools (Slather, Codecov) - Unnecessary, Xcode tools sufficient
- ❌ Manual coverage tracking - Error-prone, not scalable
- ❌ Only check coverage at end - Can't course-correct mid-implementation

**Evidence**:
- Coverage analysis from Spec 002 used xcrun xccov successfully
- Identified exact gap: 18.96% current vs 90% target

---

## Summary

**Key Decisions**:
1. ✅ Use Spec 002 test patterns (XCTest + async/await)
2. ✅ Protocol-based mocks extending existing infrastructure
3. ✅ Pragmatic 80% target initially (skip Presentation refactoring)
4. ✅ Prioritize Data/Payment (P1), then Quick Wins (P2), then Utilities (P3)
5. ✅ Extend TestData.swift with API responses and payment results
6. ✅ Track coverage via xcodebuild + xcrun xccov after each phase

**No Further Research Needed**: All technical decisions resolved. Ready for Phase 1 (Design).
