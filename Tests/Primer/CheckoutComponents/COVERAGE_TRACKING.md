# CheckoutComponents Code Coverage Tracking

**Overall Coverage on New Code:** 32.8%
**Last Updated:** 2025-12-30
**Branch:** 002-checkout-components-unit-tests

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
| CardFormProvider.swift | 48 | Medium | Provider pattern |
| CheckoutColors.swift | 66 | Low | Design tokens |
| CheckoutComponentsPrimer.swift | 236 | High | Main entry point |
| DesignTokens.swift | 526 | Low | Static tokens |
| DesignTokensDark.swift | 163 | Low | Static tokens |
| DesignTokensKey.swift | 2 | Low | Simple key |
| DesignTokensManager.swift | 411 | Medium | Token management |
| DIContainer+SwiftUI.swift | 42 | Medium | SwiftUI integration |
| HeadlessRepositoryImpl.swift | 718 | High | Core repository |
| InputFieldConfig.swift | 6 | Low | Simple config |
| MockCardFormScope.swift | 186 | N/A | Test utility |
| MockDesignTokens.swift | 39 | N/A | Test utility |
| MockDIContainer.swift | 29 | N/A | Test utility |
| MockValidationService.swift | 49 | N/A | Test utility |
| PaymentMethodSelectionProvider.swift | 47 | Medium | Provider pattern |
| PrimerCardFormScope.swift | 96 | Medium | Scope protocol |
| PrimerEnvironment.swift | 8 | Low | Environment config |
| PrimerFieldStyling.swift | 33 | Low | Styling config |
| PrimerFont.swift | 155 | Medium | Font handling |
| PrimerLayout.swift | 51 | Low | Layout constants |
| PrimerTheme+Images.swift | 26 | Low | Theme images |
| SelectCountryProvider.swift | 33 | Medium | Provider pattern |
| SwiftUI+DI.swift | 73 | Medium | SwiftUI DI utils |
| WebAuthenticationService.swift | 3 | Low | Simple service |

---

## Files with Low Coverage (1-49%) - Priority Improvement

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| DefaultCardFormScope.swift | 27.3% | 540 | Tests Exist |
| ApplePayButtonView.swift | 29.3% | 41 | SwiftUI - Skip |
| DefaultPaymentMethodSelectionScope.swift | 31.4% | 210 | Tests Exist |
| PrimerHeadlessUniversalCheckoutInputElement.swift | 32.4% | 96 | Needs Tests |
| PrimerSettings.swift | 33.3% | 4 | Needs Tests |
| UserInterfaceModule.swift | 38.5% | 8 | Needs Tests |
| ConfigurationService.swift | 43.5% | 13 | Needs Tests |
| View+Accessibility.swift | 44.0% | 14 | Needs Tests |

---

## Files with Partial Coverage (50-79%)

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| CardPaymentMethod.swift | 57.3% | 38 | Tests Added |
| PrimerPaymentMethodScope.swift | 58.4% | 32 | Needs Tests |
| PrimerTheme.swift | 60.0% | 4 | Good |
| ValidationResult.swift | 60.0% | 6 | Needs Tests |
| AccessibilityIdentifiers.swift | 62.5% | 9 | Needs Tests |
| InternalPaymentMethod.swift | 62.5% | 9 | Needs Tests |
| CheckoutComponentsPaymentMethodsBridge.swift | 63.0% | 64 | Needs Tests |
| PayPalPaymentMethod.swift | 64.8% | 25 | Tests Added |
| ContainerProtocol.swift | 66.7% | 3 | Good |
| DIContainer.swift | 69.1% | 34 | Good |
| CheckoutComponentsStrings.swift | 72.9% | 42 | Good |
| PrimerCheckoutScope.swift | 73.3% | 4 | Good |
| DependencyScope.swift | 73.7% | 5 | Good |
| ContainerDiagnostics.swift | 73.9% | 37 | Good |
| DefaultCheckoutScope.swift | 74.1% | 134 | Good |
| StructuredCardFormState.swift | 74.6% | 15 | Good |
| PrimerError.swift | 75.0% | 2 | Good |
| ComposableContainer.swift | 77.6% | 36 | Good |
| CommonValidationRules.swift | 78.9% | 64 | Good |
| DefaultApplePayScope.swift | 79.4% | 44 | Good |

---

## Files with High Coverage (80-99%)

| File | Coverage | Lines | Status |
|------|----------|-------|--------|
| AnalyticsNetworkClient.swift | 81.7% | 11 | Tests Added |
| ValidationService.swift | 82.0% | 37 | Good |
| ApplePayPaymentMethod.swift | 82.2% | 8 | Good |
| ErrorMessageResolver.swift | 82.5% | 51 | Good |
| FontRegistration.swift | 82.6% | 8 | Good |
| DesignTokensProcessor.swift | 82.8% | 35 | Tests Added |
| ApplePayScreen.swift | 85.1% | 24 | Good |
| PayPalRepositoryImpl.swift | 86.6% | 15 | Tests Added |
| AnalyticsEventService.swift | 87.5% | 8 | Tests Added |
| CheckoutSDKInitializer.swift | 87.9% | 12 | Good |
| CheckoutNavigator.swift | 88.5% | 6 | Good |
| CardValidationRules.swift | 88.8% | 14 | Good |
| UIDeviceExtension.swift | 90.3% | 6 | Good |
| Container.swift | 90.8% | 30 | Good |
| AnalyticsEnvironmentProvider.swift | 91.7% | 1 | Good |
| CardNetwork.swift | 91.7% | 1 | Good |
| CheckoutRoute.swift | 93.9% | 3 | Good |
| Factory.swift | 93.9% | 3 | Tests Added |
| PrimerAPIConfigurationModule.swift | 95.3% | 3 | Good |
| IntExtension.swift | 96.3% | 1 | Good |
| ProcessApplePayPaymentInteractor.swift | 96.3% | 4 | Good |
| AnalyticsEventMetadata.swift | 97.1% | 2 | Good |
| ApplePayRequestBuilder.swift | 97.9% | 3 | Good |
| DefaultSelectCountryScope.swift | 98.7% | 1 | Good |
| VaultedPaymentMethod+DisplayData.swift | 99.5% | 1 | Good |

---

## Files at 100% Coverage

| File | Lines |
|------|-------|
| AccessibilityConfiguration.swift | 0 |
| AnalyticsEventBuffer.swift | 0 |
| AnalyticsPayloadBuilder.swift | 0 |
| AnalyticsSessionConfig.swift | 0 |
| ApplePayFormState.swift | 0 |
| CardNetworkDetectionInteractor.swift | 0 |
| CheckoutComponentsTheme.swift | 0 |
| CheckoutCoordinator.swift | 0 |
| ContainerError.swift | 0 |
| ContainerRetainPolicy.swift | 0 |
| DefaultAccessibilityAnnouncementService.swift | 0 |
| DefaultAnalyticsInteractor.swift | 0 |
| DefaultPayPalScope.swift | 0 |
| ExpiryDateInput.swift | 0 |
| GetPaymentMethodsInteractor.swift | 0 |
| PaymentMethodMapper.swift | 0 |
| PaymentResult.swift | 0 |
| PayPalState.swift | 0 |
| Primer.swift | 0 |
| PrimerApplePayScope.swift | 0 |
| PrimerLocaleData.swift | 0 |
| PrimerPaymentMethodSelectionScope.swift | 0 |
| PrimerPaymentMethodType+ImageName.swift | 0 |
| PrimerSelectCountryScope.swift | 0 |
| ProcessCardPaymentInteractor.swift | 0 |
| ProcessPayPalPaymentInteractor.swift | 0 |
| RetentionStrategy.swift | 0 |
| RulesFactory.swift | 0 |
| StringExtension.swift | 0 |
| SubmitVaultedPaymentInteractor.swift | 0 |
| TypeKey.swift | 0 |
| ValidateInputInteractor.swift | 0 |
| ValidationError.swift | 0 |
| ValidationRule.swift | 0 |

---

## Tests Added This Session

| Test File | Tests | Target File | Previous | Current | Status |
|-----------|-------|-------------|----------|---------|--------|
| ContainerErrorTests.swift | 22 | ContainerError.swift | 32.8% | 100% | Done |
| TypeKeyTests.swift | 24 | TypeKey.swift | 50.0% | 100% | Done |
| CardPaymentMethodTests.swift | 6 | CardPaymentMethod.swift | 34.8% | 57.3% | Done |
| PayPalPaymentMethodTests.swift | 7 | PayPalPaymentMethod.swift | 4.2% | 64.8% | Done |
| DefaultCardFormScopeTests.swift | 27 | DefaultCardFormScope.swift | 27.3% | 27.3% | Existing |
| DefaultPaymentMethodSelectionScopeTests.swift | 16 | DefaultPaymentMethodSelectionScope.swift | 31.4% | 31.4% | Existing |
| DesignTokensProcessorTests.swift | 28 | DesignTokensProcessor.swift | 82.8% | 82.8% | Existing |
| FactoryTests.swift | 15 | Factory.swift | 0% | 93.9% | Done |
| ProcessPayPalPaymentInteractorTests.swift | 20 | ProcessPayPalPaymentInteractor.swift | 0% | 100% | Done |
| DefaultPayPalScopeTests.swift | 18 | DefaultPayPalScope.swift | 0% | 100% | Done |
| CheckoutComponentsThemeTests.swift | 25 | CheckoutComponentsTheme.swift | 8.2% | 100% | Done |
| PayPalRepositoryImplTests.swift | 20 | PayPalRepositoryImpl.swift | 0% | 86.6% | Done |
| DefaultConfigurationServiceTests.swift | 17 | ConfigurationService.swift | 43.5% | TBD | Done |
| ValidationResultTests.swift | 20 | ValidationResult.swift | 60% | TBD | Done |
| InternalPaymentMethodTests.swift | 22 | InternalPaymentMethod.swift | 62.5% | TBD | Done |
| PaymentMethodRegistryTests.swift | 17 | PrimerPaymentMethodScope.swift | 58.4% | TBD | Done |
| CheckoutComponentsPaymentMethodsBridgeTests.swift | 18 | CheckoutComponentsPaymentMethodsBridge.swift | 63% | TBD | Done |

**Total Tests:** 322 (all passing)

---

## Next Steps - Priority Order

### High Priority (0% coverage, testable)
1. HeadlessRepositoryImpl.swift (718 lines)
2. CheckoutComponentsPrimer.swift (236 lines)

### Medium Priority (Low coverage, partial tests exist)
1. PrimerHeadlessUniversalCheckoutInputElement.swift (32.4%)
2. ConfigurationService.swift (43.5%)
3. View+Accessibility.swift (44.0%)

### Low Priority (Already good coverage)
- Files at 80%+ coverage - minor improvements only
- SwiftUI views - test via Debug App UI tests

---

## Run All Tests Command

```bash
xcodebuild test -workspace PrimerSDK.xcworkspace -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
