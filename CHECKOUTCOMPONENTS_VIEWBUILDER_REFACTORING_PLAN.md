# CheckoutComponents ViewBuilder Refactoring Plan

## Executive Summary

**Key Goals:**
- ✅ Enable merchants to rearrange card form fields (e.g., cardholder name first)
- ✅ Replace broken PrimerModifier system with standard SwiftUI modifiers
- ✅ Allow interlacing of custom UI elements between Primer fields
- ✅ Provide clean, intuitive API matching SwiftUI conventions
- ✅ Complete PrimerCheckoutScope architecture refactoring
- ✅ PaymentMethodProtocol ViewBuilder pattern adoption
- ✅ Integration point updates across entire CheckoutComponents system

**Migration:** None needed - CheckoutComponents not yet released publicly

## Root Cause Analysis

### Fatal PrimerModifier Design Flaw

**Location:** `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Tokens/PrimerModifier.swift:72`

```swift
// BROKEN ARCHITECTURE:
internal var target: ModifierTarget = .container

func labelOnly() -> PrimerModifier {
    var copy = self
    copy.target = .labelOnly  // ← This overwrites the ENTIRE chain's target
    return copy
}
```

**Problem:** Single `target` property means `.background(.blue).inputOnly().foregroundColor(.red).labelOnly()` applies ALL modifiers to label only, instead of distributing them correctly.

### PrimerCheckoutScope Architectural Incompatibility

**PrimerCheckoutScope.setPaymentMethodScreen() Method:**
```swift
func setPaymentMethodScreen(
    _ paymentMethodType: PrimerPaymentMethodType,
    screenBuilder: @escaping (any PrimerPaymentMethodScope) -> AnyView
)
```

**Problem:** This method assumes closure-based scope customization, but ViewBuilder approach requires `@ViewBuilder` field functions.

## Reference Implementation

### ComposableCheckout Architecture (Reference Only)

**Key Reference File:** `/Users/boris/Downloads/ComposableCheckout/UIKitSupport/PrimerCheckoutViewController.swift`
- Shows clean UI manipulation patterns
- Demonstrates how merchants should be able to customize layouts
- No code extraction needed - use as inspiration only

**Other Reference Files:**
- `/Users/boris/Downloads/ComposableCheckout/PaymentMethods/Card/CardPaymentMethodScope.swift` - ViewBuilder protocol pattern
- `/Users/boris/Downloads/ComposableCheckout/PaymentMethods/Card/View/CardholderNameInputField.swift` - Clean field component
- `/Users/boris/Downloads/ComposableCheckout/PaymentMethods/Card/CardPaymentMethod.swift` - PaymentMethodProtocol pattern

**Key Patterns to Adopt:**
1. **@ViewBuilder field functions** instead of closures returning AnyView
2. **Standard SwiftUI modifiers** instead of custom PrimerModifier
3. **Individual field components** that can be arranged in any order
4. **ViewBuilder content pattern** for complete merchant control

## UPDATED COMPLETE IMPLEMENTATION PLAN

### Phase 0: Pre-Refactoring Analysis

**Files to Analyze:**
- All files importing/using PrimerCheckoutScope
- Find all `setPaymentMethodScreen()` and `getPaymentMethodScreen()` usages
- Integration points: CheckoutComponentsPrimer.swift, PrimerCheckout.swift
- Default implementations and navigation logic
- Showcase files using setPaymentMethodScreen() pattern

### Phase 1: Remove PrimerModifier System Completely

**Files to Modify:**
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Tokens/PrimerModifier.swift` - DELETE ENTIRELY
- All files using `PrimerModifier` - replace with standard SwiftUI ViewModifier

**Key Changes:**
1. Remove all PrimerModifier imports and usage
2. Remove `.primerModifier()` extension methods
3. Replace with standard SwiftUI modifier chaining

### Phase 1.5: PaymentMethodProtocol Architecture Update

**File to Modify:** `/Sources/PrimerSDK/Classes/CheckoutComponents/PaymentMethods/PaymentMethodProtocol.swift`

**Add ViewBuilder Content Method:**
```swift
@MainActor
protocol PaymentMethodProtocol: Identifiable {
    associatedtype ScopeType: PrimerPaymentMethodScope
    
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView
    
    @MainActor
    func defaultContent() -> AnyView
}
```

**Pattern Change:**
```swift
// OLD:
checkoutScope.setPaymentMethodScreen(.paymentCard) { scope in ... }

// NEW:
let cardMethod = checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self)
cardMethod.content { scope in ViewBuilder content }
```

### Phase 2: Refactor Existing Scope Protocol (IN-PLACE)

**⚠️ IMPORTANT: NO NEW FILES - REFACTOR EXISTING PROTOCOL IN-PLACE**

**File to Modify:** `/Sources/PrimerSDK/Classes/CheckoutComponents/Scope/PrimerCardFormScope.swift`

**Replace Existing Protocol (Complete Replacement):**
```swift
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope where State == PrimerCardFormState {
    // Replace ALL closure properties with @ViewBuilder field functions
    @ViewBuilder func PrimerCardholderNameField(label: String?) -> any View
    @ViewBuilder func PrimerCardNumberField(label: String?) -> any View  
    @ViewBuilder func PrimerCvvField(label: String?) -> any View
    @ViewBuilder func PrimerExpiryDateField(label: String?) -> any View
    @ViewBuilder func PrimerPostalCodeField(label: String?) -> any View
    @ViewBuilder func PrimerCountryField(label: String?) -> any View
    @ViewBuilder func PrimerCityField(label: String?) -> any View
    @ViewBuilder func PrimerStateField(label: String?) -> any View
    @ViewBuilder func PrimerAddressLine1Field(label: String?) -> any View
    @ViewBuilder func PrimerAddressLine2Field(label: String?) -> any View
    @ViewBuilder func PrimerFirstNameField(label: String?) -> any View
    @ViewBuilder func PrimerLastNameField(label: String?) -> any View
    @ViewBuilder func PrimerEmailField(label: String?) -> any View
    @ViewBuilder func PrimerPhoneNumberField(label: String?) -> any View
    // ... all other fields
    
    // Keep ALL existing methods for validation, navigation, state management:
    var state: AsyncStream<PrimerCardFormState> { get }
    var presentationContext: PresentationContext { get }
    func updateCardNumber(_ cardNumber: String)
    func updateCvv(_ cvv: String)
    func updateExpiryDate(_ expiryDate: String)
    func updateCardholderName(_ cardholderName: String)
    // ... ALL existing update methods
    func onSubmit()
    func onBack()
    func onCancel()
    func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)
    // ... ALL other existing functionality
}
```

**COMPLETELY REMOVE These Properties (Closure-Based):**
```swift
// DELETE ALL OF THESE FROM THE PROTOCOL:
var cardNumberInput: ((_ modifier: PrimerModifier) -> AnyView)?
var cvvInput: ((_ modifier: PrimerModifier) -> AnyView)?
var expiryDateInput: ((_ modifier: PrimerModifier) -> AnyView)?
var cardholderNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
var postalCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
var countryCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
var cityInput: ((_ modifier: PrimerModifier) -> AnyView)?
var stateInput: ((_ modifier: PrimerModifier) -> AnyView)?
var addressLine1Input: ((_ modifier: PrimerModifier) -> AnyView)?
var addressLine2Input: ((_ modifier: PrimerModifier) -> AnyView)?
var phoneNumberInput: ((_ modifier: PrimerModifier) -> AnyView)?
var firstNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
var lastNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
var retailOutletInput: ((_ modifier: PrimerModifier) -> AnyView)?
var otpCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
var submitButton: ((_ modifier: PrimerModifier, _ text: String) -> AnyView)?
var errorView: ((_ error: String) -> AnyView)?
var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> AnyView)?
// ... ALL closure-based properties - DELETE THEM ALL
```

### Phase 3: Refactor Field Components

**Pattern for Each Field Component:**
```swift
// Example: CardholderNameInputField.swift
struct CardholderNameInputField: View {
    let label: String?
    let placeholder: String
    let onCardholderNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // TextField implementation...
        }
    }
}

// Usage with standard SwiftUI modifiers:
CardholderNameInputField(label: "Cardholder Name", placeholder: "John Smith")
    .background(.blue)        // ← Standard SwiftUI modifier
    .padding()               // ← Standard SwiftUI modifier  
    .cornerRadius(8)         // ← Standard SwiftUI modifier
```

**Files to Refactor:**
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/InputFields/CardNumberInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/InputFields/CVVInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/InputFields/ExpiryDateInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/InputFields/CardholderNameInputField.swift`
- All other input field components in that directory

### Phase 2.5: PrimerCheckoutScope Major Refactoring

**File to Modify:** `/Sources/PrimerSDK/Classes/CheckoutComponents/Scope/PrimerCheckoutScope.swift`

**REMOVE COMPLETELY:**
```swift
func setPaymentMethodScreen(
    _ paymentMethodType: PrimerPaymentMethodType,
    screenBuilder: @escaping (any PrimerPaymentMethodScope) -> AnyView
)

func getPaymentMethodScreen(
    _ paymentMethodType: PrimerPaymentMethodType
) -> ((any PrimerPaymentMethodScope) -> AnyView)?
```

**PRESERVE:**
```swift
var container: ((_ content: @escaping () -> AnyView) -> AnyView)?
var splashScreen: (() -> AnyView)?
var loadingScreen: (() -> AnyView)?
var errorScreen: ((_ message: String) -> AnyView)?

func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T?
func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T?
```

### Phase 3: Field Components Refactoring

**Pattern for Each Field Component:**
```swift
// Example: CardholderNameInputField.swift
struct CardholderNameInputField: View {
    let label: String?
    let placeholder: String
    let onCardholderNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // TextField implementation...
        }
    }
}

// Usage with standard SwiftUI modifiers:
CardholderNameInputField(label: "Cardholder Name", placeholder: "John Smith")
    .background(.blue)        // ← Standard SwiftUI modifier
    .padding()               // ← Standard SwiftUI modifier  
    .cornerRadius(8)         // ← Standard SwiftUI modifier
```

**Files to Refactor:**
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/CardNumberInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/CVVInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/ExpiryDateInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/CardholderNameInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/PostalCodeInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/CountryInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/AddressLineInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/CityInputField.swift`  
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/StateInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/NameInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/EmailInputField.swift`
- `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Components/Inputs/OTPCodeInputField.swift`
- All other input field components in that directory

### Phase 3.5: Integration Points Update

**Files to Update:**

1. **CheckoutComponentsPrimer.swift**
   - Remove `setPaymentMethodScreen()` usage
   - Update payment method presentation for ViewBuilder approach
   - Ensure 3DS authentication continues working

2. **PrimerCheckout.swift**
   - Update SwiftUI integration for new payment method content pattern
   - Remove checkout scope screen customization dependencies

3. **Default Checkout Scope Implementations**
   - Update concrete PrimerCheckoutScope implementations
   - Remove setPaymentMethodScreen() implementation logic
   - Update navigation logic between scopes

4. **Navigation Logic**
   - Update navigation between checkout and payment method scopes
   - Ensure proper scope lifecycle management

### Phase 4: Update DefaultCardFormScope Implementation

**File to Modify:** `/Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultCardFormScope.swift`

**Remove All Field Builder Methods:**
```swift
// DELETE ALL OF THESE METHODS:
private func setupCardNumberFieldBuilder() { ... }
private func setupCvvFieldBuilder() { ... }
private func setupExpiryDateFieldBuilder() { ... }
// ... all other field builder methods
```

**Replace with ViewBuilder Field Functions:**
```swift
@ViewBuilder 
public func PrimerCardholderNameField(label: String? = nil) -> any View {
    CardholderNameInputField(
        label: label ?? "Cardholder Name",
        placeholder: "John Smith",
        onCardholderNameChange: { [weak self] name in
            self?.updateCardholderName(name)
        },
        onValidationChange: { [weak self] isValid in
            // Update validation state
        }
    )
}

@ViewBuilder 
public func PrimerCardNumberField(label: String? = nil) -> any View {
    CardNumberInputField(
        label: label ?? "Card Number", 
        placeholder: "1234 1234 1234 1234",
        // ... other parameters
    )
}

// ... implement all other field functions
```

### Phase 5: Enable Merchant Layout Control

**New Merchant Usage Pattern:**

**OLD:**
```swift
checkoutScope.setPaymentMethodScreen(.paymentCard) { scope in
    scope.cardNumberInput = { modifier in AnyView(...) }
    return CustomCardFormView(scope: scope)
}
```

**NEW:**
```swift
let cardMethod = checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self)
cardMethod.content { scope in
    VStack(spacing: 16) {
        // CARDHOLDER NAME FIRST! 🎯
        scope.PrimerCardholderNameField(label: "Full Name")
            .background(.blue.opacity(0.1))
            .padding()
        
        // Custom merchant UI between Primer fields
        MyCustomDiscountCodeField()
            .background(.yellow.opacity(0.1))
        
        scope.PrimerCardNumberField(label: "Card Number")
            .background(.green.opacity(0.1))
            
        HStack(spacing: 12) {
            scope.PrimerExpiryDateField(label: "MM/YY")
            scope.PrimerCvvField(label: "CVV")
        }
        .background(.red.opacity(0.1))
        
        MyCustomTermsView()
            .padding(.top)
    }
}
```

### Phase 6: Update Showcase Examples

**File to Update:** `/Debug App/Sources/View Controllers/CheckoutComponents/CheckoutComponentsShowcase/ColorfulThemedCardFormDemo.swift`

**Update Existing Showcase:**
- Update ColorfulThemedCardFormDemo.swift to demonstrate ViewBuilder approach with field rearrangement (cardholder name first)
- Show standard SwiftUI modifier usage instead of PrimerModifier
- Demonstrate interlacing custom UI elements between Primer fields
- Preserve exact same visual appearance to verify UI consistency

**No New Files:** Test everything on the existing ColorfulThemedCardFormDemo first before creating additional showcase examples

## Implementation Details for LLM

### Critical Context

**NO MIGRATION NEEDED:**
- CheckoutComponents not released publicly yet
- Complete in-place replacement is safe
- No historical compatibility concerns
- No need to maintain old PrimerModifier system

**⚠️ REFACTORING RULES:**
- **Avoid versioned files unless contextually appropriate** - prefer refactoring existing files in-place over creating files with V2, V3 suffixes when the goal is to replace existing functionality
- **ALWAYS refactor existing files in-place** (rename classes, protocols, methods as needed)
- **NO "versioned" approaches for this refactoring** - treat this as a normal architectural update
- **Replace, don't append** - completely transform existing code
- **UI CONSISTENCY CRITICAL**: All UI must look exactly the same after refactoring - no visual differences except improvements
- **Navigation Preservation**: All navigation flows must work identically to current implementation

**Key Files to Focus On:**

1. **Protocol Definition:** `PrimerCardFormScope.swift`
   - Replace closure properties with @ViewBuilder functions
   - Remove all PrimerModifier dependencies

2. **Implementation:** `DefaultCardFormScope.swift` 
   - Remove all field builder setup methods
   - Implement @ViewBuilder field functions directly
   - Maintain state management and validation logic

3. **Field Components:** All files in `InputFields/` directory
   - Remove PrimerModifier parameters
   - Accept standard SwiftUI styling
   - Keep existing functionality (validation, callbacks)

4. **Showcase Updates:** `CheckoutComponentsShowcase/` directory
   - Create examples showing field rearrangement
   - Demonstrate standard SwiftUI modifier usage
   - Show custom UI interlacing

### Validation Requirements

**Must Work After Refactoring:**
- ✅ All existing validation logic preserved
- ✅ State management continues working  
- ✅ Field callbacks and updates function correctly
- ✅ Submit button enablement based on validation
- ✅ All payment processing flows intact

**New Capabilities Enabled:**
- ✅ Merchants can rearrange fields (cardholder name first)
- ✅ Standard SwiftUI modifiers work correctly
- ✅ Custom UI elements can be interlaced
- ✅ Clean, intuitive API matching SwiftUI patterns

### Field Component Customization

**YES - This Plan Ensures Full Field Customization:**

**✅ Individual Field Styling:**
```swift
// Merchants can style each field independently
scope.PrimerCardholderNameField(label: "Full Name")
    .background(.blue)
    .padding()
    .cornerRadius(12)
    .shadow(radius: 2)

scope.PrimerCardNumberField(label: "Card Number")
    .background(.green)
    .font(.title2)
    .border(.gray, width: 1)
```

**✅ Field Arrangement Control:**
```swift
// Present cardholder name FIRST (your specific request)
VStack {
    scope.PrimerCardholderNameField()  // FIRST!
    scope.PrimerCardNumberField()      // SECOND!
    scope.PrimerExpiryDateField()      // THIRD!
    scope.PrimerCvvField()             // FOURTH!
}
```

**✅ Custom UI Between Fields:**
```swift
VStack {
    scope.PrimerCardholderNameField()
    
    // Custom merchant component between Primer fields
    MyCustomDiscountCodeField()
        .background(.yellow)
    
    scope.PrimerCardNumberField()
    
    // Another custom component
    MyCustomTermsAndConditionsView()
}
```

**✅ All Default Features Preserved:**
- **Validation**: All field validation logic stays intact
- **State Management**: updateCardNumber(), updateCvv(), etc. continue working
- **Submit Logic**: onSubmit(), button enablement, payment processing unchanged
- **Error Handling**: All error states and messaging preserved
- **3DS Authentication**: All payment flows continue working
- **Co-badged Cards**: Network selection functionality preserved
- **Billing Address**: All address field validation and collection unchanged
- **Surcharge**: All surcharge amount calculation and display functionality preserved

**Key Insight:** The refactoring only changes **HOW** fields are presented to merchants (ViewBuilder vs closures), not **WHAT** the fields do internally. All the validation, state management, and payment processing logic remains exactly the same.

## Success Criteria

### Before Implementation:
❌ CVV labels invisible due to PrimerModifier targeting conflicts  
❌ Cannot rearrange fields (cardholder name first impossible)  
❌ Cannot interlace custom UI between fields  
❌ Complex, broken modifier targeting system  

### After Implementation:
✅ All field labels visible with proper styling  
✅ Merchants can present cardholder name first  
✅ Custom UI elements work between Primer fields  
✅ Standard SwiftUI modifier chaining works correctly  
✅ Clean, intuitive API matching SwiftUI conventions  


---

## Architecture Changes Summary

### What Changes:
1. **PrimerModifier System** → **Standard SwiftUI Modifiers**
2. **Closure-based Field Properties** → **@ViewBuilder Field Functions**
3. **Checkout Scope Screen Mediation** → **Direct Payment Method Content**
4. **Fixed Field Order** → **Complete Field Rearrangement**
5. **Custom Modifier Targeting** → **Standard SwiftUI Composition**

### What Stays The Same:
- All validation logic and state management
- Payment processing flows and 3DS authentication
- Error handling and navigation
- Container-level customization (splashScreen, loadingScreen, etc.)
- All existing functionality merchants rely on

### New Capabilities Enabled:
- ✅ Present cardholder name field first
- ✅ Rearrange fields in any order
- ✅ Interlace custom UI elements between Primer fields
- ✅ Use standard SwiftUI modifiers throughout
- ✅ Clean, familiar API matching SwiftUI conventions
- ✅ Complete layout control for merchants

**Note for LLM:** This is a complete architectural refactoring with no backward compatibility concerns. Use ComposableCheckout files as reference for patterns, but implement everything fresh for the current CheckoutComponents architecture. Must implement all phases including PrimerCheckoutScope changes, PaymentMethodProtocol updates, and integration point modifications.