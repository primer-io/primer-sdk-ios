# CheckoutComponents Code Coverage Tracking

**Overall Coverage on New Code:** 45.2%
**Last Updated:** 2026-01-01
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
| DesignTokensManager.swift | 4.9% | 391 | Tests Added |
| PaymentMethodSelectionProvider.swift | 10.6% | 42 | Tests Added |
| CardFormProvider.swift | 12.5% | 42 | Tests Added |
| SelectCountryProvider.swift | 15.2% | 28 | Tests Added |
| CheckoutComponentsPrimer.swift | 17.4% | 195 | Tests Added |
| ApplePayButtonView.swift | 29.3% | 41 | SwiftUI - Skip |
| UserInterfaceModule.swift | 38.5% | 8 | Tests Added |
| HeadlessRepositoryImpl.swift | 43.7% | 411 | Tests Added |
| View+Accessibility.swift | 44.0% | 14 | Tests Added |

---

## Files with Partial Coverage (50-79%)

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| SwiftUI+DI.swift | 52.1% | 35 | Tests Added |
| DefaultCardFormScope.swift | 54.0% | 342 | Tests Added |
| DefaultPaymentMethodSelectionScope.swift | 54.2% | 140 | Tests Added |
| CardPaymentMethod.swift | 57.3% | 38 | Tests Added |
| PrimerCardFormScope.swift | 58.3% | 40 | Tests Added |
| PrimerTheme.swift | 60.0% | 4 | Good |
| CheckoutComponentsPaymentMethodsBridge.swift | 64.7% | 61 | Tests Added |
| PayPalPaymentMethod.swift | 64.8% | 25 | Tests Added |
| ContainerProtocol.swift | 66.7% | 3 | Good |
| DIContainer.swift | 69.1% | 34 | Good |
| CheckoutComponentsStrings.swift | 72.9% | 42 | Good |
| PrimerCheckoutScope.swift | 73.3% | 4 | Good |
| DependencyScope.swift | 73.7% | 5 | Good |
| ContainerDiagnostics.swift | 73.9% | 37 | Good |
| DefaultCheckoutScope.swift | 74.5% | 132 | Good |
| StructuredCardFormState.swift | 74.6% | 15 | Good |
| PrimerError.swift | 75.0% | 2 | Good |
| ComposableContainer.swift | 77.6% | 36 | Good |
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
| DesignTokensProcessor.swift | 82.8% | 35 | Tests Added |
| ApplePayScreen.swift | 85.1% | 24 | Good |
| PrimerPaymentMethodScope.swift | 85.7% | 11 | Tests Added |
| PayPalRepositoryImpl.swift | 86.6% | 15 | Tests Added |
| PrimerFont.swift | 87.1% | 20 | Tests Added |
| AnalyticsEventService.swift | 87.5% | 8 | Tests Added |
| CheckoutSDKInitializer.swift | 87.9% | 12 | Good |
| UIDeviceExtension.swift | 90.3% | 6 | Good |
| Container.swift | 90.8% | 30 | Good |
| AnalyticsEnvironmentProvider.swift | 91.7% | 1 | Good |
| CardNetwork.swift | 91.7% | 1 | Good |
| DesignTokens.swift | 92.0% | 42 | Tests Added |
| Factory.swift | 93.9% | 3 | Tests Added |
| CheckoutNavigator.swift | 94.2% | 3 | Good |
| PrimerAPIConfigurationModule.swift | 95.3% | 3 | Good |
| CheckoutRoute.swift | 95.9% | 2 | Good |
| IntExtension.swift | 96.3% | 1 | Good |
| ProcessApplePayPaymentInteractor.swift | 96.3% | 4 | Good |
| AnalyticsEventMetadata.swift | 97.1% | 2 | Good |
| CardValidationRules.swift | 97.6% | 3 | Tests Added |
| ApplePayRequestBuilder.swift | 97.9% | 3 | Good |
| CommonValidationRules.swift | 98.7% | 4 | Tests Added |
| DefaultSelectCountryScope.swift | 98.7% | 1 | Good |
| PrimerHeadlessUniversalCheckoutInputElement.swift | 99.3% | 1 | Tests Added |
| VaultedPaymentMethod+DisplayData.swift | 99.5% | 1 | Good |

---

## Files at 100% Coverage

| File | Lines |
|------|-------|
| AccessibilityIdentifiers.swift | 9 |
| AccessibilityConfiguration.swift | 0 |
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
| ContainerRetainPolicy.swift | 0 |
| DefaultAccessibilityAnnouncementService.swift | 0 |
| DefaultAnalyticsInteractor.swift | 0 |
| DefaultPayPalScope.swift | 0 |
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
| PrimerFieldStyling.swift | 0 |
| PrimerLayout.swift | 0 |
| PrimerEnvironment.swift | 4 |
| PrimerLocaleData.swift | 0 |
| PrimerPaymentMethodSelectionScope.swift | 0 |
| PrimerPaymentMethodType+ImageName.swift | 0 |
| PrimerSelectCountryScope.swift | 0 |
| PrimerSettings.swift | 0 |
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
