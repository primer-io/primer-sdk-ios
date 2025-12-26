# CheckoutComponents Test Structure Cleanup Plan

**Created:** 2025-12-27
**Branch:** `bn/feature/checkout-components`
**Total Test Files:** 92
**Total Test Classes:** 104
**Total Test Methods:** ~800+

---

## Current State Summary

### Statistics

| Metric | Count |
|--------|-------|
| Test files | 92 |
| Test classes (XCTestCase) | 104 |
| Files using TestData | 22 |
| Files with setUp/tearDown | 54/57 |
| Async test methods | 424 |
| Mock classes (total) | 35 |
| Shared mocks (in Mocks/) | 6 |
| Inline mocks (private) | 29 |

### Directory Structure

```
Tests/Primer/CheckoutComponents/
├── Mocks/                    # 6 shared mocks
├── TestSupport/              # 1 centralized TestData.swift (600 lines)
├── ApplePay/                 # 10 files (651 lines largest)
│   └── Mocks/                # 1 ApplePay-specific mock
├── Core/                     # 2 files
├── DI/                       # 2 files (609 lines largest - AsyncResolutionTests)
├── Data/                     # 6 files
├── Interactors/              # 4 files
├── Navigation/               # 3 files
├── Network/                  # 4 files
├── Payment/                  # 15 files (564 lines largest - PaymentProcessorTests)
├── Scope/                    # 8 files (901 lines largest - DefaultCheckoutScopeTests)
├── Utilities/                # 8 files
├── Validation/               # 5 files
└── [root level]              # 18 files (unorganized)
```

### Largest Test Files (by lines)

| File | Lines | Tests |
|------|-------|-------|
| DefaultCheckoutScopeTests.swift | 901 | 57 |
| DefaultCardFormScopeTests.swift | 762 | 27 |
| DefaultApplePayScopeTests.swift | 651 | 40 |
| VaultDefaultPaymentMethodSelectionScopeTests.swift | 620 | - |
| AsyncResolutionTests.swift | 609 | - |
| TestData.swift | 600 | N/A |
| PaymentProcessorTests.swift | 564 | - |

### Shared Mocks (in Mocks/)

| Mock | Used By | Pattern |
|------|---------|---------|
| `MockAccessibilityAnnouncementService` | Accessibility tests | Protocol conformance |
| `MockAnalyticsInteractor` | Multiple | Protocol conformance |
| `MockConfigurationService` | Scope tests | Has factory `withDefaultConfiguration()` |
| `MockHeadlessRepository` | Interactor tests | Full call tracking |
| `MockRulesFactory` | Validation tests | Call counting |
| `MockValidationService` | Multiple | Stubbed returns |

### Inline Mocks (private classes in test files)

| File | Inline Mocks | Reusability |
|------|--------------|-------------|
| `PaymentProcessorTests.swift` | `MockTokenizer`, `MockPaymentAPIClient`, `MockThreeDSHandler` | High |
| `ConfigurationServiceTests.swift` | `MockAPIClient`, `MockUserDefaults` | High |
| `ThreeDSFlowTests.swift` | `Mock3DSSDKManager`, `Mock3DSAPIClient` | Medium |
| `TransactionManagerTests.swift` | `MockTransactionStorage` | Low |
| `PaymentAnalyticsTests.swift` | `MockAnalyticsClient` | Medium |
| `CheckoutComponentsTokenizationTests.swift` | `MockTokenizationAPIClient` | Medium |
| `MerchantConfigCachingTests.swift` | `MockCacheStorage`, `MockClock` | Medium |
| `PaymentMethodCacheTests.swift` | `MockPaymentMethodStorage` | Low |
| `PaymentMethodRepositoryTests.swift` | `MockCache` | Low |
| `APIClientEdgeCasesTests.swift` | `MockNetworkManager` | Medium |
| `RetentionPolicyTests.swift` | `MockService` | Low (test-specific) |
| `SettingsObserverTests.swift` | `MockSettings` | Low (test-specific) |
| `DefaultCardFormScopeTests.swift` | `MockProcessCardPaymentInteractor`, `MockValidateInputInteractor`, `MockCardNetworkDetectionInteractor` | High |
| `ProcessApplePayPaymentInteractorTests.swift` | 8 PKPayment mocks | Low (Apple-specific) |
| `ApplePayPaymentMethodTests.swift` | `MockInvalidCheckoutScope` | Low |

---

## Issues

### Issue 1: Scattered Mocks (High Priority)
- **29 mocks** defined inline as private classes
- Reduces reusability across tests
- Makes it harder to maintain consistent mock behavior
- No duplicate mock names (good!) but conceptually similar mocks exist

**Impact:** Medium - Tests work but maintenance is harder

### Issue 2: Root-Level Test Files (Medium Priority)
18 files at root that should be organized:

**Accessibility tests (5 files):**
- `AccessibilityAnnouncementServiceTests.swift`
- `AccessibilityConfigurationTests.swift`
- `AccessibilityDIContainerTests.swift`
- `AccessibilityIdentifiersTests.swift`
- `AccessibilityStringsTests.swift`

**Vault tests (4 files):**
- `VaultDefaultCheckoutScopeTests.swift`
- `VaultDefaultPaymentMethodSelectionScopeTests.swift`
- `VaultedCardCVVInputTests.swift`
- `VaultedPaymentMethodDisplayDataTests.swift`

**View/UI tests (2 files):**
- `ViewAccessibilityExtensionTests.swift`
- `AppearanceModeTests.swift`

**Repository/Integration tests (7 files):**
- `AnalyticsSessionConfigProviderTests.swift`
- `HeadlessRepositorySettingsTests.swift`
- `HeadlessRepositoryTests.swift`
- `PrimerPaymentMethodTypeImageNameTests.swift` (58 tests!)
- `PrimerSettingsDIIntegrationTests.swift`
- `PrimerSettingsIntegrationTests.swift`
- `SubmitVaultedPaymentInteractorTests.swift`

### Issue 3: Inconsistent TestData Usage (Medium Priority)
- 22 files use `TestData.*` properly
- Several files have hardcoded test values (e.g., `"4242424242424242"`)
- `ApplePayTestData.swift` is separate (acceptable - domain-specific)

**Files with hardcoded card numbers:**
- `CheckoutComponentsTokenizationTests.swift` (9 occurrences)
- `PaymentProcessorTests.swift` (10+ occurrences)
- `CardTokenizationTests.swift`
- `PaymentMethodHandlerTests.swift`

### Issue 4: Duplicated Helper Methods (Low Priority)
Multiple files have similar `createTestContainer()` helper:
- `DefaultPaymentMethodSelectionScopeTests.swift`
- `DefaultSelectCountryScopeTests.swift`
- `DefaultCheckoutScopeTests.swift`
- `DefaultCardFormScopeTests.swift`

### Issue 5: Test Naming Conventions (Low Priority)
- Most tests follow `test_behavior_condition` pattern ✓
- Some use `testBehavior_Condition` pattern (inconsistent)
- Examples: `testCardFormFieldStrings_NotEmpty` vs `test_cardNumberField_validatesCorrectly`

---

## What's Working Well

1. **No duplicate mock names** - All 35 mocks have unique names
2. **Good assertion coverage** - 1,900+ assertions across test suite
3. **Consistent async patterns** - 424 async tests using modern Swift concurrency
4. **Comprehensive TestData** - Well-organized with CardNumbers, CVV, ExpiryDates, Errors, etc.
5. **Good test isolation** - 54 files have proper setUp/tearDown
6. **Strong coverage per file** - Average ~10 tests per file

---

## Proposed Changes

### Phase 1: Organize Root-Level Tests (Low Risk)

**Step 1.1: Create Accessibility directory**
```bash
mkdir -p Tests/Primer/CheckoutComponents/Accessibility
git mv Tests/Primer/CheckoutComponents/Accessibility*.swift Tests/Primer/CheckoutComponents/Accessibility/
git mv Tests/Primer/CheckoutComponents/ViewAccessibilityExtensionTests.swift Tests/Primer/CheckoutComponents/Accessibility/
```

**Step 1.1 Validation:**
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Commit changes

**Step 1.2: Create Vault directory**
```bash
mkdir -p Tests/Primer/CheckoutComponents/Vault
git mv Tests/Primer/CheckoutComponents/Vault*.swift Tests/Primer/CheckoutComponents/Vault/
```

**Step 1.2 Validation:**
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Commit changes

---

### Phase 2: Extract High-Value Inline Mocks (Medium Risk)

Priority order based on reusability:

| Priority | Mock | From File | Reuse Potential |
|----------|------|-----------|-----------------|
| 1 | `MockProcessCardPaymentInteractor` | DefaultCardFormScopeTests | High |
| 2 | `MockValidateInputInteractor` | DefaultCardFormScopeTests | High |
| 3 | `MockCardNetworkDetectionInteractor` | DefaultCardFormScopeTests | High |
| 4 | `MockPaymentAPIClient` | PaymentProcessorTests | Medium |
| 5 | `MockAPIClient` | ConfigurationServiceTests | Medium |
| 6 | `Mock3DSSDKManager` | ThreeDSFlowTests | Medium |

**Step 2.1: Extract Interactor mocks (1-3)**
- [ ] Create `Mocks/MockProcessCardPaymentInteractor.swift`
- [ ] Create `Mocks/MockValidateInputInteractor.swift`
- [ ] Create `Mocks/MockCardNetworkDetectionInteractor.swift`
- [ ] Update `DefaultCardFormScopeTests.swift` to use shared mocks
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

**Step 2.2: Extract API mocks (4-5)**
- [ ] Create `Mocks/MockPaymentAPIClient.swift`
- [ ] Create `Mocks/MockAPIClient.swift`
- [ ] Update source test files
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

**Step 2.3: Extract 3DS mocks (6)**
- [ ] Create `Mocks/Mock3DSSDKManager.swift`
- [ ] Update `ThreeDSFlowTests.swift`
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

**Leave as inline (low reuse):**
- `MockService`, `MockSettings` - test-specific
- PKPayment mocks - Apple framework-specific
- `MockClock` - utility-specific

---

### Phase 3: Standardize TestData Usage (Low Risk)

Replace hardcoded values with TestData references:
```swift
// Before
let cardNumber = "4242424242424242"

// After
let cardNumber = TestData.CardNumbers.validVisa
```

**Step 3.1: Update Payment tests**
- [ ] Update `CheckoutComponentsTokenizationTests.swift`
- [ ] Update `PaymentProcessorTests.swift`
- [ ] Update `CardTokenizationTests.swift`
- [ ] Update `PaymentMethodHandlerTests.swift`
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

**Step 3.2: Update remaining files**
- [ ] Update remaining files with hardcoded values
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

---

### Phase 4: Create Shared Test Helpers (Optional)

**Step 4.1: Create ContainerTestHelpers**

Create `TestSupport/ContainerTestHelpers.swift`:
```swift
@available(iOS 15.0, *)
enum ContainerTestHelpers {
    static func createTestContainer() async -> Container {
        // Shared implementation
    }
}
```

- [ ] Create shared helper file
- [ ] Update `DefaultPaymentMethodSelectionScopeTests.swift`
- [ ] Update `DefaultSelectCountryScopeTests.swift`
- [ ] Update `DefaultCheckoutScopeTests.swift`
- [ ] Update `DefaultCardFormScopeTests.swift`
- [ ] **Build succeeds**
- [ ] **All tests pass**
- [ ] Commit changes

---

## Validation Commands

```bash
# Quick compile check
xcodebuild build-for-testing \
  -workspace "PrimerSDK.xcworkspace" \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"

# Run all tests
xcodebuild test \
  -workspace "PrimerSDK.xcworkspace" \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"
```

**Note:** Use `PrimerSDK.xcworkspace` with `PrimerSDKTests` scheme for all validation.

---

## Risk Assessment

| Phase | Risk | Impact if Failed | Rollback |
|-------|------|------------------|----------|
| 1 - Move files | Low | Build fails | `git checkout` |
| 2 - Extract mocks | Medium | Tests fail | `git checkout` |
| 3 - TestData | Low | Tests fail | `git checkout` |
| 4 - Helpers | Low | No impact | `git checkout` |

---

## Progress Tracking

| Phase | Step | Status | Build | Tests | Committed |
|-------|------|--------|-------|-------|-----------|
| 1 | 1.1 Create Accessibility/ | [x] Done | [x] | [x] | [x] |
| 1 | 1.2 Create Vault/ | [x] Done | [x] | [x] | [x] |
| 2 | 2.1 Extract Interactor mocks | [x] Done | [x] | [x] | [x] |
| 2 | 2.2 Extract API mocks | [x] Skipped | N/A | N/A | N/A |
| 2 | 2.3 Extract 3DS mocks | [x] Skipped | N/A | N/A | N/A |
| 3 | 3.1 Update Payment tests | [ ] Pending | [ ] | [ ] | [ ] |
| 3 | 3.2 Update remaining files | [ ] Pending | [ ] | [ ] | [ ] |
| 4 | 4.1 Shared helpers | [ ] Pending | [ ] | [ ] | [ ] |

**Gate Rule:** Do NOT proceed to next step until Build ✓, Tests ✓, and Committed ✓

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-27 | Start with file organization | Lowest risk, immediate clarity |
| 2025-12-27 | Keep PKPayment mocks inline | Apple-specific, low reuse |
| 2025-12-27 | Keep `MockService`/`MockSettings` inline | Test-specific, no reuse value |
| 2025-12-27 | Prioritize interactor mocks for extraction | Used across multiple scope tests |
| 2025-12-27 | Don't rename existing mocks | Avoid unnecessary churn |
| 2025-12-27 | Skip Phase 2.2/2.3 (API/3DS mocks) | Single-file usage, no protocol conformance, test-specific implementations |

---

## Files Changed Summary (After All Phases)

**Phase 1:**
- 6 files moved to `Accessibility/`
- 4 files moved to `Vault/`

**Phase 2:**
- ~6 new files in `Mocks/`
- ~6 existing test files modified (remove inline mocks)

**Phase 3:**
- ~20 test files modified (TestData references)

**Phase 4:**
- 1 new file in `TestSupport/`
- ~4 test files modified (use shared helper)
