---
paths:
  - "Sources/PrimerSDK/Classes/CheckoutComponents/**/*.swift"
---

# CheckoutComponents (iOS 15+)

## Architecture
- Scope-based API: `PrimerCheckoutScope`, `PrimerCardFormScope`, `PrimerPaymentMethodSelectionScope`
- Dependency injection via `ComposableContainer` — register/resolve pattern with retention policies
- AsyncStream state observation for reactive updates

## Key Directories
```
CheckoutComponents/
├── Core/          # DI container, configuration
├── Scope/         # Public scope APIs (merchant-facing)
├── PaymentMethods/ # Payment method implementations
└── Internal/      # Internal UI components, screens
```

## Features
- Co-badged cards support
- Dynamic billing address
- Built-in 3DS handling
- Full UI customization via `PrimerTheme`

## Conventions
- All scopes are `public protocol` with `@available(iOS 15.0, *)`
- Use `func make...() -> some View` for extracted view pieces
- Register dependencies in container setup, resolve via `await container.resolve()`
