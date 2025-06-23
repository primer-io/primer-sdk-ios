# CheckoutComponents iOS Implementation Plan - LLM Execution Guide

## Overview
This is an LLM execution plan for implementing a brand new "CheckoutComponents" framework within PrimerSDK iOS. This is NOT a migration - it's a fresh implementation inspired by Android's Composable architecture but built using modern Swift and iOS best practices. The framework will provide the same public API as Android while following iOS platform conventions internally.

**Target Requirements:**
- iOS 15.0+ minimum deployment target
- Swift 6 compatibility
- SwiftUI-based implementation
- SOLID principles throughout
- No external dependencies (no Combine imports)

**Context for LLM Implementation:**
This plan serves as a detailed guide for an LLM to implement the framework phase by phase. Each phase should result in a git commit, and the implementation should be self-contained without running or testing the app (manual testing will be done separately).

## Design References

The following screenshots show the desired UI/UX for the card payment flow:

1. **Payment Method Selection**: `DesignScreenshots/01_payment_method_selection.png`
   - Shows payment method options (Apple Pay, PayPal, iDEAL, Klarna)
   - "Pay with card" option at bottom
   - Clean white background with method cards

2. **Card Form (Empty)**: `DesignScreenshots/02_card_form_empty.png`
   - Card number field with placeholder formatting
   - Payment network logos row
   - Expiry and CVV fields side by side
   - Name on card field below
   - Blue "Pay" button

3. **Card Form (Filled)**: `DesignScreenshots/03_card_form_filled.png`
   - Shows valid Visa card entry
   - All fields populated correctly
   - Pay button enabled

4. **Card Form (CVV Error)**: `DesignScreenshots/04_card_form_cvv_error.png`
   - Red highlight on CVV field
   - Error icon and message below field
   - Other fields remain valid

5. **Card Form (All Errors)**: `DesignScreenshots/05_card_form_all_errors.png`
   - All fields showing validation errors
   - Red borders and error messages
   - Consistent error styling

6. **Payment Success**: `DesignScreenshots/06_payment_success.png`
   - Green checkmark icon
   - Success message with redirect info
   - Clean, minimal design

## Understanding from Android Architecture

Based on the Android CLAUDE.md, the Composable module follows:
- **Clean Architecture**: Strict separation between Presentation → Domain → Data layers
- **Scope-based API**: Type-safe scoped APIs with customizable UI components
- **No static APIs**: Everything accessed through scope interfaces
- **State management**: Reactive state through StateFlow (Kotlin) → @Published (iOS)
- **Full customization**: Every UI component can be replaced while maintaining defaults

## Critical Components to Reuse

### IMPORTANT: These existing components are tested and working - reuse with minimal changes:
1. **Card Input Fields** (Located in `/ComposableCheckout/PaymentMethods/Card/View/`):
   - `CardholderNameInputField.swift` - ✅ Reuse as-is (just update callbacks to use scope methods)
   - `CardNumberInputField.swift` - ✅ Reuse as-is (proven card formatting and validation)
   - `CVVInputField.swift` - ✅ Reuse as-is (handles all card network CVV variations)
   - `ExpiryDateInputField.swift` - ✅ Reuse as-is (proper MM/YY formatting)

2. **Validation System** (`/ComposableCheckout/Core/Validation/`):
   - Complete validation framework with rules
   - Card-specific validators already implemented and tested
   - ✅ Copy entire validation system without changes

3. **Other Infrastructure to Copy**:
   - **DI Framework**: `/ComposableCheckout/Core/DI/` - Actor-based async dependency injection
   - **Design Tokens**: `/ComposableCheckout/Design/` - Auto-generated design system
   - **Navigation**: `/ComposableCheckout/Navigation/` - State-driven navigation (avoids SwiftUI bugs)

## Android Public API Components (EXACT API TO MATCH)

The Android Composable module exposes the following public API that iOS MUST match exactly:

### Main Entry Point
```kotlin
@Composable
fun PrimerCheckout(
    modifier: Modifier = Modifier,
    clientToken: String,
    settings: PrimerSettings = PrimerSettings(),
    scope: ((PrimerCheckoutScope) -> Unit)? = null,
)
```

### Scope Interfaces

#### 1. **PrimerCheckoutScope**
```kotlin
interface PrimerCheckoutScope {
    val state: StateFlow<State>
    
    // Customizable screens
    var container: @Composable (content: @Composable () -> Unit) -> Unit
    var splashScreen: @Composable () -> Unit
    var loadingScreen: @Composable () -> Unit
    var successScreen: @Composable () -> Unit
    var errorScreen: @Composable (message: String) -> Unit
    
    // Nested scopes
    val cardForm: PrimerCardFormScope
    val paymentMethodSelection: PrimerPaymentMethodSelectionScope
    
    fun onDismiss()
    
    sealed interface State {
        data object Initializing : State
        data object Ready : State
        data object Dismissed : State
        data class Error(val exception: Throwable) : State
    }
}
```

#### 2. **PrimerCardFormScope**
```kotlin
interface PrimerCardFormScope {
    val state: StateFlow<State>
    
    // Navigation methods
    fun onSubmit()
    fun onBack()
    fun onCancel()
    fun navigateToCountrySelection()
    
    // Update methods (15 total)
    fun updateCardNumber(cardNumber: String)
    fun updateCvv(cvv: String)
    fun updateExpiryDate(expiryDate: String)
    fun updateCardholderName(cardholderName: String)
    fun updatePostalCode(postalCode: String)
    fun updateCity(city: String)
    fun updateState(state: String)
    fun updateAddressLine1(addressLine1: String)
    fun updateAddressLine2(addressLine2: String)
    fun updatePhoneNumber(phoneNumber: String)
    fun updateFirstName(firstName: String)
    fun updateLastName(lastName: String)
    fun updateRetailOutlet(retailOutlet: String)
    fun updateOtpCode(otpCode: String)
    fun updateEmail(email: String)
    
    // Nested scope
    val selectCountry: PrimerSelectCountryScope
    
    // Customizable UI components (18 total)
    var screen: @Composable PrimerCardFormScope.() -> Unit
    var submitButton: @Composable (modifier: Modifier, text: String) -> Unit
    var cardNumberInput: @Composable (modifier: Modifier) -> Unit
    var cvvInput: @Composable (modifier: Modifier) -> Unit
    var expiryDateInput: @Composable (modifier: Modifier) -> Unit
    var cardholderNameInput: @Composable (modifier: Modifier) -> Unit
    var postalCodeInput: @Composable (modifier: Modifier) -> Unit
    var countryCodeInput: @Composable (modifier: Modifier) -> Unit
    var cityInput: @Composable (modifier: Modifier) -> Unit
    var stateInput: @Composable (modifier: Modifier) -> Unit
    var addressLine1Input: @Composable (modifier: Modifier) -> Unit
    var addressLine2Input: @Composable (modifier: Modifier) -> Unit
    var phoneNumberInput: @Composable (modifier: Modifier) -> Unit
    var firstNameInput: @Composable (modifier: Modifier) -> Unit
    var lastNameInput: @Composable (modifier: Modifier) -> Unit
    var retailOutletInput: @Composable (modifier: Modifier) -> Unit
    var otpCodeInput: @Composable (modifier: Modifier) -> Unit
    var cardDetails: @Composable (modifier: Modifier) -> Unit
    var billingAddress: @Composable (modifier: Modifier) -> Unit
    
    data class State(
        val cardNumber: String = "",
        val cvv: String = "",
        val expiryDate: String = "",
        val cardholderName: String = "",
        val postalCode: String = "",
        val countryCode: String = "",
        val city: String = "",
        val state: String = "",
        val addressLine1: String = "",
        val addressLine2: String = "",
        val phoneNumber: String = "",
        val firstName: String = "",
        val lastName: String = "",
        val retailOutlet: String = "",
        val otpCode: String = "",
        val email: String = "",
        val isSubmitting: Boolean = false
    )
}
```

#### 3. **PrimerPaymentMethodSelectionScope**
```kotlin
interface PrimerPaymentMethodSelectionScope {
    val state: StateFlow<State>
    
    fun onPaymentMethodSelected(paymentMethod: PrimerComposablePaymentMethod)
    fun onCancel()
    
    var screen: @Composable () -> Unit
    var paymentMethodCard: @Composable (modifier: Modifier, onPaymentMethodSelected: () -> Unit) -> Unit
    
    data class State(
        val paymentMethods: List<PrimerComposablePaymentMethod> = emptyList(),
        val isLoading: Boolean = false
    )
}
```

#### 4. **PrimerSelectCountryScope**
```kotlin
interface PrimerSelectCountryScope {
    val state: StateFlow<State>
    
    fun onCountrySelected(countryCode: String, countryName: String)
    fun onCancel()
    fun onSearch(query: String)
    
    var screen: @Composable PrimerSelectCountryScope.() -> Unit
    var searchBar: @Composable (query: String, onQueryChange: (String) -> Unit, placeholder: String) -> Unit
    var countryItem: @Composable (country: PrimerCountry, onSelect: () -> Unit) -> Unit
    
    data class State(
        val countries: List<PrimerCountry> = emptyList(),
        val filteredCountries: List<PrimerCountry> = emptyList(),
        val searchQuery: String = "",
        val isLoading: Boolean = false
    )
}
```

## Proposed iOS Structure

Following Android's exact architecture pattern:

```
CheckoutComponents/
├── CLAUDE.md                                    # Documentation for AI assistance
├── README.md                                    # Public documentation
├── PrimerCheckout.swift                         # Main entry point (matching Android)
│
├── Scope/                                       # PUBLIC API - Scope interfaces
│   ├── PrimerCheckoutScope.swift               # Main checkout lifecycle
│   ├── PrimerCardFormScope.swift               # Card form state and components
│   ├── PrimerPaymentMethodSelectionScope.swift # Payment method selection
│   └── PrimerSelectCountryScope.swift          # Country selection
│
└── Internal/                                    # INTERNAL implementation
    ├── Domain/                                  # Business logic layer
    │   ├── Interactors/                        # Use cases
    │   │   ├── GetPaymentMethodsInteractor.swift
    │   │   ├── GetValidationStateInteractor.swift
    │   │   ├── ProcessCardPaymentInteractor.swift
    │   │   ├── TokenizeCardInteractor.swift
    │   │   └── ValidateInputInteractor.swift
    │   ├── Models/                             # Domain models
    │   │   ├── PrimerComposablePaymentMethod.swift
    │   │   ├── PrimerInputElementType.swift
    │   │   └── PrimerInputValidationError.swift
    │   └── Repositories/                       # Repository interfaces
    │       └── HeadlessRepository.swift
    │
    ├── Data/                                   # Data access layer
    │   ├── Repositories/                       # Repository implementations
    │   │   └── HeadlessRepositoryImpl.swift
    │   └── Mappers/                           # Data transformation
    │       └── PaymentMethodMapper.swift
    │
    ├── Presentation/                           # UI layer
    │   ├── Checkout/                          # Main checkout flow
    │   │   ├── Checkout.swift                 # Internal entry composable
    │   │   ├── CheckoutNavigator.swift        # Navigation management
    │   │   └── CheckoutViewModel.swift        # Main checkout state
    │   ├── Screens/                           # Screen implementations
    │   │   ├── CardFormScreen.swift
    │   │   ├── PaymentMethodSelectionScreen.swift
    │   │   ├── SelectCountryScreen.swift
    │   │   ├── SplashScreen.swift
    │   │   ├── LoadingScreen.swift
    │   │   ├── SuccessScreen.swift
    │   │   └── ErrorScreen.swift
    │   ├── Components/                        # Reusable UI components
    │   │   ├── Input/                        # Input components (copied from ComposableCheckout)
    │   │   │   ├── CardNumberInput.swift
    │   │   │   ├── CVVInput.swift
    │   │   │   ├── ExpiryDateInput.swift
    │   │   │   ├── CardholderNameInput.swift
    │   │   │   ├── PostalCodeInput.swift
    │   │   │   ├── AddressInput.swift
    │   │   │   └── PhoneNumberInput.swift
    │   │   ├── Composite/                    # Composite components
    │   │   │   ├── CardDetails.swift
    │   │   │   └── BillingAddress.swift
    │   │   └── Common/
    │   │       ├── PrimerButton.swift
    │   │       └── PaymentMethodItem.swift
    │   ├── Scope/                            # Scope implementations
    │   │   ├── DefaultCheckoutScope.swift
    │   │   ├── DefaultCardFormScope.swift
    │   │   ├── DefaultPaymentMethodSelectionScope.swift
    │   │   └── DefaultSelectCountryScope.swift
    │   └── Theme/                            # Theming utilities
    │       └── PrimerTheme.swift
    │
    ├── DI/                                   # Dependency injection (copied from ComposableCheckout)
    │   └── ComposableContainer.swift
    │
    ├── Tokens/                               # Design tokens (copied from ComposableCheckout)
    │   └── DesignTokens.swift
    │
    └── Core/                                 # Shared utilities
        ├── Validation/                       # Validation framework (copied)
        ├── Extensions/
        └── InputConfigs.swift               # Centralized input configuration
```

## Implementation Phases

### Phase 1: Foundation & Public API (Day 1)
**Git Commit Message**: "feat: Add CheckoutComponents foundation and public API"
1. **Create directory structure** exactly as outlined above
2. **Define all public scope interfaces** in `/Scope/` - MUST MATCH ANDROID EXACTLY:
   ```swift
   // PrimerCheckoutScope.swift
   @MainActor
   public protocol PrimerCheckoutScope: AnyObject {
       var state: AsyncStream<State> { get }
       
       // Customizable screens - using @ViewBuilder for SwiftUI equivalent of @Composable
       var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)? { get set }
       var splashScreen: (@ViewBuilder () -> any View)? { get set }
       var loadingScreen: (@ViewBuilder () -> any View)? { get set }
       var successScreen: (@ViewBuilder () -> any View)? { get set }
       var errorScreen: (@ViewBuilder (_ message: String) -> any View)? { get set }
       
       // Nested scopes
       var cardForm: PrimerCardFormScope { get }
       var paymentMethodSelection: PrimerPaymentMethodSelectionScope { get }
       
       func onDismiss()
       
       enum State: Equatable {
           case initializing
           case ready
           case dismissed
           case error(PrimerError)
       }
   }
   
   // PrimerCardFormScope.swift
   @MainActor
   public protocol PrimerCardFormScope: AnyObject {
       var state: AsyncStream<State> { get }
       
       // Navigation methods
       func onSubmit()
       func onBack()
       func onCancel()
       func navigateToCountrySelection()
       
       // Update methods (15 total) - EXACT MATCH TO ANDROID
       func updateCardNumber(_ cardNumber: String)
       func updateCvv(_ cvv: String)
       func updateExpiryDate(_ expiryDate: String)
       func updateCardholderName(_ cardholderName: String)
       func updatePostalCode(_ postalCode: String)
       func updateCity(_ city: String)
       func updateState(_ state: String)
       func updateAddressLine1(_ addressLine1: String)
       func updateAddressLine2(_ addressLine2: String)
       func updatePhoneNumber(_ phoneNumber: String)
       func updateFirstName(_ firstName: String)
       func updateLastName(_ lastName: String)
       func updateRetailOutlet(_ retailOutlet: String)
       func updateOtpCode(_ otpCode: String)
       func updateEmail(_ email: String)
       
       // Nested scope
       var selectCountry: PrimerSelectCountryScope { get }
       
       // Customizable UI components (18 total) - EXACT MATCH TO ANDROID
       var screen: (@ViewBuilder (PrimerCardFormScope) -> any View)? { get set }
       var submitButton: (@ViewBuilder (_ modifier: PrimerModifier, _ text: String) -> any View)? { get set }
       var cardNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var cvvInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var expiryDateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var cardholderNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var postalCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var countryCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var cityInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var stateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var addressLine1Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var addressLine2Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var phoneNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var firstNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var lastNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var retailOutletInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var otpCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var cardDetails: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       var billingAddress: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
       
       struct State: Equatable {
           var cardNumber: String = ""
           var cvv: String = ""
           var expiryDate: String = ""
           var cardholderName: String = ""
           var postalCode: String = ""
           var countryCode: String = ""
           var city: String = ""
           var state: String = ""
           var addressLine1: String = ""
           var addressLine2: String = ""
           var phoneNumber: String = ""
           var firstName: String = ""
           var lastName: String = ""
           var retailOutlet: String = ""
           var otpCode: String = ""
           var email: String = ""
           var isSubmitting: Bool = false
       }
   }
   ```
3. **Create main entry point** `PrimerCheckout.swift` - EXACT MATCH TO ANDROID:
   ```swift
   @MainActor
   public struct PrimerCheckout: View {
       let clientToken: String
       let settings: PrimerSettings
       let scope: ((PrimerCheckoutScope) -> Void)?
       
       public init(
           clientToken: String,
           settings: PrimerSettings = PrimerSettings(),
           scope: ((PrimerCheckoutScope) -> Void)? = nil
       ) {
           self.clientToken = clientToken
           self.settings = settings
           self.scope = scope
       }
       
       public var body: some View {
           InternalCheckout(
               clientToken: clientToken,
               settings: settings,
               scope: scope
           )
       }
   }
   ```

### Phase 2: Core Infrastructure (Day 2)
**Git Commit Message**: "feat: Add core infrastructure (DI, validation, design tokens)"

**Files to Copy (with paths):**
1. **DI System**:
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/Core/DI/`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/DI/`
   - Update all imports from `ComposableCheckout` to `CheckoutComponents`

2. **Validation Framework**:
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/Core/Validation/`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Core/Validation/`
   - Keep as-is (no changes needed)

3. **Design Tokens**:
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/Design/`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Tokens/`
   - Update imports only

4. **Navigation System**:
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/Navigation/`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Navigation/`
   - Reference: `NAVIGATION_ARCHITECTURE_DECISION.md` for state-driven pattern

5. **Create DI container** following Android pattern:
   ```swift
   // ComposableContainer.swift
   internal class ComposableContainer: DIContainer {
       override func registerInitialDependencies() {
           // Singleton registrations
           registerSingleton(PaymentMethodMapper.self) { PaymentMethodMapperImpl() }
           registerSingleton(HeadlessRepository.self) { HeadlessRepositoryImpl() }
           
           // ViewModels as scoped singletons
           registerSingleton(PrimerCardFormScope.self) { DefaultCardFormScope() }
       }
   }
   ```

### Phase 3: Domain & Data Layers (Day 3)
**Git Commit Message**: "feat: Add domain layer and data repositories"

**Files to Create:**
1. **Domain Models** (in `/Internal/Domain/Models/`):
   ```swift
   // PrimerComposablePaymentMethod.swift
   internal struct PrimerComposablePaymentMethod {
       let id: String
       let type: String
       let name: String
       let icon: UIImage?
   }
   
   // PrimerInputElementType.swift
   internal enum PrimerInputElementType {
       case cardNumber, cvv, expiryDate, cardholderName
       case postalCode, city, state, addressLine1, addressLine2
       case phoneNumber, firstName, lastName, email
       case retailOutlet, otpCode, countryCode
   }
   ```

2. **Interactors** (in `/Internal/Domain/Interactors/`):
   - Follow SOLID principles - each interactor has single responsibility
   - All interactors adopt `LogReporter` protocol
   - Reference existing headless SDK: `/Sources/PrimerSDK/Classes/Core/PrimerHeadlessUniversalCheckout/`

3. **Repository** (in `/Internal/Data/Repositories/`):
   - Wrap `PrimerHeadlessUniversalCheckout.current`
   - Use async/await for all operations
   - Reference: See "Headless SDK Integration" section in plan

### Phase 4: Presentation Layer - Components (Day 4)
**Git Commit Message**: "feat: Add UI components and input fields"

**CRITICAL: Reuse Existing Card Input Fields:**
1. **Copy Card Input Components** (with minimal changes):
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/PaymentMethods/Card/View/CardNumberInputField.swift`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Input/CardNumberInput.swift`
   - CHANGES: Only update callbacks to use scope update methods instead of direct callbacks
   
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/PaymentMethods/Card/View/CVVInputField.swift`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Input/CVVInput.swift`
   
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/PaymentMethods/Card/View/ExpiryDateInputField.swift`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Input/ExpiryDateInput.swift`
   
   - FROM: `/Sources/PrimerSDK/Classes/ComposableCheckout/PaymentMethods/Card/View/CardholderNameInputField.swift`
   - TO: `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Input/CardholderNameInput.swift`

2. **Adapt Existing Billing Address Components** to SwiftUI:
   - Convert `PrimerFirstNameFieldView` → `FirstNameInput`
   - Convert `PrimerLastNameFieldView` → `LastNameInput`
   - Convert `PrimerAddressLine1FieldView` → `AddressLine1Input`
   - Convert `PrimerAddressLine2FieldView` → `AddressLine2Input`
   - Convert `PrimerCityFieldView` → `CityInput`
   - Convert `PrimerStateFieldView` → `StateInput`
   - Convert `PrimerPostalCodeFieldView` → `PostalCodeInput`
   - Convert `PrimerCountryFieldView` → `CountryCodeInput` (with country picker)
   
3. **Create New Input Components** (use PrimerInputField as base):
   - `PhoneNumberInput` - If billing address phone is enabled
   - `EmailInput` - For email collection
   - `OTPCodeInput` - For one-time passwords

6. **Build Composite Components**:
   - `CardDetails` - Groups card inputs horizontally/vertically based on design
   - `BillingAddress` - Groups address fields with dynamic layout based on configuration:
     ```swift
     struct BillingAddress: View {
         @EnvironmentObject var scope: DefaultCardFormScope
         
         var body: some View {
             VStack(spacing: 16) {
                 // Country selection (if enabled)
                 if scope.isBillingAddressCountryEnabled {
                     CountryCodeInput()
                 }
                 
                 // Name fields row
                 if scope.isBillingAddressFirstNameEnabled || scope.isBillingAddressLastNameEnabled {
                     HStack(spacing: 12) {
                         if scope.isBillingAddressFirstNameEnabled {
                             FirstNameInput()
                         }
                         if scope.isBillingAddressLastNameEnabled {
                             LastNameInput()
                         }
                     }
                 }
                 
                 // Address lines
                 if scope.isBillingAddressLine1Enabled {
                     AddressLine1Input()
                 }
                 if scope.isBillingAddressLine2Enabled {
                     AddressLine2Input()
                 }
                 
                 // City/Postal code row
                 HStack(spacing: 12) {
                     if scope.isBillingAddressPostalCodeEnabled {
                         PostalCodeInput()
                     }
                     if scope.isBillingAddressCityEnabled {
                         CityInput()
                     }
                 }
                 
                 // State
                 if scope.isBillingAddressStateEnabled {
                     StateInput()
                 }
             }
         }
     }
     ```

4. **Reuse Input Configuration from PrimerInputElementType**:
   ```swift
   // Already exists in PrimerHeadlessUniversalCheckoutInputElement.swift
   extension PrimerInputElementType {
       var isValid: (String?) -> Bool { get }
       var keyboardType: UIKeyboardType? { get }
       var allowedCharacters: CharacterSet? { get }
   }
   ```
   
5. **Create InputConfigs wrapper** for SwiftUI components:
   ```swift
   // InputConfigs.swift
   enum InputConfigs {
       static func label(for type: PrimerInputElementType) -> String {
           // Map to existing localized strings
           switch type {
           case .firstName: return Strings.BillingAddress.firstName
           case .lastName: return Strings.BillingAddress.lastName
           // etc...
           }
       }
       
       static func placeholder(for type: PrimerInputElementType) -> String
       static func validator(for type: PrimerInputElementType) -> ((String?) -> Bool)
       static func keyboardType(for type: PrimerInputElementType) -> UIKeyboardType
   }
   ```

### Phase 5: Presentation Layer - Scopes & Screens (Day 5)
**Git Commit Message**: "feat: Implement scope classes and screens"

**Files to Create:**
1. **Default Scope Implementations** (in `/Internal/Presentation/Scope/`):
   - `DefaultCheckoutScope.swift` - Implements `PrimerCheckoutScope`
   - `DefaultCardFormScope.swift` - Implements `PrimerCardFormScope` with all 15 update methods
   - `DefaultPaymentMethodSelectionScope.swift`
   - `DefaultSelectCountryScope.swift`
   
   **Key Implementation Details:**
   - Use `@Published` for internal state management
   - Expose `AsyncStream<State>` in public API
   - All classes adopt `LogReporter` protocol
   - Follow state management pattern shown in "State Management Architecture" section

2. **Screen Implementations** (in `/Internal/Presentation/Screens/`):
   - Reference design screenshots in `/DesignScreenshots/`
   - All screens receive scope via environment or initializer
   - Use design tokens for styling

3. **Setup Navigation**:
   - Copy navigation pattern from ComposableCheckout
   - Single source of truth for navigation state
   ```swift
   enum CheckoutScreen {
       case splash
       case paymentMethodSelection
       case cardForm
       case selectCountry
       case success
       case error(String)
   }
   ```

### Phase 6: Integration & PrimerUIManager (Day 6)
**Git Commit Message**: "feat: Integrate CheckoutComponents with PrimerUIManager"

**Integration Steps:**
1. **Update PrimerUIManager** (file: `/Sources/PrimerSDK/Classes/ComposableCheckout/Core/PrimerUIManager.swift`):
   ```swift
   // Add to CheckoutStyle enum
   case checkoutComponents
   
   // Update presentation logic to handle new case
   case .checkoutComponents:
       let checkoutView = PrimerCheckout(
           clientToken: clientToken,
           settings: settings
       )
       let hostingController = UIHostingController(rootView: checkoutView)
       present(hostingController, animated: true)
   ```

2. **Module Initialization**:
   - Register all dependencies in DI container
   - Initialize design tokens
   - Setup logging

3. **Bridge Configuration**:
   - Pass PrimerSettings through to components
   - Connect to existing error handling

### Phase 7: Documentation & Future Enhancements (Day 7)
**Git Commit Message**: "docs: Add documentation and usage examples"

1. **Documentation Files**:
   - Update README.md with usage examples
   - Create API documentation for public interfaces
   - Add inline documentation for all public methods

2. **Example Usage**:
   - Basic usage example
   - Custom UI component example
   - State observation example

3. **Future Enhancements**:
   - Vaulting/stored cards support
   - Advanced 3DS customization options
   - Enhanced error recovery mechanisms
   - Additional card network validations

## Critical API Parity Requirements

### iOS-Specific Adaptations for Android Parity

1. **StateFlow → @Published + AsyncStream**: 
   - Android uses `StateFlow<State>` for reactive state propagation
   - iOS will use `@Published` properties in ViewModels for SwiftUI updates
   - `AsyncStream<State>` exposed in protocols for observing state changes
   - This provides the same reactive flow pattern as Android's StateFlow

2. **@Composable → @ViewBuilder**: SwiftUI's `@ViewBuilder` provides similar composition capabilities

3. **Modifier → PrimerModifier**: Custom modifier struct for iOS styling

4. **any View**: Used for type erasure in protocols where Android uses composable functions

### State Management Architecture (iOS Approach - NO COMBINE)
```swift
// Protocol exposes AsyncStream for state observation
public protocol PrimerCheckoutScope: AnyObject {
    var state: AsyncStream<State> { get }
}

// Implementation uses @Published for SwiftUI reactivity (auto-imported with SwiftUI)
@MainActor
internal class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject {
    @Published private var internalState: State = .initializing
    
    // AsyncStream provides reactive state updates without Combine
    var state: AsyncStream<State> {
        AsyncStream { continuation in
            Task { @MainActor in
                // Initial state
                continuation.yield(internalState)
                
                // Observe state changes using async pattern
                for await _ in $internalState.values {
                    continuation.yield(internalState)
                }
            }
        }
    }
    
    // Update state internally
    private func updateState(_ newState: State) {
        internalState = newState
    }
}
```

**Key Points:**
- NO import Combine anywhere
- @Published is part of SwiftUI (no extra import needed)
- AsyncStream provides reactive updates
- Clean async/await patterns throughout

### PrimerModifier Definition
```swift
public struct PrimerModifier {
    var padding: EdgeInsets?
    var background: Color?
    var cornerRadius: CGFloat?
    var border: (color: Color, width: CGFloat)?
    
    public init(
        padding: EdgeInsets? = nil,
        background: Color? = nil,
        cornerRadius: CGFloat? = nil,
        border: (color: Color, width: CGFloat)? = nil
    ) {
        self.padding = padding
        self.background = background
        self.cornerRadius = cornerRadius
        self.border = border
    }
}
```

## SOLID Principles Implementation Guide

### S - Single Responsibility Principle
- Each scope handles only its domain (checkout flow, card form, payment selection, country selection)
- Separate interactors for each business operation
- UI components only handle presentation, not business logic

### O - Open/Closed Principle  
- Scope interfaces allow extension through component customization
- Default implementations can be replaced without modifying core code
- New payment methods can be added without changing existing code

### L - Liskov Substitution Principle
- All scope implementations must fulfill their protocol contracts
- Custom UI components must be drop-in replacements for defaults

### I - Interface Segregation Principle
- Separate protocols for each scope type
- Components depend only on the interfaces they need
- No "god" interfaces with unnecessary methods

### D - Dependency Inversion Principle
- High-level modules (scopes) depend on abstractions (protocols)
- Repository pattern abstracts data sources
- DI container manages all dependencies

## Key Design Decisions

### 1. Exact Android API Parity
- **Main entry point**: `PrimerCheckout` SwiftUI view (matches Android @Composable)
- **Scope interfaces**: Exact same scope hierarchy as Android
- **Customizable components**: Every component replaceable via scope properties
- **No static APIs**: Everything through scope interfaces
- **All methods/properties**: Must match Android exactly (no additions/removals)

### 2. Architecture Mapping
| Android | iOS | Purpose |
|---------|-----|---------|
| @Composable | SwiftUI View | UI components |
| StateFlow | CurrentValueSubject | Reactive state |
| ViewModel | ObservableObject | State management |
| Coroutines | async/await | Async operations |
| sealed class | enum with cases | Type-safe states |

### 3. Component Customization Pattern
```swift
// Default implementation in scope
var cardNumberInput: (() -> AnyView)? = {
    AnyView(CardNumberInput())
}

// Client can override
scope.cardNumberInput = {
    AnyView(CustomCardNumberInput())
}
```

### 4. Input Configuration System
- Centralized `InputConfigs` matching Android
- Handles labels, placeholders, keyboard types, validation rules
- Single source of truth for input behavior

## Example API Usage (Matching Android)

### Basic Usage
```swift
// Direct SwiftUI usage
struct ContentView: View {
    var body: some View {
        PrimerCheckout(
            clientToken: "your_client_token",
            settings: PrimerSettings()
        )
    }
}

// With scope customization
struct CustomCheckoutView: View {
    var body: some View {
        PrimerCheckout(
            clientToken: "your_client_token",
            settings: PrimerSettings(),
            scope: { checkoutScope in
                // Customize container
                checkoutScope.container = { content in
                    ZStack {
                        Color.blue.opacity(0.1)
                        VStack {
                            Text("Custom Header")
                            content()
                        }
                    }
                }
                
                // Customize card form screen
                checkoutScope.cardForm.screen = {
                    VStack(spacing: 16) {
                        Text("Enter Card Details")
                            .font(.headline)
                        
                        checkoutScope.cardForm.cardDetails()
                        checkoutScope.cardForm.billingAddress()
                        
                        checkoutScope.cardForm.submitButton(
                            Modifier(),
                            "Complete Payment"
                        )
                    }
                    .padding()
                }
                
                // Customize individual component
                checkoutScope.cardForm.cardNumberInput = { _ in
                    // Custom implementation
                    CustomCardNumberField()
                }
            }
        )
    }
}
```

### UIKit Integration
```swift
// In PrimerUIManager
case .checkoutComponents:
    let checkoutView = PrimerCheckout(
        clientToken: clientToken,
        settings: settings
    )
    let hostingController = UIHostingController(rootView: checkoutView)
    present(hostingController, animated: true)
```

## Implementation Checklist

### Phase 1: Foundation & Public API (Day 1)
- [ ] Create CheckoutComponents directory structure
- [ ] Define PrimerCheckoutScope protocol
- [ ] Define PrimerCardFormScope protocol  
- [ ] Define PrimerPaymentMethodSelectionScope protocol
- [ ] Define PrimerSelectCountryScope protocol
- [ ] Create PrimerCheckout.swift entry point
- [ ] Create CLAUDE.md documentation

### Phase 2: Core Infrastructure (Day 2)
- [ ] Copy DI framework to Internal/DI/
- [ ] Copy Validation framework to Internal/Core/Validation/
- [ ] Copy Design tokens to Internal/Tokens/
- [ ] Copy Navigation system to Internal/Navigation/
- [ ] Create ComposableContainer with registrations
- [ ] Update all imports for new paths
- [ ] Setup DI resolution patterns
- [ ] Create CheckoutComponentsLocalizable enum
- [ ] Add LogReporter to all major classes

### Phase 3: Domain & Data Layers (Day 3)
- [ ] Create PrimerComposablePaymentMethod model
- [ ] Create PrimerInputElementType enum (all 17 types)
- [ ] Create PrimerInputValidationError model
- [ ] Implement GetPaymentMethodsInteractor
- [ ] Implement GetValidationStateInteractor
- [ ] Implement ProcessCardPaymentInteractor
- [ ] Create HeadlessRepository protocol
- [ ] Create HeadlessRepositoryImpl
- [ ] Create PaymentMethodMapper

### Phase 4: Presentation - Components (Day 4)
- [ ] Copy & adapt CardNumberInput (remove callbacks)
- [ ] Copy & adapt CVVInput
- [ ] Copy & adapt ExpiryDateInput
- [ ] Copy & adapt CardholderNameInput
- [ ] Convert PrimerFirstNameFieldView → FirstNameInput
- [ ] Convert PrimerLastNameFieldView → LastNameInput
- [ ] Convert PrimerAddressLine1FieldView → AddressLine1Input
- [ ] Convert PrimerAddressLine2FieldView → AddressLine2Input
- [ ] Convert PrimerCityFieldView → CityInput
- [ ] Convert PrimerStateFieldView → StateInput
- [ ] Convert PrimerPostalCodeFieldView → PostalCodeInput
- [ ] Convert PrimerCountryFieldView → CountryCodeInput
- [ ] Create PhoneNumberInput (if needed)
- [ ] Create EmailInput (new)
- [ ] Create OTPCodeInput (new)
- [ ] Create SelectCountryScreen (SwiftUI country picker)
- [ ] Create CardDetails composite
- [ ] Create BillingAddress composite with dynamic layout
- [ ] Create InputConfigs wrapper for PrimerInputElementType
- [ ] Copy Navigation system from ComposableCheckout

### Phase 5: Presentation - Scopes & Screens (Day 5)
- [ ] Implement DefaultCheckoutScope
- [ ] Implement DefaultCardFormScope with:
    - [ ] All 15 update methods from Android API
    - [ ] Billing address configuration from API
    - [ ] Co-badged card network selection
    - [ ] RawDataManager integration
- [ ] Implement DefaultPaymentMethodSelectionScope
- [ ] Implement DefaultSelectCountryScope with search
- [ ] Create all screens (Splash, Loading, Success, Error, etc.)
- [ ] Create SelectCountryScreen with search functionality
- [ ] Implement CheckoutNavigator
- [ ] Setup screen navigation flow

### Phase 6: Integration (Day 6)
- [ ] Add checkoutComponents to CheckoutStyle enum
- [ ] Integrate with PrimerUIManager
- [ ] Bridge to PrimerHeadlessUniversalCheckout
- [ ] Setup module initialization
- [ ] Test end-to-end flow

### Phase 7: Documentation & Future Enhancements (Day 7)
- [ ] Write README.md with usage examples
- [ ] Create API documentation
- [ ] Add inline documentation for public methods
- [ ] Document co-badged cards feature
- [ ] Add placeholders for future vaulting support
- [ ] Document 3DS handling approach

## Complete List of Input Types from Android

Based on the Android CardFormScope, all 17 input types that need to be supported:

### Card Fields (Already Implemented)
1. **cardNumber** - Card number input with formatting (✅ REUSE existing validation)
2. **cvv** - CVV/CVC security code (✅ REUSE existing validation)
3. **expiryDate** - Expiry date (MM/YY format) (✅ REUSE existing validation)
4. **cardholderName** - Name on card (✅ REUSE existing validation)

### Billing Address Fields (Partially Implemented)
5. **postalCode** - Postal/ZIP code (✅ REUSE `PrimerPostalCodeFieldView`)
6. **countryCode** - Country selection (✅ REUSE `PrimerCountryFieldView` + `CountrySelectorViewController`)
7. **city** - City name (✅ REUSE `PrimerCityFieldView`)
8. **state** - State/Province (✅ REUSE `PrimerStateFieldView`)
9. **addressLine1** - Street address line 1 (✅ REUSE `PrimerAddressLine1FieldView`)
10. **addressLine2** - Street address line 2 (optional) (✅ REUSE `PrimerAddressLine2FieldView`)
11. **firstName** - First name (✅ REUSE `PrimerFirstNameFieldView`)
12. **lastName** - Last name (✅ REUSE `PrimerLastNameFieldView`)

### Additional Fields
13. **phoneNumber** - Phone number with formatting (⚠️ Exists in PostalCodeOptions but needs field implementation)
14. **retailOutlet** - Retail outlet selection (❌ Xendit specific - SKIP for now)
15. **otpCode** - One-time password input (🆕 NEW implementation needed)
16. **email** - Email address (🆕 NEW implementation needed)
17. **birthDate** - Date of birth (🆕 NEW implementation needed - not in current SDK)

## Existing Input Element Model

Reuse `PrimerHeadlessUniversalCheckoutInputElement` which already defines:
```swift
public enum PrimerInputElementType: String {
    case cardNumber, expiryDate, cvv, cardholderName
    case firstName, lastName, addressLine1, addressLine2
    case city, state, postalCode, countryCode
    case phoneNumber, retailOutlet, birthDate
    // Methods for validation, keyboard type, allowed characters
}
```

## Billing Address Feature Architecture

### Configuration
Billing address fields are controlled by the API configuration:
```swift
PrimerAPIConfiguration.CheckoutModule {
    type: "BILLING_ADDRESS"
    options: PostalCodeOptions {
        firstName: Bool?
        lastName: Bool?
        city: Bool?
        postalCode: Bool?
        addressLine1: Bool?
        addressLine2: Bool?
        countryCode: Bool?
        phoneNumber: Bool?
        state: Bool?
    }
}
```

### Field Management Pattern
Reuse the existing `BillingAddressField` pattern:
```swift
typealias BillingAddressField = (fieldView: PrimerTextFieldView, 
                                 containerFieldView: PrimerCustomFieldView, 
                                 isFieldHidden: Bool)
```

### Layout Organization
Fields are organized in rows for proper layout:
```swift
[
    [countryField],
    [firstNameField, lastNameField],
    [addressLine1Field],
    [addressLine2Field],
    [postalCodeField, cityField],
    [stateField]
]
```

### Data Flow
1. **Collection**: Fields are part of the card form UI
2. **Validation**: Each field validates using `PrimerInputElementType` rules
3. **Submission**: Billing address is sent separately via Client Session Actions API
4. **Storage**: Stored in `ClientSession.Customer.billingAddress`

### Important: Billing Address is NOT part of tokenization
- Card tokenization only includes card details
- Billing address is sent via `ClientSession.Action.setBillingAddressActionWithParameters`
- This separation allows flexible configuration and compliance

## Validation Rules Strategy

### Reuse Existing Validators
Most billing address fields already have validators in the SDK:
- ✅ `PrimerFirstNameFieldView` - Uses `isValidNonDecimalString`
- ✅ `PrimerLastNameFieldView` - Uses `isValidNonDecimalString`
- ✅ `PrimerAddressLine1FieldView` - Uses `isValidString`
- ✅ `PrimerAddressLine2FieldView` - Uses `isValidString`
- ✅ `PrimerCityFieldView` - Uses `isValidNonDecimalString`
- ✅ `PrimerStateFieldView` - Uses `isValidNonDecimalString`
- ✅ `PrimerPostalCodeFieldView` - Custom postal code validation
- ✅ `PrimerCountryFieldView` - Validates against CountryCode enum

### New Validators Needed
- 🆕 **PhoneNumberValidator** - For phone number field (if implemented)
- 🆕 **EmailValidator** - For email field validation
- 🆕 **OTPValidator** - For one-time password validation
- CityValidator & CityRule
- StateValidator & StateRule
- OTPCodeValidator & OTPCodeRule

## Country Selection Implementation

Reuse existing iOS infrastructure:
- **Data Model**: `/Data Models/CountryCode.swift` - Complete enum with all countries
- **UIKit Reference**: `CountrySelectorViewController` in existing SDK
- **SwiftUI Component**: Create `SelectCountryScreen.swift` with search functionality
- **Integration**: Country selection triggers through `navigateToCountrySelection()` in CardFormScope
- **Search**: Reuse country search logic from `CountrySelectorViewController`

### Country Picker Flow
1. User taps country field → `navigateToCountrySelection()`
2. `SelectCountryScreen` presents with searchable list
3. User selects country → `onCountrySelected(code, name)`
4. Updates `countryCode` in CardFormScope state
5. Navigation pops back to card form

## Payment Method Architecture

CheckoutComponents introduces a new architecture that will eventually support all payment methods:
- **Phase 1**: Card payments only
- **Future phases**: PayPal, Apple Pay, Klarna, etc.
- **No dependency** on existing PrimerPaymentMethodManager
- Each payment method will be implemented fresh in the new architecture

## Headless SDK Integration - Card Payment Implementation

### Overview
The card payment implementation will leverage the existing headless SDK's `RawDataManager` internally to handle the payment flow. This approach ensures consistency with the current SDK behavior and reuses battle-tested payment processing logic.

### Architecture Flow
```
CardFormScope → Internal RawDataManager → Tokenization → Payment Processing → Scope State Updates
```

### Key Components

1. **RawDataManager Integration**
   - Create internal instance of `PrimerHeadlessUniversalCheckout.RawDataManager` for "PAYMENT_CARD" type
   - Use `PrimerCardData` model to pass card information
   - Handle delegate callbacks internally and expose state through CardFormScope

2. **Repository Implementation**
```swift
// HeadlessRepositoryImpl.swift
internal class HeadlessRepositoryImpl: HeadlessRepository {
    private let headlessCheckout = PrimerHeadlessUniversalCheckout.current
    
    func startCheckout(clientToken: String) async throws -> [PaymentMethod] {
        return try await withCheckedThrowingContinuation { continuation in
            headlessCheckout.start(
                withClientToken: clientToken,
                settings: nil,
                delegate: nil,
                uiDelegate: nil
            ) { paymentMethods, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: paymentMethods ?? [])
                }
            }
        }
    }
    
    func processCardPayment(cardData: PrimerCardData) async throws -> PaymentResult {
        // Create RawDataManager instance
        let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: "PAYMENT_CARD",
            delegate: self
        )
        
        // Set card data and submit
        rawDataManager.rawData = cardData
        
        return try await withCheckedThrowingContinuation { continuation in
            self.paymentContinuation = continuation
            rawDataManager.submit()
        }
    }
}
```

3. **CardFormScope Internal Implementation**
```swift
// DefaultCardFormScope.swift
internal class DefaultCardFormScope: PrimerCardFormScope, ObservableObject {
    private let rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    private let rawCardData: PrimerCardData
    
    // Co-badged cards support
    @Published private(set) var availableNetworks: [CardNetwork] = []
    @Published private(set) var selectedNetwork: CardNetwork?
    
    // Billing address configuration from API
    private var billingAddressOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .first { $0.type == "BILLING_ADDRESS" }?
            .options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }
    
    // Billing address field visibility
    var isBillingAddressFirstNameEnabled: Bool { billingAddressOptions?.firstName != false }
    var isBillingAddressLastNameEnabled: Bool { billingAddressOptions?.lastName != false }
    var isBillingAddressLine1Enabled: Bool { billingAddressOptions?.addressLine1 != false }
    var isBillingAddressLine2Enabled: Bool { billingAddressOptions?.addressLine2 != false }
    var isBillingAddressCityEnabled: Bool { billingAddressOptions?.city != false }
    var isBillingAddressStateEnabled: Bool { billingAddressOptions?.state != false }
    var isBillingAddressPostalCodeEnabled: Bool { billingAddressOptions?.postalCode != false }
    var isBillingAddressCountryEnabled: Bool { billingAddressOptions?.countryCode != false }
    
    init() {
        self.rawCardData = PrimerCardData(
            cardNumber: "",
            expiryDate: "",
            cvv: "",
            cardholderName: ""
        )
        
        // Initialize RawDataManager for card payments
        self.rawDataManager = try? PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: "PAYMENT_CARD",
            delegate: self,
            isUsedInDropIn: false // Using in CheckoutComponents
        )
    }
    
    func updateCardNumber(_ cardNumber: String) {
        rawCardData.cardNumber = cardNumber
        
        // Detect available networks for co-badged cards
        if let networks = detectAvailableNetworks(for: cardNumber), networks.count > 1 {
            availableNetworks = networks
            // Show network selection UI through scope state
        }
    }
    
    func selectCardNetwork(_ network: CardNetwork) {
        selectedNetwork = network
        rawCardData.cardNetwork = network
    }
    
    func getBillingAddress() -> ClientSession.Customer.BillingAddress? {
        guard billingAddressOptions != nil else { return nil }
        
        return ClientSession.Customer.BillingAddress(
            firstName: state.firstName.isEmpty ? nil : state.firstName,
            lastName: state.lastName.isEmpty ? nil : state.lastName,
            addressLine1: state.addressLine1.isEmpty ? nil : state.addressLine1,
            addressLine2: state.addressLine2.isEmpty ? nil : state.addressLine2,
            city: state.city.isEmpty ? nil : state.city,
            state: state.state.isEmpty ? nil : state.state,
            countryCode: state.countryCode.isEmpty ? nil : state.countryCode,
            postalCode: state.postalCode.isEmpty ? nil : state.postalCode
        )
    }
    
    func onSubmit() {
        // Send billing address if configured
        if let billingAddress = getBillingAddress() {
            // This will be handled by ProcessCardPaymentInteractor
        }
        
        // Use automatic payment handling
        rawDataManager?.rawData = rawCardData
        rawDataManager?.submit()
    }
}
```

### Co-Badged Cards Implementation

Based on the screenshots and existing `CardFormPaymentMethodTokenizationViewModel` implementation:

1. **Network Detection**
   - Detect multiple available networks from card BIN
   - Show network selection dropdown when multiple networks available
   - Update `PrimerCardData.cardNetwork` based on user selection

2. **UI Flow**
   - Initial state: No network selected (Screenshot 15.35.06)
   - Card recognized as co-badged: Show Cartes Bancaires logo with dropdown (Screenshot 15.35.30)
   - Dropdown open: Show available networks with current selection (Screenshot 15.35.24)
   - Network selected: Show checkmark and update UI (Screenshot 15.35.18)
   - Final state: Show selected network chip icon (Screenshot 15.35.12)

3. **Implementation Details**
```swift
// In CardNumberInput component
struct CardNumberInput: View {
    @EnvironmentObject var scope: DefaultCardFormScope
    
    var body: some View {
        HStack {
            TextField("Card number", text: $scope.cardNumber)
            
            // Co-badged card network selector
            if scope.availableNetworks.count > 1 {
                Menu {
                    ForEach(scope.availableNetworks, id: \.self) { network in
                        Button(action: { scope.selectCardNetwork(network) }) {
                            HStack {
                                Text(network.displayName)
                                if scope.selectedNetwork == network {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let selected = scope.selectedNetwork {
                            Image(selected.iconName)
                        } else {
                            Image("cartes_bancaires_logo")
                        }
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
    }
}
```

### 3DS Handling

1. **Automatic 3DS Flow**
   - RawDataManager handles 3DS flow automatically
   - Present SafariViewController for web redirects
   - Update scope state during 3DS process (isProcessing3DS)
   - Handle completion/cancellation through delegate callbacks

2. **Implementation**
```swift
// PrimerRawDataManagerDelegate implementation in DefaultCardFormScope
extension DefaultCardFormScope: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willPresentSafariViewControllerForURLRequest urlRequest: URLRequest) {
        // Update state to show 3DS in progress
        updateState(.isProcessing3DS(true))
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didCompleteSafariViewControllerFlow flow: String) {
        // 3DS completed, waiting for final result
        updateState(.isProcessing3DS(false))
    }
}
```

### Payment Flow Summary

1. **Initialization**
   - Create RawDataManager instance in CardFormScope
   - Set up PrimerCardData model

2. **Data Collection**
   - Update PrimerCardData as user types
   - Validate fields using existing validators
   - Handle co-badged card network selection

3. **Payment Submission**
   - Set rawDataManager.rawData with collected data
   - Call rawDataManager.submit()
   - Handle automatic payment flow including 3DS

4. **State Updates**
   - Convert delegate callbacks to scope state updates
   - Expose payment state through AsyncStream
   - Handle errors and success states

### Future Enhancements (Placeholders)

```swift
// TODO: Vaulting support
// When implementing vaulting:
// 1. Check if user opted in for saving card
// 2. Set appropriate flags in RawDataManager
// 3. Handle vault token in success response

// TODO: Advanced 3DS customization
// When implementing custom 3DS:
// 1. Allow custom Safari presentation style
// 2. Support custom loading indicators
// 3. Handle 3DS challenge parameters
```

## Navigation Implementation

Reuse the state-driven navigation from ComposableCheckout:
- **Copy**: `/ComposableCheckout/Navigation/` → `/CheckoutComponents/Internal/Navigation/`
- **Pattern**: State-driven navigation avoiding SwiftUI bugs
- **Coordinator**: Single source of truth for navigation state
- **iOS 15+**: Compatible without NavigationStack

## Scope Property Architecture Decision

For maximum flexibility and type safety, use **@ViewBuilder closures**:
```swift
public protocol PrimerCardFormScope: AnyObject {
    // Using ViewBuilder for type-safe, flexible composition
    var cardNumberInput: (@ViewBuilder () -> any View)? { get set }
    var cvvInput: (@ViewBuilder () -> any View)? { get set }
    
    // Alternative: For components that need parameters
    var submitButton: (@ViewBuilder (_ text: String) -> any View)? { get set }
}

// Default implementation
class DefaultCardFormScope: PrimerCardFormScope, ObservableObject {
    var cardNumberInput: (@ViewBuilder () -> any View)? = {
        CardNumberInput()
    }
}
```

Benefits:
- Type-safe without type erasure
- Supports SwiftUI modifiers
- Parameters can be passed where needed
- Modern Swift approach

## Dependency Injection Strategy

Use SwiftUI Environment for clean DI:
```swift
// In PrimerCheckout entry point
struct PrimerCheckout: View {
    @StateObject private var container = ComposableContainer()
    @StateObject private var designTokens = DesignTokensManager.shared
    
    var body: some View {
        InternalCheckout()
            .environmentObject(container)
            .environment(\.designTokens, designTokens.tokens)
    }
}

// In components
struct CardNumberInput: View {
    @EnvironmentObject var container: ComposableContainer
    @Environment(\.designTokens) var tokens
    
    var body: some View {
        // Use container and tokens
    }
}
```

## State Management Architecture

**No Combine Framework** - Use pure SwiftUI and async/await:
```swift
// Use @Published alternative with ObservableObject
@MainActor
class DefaultCardFormScope: PrimerCardFormScope, ObservableObject {
    // Use @Published for automatic UI updates
    @Published private(set) var cardNumber: String = ""
    @Published private(set) var isValid: Bool = false
    
    // Public async methods for merchants
    func submitPayment() async throws -> PaymentResult {
        // Implementation
    }
}

// For reactive state without Combine
@MainActor
class CheckoutViewModel: ObservableObject {
    @Published var state: CheckoutState = .loading
    
    // Use AsyncStream for event streams if needed
    var events: AsyncStream<CheckoutEvent> {
        AsyncStream { continuation in
            // Event emission
        }
    }
}
```

Benefits:
- No additional import required for merchants
- Clean async/await public API
- SwiftUI's built-in state management
- iOS 15+ native patterns

## Localization Strategy

Create dedicated localization for CheckoutComponents:
```swift
// Internal/Core/Localization/CheckoutComponentsLocalizable.swift
internal enum CheckoutComponentsLocalizable {
    // Card inputs
    static let cardNumberLabel = Strings.CardForm.cardNumberFieldTitle
    static let cardNumberPlaceholder = "1234 5678 9012 3456"
    static let cvvLabel = Strings.CardForm.cvvFieldTitle
    static let expiryLabel = Strings.CardForm.expiryFieldTitle
    
    // Address inputs
    static let postalCodeLabel = "Postal Code"
    static let cityLabel = "City"
    static let stateLabel = "State/Province"
    
    // Reuse existing translations where possible
    // Add new ones as needed
}
```

## Logging Implementation

All classes should adopt `LogReporter` protocol:
```swift
// Example in every major class
final class DefaultCardFormScope: PrimerCardFormScope, ObservableObject, LogReporter {
    
    init() {
        logger.debug(message: "DefaultCardFormScope initialized")
    }
    
    func updateCardNumber(_ number: String) {
        logger.debug(message: "Updating card number: \(number.masked())")
        // Implementation
    }
}

// In interactors
final class ProcessCardPaymentInteractor: LogReporter {
    func execute() async throws {
        logger.info(message: "Processing card payment")
        do {
            let result = try await repository.process()
            logger.info(message: "Card payment processed successfully")
            return result
        } catch {
            logger.error(message: "Card payment failed: \(error)")
            throw error
        }
    }
}
```

## Resource Management

Images and assets strategy:
- **Reuse existing icons** from PrimerSDK bundle
- **Card network logos**: Already available in existing SDK
- **No new image assets** needed for Phase 1
- Future phases may require payment method logos

## Error Handling Strategy

Use existing SDK error infrastructure:
```swift
// Reuse ErrorHandler for logging
ErrorHandler.handle(error: someError)

// Input validation errors
// Already handled by PrimerInputField - shows red text below field
struct CardNumberInput: View {
    @State private var errorMessage: String?
    
    var body: some View {
        PrimerInputField(
            value: cardNumber,
            onValueChange: updateCardNumber,
            isError: errorMessage != nil,
            validationError: errorMessage
        )
    }
}

// General errors - Create error screen
struct ErrorScreen: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
            }
        }
    }
}
```

## Theme Configuration

Pass settings through PrimerCheckout entry point like Android:
```swift
public struct PrimerCheckout: View {
    let clientToken: String
    let settings: PrimerSettings  // Includes theme configuration
    let scope: ((PrimerCheckoutScope) -> Void)?
    
    public init(
        clientToken: String,
        settings: PrimerSettings = PrimerSettings(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = scope
    }
}

// PrimerSettings should include theme options
extension PrimerSettings {
    var theme: PrimerTheme? { get set }
}
```

## Detailed File Mapping

### Files to Copy and Adapt

| Source (ComposableCheckout) | Destination (CheckoutComponents/Internal) | Changes Needed |
|----------------------------|-------------------------------------------|----------------|
| Core/DI/* | DI/* | Update imports, change namespace |
| Core/Validation/* | Core/Validation/* | Update imports only |
| Design/* | Tokens/* | Update imports only |
| PaymentMethods/Card/View/CardNumberInputField.swift | Presentation/Components/Input/CardNumberInput.swift | Remove callbacks, use scope |
| PaymentMethods/Card/View/CVVInputField.swift | Presentation/Components/Input/CVVInput.swift | Remove callbacks, use scope |
| PaymentMethods/Card/View/ExpiryDateInputField.swift | Presentation/Components/Input/ExpiryDateInput.swift | Remove callbacks, use scope |
| PaymentMethods/Card/View/CardholderNameInputField.swift | Presentation/Components/Input/CardholderNameInput.swift | Remove callbacks, use scope |
| PaymentMethods/Card/Validation/* | Core/Validation/Rules/* | Update imports only |

### Critical Implementation Notes

1. **Access Control Strategy**:
   - **Public**: Only `/Scope/` protocols and `PrimerCheckout.swift`
   - **Internal**: Everything under `/Internal/` uses `internal` modifier
   - **No @testable**: Testing deferred to post-beta phase

2. **Component Access Pattern**: Components are NEVER exposed directly. They're only accessible through scope properties:
   ```swift
   // ✅ Correct - through scope
   checkoutScope.cardForm.cardNumberInput = { CustomCardInput() }
   
   // ❌ Wrong - direct access
   CardNumberInput() // This is internal
   ```

3. **State Management**: All state flows through scope, no callbacks in components:
   ```swift
   // Component just displays, scope manages state
   struct CardNumberInput: View {
       @EnvironmentObject var scope: DefaultCardFormScope
       
       var body: some View {
           TextField("", text: $scope.cardNumber)
       }
   }
   ```

4. **Development Testing Integration**: 
   - Use PrimerUIManager as entry point during development
   - Add `.checkoutComponents` case to `CheckoutStyle` enum
   - Manual testing through existing SDK infrastructure
   ```swift
   // In PrimerUIManager
   case .checkoutComponents:
       let checkoutView = PrimerCheckout(
           clientToken: clientToken,
           settings: settings
       )
       let hostingController = UIHostingController(rootView: checkoutView)
       present(hostingController, animated: true)
   ```

5. **Headless SDK Usage**:
   - All payment operations go through `PrimerHeadlessUniversalCheckout`
   - Repository pattern wraps headless SDK with async/await
   - Tokenization, payment processing handled by existing infrastructure
   - **Billing Address**: Sent separately via Client Session Actions API:
     ```swift
     // In ProcessCardPaymentInteractor
     if let billingAddress = scope.getBillingAddress() {
         try await repository.setBillingAddress(billingAddress)
     }
     // Then proceed with card tokenization
     let token = try await repository.tokenizeCard(cardData)
     ```

6. **Validation Architecture**:
   - Create new validators for non-card fields
   - Follow existing pattern: Validator + Rule classes
   - Integrate with ValidationService from copied framework

7. **Country Selection Flow**:
   - Reuse `CountryCode` enum from existing SDK
   - Create SwiftUI picker component
   - Navigate via `navigateToCountrySelection()` in scope

8. **Navigation Architecture**:
   - Use state-driven navigation from ComposableCheckout
   - Avoid SwiftUI NavigationLink bugs documented in NAVIGATION_ARCHITECTURE_DECISION.md
   - Single coordinator manages all navigation state

9. **No Combine Imports**:
   - Use SwiftUI's built-in @Published (auto-imported)
   - Async/await for all asynchronous operations
   - AsyncStream for event streams where needed

## Success Criteria

1. ✅ Exact API parity with Android Composable module
2. ✅ All required input types supported with proper configuration
3. ✅ Clean architecture with strict public/internal separation
4. ✅ Full customization capability for every UI component
5. ✅ Seamless integration with existing PrimerSDK infrastructure
6. ✅ Reuse of all existing validation and input components
7. ✅ Proper logging throughout the implementation
8. ✅ Localization support for all user-facing strings
9. ✅ SwiftUI best practices with @ViewBuilder and Environment

## API Verification Summary

### Screenshots Added
✅ Added 6 design screenshots to `DesignScreenshots/` directory showing:
- Payment method selection
- Card form states (empty, filled, with errors)
- Success screen
- Visual validation feedback patterns

### Co-Badged Cards UI Flow
✅ Added 5 co-badged cards screenshots showing:
1. **Screenshot at 15.35.06.png**: Initial card form state without network selected
2. **Screenshot at 15.35.30.png**: Card with Cartes Bancaires logo and dropdown arrow
3. **Screenshot at 15.35.24.png**: Network selection dropdown menu open showing Visa and Cartes Bancaires options
4. **Screenshot at 15.35.18.png**: Visa selected in dropdown with checkmark
5. **Screenshot at 15.35.12.png**: Collapsed state showing Visa chip icon after selection

### Android API Parity Verification
✅ Analyzed Android Composable module structure
✅ Updated iOS scope definitions to match Android exactly:
- Same method names and signatures
- Same property names and types
- Same nested scope structure
- Same state management pattern

### Key API Changes Made
1. **Entry Point**: Now matches Android's callback pattern exactly
2. **State Management**: Using `AsyncStream<State>` instead of `StateFlow<State>`
3. **UI Customization**: Using `@ViewBuilder` closures instead of `@Composable`
4. **All Scopes**: Now have exact method/property parity with Android

## LLM Implementation Guide Summary

### Key Points for LLM Execution:
1. **This is NEW code, not a migration** - Fresh implementation inspired by Android
2. **Reuse existing card input fields** - They're tested and working, just update callbacks
3. **One git commit per phase** - Clear progression through implementation
4. **NO build verification** - LLM should not attempt to build or run the code
5. **Follow SOLID principles** - Clean architecture throughout
6. **iOS 15+ and Swift 6** - Use modern Swift features
7. **NO Combine imports** - Use SwiftUI's built-in @Published and AsyncStream
8. **Match Android API exactly** - But implement using iOS patterns internally

### File Organization:
- **Public API**: `/Scope/` directory only
- **Everything else**: Under `/Internal/` with proper subdirectories
- **Reuse from**: `/ComposableCheckout/` components where specified

### State Management:
- Android's StateFlow → iOS AsyncStream (provides same reactive flow)
- Internal: @Published properties for SwiftUI
- Public: AsyncStream for state observation
- NO Combine framework usage

### Critical Success Factors:
1. ✅ Exact API match with Android (methods, properties, scopes)
2. ✅ Reuse proven card input components
3. ✅ Follow iOS platform conventions internally
4. ✅ Clean separation of public API and internal implementation
5. ✅ Comprehensive logging with LogReporter
6. ✅ Design token integration for consistent styling

## Next Steps

1. ✅ Android API structure fully understood and matched
2. ✅ Design screenshots added for UI reference
3. ✅ All scope interfaces updated for exact API parity
4. ✅ Clear implementation phases with git commits
5. ✅ File paths and reuse strategy documented
6. **Ready for LLM to execute Phase 1 implementation**

---

*This LLM execution plan is complete with all necessary context and instructions for implementation.*