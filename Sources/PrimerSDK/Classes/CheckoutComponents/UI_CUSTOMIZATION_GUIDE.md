# CheckoutComponents UI Customization Guide

This guide explains how to completely customize the UI of CheckoutComponents screens while maintaining the scope-based architecture and business logic.

## Overview

CheckoutComponents provides multiple levels of UI customization:

1. **Complete Screen Replacement** - Replace entire screens with custom implementations
2. **Section Customization** - Override specific sections of a screen
3. **Component Customization** - Replace individual UI components
4. **Styling Customization** - Apply custom styles to existing components

## Complete Screen Replacement

### Payment Method Selection Screen

You can completely replace the payment method selection screen by setting the `screen` property:

```swift
// In your scope customization
checkoutScope.paymentMethodSelection.screen = {
    AnyView(CustomPaymentSelectionScreen(scope: checkoutScope.paymentMethodSelection))
}
```

Your custom screen should:
1. Observe the scope's state stream
2. Call appropriate scope methods (onPaymentMethodSelected, onCancel)
3. Handle all UI interactions

Example custom screen:

```swift
struct CustomPaymentSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope
    @State private var selectionState = PrimerPaymentMethodSelectionState()
    
    var body: some View {
        // Your completely custom UI
        ZStack {
            // Custom background
            LinearGradient(...)
            
            VStack {
                // Custom header
                customHeader
                
                // Custom payment method list
                ForEach(selectionState.paymentMethods) { method in
                    customPaymentMethodCard(method)
                }
            }
        }
        .onAppear { observeState() }
    }
    
    private func observeState() {
        Task {
            for await state in scope.state {
                self.selectionState = state
            }
        }
    }
}
```

### Card Form Screen

Similarly for card forms:

```swift
cardFormScope.screen = { scope in
    AnyView(CustomCardFormScreen(scope: scope))
}
```

## Section-Level Customization

### Payment Method Selection Components

Customize specific parts while keeping the default structure:

```swift
// Custom category headers
scope.paymentMethodSelection.categoryHeader = { category in
    AnyView(
        HStack {
            Image(systemName: "star.fill")
            Text(category)
                .bold()
        }
        .padding()
        .background(Color.purple)
        .cornerRadius(8)
    )
}

// Custom payment method items
scope.paymentMethodSelection.paymentMethodItem = { method in
    AnyView(CustomPaymentMethodCard(method: method, onTap: {
        scope.onPaymentMethodSelected(paymentMethod: method)
    }))
}

// Custom empty state
scope.paymentMethodSelection.emptyStateView = {
    AnyView(
        VStack {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
            Text("No payment methods available")
        }
    )
}
```

### Card Form Sections

For card forms, you can customize entire sections:

```swift
// Custom card input section
cardFormScope.cardInputSection = {
    AnyView(CustomCardInputSection(scope: cardFormScope))
}

// Custom billing address section
cardFormScope.billingAddressSection = {
    AnyView(CustomBillingAddressSection(scope: cardFormScope))
}
```

## Field-Level Customization

Customize individual input fields using closure properties:

```swift
// Custom card number field
cardFormScope.cardNumberField = { label, styling in
    AnyView(
        CustomCardNumberField(
            label: label,
            value: cardFormScope.state.cardNumber,
            onChange: cardFormScope.updateCardNumber
        )
    )
}

// Custom expiry date field
cardFormScope.expiryDateField = { label, styling in
    AnyView(
        CustomExpiryField(
            label: label,
            onMonthChange: cardFormScope.updateExpiryMonth,
            onYearChange: cardFormScope.updateExpiryYear
        )
    )
}

// Custom CVV field
cardFormScope.cvvField = { label, styling in
    AnyView(
        CustomCVVField(
            label: label,
            onChange: cardFormScope.updateCvv
        )
    )
}
```

**Note**: CheckoutComponents uses a single, consistent approach for UI customization through closure properties. This provides a clean API that matches Android's pattern exactly.

## Styling Without Full Replacement

Apply custom styles to default components:

```swift
// Set default field styling
cardFormScope.defaultFieldStyling = [
    "cardNumber": PrimerFieldStyling(
        inputTextColor: .white,
        inputBackgroundColor: .purple,
        borderColor: .clear,
        borderWidth: 0,
        cornerRadius: 12
    )
]
```

## Complete UI Theming

For app-wide theming without overriding individual screens:

### Option 1: Custom Design Tokens

Create custom design tokens and inject them:

```swift
struct CustomDesignTokens: DesignTokens {
    var primerColorBackground: Color { Color.purple.opacity(0.1) }
    var primerColorTextPrimary: Color { Color.white }
    // ... other tokens
}

// Apply in your view
MyView()
    .environment(\.designTokens, CustomDesignTokens())
```

### Option 2: Container Wrapping

Use the CheckoutScope's container property:

```swift
checkoutScope.container = { content in
    AnyView(
        ZStack {
            // Custom background
            LinearGradient(...)
                .ignoresSafeArea()
            
            // Original content
            content()
        }
    )
}
```

## Best Practices

1. **Maintain State Observation**: Always observe the scope's state stream
2. **Call Scope Methods**: Use scope methods for actions (don't bypass business logic)
3. **Handle All States**: Consider loading, error, and empty states
4. **Preserve Accessibility**: Ensure custom UI remains accessible
5. **Test Thoroughly**: Test all payment flows with custom UI

## Common Patterns

### Animated Backgrounds

```swift
struct AnimatedBackgroundWrapper<Content: View>: View {
    let content: Content
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Animated shapes
            ForEach(0..<3) { index in
                Circle()
                    .fill(LinearGradient(...))
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 3).repeatForever())
            }
            
            content
        }
        .onAppear { animate = true }
    }
}
```

### Floating Card Design

```swift
struct FloatingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 20)
            )
            .padding()
    }
}
```

### Custom Transitions

```swift
extension AnyTransition {
    static var customSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}
```

## Migration from Design Tokens

If you're currently using design tokens override and want more control:

1. Identify which screens need custom UI
2. Create custom screen implementations
3. Set the scope's screen property
4. Remove design token overrides
5. Test all flows

This approach gives you complete control while maintaining the CheckoutComponents architecture and payment processing logic.