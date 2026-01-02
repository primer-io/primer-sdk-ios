# Implementation Plan: CheckoutComponents Code Coverage Improvement

**Branch**: `003-coverage-improvement` | **Date**: 2025-12-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-coverage-improvement/spec.md`

## Summary

Improve CheckoutComponents production code coverage from 18.96% to 90% by adding comprehensive unit tests for Data repositories, Payment interactors, and completing coverage for near-finished areas (Navigation, Validation, Core, DI Container). The test infrastructure from Spec 002 is already complete—this plan focuses on adding tests for untested production code following established patterns.

**Pragmatic Approach**: Target 80% coverage initially by prioritizing Data/Payment layers (P1) and avoiding high-risk Presentation layer refactoring. Presentation refactoring (extracting ViewModels from SwiftUI) is optional Phase 6 if 90% target is required.

## Technical Context

**Language/Version**: Swift 6.0+ with strict concurrency checking
**Primary Dependencies**: XCTest, CheckoutComponents DI framework, existing mock utilities from Spec 002
**Storage**: N/A (tests are stateless)
**Testing**: XCTest with async/await support, @MainActor isolation
**Target Platform**: iOS 15.0+ (CheckoutComponents minimum)
**Project Type**: Mobile SDK - test extension
**Performance Goals**: Test suite execution < 2 minutes total
**Constraints**: No network calls (all external dependencies mocked), zero flaky tests across 10 consecutive runs
**Scale/Scope**: ~50-70 new test files covering Data/Payment/Utilities layers, targeting 12,809 additional lines of production code coverage

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. iOS Platform Standards | ✅ PASS | XCTest is Apple's official testing framework; Swift 6.0+ compliant with async/await |
| II. Cross-Platform API Parity | ✅ PASS | Unit tests are platform-specific by nature; no parity requirement for internal tests |
| III. Integration Flexibility | ✅ PASS | Tests verify internal behavior without coupling integration approaches (Drop-In/Headless/Components) |
| IV. Security & PCI Compliance | ✅ PASS | Tests use mock data only; no real PII or payment card data; follows Spec 002 patterns |
| V. Test Coverage & Quality Gates | ✅ PASS | Spec targets 90% coverage (exceeds constitution's 80% minimum); enforces quality gates |
| VI. Backward Compatibility | ✅ PASS | Tests are internal; no public API changes; no merchant impact |

**Gate Status**: ✅ PASSED - No violations requiring justification

## Project Structure

### Documentation (this feature)

```text
specs/003-coverage-improvement/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: Research decisions
├── data-model.md        # Phase 1: Test data entities
├── quickstart.md        # Phase 1: Developer guide
├── checklists/
│   └── requirements.md  # Spec quality validation
└── tasks.md             # Phase 2: Created by /speckit.tasks (NOT by this command)
```

### Source Code (repository root)

```text
Tests/Primer/CheckoutComponents/          # Existing from Spec 002 (36 files)
├── Data/                                 # NEW: Repository tests (~10 files)
│   ├── Repositories/
│   │   ├── HeadlessRepositoryImplTests.swift
│   │   ├── PayPalRepositoryImplTests.swift
│   │   └── ConfigurationRepositoryTests.swift
│   └── Mappers/
│       ├── PaymentMethodMapperTests.swift
│       └── ErrorMapperTests.swift
├── Payment/                              # NEW: Payment flow tests (~8 files)
│   ├── Interactors/
│   │   ├── PaymentFlowCoordinatorTests.swift
│   │   ├── ThreeDSHandlerTests.swift
│   │   └── TokenizationServiceTests.swift
│   └── Models/
│       └── PaymentResultTests.swift
├── Analytics/                            # NEW: Analytics tests (~3 files)
│   ├── AnalyticsEventTests.swift
│   └── AnalyticsSessionTests.swift
├── Utilities/                            # NEW: Utility tests (~8 files)
│   ├── Tokens/
│   │   ├── DesignTokensTests.swift
│   │   └── DesignTokensManagerTests.swift
│   ├── Formatters/
│   │   ├── CardNumberFormatterTests.swift
│   │   └── ExpiryDateFormatterTests.swift
│   └── Extensions/
│       └── StringExtensionsTests.swift
├── Scope/                                # ENHANCE: Add customization tests (~4 files)
│   └── ScopeCustomizationTests.swift    # NEW
├── Validation/                           # ENHANCE: Complete edge cases (~2 files)
│   └── BillingAddressValidationTests.swift  # NEW
├── Navigation/                           # ENHANCE: Final 1.48% gap (~1 file)
│   └── NavigationEdgeCasesTests.swift   # NEW
├── Core/                                 # ENHANCE: Complete services (~3 files)
│   ├── CheckoutSDKInitializerTests.swift  # NEW
│   └── SettingsObserverTests.swift      # NEW
└── DI/                                   # ENHANCE: Complete container (~3 files)
    ├── RetentionPolicyTests.swift       # NEW
    ├── FactoryRegistrationTests.swift   # NEW
    └── AsyncResolutionTests.swift       # NEW

Sources/PrimerSDK/Classes/CheckoutComponents/
└── Internal/                             # NO CHANGES (unless Presentation refactoring in Phase 6)
    ├── Data/Repositories/                # TARGET: Add tests for these
    ├── Domain/Interactors/               # TARGET: Add tests for these
    ├── Core/Services/                    # TARGET: Complete coverage
    └── Presentation/                     # SKIP INITIALLY (Phase 6 optional)
```

**Structure Decision**: Extending Spec 002 test infrastructure with new test files following established patterns. Tests organized by layer (Data, Payment, Analytics, Utilities) matching production code structure under `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/`. No production code changes except optional Phase 6 Presentation refactoring.

## Complexity Tracking

> No violations requiring justification - all constitution gates passed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _(none)_  | _(n/a)_    | _(n/a)_                             |

---

## Phase 0: Research Summary

See [research.md](./research.md) for detailed findings.

**Key Decisions**:
1. **Test Pattern Reuse**: Use existing Spec 002 patterns (XCTest + async/await, @MainActor isolation)
2. **Mock Strategy**: Protocol-based mocks extending existing MockHeadlessRepository, MockValidationService
3. **Coverage Target**: Start with pragmatic 80% (skip Presentation refactoring), escalate to 90% only if required
4. **Prioritization**: P1 Data/Payment layers first (revenue-critical), P2 quick wins, P3 utilities last

---

## Phase 1: Design Outputs

### Data Model
See [data-model.md](./data-model.md) for test data entities.

**Key Entities**:
- Mock API Response (payment methods, merchant config)
- Test Coverage Report (per-module metrics)
- Mock 3DS Flow (challenge scenarios)

### Contracts
**N/A** - This feature adds tests, not new public APIs. No contracts to define.

### Developer Guide
See [quickstart.md](./quickstart.md) for implementation guidance.

---

## Critical Files

The following files are most critical for implementing this plan:

1. **`/Users/onurvar/Projects/primer-sdk-ios/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Data/Repositories/HeadlessRepositoryImpl.swift`**
   - Core payment data repository with 16.82% coverage gap
   - Critical for API interactions, data mapping, error handling
   - Direct impact on payment success rates

2. **`/Users/onurvar/Projects/primer-sdk-ios/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Domain/Interactors/ProcessCardPaymentInteractor.swift`**
   - Payment orchestration with 3DS handling at 13.17% coverage
   - Bugs here cause payment failures and poor UX
   - Critical for revenue

3. **`/Users/onurvar/Projects/primer-sdk-ios/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Core/Validation/ValidationService.swift`**
   - Validation engine at 72.14% coverage
   - Pattern to follow for completing near-finished areas
   - Already well-tested, just needs edge case completion

4. **`/Users/onurvar/Projects/primer-sdk-ios/Tests/Primer/CheckoutComponents/Mocks/MockHeadlessRepository.swift`**
   - Existing mock to extend (currently 75.45% coverage)
   - Enables all Data/Payment layer testing without real network calls
   - Foundation for repository test mocks

5. **`/Users/onurvar/Projects/primer-sdk-ios/Tests/Primer/CheckoutComponents/TestSupport/TestData.swift`**
   - Existing test fixtures at 41.18% coverage
   - Needs extension with repository responses and payment results
   - Centralized test data prevents duplication

---

## Implementation Phases

### Phase 0: Research & Setup ✅ COMPLETE
- Review existing test patterns from Spec 002
- Identify uncovered code paths via coverage report
- Document mock strategy

### Phase 1: Quick Wins (Days 1-2)
**Target**: +653 lines → 22.58% coverage
- Navigation: 88.52% → 90% (~3 lines)
- Validation: 72.14% → 90% (~158 lines)
- Core: 70.23% → 90% (~87 lines)
- DI Container: 56.90% → 90% (~405 lines)

### Phase 2: Data Layer (Days 3-5)
**Target**: +958 lines → 27.89% coverage
- Repository implementation tests
- Data mapper tests
- Cache behavior tests
- Error propagation tests

### Phase 3: Payment Layer (Days 6-8)
**Target**: +899 lines → 32.87% coverage
- Payment interactor tests
- 3DS flow handling tests
- Tokenization tests
- Surcharge calculation tests

### Phase 4: Scope & Utilities (Days 9-11)
**Target**: +3,364 lines → 51.53% coverage
- Scope customization tests: +1,068 lines
- Analytics/tokens/utilities: +2,296 lines

### Phase 5: Decision Point
**Evaluate**: Have we reached 80%+ coverage?
- **YES**: Declare success with pragmatic 80% target (recommended)
- **NO**: Proceed to Phase 6 (high risk)

### Phase 6: Presentation Refactoring (Days 12-18, OPTIONAL)
**Target**: +5,150 lines → 90.00% coverage
- Extract ViewModels from SwiftUI views
- Test formatting/validation logic independently
- HIGH RISK: May introduce UI regressions

---

## Risk Mitigation

1. **Presentation Refactoring (HIGH)**
   - Mitigation: Make optional; accept 80% target without refactoring
   - Fallback: Use snapshot testing if ViewModels extracted

2. **Mock Fragility (MEDIUM)**
   - Mitigation: Keep mocks protocol-based; validate against integration tests periodically
   - Pattern: Use existing MockHeadlessRepository as template

3. **Test Execution Time (LOW)**
   - Mitigation: Run tests in parallel; profile slow tests
   - Target: Maintain <2 minute execution time

4. **Coverage Gaming (MEDIUM)**
   - Mitigation: Code review focuses on test quality; require assertions
   - Pattern: Follow Spec 002 assertion-heavy style

---

## Success Metrics

**Coverage Goals**:
- Primary: 90% (16,228/18,031 lines)
- Pragmatic: 80% excluding Presentation (11,078/13,863 non-Presentation lines)

**Quality Gates**:
- All tests pass consistently (0 failures across 10 runs)
- Test execution < 2 minutes
- No flaky tests
- Tests verify behavior, not implementation details

---

## Next Steps

1. Review this plan with team
2. Run `/speckit.tasks` to generate actionable task breakdown
3. Begin Phase 1 (Quick Wins) implementation
4. Track coverage progress after each phase
5. Evaluate at Phase 5 decision point: 80% vs 90% target
