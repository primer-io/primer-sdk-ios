# CheckoutComponents Coverage Improvement Plan
**Target**: 90% code coverage | **Current**: 18.96% | **Gap**: 71.04 percentage points

## Executive Summary

To reach 90% coverage target, we need to cover **12,809 additional lines** out of 18,031 total lines in CheckoutComponents.

### Coverage Gap Analysis

| Priority | Area | Current | Target | Lines Needed | Effort |
|----------|------|---------|--------|--------------|--------|
| **P0** | Presentation | 0.15% | 70%* | ~5,150 | High |
| **P1** | Data | 16.82% | 90% | ~958 | Medium |
| **P1** | Payment | 13.17% | 90% | ~899 | Medium |
| **P2** | Other | 7.14% | 80% | ~2,296 | High |
| **P2** | Scope | 43.60% | 90% | ~1,068 | Medium |
| **P3** | DI Container | 56.90% | 90% | ~405 | Low |
| **P3** | Validation | 72.14% | 90% | ~158 | Low |
| **P3** | Core | 70.23% | 90% | ~87 | Low |
| **P3** | Navigation | 88.52% | 90% | ~3 | Trivial |

*Note: Presentation (SwiftUI UI) realistically targets 70% due to testability constraints

---

## Phase 1: Quick Wins (P3 - Low Effort)
**Goal**: +650 lines | **Effort**: 1-2 days

### 1.1 Complete Navigation Coverage (88.52% → 90%)
**Lines needed**: ~3

**Strategy**:
- Review uncovered edge cases in `CheckoutCoordinator` and `CheckoutNavigator`
- Add missing navigation flow tests
- Test error handling paths

**Files to enhance**:
- `Tests/Primer/CheckoutComponents/Navigation/CheckoutCoordinatorTests.swift`
- `Tests/Primer/CheckoutComponents/Navigation/CheckoutNavigatorTests.swift`

### 1.2 Complete Validation Coverage (72.14% → 90%)
**Lines needed**: ~158

**Strategy**:
- Add edge case tests for card validation rules
- Test error message variations
- Test validation rule combinations

**Files to enhance**:
- `Tests/Primer/CheckoutComponents/Validation/CardValidationRulesTests.swift`
- `Tests/Primer/CheckoutComponents/Validation/CommonValidationRulesTests.swift`

**New test files**:
```
Tests/Primer/CheckoutComponents/Validation/
├── BillingAddressValidationRulesTests.swift  (NEW)
└── ValidationErrorMessagesTests.swift         (NEW)
```

### 1.3 Complete Core Services (70.23% → 90%)
**Lines needed**: ~87

**Strategy**:
- Test uncovered service methods
- Add error handling tests
- Test service initialization edge cases

**Files to enhance**:
- Add tests for `CheckoutSDKInitializer`
- Add tests for `SettingsObserver`
- Add tests for analytics services

**New test files**:
```
Tests/Primer/CheckoutComponents/Core/
├── CheckoutSDKInitializerTests.swift  (NEW)
└── SettingsObserverTests.swift        (NEW)
```

### 1.4 Improve DI Container (56.90% → 90%)
**Lines needed**: ~405

**Strategy**:
- Test factory registration edge cases
- Test container lifecycle
- Test error scenarios

**Files to enhance**:
- `Tests/Primer/CheckoutComponents/Core/ContainerTests.swift`

**New test files**:
```
Tests/Primer/CheckoutComponents/DI/
├── RetentionPolicyTests.swift         (NEW - was planned but not created)
├── FactoryRegistrationTests.swift     (NEW - was planned but not created)
└── AsyncResolutionTests.swift         (NEW)
```

---

## Phase 2: Medium Effort (P2)
**Goal**: +3,364 lines | **Effort**: 3-5 days

### 2.1 Complete Scope Coverage (43.60% → 90%)
**Lines needed**: ~1,068

**Strategy**:
- Test scope customization closures
- Test field configuration variations
- Test scope lifecycle edge cases

**Files to enhance**:
- `Tests/Primer/CheckoutComponents/Scope/DefaultCardFormScopeTests.swift`
- `Tests/Primer/CheckoutComponents/Scope/DefaultPaymentMethodSelectionScopeTests.swift`

**New test files**:
```
Tests/Primer/CheckoutComponents/Scope/
├── CardFormCustomizationTests.swift              (NEW)
├── PaymentMethodScopeFactoryTests.swift          (NEW)
├── ScopeNavigationIntegrationTests.swift         (NEW)
└── CheckoutScreenCustomizationTests.swift        (NEW)
```

### 2.2 Cover "Other" Category (7.14% → 80%)
**Lines needed**: ~2,296

**Strategy**:
- Identify files in "Other" category
- Prioritize by usage frequency
- Focus on analytics, utilities, extensions

**Investigation needed**:
```bash
# Run this to identify "Other" files:
xcrun xccov view --report TestResults.xcresult | \
  grep "Sources/PrimerSDK/Classes/CheckoutComponents" | \
  grep -v "/Scope/" | grep -v "/Validation/" | \
  grep -v "/DI/" | grep -v "/Payment" | \
  grep -v "/Navigation/" | grep -v "/Presentation/" | \
  grep -v "/Data/" | grep -v "/Core/"
```

**Likely areas**:
- Analytics event tracking
- Design tokens and theming
- Accessibility infrastructure
- String localizations
- Extensions and utilities

**New test files** (estimated):
```
Tests/Primer/CheckoutComponents/Analytics/
├── AnalyticsEventTests.swift             (NEW)
└── AnalyticsEventMetadataTests.swift     (NEW)

Tests/Primer/CheckoutComponents/Tokens/
├── DesignTokensTests.swift               (NEW)
└── DesignTokensManagerTests.swift        (NEW)

Tests/Primer/CheckoutComponents/Utilities/
├── StringExtensionsTests.swift           (NEW)
└── DateFormattingTests.swift             (NEW)
```

---

## Phase 3: High Effort - Data & Payment (P1)
**Goal**: +1,857 lines | **Effort**: 4-6 days

### 3.1 Data Layer Coverage (16.82% → 90%)
**Lines needed**: ~958

**Strategy**:
- Test repository implementations
- Mock API responses
- Test data mapping
- Test error handling

**New test files**:
```
Tests/Primer/CheckoutComponents/Data/
├── Repositories/
│   ├── HeadlessRepositoryImplTests.swift          (NEW)
│   ├── PayPalRepositoryImplTests.swift            (NEW)
│   └── ConfigurationRepositoryTests.swift         (NEW)
├── Mappers/
│   ├── PaymentMethodMapperTests.swift             (NEW)
│   └── ErrorMapperTests.swift                     (NEW)
└── Models/
    └── InternalPaymentMethodTests.swift           (NEW)
```

**Key testing patterns**:
- Mock network responses
- Test data transformation
- Test cache behavior
- Test error propagation

### 3.2 Payment Layer Coverage (13.17% → 90%)
**Lines needed**: ~899

**Strategy**:
- Test payment interactors
- Test 3DS flow handling
- Test payment state machines
- Test error recovery

**Files to enhance**:
- `Tests/Primer/CheckoutComponents/Interactors/ProcessCardPaymentInteractorTests.swift`

**New test files**:
```
Tests/Primer/CheckoutComponents/Payment/
├── PaymentFlowCoordinatorTests.swift              (NEW)
├── ThreeDSHandlerTests.swift                      (NEW)
├── PaymentMethodHandlerTests.swift                (NEW)
├── TokenizationServiceTests.swift                 (NEW)
└── SurchargeCalculationTests.swift                (NEW)
```

**Key testing patterns**:
- Mock payment gateway responses
- Test 3DS challenge flows
- Test payment retry logic
- Test tokenization

---

## Phase 4: Presentation Layer Strategy (P0)
**Goal**: +5,150 lines (70% target) | **Effort**: High - 5-7 days

**Challenge**: SwiftUI views (7,368 lines) are difficult to unit test

### 4.1 Realistic Approach: 70% Coverage Target

**What CAN be unit tested** (~5,150 lines):
1. **ViewModels and State** (if extracted)
2. **Business logic in views** (extract to testable functions)
3. **Input formatters and validators**
4. **Accessibility configuration**
5. **Design token application**

**What requires UI testing** (~2,218 lines):
1. Pure SwiftUI layout code
2. Gesture recognizers
3. Animation code
4. Visual appearance

### 4.2 Testing Strategy

**Strategy A: Extract ViewModels** (Recommended)
- Create ViewModels for complex views
- Move business logic out of View structs
- Test ViewModels with traditional unit tests

Example:
```swift
// Before (hard to test):
struct CardNumberField: View {
    @State private var cardNumber: String = ""

    var body: some View {
        TextField("Card Number", text: $cardNumber)
            .onChange(of: cardNumber) { newValue in
                // Complex formatting logic here
                let formatted = formatCardNumber(newValue)
                cardNumber = formatted
            }
    }
}

// After (testable):
@Observable
class CardNumberFieldViewModel {
    var cardNumber: String = ""

    func formatCardNumber(_ input: String) -> String {
        // Testable logic
    }
}

struct CardNumberField: View {
    @State private var viewModel = CardNumberFieldViewModel()
    // ...
}
```

**Strategy B: Snapshot Testing**
- Use Swift Snapshot Testing for visual regression
- Captures layout without full unit test coverage
- Complements unit test coverage

**Strategy C: ViewInspector**
- Third-party library for SwiftUI view testing
- Allows assertions on view hierarchy
- Limited but better than nothing

### 4.3 Presentation Layer Test Plan

**High-value targets** (extract and test):
```
Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/
├── Components/Inputs/                    Priority: HIGH
│   ├── CardNumberInputField/             (Extract ViewModel)
│   ├── CVVInputField/                    (Extract ViewModel)
│   ├── ExpiryDateInputField/             (Extract ViewModel)
│   └── CountryInputField/                (Extract ViewModel)
├── Components/Composite/                 Priority: MEDIUM
│   ├── BillingAddressView.swift          (Extract ViewModel)
│   └── CardFormView.swift                (Extract ViewModel)
└── Scope/                                Priority: HIGH
    ├── DefaultCardFormScope.swift        (Already tested - enhance)
    └── DefaultCheckoutScope.swift        (Already tested - enhance)
```

**New test files**:
```
Tests/Primer/CheckoutComponents/Presentation/
├── ViewModels/
│   ├── CardNumberInputViewModelTests.swift        (NEW)
│   ├── CVVInputViewModelTests.swift               (NEW)
│   ├── ExpiryDateInputViewModelTests.swift        (NEW)
│   └── BillingAddressViewModelTests.swift         (NEW)
├── Formatters/
│   ├── CardNumberFormatterTests.swift             (NEW)
│   ├── ExpiryDateFormatterTests.swift             (NEW)
│   └── PhoneNumberFormatterTests.swift            (NEW)
└── Accessibility/
    ├── ViewAccessibilityTests.swift               (Enhance existing)
    └── AccessibilityAnnouncementTests.swift       (Enhance existing)
```

**Code changes required**:
- Extract ViewModels from complex SwiftUI views
- Move formatting logic to testable utility classes
- Separate business logic from presentation

---

## Execution Strategy

### Recommended Order

1. **Phase 1 (Quick Wins)**: Complete Navigation, Validation, Core, DI → **+650 lines** (1-2 days)
2. **Phase 3.1 (Data Layer)**: Critical for app functionality → **+958 lines** (2-3 days)
3. **Phase 3.2 (Payment Layer)**: Critical for app functionality → **+899 lines** (2-3 days)
4. **Phase 2.1 (Scope)**: Important for customization → **+1,068 lines** (1-2 days)
5. **Phase 4 (Presentation - Refactor)**: Extract ViewModels → **+5,150 lines** (5-7 days)
6. **Phase 2.2 (Other)**: Mop-up analytics, utilities → **+2,296 lines** (2-3 days)

**Total estimated effort**: 13-20 days

### Alternative: Pragmatic 80% Target

If 90% proves too costly, consider **80% target** instead:
- Skip Phase 4 (Presentation refactoring)
- Focus on Phases 1-3 only
- Achievable in **7-11 days**
- Coverage: ~78-80% (14,424 lines / 18,031)

### Tracking Progress

Run coverage after each phase:
```bash
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

xcrun xccov view --report TestResults.xcresult | \
  grep "Sources/PrimerSDK/Classes/CheckoutComponents" | \
  python3 /path/to/coverage_analyzer.py
```

---

## Risk Assessment

### High Risk Areas

1. **Presentation Layer Refactoring**
   - Risk: Breaking existing SwiftUI views
   - Mitigation: Incremental refactoring with manual testing
   - Consider: Skip if 80% target acceptable

2. **Data Layer Mocking**
   - Risk: Fragile mocks that break with API changes
   - Mitigation: Use protocol-based mocking, record/replay pattern

3. **Payment Flow Testing**
   - Risk: Complex 3DS flows hard to simulate
   - Mitigation: Study existing Primer3DS tests, use mock responses

### Success Criteria

- ✅ Each phase independently testable
- ✅ No breaking changes to existing functionality
- ✅ All new tests pass consistently
- ✅ Test execution time remains under 2 minutes
- ✅ Coverage verifiable via xcresult

---

## Next Steps

1. **Validate Plan**: Review with team
2. **Choose Target**: 90% (full) vs 80% (pragmatic)
3. **Start Phase 1**: Quick wins to build momentum
4. **Create Branch**: `003-checkout-components-coverage-improvement`
5. **Track Progress**: Update this document with actual vs. estimated

---

## Appendix: Coverage Formula

```
Target Coverage = (Lines Covered / Total Lines) × 100

Current: 18.96% = 3,419 / 18,031
Target:  90.00% = 16,228 / 18,031

Gap: 16,228 - 3,419 = 12,809 lines needed
```

**Note**: These are executable lines, not total source lines. Comments, blank lines, and non-executable declarations are excluded.
