---
paths:
  - "Sources/PrimerSDK/Classes/CheckoutComponents/**/*.swift"
---

# Accessibility (CheckoutComponents)

WCAG 2.1 Level AA accessibility support (VoiceOver, Dynamic Type, keyboard navigation). All features are automatically applied.

## Key Patterns
- **Identifiers**: `checkout_components_{screen}_{component}_{element}` (snake_case, API contract)
- **Strings**: `a11y.` prefix in Localizable.strings (41 languages)
- **Fonts**: Use `PrimerFont` methods for automatic Dynamic Type scaling
- **Logging**: `logger.debug(message: "[A11Y] ...")` for debug-only accessibility logs

## Apply Accessibility (SwiftUI)
```swift
TextField("Label", text: $value)
    .accessibility(config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.field,
        label: CheckoutComponentsStrings.a11y_label,
        hint: CheckoutComponentsStrings.a11y_hint,
        traits: [.isTextField]
    ))
```

## VoiceOver Announcements
```swift
let service: AccessibilityAnnouncementService = await container.resolve()
service.announceError("Invalid card number")
```

## Keyboard Navigation
```swift
@FocusState private var focusedField: PrimerInputElementType?

TextField("Card Number", text: $cardNumber)
    .focused($focusedField, equals: .cardNumber)
    .onSubmit { focusedField = .expiry }
```

Resources: `specs/001-checkout-components-accessibility/quickstart.md`
