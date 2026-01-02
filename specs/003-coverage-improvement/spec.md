# Feature Specification: CheckoutComponents Code Coverage Improvement

**Feature Branch**: `003-coverage-improvement`
**Created**: 2025-12-24
**Status**: Draft
**Input**: User description: "Improve CheckoutComponents code coverage from 18.96% to 90% by adding tests for Data, Payment, Presentation, and other untested areas"
**Prerequisite**: [Spec 002 - Unit Test Suite](../002-checkout-components-unit-tests/spec.md)

## Problem Statement

After implementing comprehensive unit test infrastructure in Spec 002, CheckoutComponents production code coverage stands at **18.96%** (3,419/18,031 lines), falling short of the **90% target** by 71 percentage points (12,809 lines).

The gap isn't due to missing test infrastructure—it's because significant portions of production code lack corresponding tests, particularly in Data repositories (16.82%), Payment interactors (13.17%), and Presentation layer (0.15%).

## Clarifications

### Session 2025-12-25

- Q: When production API contracts change (e.g., new required fields, deprecated endpoints), how should test fixtures and mock data be updated to prevent stale tests? → A: Manual update - Developers update TestData.swift only when they notice test failures
- Q: How should coverage progress be tracked and reported to support the Phase 5 decision point (80% vs 90% target)? → A: GitHub Actions run Sonar to check code coverage
- Q: To prevent mock drift (where MockHeadlessRepository behavior diverges from real HeadlessRepositoryImpl), how frequently should mocks be validated against real implementations? → A: Code review only - Reviewers verify mock behavior matches production during PR reviews
- Q: FR-004 requires "zero flaky failures across 10 consecutive runs." How should "flaky" be defined for enforcement? → A: Non-deterministic - Test that passes/fails inconsistently on identical code without external changes
- Q: How does payment flow handle race conditions between cancellation and successful payment completion? → A: Cancellation-takes-priority - If user cancels, ignore success callback and treat as cancelled even if payment succeeded

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Data Layer Coverage (Priority: P1)

As a developer, I need comprehensive tests for repository implementations so that API interactions, data mapping, error handling, and cache behavior are verified, ensuring payment data flows correctly between the backend and SDK.

**Why this priority**: Data layer bridges SDK with backend services. Bugs here directly cause payment failures, incorrect error handling, and data inconsistencies that impact revenue.

**Independent Test**: Can be fully tested with mocked network responses and repository implementations, delivering immediate confidence in data integrity without requiring full integration.

**Acceptance Scenarios**:

1. **Given** `HeadlessRepositoryImpl` with mocked API, **When** fetching payment methods succeeds, **Then** response should correctly map to internal models with all fields populated
2. **Given** repository with network error, **When** API call fails, **Then** error should propagate with proper error codes and user-facing messages
3. **Given** repository with cached data, **When** fetching payment methods again, **Then** cache should be used appropriately per cache policy
4. **Given** `PayPalRepositoryImpl` with retry logic, **When** transient failure occurs, **Then** request should retry with exponential backoff
5. **Given** configuration repository, **When** fetching merchant config, **Then** settings should be correctly parsed and validated

---

### User Story 2 - Payment Flow Coverage (Priority: P1)

As a developer, I need comprehensive tests for payment interactors so that payment orchestration, 3DS handling, tokenization, and surcharge calculation are verified, ensuring payments complete successfully.

**Why this priority**: Payment interactors orchestrate the core payment flow. Bugs here cause payment failures, poor user experience, and potential security issues with sensitive card data.

**Independent Test**: Can be fully tested with mocked repositories and 3DS handlers, delivering confidence in payment orchestration logic without real payment processing.

**Acceptance Scenarios**:

1. **Given** card payment with 3DS required, **When** processing payment, **Then** 3DS challenge flow should execute with proper state transitions
2. **Given** card tokenization flow, **When** tokenizing card data, **Then** sensitive data should never be logged or stored inappropriately
3. **Given** payment with network surcharge, **When** calculating final amount, **Then** surcharge should be added correctly based on card network
4. **Given** payment failure, **When** error occurs during processing, **Then** error should be properly categorized (network, validation, payment declined) and surfaced to user
5. **Given** payment cancellation, **When** user cancels mid-flow, **Then** all resources should be cleaned up and state reset appropriately
6. **Given** payment cancellation requested during processing, **When** payment completes successfully before cancellation processes, **Then** cancellation takes priority and payment is treated as cancelled (ignoring success callback)

---

### User Story 3 - Complete Near-Finished Areas (Priority: P2)

As a developer, I need to achieve 90% coverage in Navigation (88.52%), Validation (72.14%), Core (70.23%), and DI Container (56.90%) so that we close all testing gaps in foundational infrastructure.

**Why this priority**: These areas are close to target and provide maximum coverage gain with minimal effort. Completing them demonstrates systematic thoroughness and catches edge cases in critical infrastructure.

**Independent Test**: Each area can be tested independently with incremental test additions to existing test suites, delivering quick wins that boost overall coverage metrics.

**Acceptance Scenarios**:

1. **Given** Navigation system at 88.52%, **When** edge cases for back navigation and route deduplication are tested, **Then** coverage reaches 90%
2. **Given** Validation system at 72.14%, **When** edge cases for billing address and expiry date validation are tested, **Then** coverage reaches 90%
3. **Given** Core services at 70.23%, **When** error paths in CheckoutSDKInitializer and SettingsObserver are tested, **Then** coverage reaches 90%
4. **Given** DI Container at 56.90%, **When** factory registration, async resolution, and retention policies are tested, **Then** coverage reaches 90%

---

### User Story 4 - Scope & Utilities Coverage (Priority: P3)

As a developer, I need tests for Scope customization paths (43.60%), Analytics tracking (part of Other 7.14%), and utility code so that all user-facing customization options and observability features are verified.

**Why this priority**: Important for merchant customization and debugging, but lower business impact than payment flows. Can be deferred if time-constrained.

**Independent Test**: Can be tested independently with mock dependencies, delivering confidence in customization APIs and analytics accuracy.

**Acceptance Scenarios**:

1. **Given** Scope with customization closures, **When** merchant provides custom UI components, **Then** custom components should render correctly within scope lifecycle
2. **Given** analytics event tracking, **When** payment flow events occur, **Then** events should be logged with correct metadata (event type, timestamp, session ID)
3. **Given** design token system, **When** switching between light/dark themes, **Then** correct token values should be returned for each theme
4. **Given** formatting utilities for card numbers and expiry dates, **When** formatting input, **Then** output should match expected mask patterns

---

### User Story 5 - Presentation Layer Refactoring (Priority: P4 - Optional, High Risk)

As a developer, I need SwiftUI views with business logic extracted into ViewModels so that input formatting, validation, and field visibility logic can be unit tested independently of UI rendering.

**Why this priority**: Presentation layer (7,368 lines, 0.15% coverage) represents largest coverage gap. However, refactoring working UI carries HIGH RISK of regressions. This is optional—90% target is achievable without it by accepting 80% overall with Presentation exempted.

**Independent Test**: ViewModels can be unit tested; UI components would require snapshot or UI tests (out of scope).

**Acceptance Scenarios**:

1. **Given** `CardNumberInputField` refactored with ViewModel, **When** testing card number formatting, **Then** ViewModel logic can be unit tested without SwiftUI rendering
2. **Given** `CVVInputField` refactored with ViewModel, **When** testing CVV validation, **Then** validation logic is testable independently
3. **Given** `BillingAddressView` refactored with ViewModel, **When** testing field visibility rules, **Then** conditional display logic is unit testable
4. **Given** existing SwiftUI views after refactoring, **When** manually testing UI, **Then** visual appearance and user interactions remain unchanged (no regressions)

---

### Edge Cases

- What happens when repository returns malformed JSON that doesn't match expected schema?
- Payment flow race condition (cancellation vs. completion): Cancellation takes priority—if user cancels, ignore success callback and treat as cancelled even if payment succeeded
- What happens when DI container is asked to resolve a dependency during container shutdown?
- How does validation system handle internationalization edge cases (e.g., postal codes in non-standard formats)?
- What happens when SwiftUI view customization closures throw unexpected errors?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST achieve 90% code coverage for CheckoutComponents production code (excluding Mocks, Previews, and test utilities)
- **FR-002**: New tests MUST follow existing test patterns from Spec 002 (XCTest with async/await, @MainActor isolation)
- **FR-003**: Tests MUST execute in under 2 minutes total to maintain fast CI/CD feedback loop
- **FR-004**: Tests MUST be deterministic with zero flaky failures across 10 consecutive runs (flaky defined as non-deterministic: passes/fails inconsistently on identical code without external changes)
- **FR-005**: Data layer tests MUST mock all network calls and verify request/response mapping accuracy
- **FR-006**: Payment layer tests MUST verify 3DS flow handling, tokenization security, and error categorization
- **FR-007**: All tests MUST verify error handling paths in addition to happy path scenarios
- **FR-008**: Coverage reports MUST exclude non-production code (Mocks, MockDesignTokens, Preview providers)
- **FR-009**: Presentation layer refactoring (if pursued) MUST preserve existing UI behavior with no visual regressions
- **FR-010**: DI Container tests MUST verify factory registration, singleton/transient/weak retention policies, and async resolution

### Key Entities

- **Test Coverage Report**: Tracks lines covered/total per module, overall percentage, uncovered line numbers
- **Mock Repository**: Test double for data repositories, configurable to return success/error responses
- **Mock Payment Processor**: Test double for payment processing, simulates 3DS flows and tokenization
- **Test Fixture Data**: Reusable test data (card numbers, expiry dates, addresses) following patterns from Spec 002. Maintained manually—developers update TestData.swift when test failures indicate API contract changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: CheckoutComponents production code coverage reaches 90% (16,228/18,031 lines) measured via xcrun xccov
- **SC-002**: Alternative pragmatic target - 80% coverage excluding Presentation layer (11,078/13,863 lines for non-Presentation code)
- **SC-003**: All new tests pass consistently with 0 failures across 10 consecutive test runs
- **SC-004**: Total test suite execution time remains under 2 minutes on iPhone 17 simulator
- **SC-005**: Code review identifies zero instances of tests testing implementation details rather than behavior
- **SC-006**: Coverage gaps identified in Phase 1-3 are reduced to zero (Navigation, Validation, Core, DI, Data, Payment)

## Non-Goals

- UI/Snapshot testing for SwiftUI components (complementary, not replacement for unit tests)
- Integration testing with real backend APIs
- Performance/load testing
- Fixing existing bugs (only test existing behavior as-is)
- Refactoring production code beyond what's needed for testability

## Dependencies

- Spec 002: Unit test infrastructure (test base classes, mocks, fixtures) must be complete
- Test Execution Environment: iPhone 17 simulator with iOS 26.2
- Xcode 15.0+ with Swift 6.0+ for async/await test support
- Coverage Tools: xcodebuild with enableCodeCoverage and xcrun xccov (local), GitHub Actions with Sonar for CI coverage tracking

## Assumptions

- Existing test patterns from Spec 002 are sufficient and don't need modification
- Mock implementations can accurately represent real repository/service behavior
- Presentation layer can be exempted from 90% target if refactoring deemed too risky (fallback to 80% overall target)
- GitHub Actions with Sonar will automatically track coverage progress and provide reporting for Phase 5 decision point

## Risks

1. **Presentation Layer Refactoring** (HIGH RISK)
   - Risk: Refactoring working SwiftUI views to extract ViewModels may introduce visual regressions or break existing functionality
   - Mitigation: Make refactoring optional (accept 80% target without it), use snapshot testing to catch regressions
   - Decision Point: Go/No-Go after completing Phases 1-3

2. **Mock Fragility** (MEDIUM RISK)
   - Risk: Mock repositories/services diverge from real implementations, giving false confidence
   - Mitigation: Keep mocks protocol-based, validate mock behavior matches production during code review, leverage existing integration tests for sanity checks

3. **Test Execution Time** (LOW RISK)
   - Risk: Large test suite becomes slow, slowing down development feedback
   - Mitigation: Run tests in parallel, keep tests isolated and fast, profile slow tests

4. **Coverage Gaming** (MEDIUM RISK)
   - Risk: Tests hit lines without verifying meaningful behavior just to boost coverage numbers
   - Mitigation: Code review focuses on test quality, require assertion-heavy tests, avoid testing implementation details

## Rollout Strategy

**Phase 1: Quick Wins** (Days 1-2)
- Complete Navigation (88.52% → 90%): ~3 lines
- Complete Validation (72.14% → 90%): ~158 lines
- Complete Core (70.23% → 90%): ~87 lines
- Complete DI Container (56.90% → 90%): ~405 lines
- Total: +653 lines, New Coverage: ~22.58%

**Phase 2: Data Layer** (Days 3-5)
- Add repository tests: ~958 lines
- Total: +958 lines, New Coverage: ~27.89%

**Phase 3: Payment Layer** (Days 6-8)
- Add payment interactor tests: ~899 lines
- Total: +899 lines, New Coverage: ~32.87%

**Phase 4: Scope & Utilities** (Days 9-11)
- Add scope customization tests: ~1,068 lines
- Add analytics/token/utility tests: ~2,296 lines
- Total: +3,364 lines, New Coverage: ~51.53%

**Phase 5: Decision Point**
- Evaluate: Have we reached 80%+ coverage without Presentation refactoring?
  - YES: Declare success with pragmatic 80% target
  - NO: Proceed to Phase 6 (high risk)

**Phase 6: Presentation Refactoring** (Days 12-18, OPTIONAL)
- Extract ViewModels from SwiftUI views: ~5,150 lines to 70% coverage
- Total: +5,150 lines, New Coverage: ~90.00%
