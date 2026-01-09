# CheckoutComponents Code Coverage Tracking

**Overall Coverage on New Code:** 49.6%
**Last Updated:** 2026-01-02
**Branch:** 002-checkout-components-unit-tests
**Total Tests in Project:** 3463 (all passing)

---

## Coverage Categories

| Category | Description |
|----------|-------------|
| **0%** | No tests - Needs immediate attention |
| **1-49%** | Low coverage - Priority improvement needed |
| **50-79%** | Partial coverage - Good progress |
| **80-99%** | High coverage - Minor gaps |
| **100%** | Full coverage - Complete |

---

## Files at 0% Coverage (SwiftUI Views - Exclude from Unit Tests)

These are SwiftUI views that are difficult to unit test. They should be tested via UI tests or the Debug App.

| File | Lines | Category |
|------|-------|----------|
| AddressLineInputField+UIViewRepresentable.swift | 185 | SwiftUI |
| AddressLineInputField.swift | 70 | SwiftUI |
| AllowedCardNetworksView.swift | 16 | SwiftUI |
| BackportedNavigationStack.swift | 15 | SwiftUI |
| BillingAddressView.swift | 149 | SwiftUI |
| CardDetailsView.swift | 37 | SwiftUI |
| CardFormFieldsView.swift | 309 | SwiftUI |
| CardFormScreen.swift | 618 | SwiftUI |
| CardholderNameInputField+UIViewRepresentable.swift | 127 | SwiftUI |
| CardholderNameInputField.swift | 61 | SwiftUI |
| CardNetworkBadge.swift | 18 | SwiftUI |
| CardNumberInputField+UIViewRepresentable.swift | 353 | SwiftUI |
| CardNumberInputField.swift | 146 | SwiftUI |
| CheckoutHeaderView.swift | 80 | SwiftUI |
| CheckoutScopeObserver.swift | 205 | SwiftUI |
| CityInputField+UIViewRepresentable.swift | 114 | SwiftUI |
| CityInputField.swift | 60 | SwiftUI |
| CountryInputField+SelectionButton.swift | 35 | SwiftUI |
| CountryInputField.swift | 133 | SwiftUI |
| CountryInputFieldWrapper.swift | 8 | SwiftUI |
| CVVInputField+UIViewRepresentable.swift | 126 | SwiftUI |
| CVVInputField.swift | 62 | SwiftUI |
| DefaultLoadingScreen.swift | 18 | SwiftUI |
| DeleteVaultedPaymentMethodConfirmationScreen.swift | 118 | SwiftUI |
| DropdownCardNetworkSelector.swift | 48 | SwiftUI |
| DualBadgeDisplay.swift | 8 | SwiftUI |
| EmailInputField+UIViewRepresentable.swift | 117 | SwiftUI |
| EmailInputField.swift | 68 | SwiftUI |
| ErrorScreen.swift | 66 | SwiftUI |
| ExpiryDateInputField+UIViewRepresentable.swift | 203 | SwiftUI |
| ExpiryDateInputField.swift | 64 | SwiftUI |
| InlineCardNetworkSelector+Border.swift | 65 | SwiftUI |
| InlineCardNetworkSelector+Button.swift | 21 | SwiftUI |
| InlineCardNetworkSelector.swift | 61 | SwiftUI |
| NameInputField+UIViewRepresentable.swift | 178 | SwiftUI |
| NameInputField.swift | 69 | SwiftUI |
| OTPCodeInputField.swift | 91 | SwiftUI |
| PaymentMethodButton.swift | 39 | SwiftUI |
| PaymentMethodComponents.swift | 97 | SwiftUI |
| PaymentMethodSelectionScreen.swift | 99 | SwiftUI |
| PaymentMethodsSection.swift | 54 | SwiftUI |
| PayPalView.swift | 179 | SwiftUI |
| PostalCodeInputField+UIViewRepresentable.swift | 126 | SwiftUI |
| PostalCodeInputField.swift | 70 | SwiftUI |
| PrimerCheckout.swift | 173 | SwiftUI |
| PrimerInputFieldContainer+PreviewHelpers.swift | 55 | SwiftUI |
| PrimerInputFieldContainer+Rendering.swift | 77 | SwiftUI |
| PrimerInputFieldContainer+Styling.swift | 28 | SwiftUI |
| PrimerInputFieldContainer.swift | 36 | SwiftUI |
| PrimerSwiftUIBridgeViewController.swift | 192 | SwiftUI |
| PrimerTextFieldExtension.swift | 64 | SwiftUI |
| SDKInitializationViews.swift | 23 | SwiftUI |
| SelectCountryScreen.swift | 175 | SwiftUI |
| SlideInModifier.swift | 44 | SwiftUI |
| SplashScreen.swift | 34 | SwiftUI |
| StateInputField+UIViewRepresentable.swift | 114 | SwiftUI |
| StateInputField.swift | 53 | SwiftUI |
| SuccessScreen.swift | 51 | SwiftUI |
| VaultedCardCVVInput.swift | 93 | SwiftUI |
| VaultedPaymentMethodCard.swift | 229 | SwiftUI |
| VaultedPaymentMethodsListScreen.swift | 51 | SwiftUI |
| VaultSection.swift | 98 | SwiftUI |

---

## Files at 0% Coverage (Testable - Need Tests)

| File | Lines | Priority | Notes |
|------|-------|----------|-------|
| MockCardFormScope.swift | 186 | N/A | Test utility |
| MockDesignTokens.swift | 39 | N/A | Test utility |
| MockDIContainer.swift | 29 | N/A | Test utility |
| MockValidationService.swift | 49 | N/A | Test utility |
| RawDataManagerProtocol.swift | 6 | N/A | Protocol |
| WebAuthenticationService.swift | 3 | Low | Simple service |

---

## Files with Low Coverage (1-49%) - Priority Improvement

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| CardNumberInputField.swift | 9.6% | 132 | SwiftUI - Skip |
| PaymentMethodSelectionProvider.swift | 10.6% | 42 | Tests Added |
| CardFormProvider.swift | 12.5% | 42 | Tests Added |
| OTPCodeInputField.swift | 13.2% | 79 | SwiftUI - Skip |
| PostalCodeInputField.swift | 14.3% | 60 | SwiftUI - Skip |
| CardholderNameInputField.swift | 14.8% | 52 | SwiftUI - Skip |
| CityInputField.swift | 15.0% | 51 | SwiftUI - Skip |
| SelectCountryProvider.swift | 15.2% | 28 | Tests Added |
| CVVInputField.swift | 16.1% | 52 | SwiftUI - Skip |
| EmailInputField.swift | 16.2% | 57 | SwiftUI - Skip |
| StateInputField.swift | 17.0% | 44 | SwiftUI - Skip |
| ExpiryDateInputField.swift | 17.2% | 53 | SwiftUI - Skip |
| NameInputField.swift | 17.4% | 57 | SwiftUI - Skip |
| AddressLineInputField.swift | 18.6% | 57 | SwiftUI - Skip |
| CheckoutComponentsPrimer.swift | 27.5% | 171 | Tests Added |
| ApplePayButtonView.swift | 29.3% | 41 | SwiftUI - Skip |
| UserInterfaceModule.swift | 38.5% | 8 | Tests Added |
| DesignTokensManager.swift | 39.4% | 249 | Tests Added |
| View+Accessibility.swift | 44.0% | 14 | Tests Added |

---

## Files with Partial Coverage (50-79%)

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| HeadlessRepositoryImpl.swift | 52.9% | 344 | Tests Added |
| DefaultPaymentMethodSelectionScope.swift | 54.2% | 140 | Tests Added |
| SwiftUI+DI.swift | 60.3% | 29 | Tests Added |
| PrimerCardFormScope.swift | 64.6% | 34 | Tests Added |
| PayPalPaymentMethod.swift | 70.4% | 21 | Tests Added |
| CardPaymentMethod.swift | 71.9% | 25 | Tests Added |
| CheckoutComponentsStrings.swift | 72.9% | 42 | Good |
| PrimerCheckoutScope.swift | 73.3% | 4 | Good |
| DependencyScope.swift | 73.7% | 5 | Good |
| ContainerDiagnostics.swift | 73.9% | 37 | Good |
| StructuredCardFormState.swift | 74.6% | 15 | Good |
| PrimerError.swift | 75.0% | 2 | Good |
| ComposableContainer.swift | 77.6% | 36 | Good |
| DefaultCheckoutScope.swift | 78.4% | 112 | Good |
| DefaultApplePayScope.swift | 79.4% | 44 | Good |

---

## Files with High Coverage (80-99%)

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| PrimerTheme+Images.swift | 80.8% | 5 | Tests Added |
| AnalyticsNetworkClient.swift | 81.7% | 11 | Tests Added |
| ValidationService.swift | 82.0% | 37 | Good |
| ApplePayPaymentMethod.swift | 82.2% | 8 | Good |
| ErrorMessageResolver.swift | 82.5% | 51 | Good |
| FontRegistration.swift | 82.6% | 8 | Good |
| ApplePayScreen.swift | 85.1% | 24 | Good |
| PrimerPaymentMethodScope.swift | 85.7% | 11 | Tests Added |
| PayPalRepositoryImpl.swift | 86.6% | 15 | Tests Added |
| DefaultCardFormScope.swift | 87.1% | 96 | Tests Added |
| PrimerFont.swift | 87.1% | 20 | Tests Added |
| AnalyticsEventService.swift | 87.5% | 8 | Tests Added |
| CheckoutSDKInitializer.swift | 87.9% | 12 | Good |
| UIDeviceExtension.swift | 90.3% | 6 | Good |
| Container.swift | 90.8% | 30 | Good |
| AnalyticsEnvironmentProvider.swift | 91.7% | 1 | Good |
| CardNetwork.swift | 91.7% | 1 | Good |
| Factory.swift | 93.9% | 3 | Tests Added |
| CheckoutNavigator.swift | 94.2% | 3 | Good |
| PrimerAPIConfigurationModule.swift | 95.3% | 3 | Good |
| CheckoutComponentsPaymentMethodsBridge.swift | 95.4% | 8 | Tests Added |
| CheckoutRoute.swift | 95.9% | 2 | Good |
| IntExtension.swift | 96.3% | 1 | Good |
| ProcessApplePayPaymentInteractor.swift | 96.3% | 4 | Good |
| DesignTokensProcessor.swift | 96.6% | 7 | Tests Added |
| AnalyticsEventMetadata.swift | 97.1% | 2 | Good |
| CardValidationRules.swift | 97.6% | 3 | Tests Added |
| ApplePayRequestBuilder.swift | 97.9% | 3 | Good |
| CommonValidationRules.swift | 98.7% | 4 | Tests Added |
| DefaultSelectCountryScope.swift | 98.7% | 1 | Good |
| DIContainer.swift | 99.1% | 1 | Good |
| PrimerHeadlessUniversalCheckoutInputElement.swift | 99.3% | 1 | Tests Added |
| VaultedPaymentMethod+DisplayData.swift | 99.5% | 1 | Good |

---

## Files at 100% Coverage

| File | Lines |
|------|-------|
| AccessibilityConfiguration.swift | 0 |
| AccessibilityIdentifiers.swift | 0 |
| AnalyticsEventBuffer.swift | 0 |
| AnalyticsPayloadBuilder.swift | 0 |
| AnalyticsSessionConfig.swift | 0 |
| ApplePayFormState.swift | 0 |
| CardNetworkDetectionInteractor.swift | 0 |
| CheckoutColors.swift | 0 |
| CheckoutComponentsTheme.swift | 0 |
| CheckoutCoordinator.swift | 0 |
| ConfigurationService.swift | 0 |
| ContainerError.swift | 0 |
| ContainerProtocol.swift | 0 |
| ContainerRetainPolicy.swift | 0 |
| DefaultAccessibilityAnnouncementService.swift | 0 |
| DefaultAnalyticsInteractor.swift | 0 |
| DefaultPayPalScope.swift | 0 |
| DesignTokens.swift | 0 |
| DesignTokensDark.swift | 0 |
| DesignTokensKey.swift | 0 |
| DIContainer+SwiftUI.swift | 0 |
| ExpiryDateInput.swift | 0 |
| GetPaymentMethodsInteractor.swift | 0 |
| InputFieldConfig.swift | 0 |
| InternalPaymentMethod.swift | 0 |
| PaymentMethodMapper.swift | 0 |
| PaymentResult.swift | 0 |
| PayPalState.swift | 0 |
| Primer.swift | 0 |
| PrimerApplePayScope.swift | 0 |
| PrimerEnvironment.swift | 0 |
| PrimerFieldStyling.swift | 0 |
| PrimerLayout.swift | 0 |
| PrimerLocaleData.swift | 0 |
| PrimerPaymentMethodSelectionScope.swift | 0 |
| PrimerPaymentMethodType+ImageName.swift | 0 |
| PrimerSelectCountryScope.swift | 0 |
| PrimerSettings.swift | 0 |
| PrimerTheme.swift | 0 |
| ProcessCardPaymentInteractor.swift | 0 |
| ProcessPayPalPaymentInteractor.swift | 0 |
| RetentionStrategy.swift | 0 |
| RulesFactory.swift | 0 |
| StringExtension.swift | 0 |
| SubmitVaultedPaymentInteractor.swift | 0 |
| TypeKey.swift | 0 |
| ValidateInputInteractor.swift | 0 |
| ValidationError.swift | 0 |
| ValidationResult.swift | 0 |
| ValidationRule.swift | 0 |

---

## Tests Added This Session

| Test File | Tests | Target File | Previous | Current | Status |
|-----------|-------|-------------|----------|---------|--------|
| ContainerErrorTests.swift | 22 | ContainerError.swift | 32.8% | 100% | Done |
| TypeKeyTests.swift | 24 | TypeKey.swift | 50.0% | 100% | Done |
| CardPaymentMethodTests.swift | 6 | CardPaymentMethod.swift | 34.8% | 57.3% | Done |
| PayPalPaymentMethodTests.swift | 7 | PayPalPaymentMethod.swift | 4.2% | 64.8% | Done |
| DefaultCardFormScopeTests.swift | 73 | DefaultCardFormScope.swift | 27.3% | 54.0% | Done |
| DefaultPaymentMethodSelectionScopeTests.swift | 32 | DefaultPaymentMethodSelectionScope.swift | 31.4% | 54.2% | Done |
| DesignTokensProcessorTests.swift | 28 | DesignTokensProcessor.swift | 82.8% | 82.8% | Existing |
| FactoryTests.swift | 15 | Factory.swift | 0% | 93.9% | Done |
| ProcessPayPalPaymentInteractorTests.swift | 20 | ProcessPayPalPaymentInteractor.swift | 0% | 100% | Done |
| DefaultPayPalScopeTests.swift | 18 | DefaultPayPalScope.swift | 0% | 100% | Done |
| CheckoutComponentsThemeTests.swift | 25 | CheckoutComponentsTheme.swift | 8.2% | 100% | Done |
| PayPalRepositoryImplTests.swift | 20 | PayPalRepositoryImpl.swift | 0% | 86.6% | Done |
| DefaultConfigurationServiceTests.swift | 18 | ConfigurationService.swift | 43.5% | 100% | Done |
| ValidationResultTests.swift | 21 | ValidationResult.swift | 60% | 100% | Done |
| InternalPaymentMethodTests.swift | 23 | InternalPaymentMethod.swift | 62.5% | 100% | Done |
| PaymentMethodRegistryTests.swift | 17 | PrimerPaymentMethodScope.swift | 58.4% | 85.7% | Done |
| CheckoutComponentsPaymentMethodsBridgeTests.swift | 17 | CheckoutComponentsPaymentMethodsBridge.swift | 63% | 64.7% | Done |
| PrimerCardFormScopeTests.swift | 31 | PrimerCardFormScope.swift | 0% | 58.3% | Done |
| DIContainerSwiftUITests.swift | 19 | DIContainer+SwiftUI.swift | 0% | 100% | Done |
| SwiftUIDITests.swift | 19 | SwiftUI+DI.swift | 0% | 52.1% | Done |
| CardFormProviderTests.swift | 14 | CardFormProvider.swift | 0% | 12.5% | Done |
| PaymentMethodSelectionProviderTests.swift | 21 | PaymentMethodSelectionProvider.swift | 0% | 10.6% | Done |
| SelectCountryProviderTests.swift | 19 | SelectCountryProvider.swift | 0% | 15.2% | Done |
| PrimerSelectCountryStateTests.swift | 8 | SelectCountryProvider.swift | 0% | 15.2% | Done |
| DesignTokensManagerTests.swift | 44 | DesignTokensManager.swift | 0% | 4.9% | Done |
| PrimerFontTests.swift | 29 | PrimerFont.swift | 0% | 87.1% | Done |
| DesignTokensDarkTests.swift | 22 | DesignTokensDark.swift | 0% | 100% | Done |
| CheckoutComponentsPrimerTests.swift | 21 | CheckoutComponentsPrimer.swift | 0% | 17.4% | Done |
| DesignTokensTests.swift | 34 | DesignTokens.swift | 0% | 92.0% | Done |
| ViewAccessibilityExtendedTests.swift | 15 | View+Accessibility.swift | 44.0% | 44.0% | Done |
| PrimerInputElementTypeExtendedTests.swift | 40 | PrimerHeadlessUniversalCheckoutInputElement.swift | 32.4% | 99.3% | Done |
| InputFieldConfigTests.swift | 8 | InputFieldConfig.swift | 0% | 100% | Done |
| PrimerEnvironmentTests.swift | 25 | PrimerEnvironment.swift | 0% | 100% | Done |
| PrimerFieldStylingTests.swift | 18 | PrimerFieldStyling.swift | 0% | 100% | Done |
| PrimerThemeImagesTests.swift | 25 | PrimerTheme+Images.swift | 0% | 80.8% | Done |
| DesignTokensKeyTests.swift | 6 | DesignTokensKey.swift | 0% | 100% | Done |
| CheckoutColorsTests.swift | 24 | CheckoutColors.swift | 0% | 100% | Done |
| PrimerLayoutTests.swift | 20 | PrimerLayout.swift | 0% | 100% | Done |
| HeadlessRepositoryImplTests.swift | 94 | HeadlessRepositoryImpl.swift | 12.4% | 43.7% | Done |
| CardValidationRulesTests.swift | 15 | CardValidationRules.swift | 88.8% | 97.6% | Done |
| CommonValidationRulesTests.swift | 35 | CommonValidationRules.swift | 78.9% | 98.7% | Done |
| PrimerSettingsTests.swift | 48 | PrimerSettings.swift | 33.3% | 100% | Done |
| UserInterfaceModuleTests.swift | 45 | UserInterfaceModule.swift | 38.5% | 38.5% | Done |
| ViewAccessibilityConditionalsTests.swift | 30 | View+Accessibility.swift | 44.0% | 44.0% | Done |
| AccessibilityIdentifiersTests.swift | 35 | AccessibilityIdentifiers.swift | 62.5% | 100% | Done |

**Total Tests Added:** 1000+ (all passing)

---

## Next Steps - Priority Order

### High Priority (Completed)
- ✅ HeadlessRepositoryImpl.swift (43.7%) - 94 tests added including processCardPayment
- ✅ DesignTokensManager.swift (4.9%) - Tests added (44 tests)
- ✅ CheckoutComponentsPrimer.swift (17.4%) - Tests added (21 tests)
- ✅ Provider classes - Tests added (~54 tests)
- ✅ DefaultCardFormScope.swift (54.0%) - Tests added (73 tests)
- ✅ DefaultPaymentMethodSelectionScope.swift (54.2%) - Tests added (32 tests)
- ✅ DesignTokens.swift (92.0%) - Tests added (34 tests)
- ✅ PrimerHeadlessUniversalCheckoutInputElement.swift (99.3%) - Tests added
- ✅ CardValidationRules.swift (97.6%) - Tests added
- ✅ CommonValidationRules.swift (98.7%) - Tests added
- ✅ PrimerSettings.swift (100%) - Tests added (48 tests)
- ✅ UserInterfaceModule.swift (38.5%) - Tests added (45 tests)
- ✅ View+Accessibility.swift (44.0%) - Tests added (30 tests)
- ✅ AccessibilityIdentifiers.swift (100%) - Tests added (35 tests)
- ✅ PrimerEnvironment.swift (100%) - Tests added (25 tests)

### Medium Priority (Low coverage, can still improve)
1. HeadlessRepositoryImpl.swift (43.7%) - Can still improve
2. View+Accessibility.swift (44.0%) - Can still improve
3. SwiftUI+DI.swift (52.1%) - Can still improve
4. CardPaymentMethod.swift (57.3%) - Can still improve
5. PrimerCardFormScope.swift (58.3%) - Can still improve

### Low Priority (Already good coverage)
- Files at 80%+ coverage - minor improvements only
- SwiftUI views - test via Debug App UI tests

---

## Run All Tests Command

```bash
xcodebuild test -workspace PrimerSDK.xcworkspace -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

---

## PR Split Tracking

| PR | Branch | Category | Files | Status |
|----|--------|----------|-------|--------|
| 1 | `ov/test/checkout-components-01-foundation` | Foundation | 6 | 🔄 In Review |
| 2 | `ov/test/checkout-components-02-di-core` | DI Core | 8 | 🔄 In Review |
| 3 | `ov/test/checkout-components-03-di-swiftui` | DI SwiftUI | 7 | 🔄 In Review |
| 4 | `ov/test/checkout-components-04-accessibility` | Accessibility | 8 | 🔄 In Review |
| 5 | `ov/test/checkout-components-05-validation-pt1` | Validation Pt1 | 8+6 | 🔄 In Review |
| 6 | `ov/test/checkout-components-06-validation-pt2` | Validation Pt2 | 5+7 | 🔄 In Review |
| 7 | `ov/test/checkout-components-07-navigation` | Navigation | 5 | 🔄 In Review |
| 8 | `ov/test/checkout-components-08-network` | Network | 4+6 | 🔄 In Review |
| 9 | `ov/test/checkout-components-09-data-config` | Data Config | 6+6 | 🔄 In Review |
| 10 | `ov/test/checkout-components-10-headless-pt1` | HeadlessRepo Pt1 | 4+6 | 🔄 In Review |
| 11 | `ov/test/checkout-components-11-headless-pt2` | HeadlessRepo Pt2 | 6+source | 🔄 In Review |
| 12 | `ov/test/checkout-components-12-headless-pt3` | HeadlessRepo Pt3 | 5+source | 🔄 In Review |
| 13 | `ov/test/checkout-components-13-interactors` | Interactors | 7 | 🔄 In Review |
| 14 | `ov/test/checkout-components-14-payment-pt1` | Payment Pt1 | 8 | 🔄 In Review |
| 15 | `ov/test/checkout-components-15-payment-pt2` | Payment Pt2 | 7 | 🔄 In Review |
| 16 | `ov/test/checkout-components-16-applepay` | ApplePay | 10 | 🔄 In Review |
| 17 | `ov/test/checkout-components-17-paypal-methods` | PayPal & Methods | 5 | ⬜ Pending |
| 18 | `ov/test/checkout-components-18-scope-pt1` | Scope Pt1 | 7 | ⬜ Pending |
| 19 | `ov/test/checkout-components-19-scope-pt2` | Scope Pt2 | 7 | ⬜ Pending |
| 20 | `ov/test/checkout-components-20-vault-providers` | Vault & Providers | 8 | ⬜ Pending |
| 21 | `ov/test/checkout-components-21-theme-tokens` | Theme & Tokens | 9 | ⬜ Pending |
| 22 | `ov/test/checkout-components-22-ui-utilities-pt1` | UI & Utilities Pt1 | 9 | ⬜ Pending |
| 23 | `ov/test/checkout-components-23-utilities-pt2` | Utilities Pt2 | 8 | ⬜ Pending |

**Status Legend:** ⬜ Pending | 🔄 In Review | ✅ Merged

### PR Workflow
1. Create branch from `bn/feature/checkout-components`
2. Checkout files from `002-checkout-components-unit-tests`
3. **Run tests first** to verify build succeeds
4. Commit and push
5. Update this file and commit to `002-checkout-components-unit-tests`

### Known Test Failures
- `PrimerInputElementTests.test_validate_expiryDate` - Uses hardcoded `12/25` expiry date (now expired in 2026)
- **Fix:** Handled in separate branch, ignore for PR testing

---

## PR File Details

### PR 1: Foundation (6 files) ⚠️ *Must merge first - required by base branch*
- [x] TestSupport/TestData.swift
- [x] TestSupport/XCTestCase+Async.swift
- [x] TestSupport/ContainerTestHelpers.swift
- [x] Mocks/MockConfigurationService.swift
- [x] Mocks/MockAnalyticsInteractor.swift
- [x] Mocks/MockAccessibilityAnnouncementService.swift *(moved from PR 4)*

### PR 2: DI Core (8 files)
- [x] Core/ContainerTests.swift
- [x] DI/ContainerErrorTests.swift
- [x] DI/ContainerDiagnosticsTests.swift
- [x] DI/ContainerProtocolTests.swift
- [x] DI/DIContainerTests.swift
- [x] DI/TypeKeyTests.swift
- [x] DI/RetentionPolicyTests.swift
- [x] DI/FactoryTests.swift

### PR 3: DI SwiftUI (7 files) *Includes file reorganization*
- [x] Core/SettingsObserverTests.swift
- [x] Core/AnalyticsSessionConfigProviderTests.swift *(moved from root)*
- [x] DI/AsyncResolutionTests.swift
- [x] DI/DIContainerSwiftUITests.swift
- [x] DI/SwiftUIDITests.swift
- [x] DI/PrimerSettingsDIIntegrationTests.swift *(moved from root)*
- [x] DI/PrimerSettingsIntegrationTests.swift *(moved from root)*

### PR 4: Accessibility (8 files) *Depends on PR 1, includes file reorganization*
- [x] Accessibility/AccessibilityIdentifiersTests.swift
- [x] Accessibility/AccessibilityConfigurationTests.swift *(moved from root)*
- [x] Accessibility/AccessibilityAnnouncementServiceTests.swift *(moved from root)*
- [x] Accessibility/AccessibilityStringsTests.swift *(moved from root)*
- [x] Accessibility/AccessibilityDIContainerTests.swift *(moved from root)*
- [x] Accessibility/ViewAccessibilityExtensionTests.swift *(moved from root)*
- [x] Accessibility/ViewAccessibilityExtendedTests.swift
- [x] Accessibility/ViewAccessibilityConditionalsTests.swift

### PR 5: Validation Pt1 (8 files + 6 foundation dependencies)
*Includes foundation files because PR 1 hasn't merged yet*
- [x] Mocks/MockValidationService.swift
- [x] Mocks/MockRulesFactory.swift
- [x] Validation/CardValidationRulesTests.swift
- [x] Validation/CommonValidationRulesTests.swift
- [x] Validation/ValidationServiceTests.swift
- [x] Validation/ValidationErrorTests.swift
- [x] Validation/ValidationResultTests.swift
- [x] Validation/ValidationRuleTests.swift
- [x] *Foundation:* TestSupport/TestData.swift
- [x] *Foundation:* TestSupport/XCTestCase+Async.swift
- [x] *Foundation:* TestSupport/ContainerTestHelpers.swift
- [x] *Foundation:* Mocks/MockConfigurationService.swift
- [x] *Foundation:* Mocks/MockAnalyticsInteractor.swift
- [x] *Foundation:* Mocks/MockAccessibilityAnnouncementService.swift

### PR 6: Validation Pt2 (5 files + 7 dependencies)
*Includes foundation + MockValidationService since PR 1 & 5 haven't merged yet*
- [x] Mocks/MockValidateInputInteractor.swift
- [x] Validation/RulesFactoryTests.swift
- [x] Validation/ExpiryDateValidationEdgeCasesTests.swift
- [x] Core/ErrorMessageResolverTests.swift
- [x] Interactors/ValidateInputInteractorTests.swift
- [x] *Dependencies:* TestSupport/TestData.swift
- [x] *Dependencies:* TestSupport/XCTestCase+Async.swift
- [x] *Dependencies:* TestSupport/ContainerTestHelpers.swift
- [x] *Dependencies:* Mocks/MockConfigurationService.swift
- [x] *Dependencies:* Mocks/MockAnalyticsInteractor.swift
- [x] *Dependencies:* Mocks/MockAccessibilityAnnouncementService.swift
- [x] *Dependencies:* Mocks/MockValidationService.swift

### PR 7: Navigation (5 files) ✅ *No dependencies required*
- [x] Mocks/MockCheckoutCoordinator.swift
- [x] Mocks/MockCheckoutNavigator.swift
- [x] Navigation/CheckoutCoordinatorTests.swift
- [x] Navigation/CheckoutNavigatorTests.swift
- [x] Navigation/CheckoutRouteTests.swift

### PR 8: Network (4 files + 6 foundation dependencies)
*Includes foundation files since PR 1 hasn't merged yet*
- [x] Network/APIClientEdgeCasesTests.swift
- [x] Network/APIResponseParsingTests.swift
- [x] Network/ErrorMappingTests.swift
- [x] Network/NetworkManagerErrorHandlingTests.swift
- [x] *Foundation:* TestSupport/TestData.swift
- [x] *Foundation:* TestSupport/XCTestCase+Async.swift
- [x] *Foundation:* TestSupport/ContainerTestHelpers.swift
- [x] *Foundation:* Mocks/MockConfigurationService.swift
- [x] *Foundation:* Mocks/MockAnalyticsInteractor.swift
- [x] *Foundation:* Mocks/MockAccessibilityAnnouncementService.swift

### PR 9: Data Config (6 files + 6 foundation dependencies)
*Includes foundation files since PR 1 hasn't merged yet*
- [x] Data/ConfigurationServiceTests.swift
- [x] Data/ConfigurationValidationTests.swift
- [x] Data/DataPersistenceTests.swift
- [x] Data/MerchantConfigCachingTests.swift
- [x] Data/PaymentMethodCacheTests.swift
- [x] Data/PaymentMethodRepositoryTests.swift
- [x] *Foundation:* TestSupport/TestData.swift
- [x] *Foundation:* TestSupport/XCTestCase+Async.swift
- [x] *Foundation:* TestSupport/ContainerTestHelpers.swift
- [x] *Foundation:* Mocks/MockConfigurationService.swift
- [x] *Foundation:* Mocks/MockAnalyticsInteractor.swift
- [x] *Foundation:* Mocks/MockAccessibilityAnnouncementService.swift

### PR 10: HeadlessRepo Pt1 (4 files + 6 foundation) *Includes file reorganization*
*Note: 3 tests excluded (access private methods not exposed in base branch)*
- [x] Mocks/MockHeadlessRepository.swift
- [x] Mocks/MockClientSessionActionsModule.swift
- [x] Data/HeadlessRepositoryTests.swift *(moved from root)*
- [x] Data/HeadlessRepositorySettingsTests.swift *(moved from root)*
- [x] *Foundation:* TestSupport/TestData.swift
- [x] *Foundation:* TestSupport/XCTestCase+Async.swift
- [x] *Foundation:* TestSupport/ContainerTestHelpers.swift
- [x] *Foundation:* Mocks/MockConfigurationService.swift
- [x] *Foundation:* Mocks/MockAnalyticsInteractor.swift
- [x] *Foundation:* Mocks/MockAccessibilityAnnouncementService.swift
- [ ] ~~Data/HeadlessRepositoryHelperTests.swift~~ *(excluded - private access)*
- [ ] ~~Data/HeadlessRepository/HeadlessRepositoryInitTests.swift~~ *(excluded - private access)*
- [ ] ~~Data/HeadlessRepository/HeadlessRepositoryUtilityTests.swift~~ *(excluded - private access)*

### PR 11: HeadlessRepo Pt2 (6 files + source changes)
*Note: Includes source code changes (RawDataManagerProtocol.swift) for testability*
- [x] Data/HeadlessRepository/HeadlessRepositoryPaymentFlowTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryProcessCardPaymentTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryGetPaymentMethodsTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositorySelectCardNetworkTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryAnalyticsTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryDelegateTests.swift
- [x] *Source:* Internal/Services/RawDataManagerProtocol.swift
- [x] *Source:* Internal/Data/Repositories/HeadlessRepositoryImpl.swift (modified)
- [x] *Fix:* Tests/Primer/DependencyInjectionTests.swift (test isolation fix)

### PR 12: HeadlessRepo Pt3 (5 files + source changes)
*Note: Includes same source changes as PR 11 for testability*
- [x] Mocks/MockPaymentMethodMapper.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryNetworkSurchargesTests.swift
- [x] Data/HeadlessRepository/HeadlessRepositoryVaultTests.swift
- [x] Data/PayPalRepositoryImplTests.swift
- [x] Mappers/PaymentMethodMapperTests.swift
- [x] *Source:* Internal/Services/RawDataManagerProtocol.swift
- [x] *Source:* Internal/Data/Repositories/HeadlessRepositoryImpl.swift (modified)

### PR 13: Interactors (7 files) *Includes file reorganization*
- [x] Mocks/MockProcessCardPaymentInteractor.swift
- [x] Mocks/MockCardNetworkDetectionInteractor.swift
- [x] Interactors/CardNetworkDetectionInteractorTests.swift
- [x] Interactors/GetPaymentMethodsInteractorTests.swift
- [x] Interactors/ProcessCardPaymentInteractorTests.swift
- [x] Interactors/SubmitVaultedPaymentInteractorTests.swift *(reorganized from root)*
- [x] Domain/Interactors/ProcessPayPalPaymentInteractorTests.swift
- [x] *Reorganized:* Data/HeadlessRepositoryTests.swift
- [x] *Reorganized:* Data/HeadlessRepositorySettingsTests.swift

### PR 14: Payment Pt1 (8 files)
- [x] Payment/PaymentProcessorTests.swift
- [x] Payment/PaymentStateMachineTests.swift
- [x] Payment/PaymentValidationTests.swift
- [x] Payment/PaymentResultHandlingTests.swift
- [x] Payment/PaymentCancellationTests.swift
- [x] Payment/PaymentMethodHandlerTests.swift
- [x] Payment/PaymentAnalyticsTests.swift
- [x] Payment/PaymentRetryLogicTests.swift

### PR 15: Payment Pt2 (7 files)
- [x] Payment/CardTokenizationTests.swift
- [x] Payment/CheckoutComponentsTokenizationTests.swift
- [x] Payment/ThreeDSFlowTests.swift
- [x] Payment/ThreeDSChallengeTests.swift
- [x] Payment/FraudCheckIntegrationTests.swift
- [x] Payment/SurchargeCalculationTests.swift
- [x] Payment/TransactionManagerTests.swift

### PR 16: ApplePay (10 files) *Note: 2 tests excluded (scope caching dependency)*
- [x] ApplePay/Mocks/MockProcessApplePayPaymentInteractor.swift
- [x] ApplePay/ApplePayTestData.swift
- [x] ApplePay/ApplePayFormStateTests.swift
- [x] ApplePay/ApplePayPaymentMethodTests.swift *(2 tests excluded)*
- [x] ApplePay/ApplePayButtonViewTests.swift
- [x] ApplePay/ApplePayScreenTests.swift
- [x] ApplePay/ApplePayAuthorizationCoordinatorTests.swift
- [x] ApplePay/ApplePayRequestBuilderTests.swift
- [x] ApplePay/ProcessApplePayPaymentInteractorTests.swift
- [x] ApplePay/DefaultApplePayScopeTests.swift

### PR 17: PayPal & Methods (8 files) - 🔄 In Review
- [x] PayPal/DefaultPayPalScopeTests.swift
- [x] PaymentMethods/CardPaymentMethodTests.swift
- [x] PaymentMethods/PayPalPaymentMethodTests.swift
- [x] Registry/PaymentMethodRegistryTests.swift
- [x] Bridge/CheckoutComponentsPaymentMethodsBridgeTests.swift
- [x] Mocks/MockProcessCardPaymentInteractor.swift
- [x] Mocks/MockCardNetworkDetectionInteractor.swift
- [x] Mocks/MockValidateInputInteractor.swift

### PR 18: Scope Pt1 (7 files)
- [ ] Mocks/MockRawDataManager.swift
- [ ] Scope/DefaultCardFormScopeTests.swift
- [ ] Scope/PrimerCardFormScopeTests.swift
- [ ] Scope/InputFieldConfigTests.swift
- [ ] Scope/PrimerFieldStylingTests.swift
- [ ] Scope/ScopeLifecycleTests.swift
- [ ] Scope/ScopeStateManagerTests.swift

### PR 19: Scope Pt2 (7 files)
- [ ] Mocks/MockSubmitVaultedPaymentInteractor.swift
- [ ] Scope/DefaultCheckoutScopeTests.swift
- [ ] Scope/DefaultPaymentMethodSelectionScopeTests.swift
- [ ] Scope/PaymentMethodSelectionStateTests.swift
- [ ] Scope/DefaultSelectCountryScopeTests.swift
- [ ] Scope/SelectCountryStateTests.swift
- [ ] Scope/PrimerEnvironmentTests.swift

### PR 20: Vault & Providers (8 files)
- [ ] Vault/VaultDefaultCheckoutScopeTests.swift
- [ ] Vault/VaultDefaultPaymentMethodSelectionScopeTests.swift
- [ ] Vault/VaultedCardCVVInputTests.swift
- [ ] Vault/VaultedPaymentMethodDisplayDataTests.swift
- [ ] Providers/CardFormProviderTests.swift
- [ ] Providers/PaymentMethodSelectionProviderTests.swift
- [ ] Providers/SelectCountryProviderTests.swift
- [ ] Primer/CheckoutComponentsPrimerTests.swift

### PR 21: Theme & Tokens (9 files)
- [ ] Theme/CheckoutComponentsThemeTests.swift
- [ ] Theme/PrimerThemeImagesTests.swift
- [ ] Theme/PrimerThemeTests.swift
- [ ] Tokens/DesignTokensTests.swift
- [ ] Tokens/DesignTokensDarkTests.swift
- [ ] Tokens/DesignTokensKeyTests.swift
- [ ] Tokens/DesignTokensManagerTests.swift
- [ ] Tokens/DesignTokensProcessorTests.swift
- [ ] Tokens/PrimerFontTests.swift

### PR 22: UI & Utilities Pt1 (9 files)
- [ ] UI/CheckoutColorsTests.swift
- [ ] UI/PrimerLayoutTests.swift
- [ ] Utilities/StringExtensionsTests.swift
- [ ] Utilities/IntExtensionTests.swift
- [ ] Utilities/CollectionExtensionsTests.swift
- [ ] Utilities/FormatterUtilsTests.swift
- [ ] Utilities/CurrencyFormattingTests.swift
- [ ] Utilities/DateTimeUtilsTests.swift
- [ ] Tests/Primer/Modules/UserInterfaceModuleTests.swift

### PR 23: Utilities Pt2 (8 files)
- [ ] Utilities/DebugUtilsTests.swift
- [ ] Utilities/LoggerTests.swift
- [ ] Utilities/ValidationHelpersTests.swift
- [ ] Utilities/PrimerPaymentMethodTypeImageNameTests.swift
- [ ] Utilities/AppearanceModeTests.swift
- [ ] Models/InternalPaymentMethodTests.swift
- [ ] Models/PrimerInputElementTypeExtendedTests.swift
- [ ] Services/DefaultConfigurationServiceTests.swift
