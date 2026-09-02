---
paths:
  - "Sources/PrimerSDK/Classes/CheckoutComponents/**/*.swift"
---

# Accessibility (CheckoutComponents)

WCAG 2.1 Level AA accessibility support (VoiceOver, Dynamic Type, keyboard navigation). All features are automatically applied.

## Key Patterns
- **Identifiers**: `checkout_components_{screen}_{component}_{element}` (snake_case). This is a cross-repo contract: the CC E2E page objects select on these strings. All identifiers live in the `AccessibilityIdentifiers` registry — never hardcode one in a view. Chrome rendered by shared components (the `Common` namespace: back, close, edit, done, delete, cancel, loading) omits the screen segment. Vaulted rows carry the vault token id: `checkout_components_vaulted_payment_method_{id}_item`.
- **Registry rules**: every declared member must have a call site (a Danger check warns when one does not). Dynamic builders take parameters from bounded, code-controlled domains (payment-method type, card network, country code). A rename must update the contract test (`AccessibilityIdentifiersContractTests`), the CC identifier convention doc in the e2e-tests repo, and the E2E page objects together.
- **Wrapped text fields**: the editable UIKit field inside an identified container carries `{container_id}_input`, built with `AccessibilityIdentifiers.inputField(within:)`, so UI tests can address the control directly.
- **Strings**: `accessibility_` key prefix in `Modules/PrimerResources/Sources/PrimerResources/Resources/CheckoutComponentsLocalizable/{LANG}.lproj/CheckoutComponentsStrings.strings` (57 languages); the Swift constants are the `a11y*` members of `CheckoutComponentsStrings`. Identifiers are never localized; labels and hints always are.
- **Fonts**: Use `PrimerFont` methods for automatic Dynamic Type scaling
- **Logging**: `logger.debug(message: "[A11Y] ...")` for debug-only accessibility logs

## Apply Accessibility (SwiftUI)
```swift
PrimerInputFieldContainer(...) { ... }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.cardNumberField,
        label: CheckoutComponentsStrings.a11yCardNumberLabel,
        hint: CheckoutComponentsStrings.a11yCardNumberHint,
        value: errorMessage,
        traits: []
      ),
      combinesChildren: false
    )
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

Contract: `Tests/Primer/CheckoutComponents/Accessibility/AccessibilityIdentifiersContractTests.swift`. Cross-platform convention: `CC_IDENTIFIER_CONVENTION.md` next to the CC scenario matrix in the e2e-tests repo.
