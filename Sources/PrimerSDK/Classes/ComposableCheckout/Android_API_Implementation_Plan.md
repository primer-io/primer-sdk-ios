# ComposableCheckout iOS Alignment Plan - EXECUTION READY

## Executive Summary

This plan aligns iOS ComposableCheckout with Android's architecture by removing the static API and eliminating the wrapper layer to achieve a clean scope-based approach.

**Timeline**: 1 week (7 days)
**Strategy**: Remove PrimerComponents, eliminate wrappers, use scope-based API only
**Outcome**: iOS matches Android's architecture with single source of truth

## Architecture Verification Results

### ✅ iOS DOES Have Proper Architecture Layers
```
iOS ComposableCheckout/
├── Domain/                    # ✅ Interactors & Models (matching Android)
│   ├── Interactors/          # GetPaymentMethodsInteractor, ProcessCardPaymentInteractor, etc.
│   └── Models/               # Domain models
├── Data/                     # ✅ Repositories & Services (matching Android)
│   ├── Repositories/         # PaymentMethodRepository, PaymentRepository, etc.
│   └── Services/             # PaymentService, TokenizationService, etc.
├── Scopes/                   # Public API (matches Android)
└── PaymentMethods/           # UI Components
```

### Current State Analysis

### iOS Current Architecture
1. **Domain Layer**: ✅ Proper interactors (GetPaymentMethodsInteractor, ProcessCardPaymentInteractor, ValidatePaymentDataInteractor)
2. **Data Layer**: ✅ Repository pattern implemented (PaymentMethodRepository, TokenizationRepository)
3. **Sophisticated Components**: CardNumberInputField, CVVInputField (900+ lines each - built from scratch)
4. **UIWrappers**: ❌ CardNumberInputWrapper (unnecessary intermediate layer - TO BE REMOVED)
5. **Scope Extensions**: ✅ CardFormScope.PrimerCardNumberInput()
6. **Static API**: ❌ PrimerComponents.PrimerCardNumberInput() (redundant - TO BE REMOVED)

### Android Architecture
1. **Domain Layer**: Interactors for business logic
2. **Data Layer**: Repositories for data access
3. **Internal Components**: Input.kt (281 lines - reuses existing components)
4. **Scope Extensions**: CardFormScope.PrimerCardNumberInput()

### Key Differences to Fix
1. **Dual API Problem**: iOS has both static and scope-based APIs, Android only has scope-based
2. **Wrapper Complexity**: iOS has unnecessary wrapper components between scopes and components
3. **Component Size**: iOS components are larger because they're built from scratch (ACCEPTABLE - not a problem)
4. **Localization**: iOS will use InputLocalizable.swift (ACCEPTABLE - platform difference)
5. **Navigation**: iOS uses custom CheckoutNavigator (ACCEPTABLE - platform constraints)

## Implementation Strategy

### What Actually Needs to Change

Based on the architecture analysis, iOS already has the proper Domain and Data layers. We only need to:
1. **Remove Static API**: Delete PrimerComponents.swift
2. **Remove Wrapper Layer**: Delete UIWrappers directory
3. **Connect Scopes Directly**: Update scope extensions to use components directly

### Align Public API with Android

```swift
// Android approach (what we want):
@Composable
fun CardFormScope.PrimerCardNumberInput(
    modifier: Modifier = Modifier
) {
    CardNumberInput(modifier)
}

// iOS aligned approach:
extension CardFormScope {
    @ViewBuilder
    func PrimerCardNumberInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardNumberInputField(
            label: InputLocalizable.cardNumberLabel,
            placeholder: InputLocalizable.cardNumberPlaceholder,
            onCardNumberChange: { newValue in
                self.updateCardNumber(newValue)
            },
            onCardNetworkChange: nil,  // Internal - not exposed
            onValidationChange: nil     // Internal - not exposed
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
}
```

### Key Changes Summary

1. **Delete PrimerComponents.swift entirely** (remove ~1000 lines)
2. **Delete UIWrappers directory** (remove intermediate layer ~600 lines)
3. **Update scope extensions** to directly use sophisticated components
4. **Remove callbacks** from public API (state flows through scope only)
5. **Add localization file** (InputLocalizable.swift)

### IMPORTANT NOTES FOR IMPLEMENTATION

1. **Domain/Data Layers**: ✅ Already exist - DO NOT modify these layers
2. **Component Size**: ✅ iOS components are larger because built from scratch - this is FINE
3. **Localization**: ✅ Use InputLocalizable.swift approach - NOT .strings files
4. **Navigation**: ✅ Keep existing CheckoutNavigator - platform specific
5. **Focus Only On**: Removing static API + wrappers, connecting scopes directly

### One-Week Implementation Plan

## Phase 1: Core Component Replacement (Days 1-4)

### Day 1: Remove Static API and Create Foundation
**Task**: Delete PrimerComponents.swift and create foundation helpers

**Step 1: Delete Files**
```bash
# Delete the static API completely
rm Sources/PrimerSDK/Classes/ComposableCheckout/Components/PrimerComponents.swift

# Delete all wrapper files
rm -rf Sources/PrimerSDK/Classes/ComposableCheckout/UIWrappers/

# Verify deletions
git status
```

**Step 2: Create Foundation Files**

**ModifierApplication.swift**:
```swift
// Sources/PrimerSDK/Classes/ComposableCheckout/Extensions/ModifierApplication.swift
import SwiftUI

@available(iOS 15.0, *)
extension View {
    func applyPrimerModifier(_ modifier: PrimerModifier) -> some View {
        modifier.modifiers.reduce(AnyView(self)) { view, modifierType in
            switch modifierType {
            case .fillMaxWidth:
                return AnyView(view.frame(maxWidth: .infinity))
            case .padding(let edges, let value):
                return AnyView(view.padding(edges, value))
            case .background(let color):
                return AnyView(view.background(color))
            case .cornerRadius(let radius):
                return AnyView(view.cornerRadius(radius))
            case .disabled(let isDisabled):
                return AnyView(view.disabled(isDisabled))
            // Add all other modifier types from PrimerModifier
            }
        }
    }
}

// Environment helper for DI container and design tokens
extension View {
    func withPrimerEnvironment() -> some View {
        self
            .environment(\.diContainer, DIContainer.currentSync)
            .environment(\.designTokens, DesignTokensManager.current)
    }
}
```


### Day 2: Update Scope Extensions with Localization
**Task**: Update CardFormScope extensions to use sophisticated components directly

**Step 1: Create Localization File for Inputs**

**InputLocalizable.swift**:
```swift
// Sources/PrimerSDK/Classes/ComposableCheckout/Localization/InputLocalizable.swift
import Foundation

@available(iOS 15.0, *)
internal enum InputLocalizable {
    // MARK: - Card Fields
    static let cardNumberLabel = "Card Number"
    static let cardNumberPlaceholder = "1234 5678 9012 3456"
    
    static let cvvLabel = "CVV"
    static let cvvPlaceholder = "123"
    
    static let expiryDateLabel = "Expiry Date"
    static let expiryDatePlaceholder = "MM/YY"
    
    static let cardholderNameLabel = "Cardholder Name"
    static let cardholderNamePlaceholder = "John Doe"
    
    // MARK: - Address Fields
    static let postalCodeLabel = "Postal Code"
    static let postalCodePlaceholder = "12345"
    
    static let countryCodeLabel = "Country Code"
    static let countryCodePlaceholder = "US"
    
    static let cityLabel = "City"
    static let cityPlaceholder = "New York"
    
    static let stateLabel = "State"
    static let statePlaceholder = "NY"
    
    static let addressLine1Label = "Address Line 1"
    static let addressLine1Placeholder = "123 Main Street"
    
    static let addressLine2Label = "Address Line 2"
    static let addressLine2Placeholder = "Apt 4B"
    
    // MARK: - Personal Information
    static let phoneNumberLabel = "Phone Number"
    static let phoneNumberPlaceholder = "+1 (555) 123-4567"
    
    static let firstNameLabel = "First Name"
    static let firstNamePlaceholder = "John"
    
    static let lastNameLabel = "Last Name"
    static let lastNamePlaceholder = "Doe"
    
    // MARK: - Other Fields
    static let retailOutletLabel = "Retail Outlet"
    static let retailOutletPlaceholder = "Select outlet"
    
    static let otpCodeLabel = "OTP Code"
    static let otpCodePlaceholder = "123456"
    
    // MARK: - Buttons
    static let submitButtonText = "Submit"
    static let payButtonText = "Pay"
}
```

**Step 2: Update CardFormScope.swift**

Replace placeholder implementations with actual components:

```swift
// Update the extension in CardFormScope.swift (starting around line 44)
@available(iOS 15.0, *)
public extension CardFormScope {
    
    @ViewBuilder
    func PrimerCardNumberInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardNumberInputField(
            label: InputLocalizable.cardNumberLabel,
            placeholder: InputLocalizable.cardNumberPlaceholder,
            onCardNumberChange: { newValue in
                self.updateCardNumber(newValue)
            },
            onCardNetworkChange: nil,
            onValidationChange: nil
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
    
    @ViewBuilder
    func PrimerCvvInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CVVInputField(
            label: InputLocalizable.cvvLabel,
            placeholder: InputLocalizable.cvvPlaceholder,
            cardNetwork: .unknown, // Should be managed by scope state
            onCvvChange: { newValue in
                self.updateCvv(newValue)
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
    
    @ViewBuilder
    func PrimerExpiryDateInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        ExpiryDateInputField(
            label: InputLocalizable.expiryDateLabel,
            placeholder: InputLocalizable.expiryDatePlaceholder,
            onExpiryDateChange: { newValue in
                self.updateExpiryDate(newValue)
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
    
    @ViewBuilder
    func PrimerCardholderNameInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardholderNameInputField(
            label: InputLocalizable.cardholderNameLabel,
            placeholder: InputLocalizable.cardholderNamePlaceholder,
            onCardholderNameChange: { newValue in
                self.updateCardholderName(newValue)
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
}
```

**Step 3: Delete old wrapper references**

In CardFormScope.swift, delete all the placeholder view implementations (lines ~362-578):
- SubmitButtonView
- CardNumberInputView
- CvvInputView
- ExpiryDateInputView
- All other placeholder views


### Day 3: Implement Remaining Scope Components
**Task**: Complete all input components in scope extensions

**Step 1: Check for existing sophisticated components**

First, check if these components exist:
```bash
# Search for existing input components
find Sources/PrimerSDK/Classes/ComposableCheckout -name "*InputField.swift" | grep -E "(Postal|Country|City|State|Address|Phone|Name)"
```

**Step 2: Update remaining components in CardFormScope**

For components without sophisticated implementations, use PrimerInputField:

```swift
// Continue updating CardFormScope.swift

@ViewBuilder
func PrimerPostalCodeInput(
    modifier: PrimerModifier = PrimerModifier()
) -> some View {
    // Get current value from scope state
    let state = self.state.eraseToAnyPublisher()
    
    PrimerInputField(
        label: InputLocalizable.postalCodeLabel,
        placeholder: InputLocalizable.postalCodePlaceholder,
        textContentType: .postalCode,
        onValueChange: { newValue in
            self.updatePostalCode(newValue)
        }
    )
    .applyPrimerModifier(modifier)
    .withPrimerEnvironment()
}

@ViewBuilder
func PrimerSubmitButton(
    modifier: PrimerModifier = PrimerModifier(),
    text: String = InputLocalizable.submitButtonText
) -> some View {
    // Subscribe to state for button enabled status
    let statePublisher = self.state
    
    PrimerButton(
        text: text,
        action: {
            self.submit()
        }
    )
    .onReceive(statePublisher) { state in
        // Button enabled based on state.isSubmitEnabled
    }
    .applyPrimerModifier(modifier)
    .withPrimerEnvironment()
}

// Continue with all other components...
```

**Step 3: Use Existing PrimerInputField**

PrimerInputField already exists at `Core/View/PrimerInputField.swift`. Use it for components without sophisticated implementations:

```swift
// Example usage in scope extensions:
@ViewBuilder
func PrimerPostalCodeInput(
    modifier: PrimerModifier = PrimerModifier()
) -> some View {
    PrimerInputField(
        label: InputLocalizable.postalCodeLabel,
        placeholder: InputLocalizable.postalCodePlaceholder,
        textContentType: .postalCode,
        onValueChange: { newValue in
            self.updatePostalCode(newValue)
        }
    )
    .applyPrimerModifier(modifier)
    .withPrimerEnvironment()
}
```

Note: The existing PrimerInputField is already sophisticated with:
- Comprehensive state management
- Design system integration
- Focus state detection
- Dynamic color management
- Accessibility support


### Day 4: State Management Alignment
**Task**: Ensure single source of truth through scope only

**Step 1: Update CardFormViewModel to manage card network state**

```swift
// In ViewModels/CardFormViewModel.swift
@MainActor
class CardFormViewModel: CardFormScope, ObservableObject, LogReporter {
    // Add card network tracking
    @Published private var detectedCardNetwork: CardNetwork = .unknown
    
    // Update state to include card network
    private func updateState() {
        _state = CardFormState(
            cardFields: determineRequiredFields(),
            billingFields: determineBillingFields(),
            fieldErrors: validationErrors,
            inputFields: inputFields,
            isLoading: isLoading,
            isSubmitEnabled: isFormValid(),
            cardNetwork: detectedCardNetwork // Add this
        )
    }
    
    // Update card number handler to detect network
    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "Updating card number")
        
        // Update input field
        inputFields[.cardNumber] = cardNumber
        
        // Detect card network
        let network = CardNetworkDetector.detectNetwork(from: cardNumber)
        if network != detectedCardNetwork {
            detectedCardNetwork = network
            logger.debug(message: "Detected card network: \(network)")
        }
        
        // Validate
        validateField(.cardNumber, value: cardNumber)
        updateState()
    }
}
```

**Step 2: Update CVV component to use network from state**

```swift
// In CardFormScope extension
@ViewBuilder
func PrimerCvvInput(
    modifier: PrimerModifier = PrimerModifier()
) -> some View {
    // Create a stateful wrapper that tracks card network
    CVVInputWithNetwork(scope: self, modifier: modifier)
}

// Helper view to bridge state
@available(iOS 15.0, *)
private struct CVVInputWithNetwork: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var cardNetwork: CardNetwork = .unknown
    
    var body: some View {
        CVVInputField(
            label: InputLocalizable.cvvLabel,
            placeholder: InputLocalizable.cvvPlaceholder,
            cardNetwork: cardNetwork,
            onCvvChange: { newValue in
                scope.updateCvv(newValue)
            }
        )
        .onReceive(scope.state) { state in
            if let network = state.cardNetwork {
                cardNetwork = network
            }
        }
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
}
```

**Step 3: Verify no external state management**

Check that:
1. Components don't have their own @State for business logic
2. All state flows through scope update methods
3. No callbacks are exposed in public API
4. State is read from scope.state publisher

**Step 4: Update CardFormState to include necessary data**

```swift
// In Models/States/CardFormState.swift
@available(iOS 15.0, *)
public struct CardFormState {
    public let cardFields: [ComposableInputElementType]
    public let billingFields: [ComposableInputElementType]
    public let fieldErrors: [ComposableInputValidationError]
    public let inputFields: [ComposableInputElementType: String]
    public let isLoading: Bool
    public let isSubmitEnabled: Bool
    public let cardNetwork: CardNetwork? // Add this
    
    // Update initializer
    public init(
        cardFields: [ComposableInputElementType] = [],
        billingFields: [ComposableInputElementType] = [],
        fieldErrors: [ComposableInputValidationError] = [],
        inputFields: [ComposableInputElementType: String] = [:],
        isLoading: Bool = false,
        isSubmitEnabled: Bool = false,
        cardNetwork: CardNetwork? = nil
    ) {
        self.cardFields = cardFields
        self.billingFields = billingFields
        self.fieldErrors = fieldErrors
        self.inputFields = inputFields
        self.isLoading = isLoading
        self.isSubmitEnabled = isSubmitEnabled
        self.cardNetwork = cardNetwork
    }
}
```

### Day 5: Composite Components and Field Visibility
**Task**: Implement composite components with field visibility logic

**Step 1: Update PrimerCardDetails composite**

```swift
// In CardFormScope extension
@ViewBuilder
func PrimerCardDetails(
    modifier: PrimerModifier = PrimerModifier()
) -> some View {
    // Create a view that responds to state for field visibility
    CardDetailsComposite(scope: self, modifier: modifier)
}

// Helper composite view
@available(iOS 15.0, *)
private struct CardDetailsComposite: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var visibleFields: Set<ComposableInputElementType> = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Always show card number
            scope.PrimerCardNumberInput()
            
            HStack(spacing: 12) {
                // Show expiry if required
                if visibleFields.contains(.expiryDate) {
                    scope.PrimerExpiryDateInput()
                }
                
                // Show CVV if required
                if visibleFields.contains(.cvv) {
                    scope.PrimerCvvInput()
                }
            }
            
            // Show cardholder name if required
            if visibleFields.contains(.cardholderName) {
                scope.PrimerCardholderNameInput()
            }
        }
        .onReceive(scope.state) { state in
            // Update visible fields based on state
            visibleFields = Set(state.cardFields)
        }
        .applyPrimerModifier(modifier)
    }
}
```

**Step 2: Update PrimerBillingAddress composite**

```swift
@ViewBuilder
func PrimerBillingAddress(
    modifier: PrimerModifier = PrimerModifier()
) -> some View {
    BillingAddressComposite(scope: self, modifier: modifier)
}

@available(iOS 15.0, *)
private struct BillingAddressComposite: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var visibleFields: Set<ComposableInputElementType> = []
    
    var body: some View {
        VStack(spacing: 16) {
            Text(InputLocalizable.billingAddressTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Show fields based on configuration
            if visibleFields.contains(.addressLine1) {
                scope.PrimerAddressLine1Input()
            }
            
            if visibleFields.contains(.addressLine2) {
                scope.PrimerAddressLine2Input()
            }
            
            HStack(spacing: 12) {
                if visibleFields.contains(.city) {
                    scope.PrimerCityInput()
                }
                
                if visibleFields.contains(.state) {
                    scope.PrimerStateInput()
                }
            }
            
            HStack(spacing: 12) {
                if visibleFields.contains(.postalCode) {
                    scope.PrimerPostalCodeInput()
                }
                
                if visibleFields.contains(.countryCode) {
                    scope.PrimerCountryCodeInput()
                }
            }
        }
        .onReceive(scope.state) { state in
            // Update visible fields based on state
            visibleFields = Set(state.billingFields)
        }
        .applyPrimerModifier(modifier)
    }
}
```

**Step 3: Add localization for composite components**

```swift
// Add to InputLocalizable.swift
static let billingAddressTitle = "Billing Address"
static let cardDetailsTitle = "Card Details"
```

### Day 6: Navigation and Screen Integration
**Task**: Verify navigation works like Android

**Step 1: Review Android navigation pattern**

Android uses:
- CheckoutNavigator with navigation events
- Screens managed by CheckoutNavHost
- CompositionLocal for navigator access

**Step 2: Verify iOS matches**

```swift
// Verify CheckoutNavigator matches Android pattern
// In Core/Navigation/CheckoutNavigator.swift

// Should have similar navigation events:
public enum NavigationEvent {
    case navigateToPaymentSelection
    case navigateToCardForm
    case navigateToSuccess
    case navigateToError(String)
    case navigateBack
}

// Should be available via environment
@Environment(\.checkoutNavigator) var navigator
```

**Step 3: Update PrimerCheckout to use navigator**

```swift
// In Core/PrimerCheckout/PrimerCheckout.swift
@available(iOS 15.0, *)
public struct PrimerCheckout: View {
    // Navigation state
    @StateObject private var navigator = CheckoutNavigator()
    @State private var currentScreen: CheckoutScreen = .loading
    
    public var body: some View {
        ZStack {
            switch currentScreen {
            case .loading:
                LoadingScreen()
            case .paymentSelection:
                PaymentSelectionScreen()
            case .cardForm:
                CardFormScreen()
            case .success:
                SuccessScreen()
            case .error(let message):
                ErrorScreen(message: message)
            }
        }
        .environment(\.checkoutNavigator, navigator)
        .onReceive(navigator.navigationEvents) { event in
            handleNavigationEvent(event)
        }
    }
}
```

**Step 4: Create screen wrapper components**

```swift
// Create screen files that match Android structure
// Sources/PrimerSDK/Classes/ComposableCheckout/Screens/

// CardFormScreen.swift
@available(iOS 15.0, *)
struct CardFormScreen: View {
    @StateObject private var viewModel: CardFormViewModel
    
    var body: some View {
        viewModel.scope.PrimerCardDetails()
        viewModel.scope.PrimerBillingAddress()
        viewModel.scope.PrimerSubmitButton()
    }
}
```

## Phase 3: Final Integration (Day 7)

### Day 7: Final Verification and Cleanup
**Task**: Ensure complete alignment with Android

**Step 1: Final Architecture Verification**

```bash
# Verify static API is completely removed
find Sources/PrimerSDK/Classes/ComposableCheckout -name "PrimerComponents.swift" | wc -l
# Expected: 0

# Verify no UIWrappers exist
find Sources/PrimerSDK/Classes/ComposableCheckout -name "*Wrapper.swift" | wc -l
# Expected: 0

# Count scope extension functions
grep -E "func Primer[A-Z]" Sources/PrimerSDK/Classes/ComposableCheckout/Scopes/*.swift | wc -l
# Should match Android's count
```

**Step 2: Create Architecture Documentation**

```swift
// Sources/PrimerSDK/Classes/ComposableCheckout/ARCHITECTURE.md

# ComposableCheckout Architecture (iOS)

## Overview
iOS ComposableCheckout follows Android's 2-layer architecture:

1. **Internal Components**: Sophisticated input fields (CardNumberInputField, etc.)
2. **Scope Extensions**: Public API via CardFormScope.PrimerCardNumberInput()

## Key Principles
- Single source of truth: All state flows through scope
- No callbacks in public API: Use scope update methods
- Field visibility: Components shown based on payment method configuration
- Localization ready: Strings extracted to InputLocalizable

## Usage
```swift
// Inside a scope
scope.PrimerCardNumberInput(modifier: .fillMaxWidth())
scope.PrimerSubmitButton(text: "Pay Now")
```
```

**Step 3: Update CLAUDE.md with new architecture**

Add to ComposableCheckout/CLAUDE.md:
```markdown
## Architecture Alignment with Android

### What Changed
1. **Removed Static API**: No more PrimerComponents.swift
2. **Removed UIWrappers**: Direct connection from scopes to components
3. **Single State Flow**: All state through scope, no callbacks
4. **Localization Pattern**: InputLocalizable.swift for string extraction

### Current Structure
```
ComposableCheckout/
├── Core/
│   ├── DI/                  # Dependency Injection (platform-specific)
│   ├── Navigation/          # CheckoutNavigator
│   └── PrimerCheckout/      # Main entry point
├── Scopes/                  # Public API (matches Android)
│   ├── CardFormScope.swift
│   └── PaymentMethodSelectionScope.swift
├── PaymentMethods/          # Internal sophisticated components
│   └── Card/View/
│       ├── CardNumberInputField.swift
│       └── CVVInputField.swift
├── Localization/            # String extraction
│   └── InputLocalizable.swift
└── Extensions/              # Helper extensions
    └── ModifierApplication.swift
```
```

**Step 4: Final Cleanup**

```bash
# Clean build folder (optional)
rm -rf ~/Library/Developer/Xcode/DerivedData/PrimerSDK-*

# Verify changes
git status

# View diff to ensure all changes are correct
git diff --stat
```

## Success Criteria & Metrics

### Architecture Alignment
- ✅ **Clean Architecture**: Domain + Data + Presentation layers (ALREADY EXISTS)
- ✅ **No Static API**: Only scope-based component access
- ✅ **No Wrappers**: Direct connection from scopes to components
- ✅ **Single State Flow**: All state through scope update methods

### Functional Requirements
- ✅ **Scope Extensions**: All components available via scope.PrimerXxx()
- ✅ **Field Visibility**: Components shown based on payment method config
- ✅ **Validation**: Works through existing ValidationService
- ✅ **Localization**: Strings extracted to InputLocalizable

### Code Reduction
- ✅ **Remove ~1000 lines**: Delete PrimerComponents.swift
- ✅ **Remove ~600 lines**: Delete UIWrappers directory
- ✅ **Net reduction**: ~1600 lines removed
- ✅ **Cleaner public API**: Direct scope-to-component connection

## Risk Mitigation

### Low Risk: Integration Issues
**Risk**: Sophisticated components might not work properly when used through PrimerComponents
**Mitigation**: 
- Manual verification of each component integration
- Verify all callbacks and validation work correctly
- Check modifier application edge cases
- Ensure environment injection works reliably

### Low Risk: State Coordination
**Risk**: Composite components might need coordinated state
**Mitigation**:
- Keep state coordination optional
- Use simple callback patterns
- Leverage existing patterns where possible
- Verify composite component interactions work

## Implementation Notes

### Key Architecture Changes
1. **Remove Static API**: Delete PrimerComponents.swift entirely
2. **Remove Wrappers**: Delete UIWrappers directory
3. **Scope-Only Access**: Components only available through scope extensions
4. **State Through Scope**: No callbacks, use scope update methods
5. **Field Visibility**: Show/hide based on payment method configuration
6. **Localization Pattern**: Extract strings to adjacent files

### Final Code Organization
```
Sources/PrimerSDK/Classes/ComposableCheckout/
├── Domain/                           # ✅ ALREADY EXISTS - DO NOT CHANGE
│   ├── Interactors/                 # Business logic use cases
│   └── Models/                      # Domain models
├── Data/                            # ✅ ALREADY EXISTS - DO NOT CHANGE
│   ├── Repositories/                # Data access abstractions
│   └── Services/                    # External service integrations
├── Core/
│   ├── DI/                         # Platform-specific DI (unchanged)
│   ├── Navigation/                 # CheckoutNavigator (keep as-is)
│   └── PrimerCheckout/            # Main entry point
├── Scopes/                        # Public API (matches Android)
│   ├── CardFormScope.swift        # Extension functions for components
│   └── PaymentMethodSelectionScope.swift
├── PaymentMethods/                # Internal components
│   └── Card/View/
│       ├── CardNumberInputField.swift # Sophisticated implementation (900+ lines)
│       ├── CVVInputField.swift       # Keep as-is
│       └── ExpiryDateInputField.swift # Keep as-is
├── Localization/                  # String extraction
│   └── InputLocalizable.swift     # All component strings
├── Core/View/                     # Core UI components
│   └── PrimerInputField.swift    # Existing sophisticated input field
└── Extensions/
    └── ModifierApplication.swift  # PrimerModifier support
```

### Dependencies (Unchanged)
- **Validation System**: ValidationService with caching
- **DI Container**: Platform-specific async/await DI
- **Design Tokens**: Platform-specific theming
- **Existing Infrastructure**: Logging, error handling, analytics

## Conclusion

This implementation plan aligns iOS ComposableCheckout with Android by focusing on the PUBLIC API alignment:

### What We're Changing:
1. **Removing the static API entirely** (~1000 lines) - PrimerComponents.swift
2. **Deleting UIWrapper intermediate layer** (~600 lines) - UIWrappers directory
3. **Connecting scopes directly to components** - Update scope extensions

### What We're NOT Changing:
1. **Domain Layer** - Already matches Android with proper interactors
2. **Data Layer** - Already has repository pattern like Android
3. **Component Size** - iOS components are larger due to building from scratch (acceptable)
4. **Navigation** - Keep CheckoutNavigator due to platform constraints
5. **Localization** - Use InputLocalizable.swift (platform-specific approach)

**Expected Outcome**: 
- Clean scope-based API matching Android
- No dual API confusion
- Direct scope-to-component connection
- ~1600 lines of unnecessary code removed
- Same user experience with cleaner architecture

The architecture is already well-aligned at the Domain/Data layers. This plan simply removes the unnecessary public API complexity to match Android's clean scope-based approach.