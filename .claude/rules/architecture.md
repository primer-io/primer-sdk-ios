---
paths:
  - "Sources/**/*.swift"
---

# Architecture

## Entry Points
- **`Primer.swift`**: Main SDK singleton (`Primer.shared`) — `configure(settings:delegate:)`, `showUniversalCheckout(clientToken:)`
- **`PrimerDelegate.swift`**: Primary callback protocol for checkout lifecycle events

## Checkout Integration Approaches

1. **Drop-In UI**: `Sources/.../User Interface/Root/PrimerUniversalCheckoutViewController.swift` — fully managed UI, entry via `Primer.shared.showUniversalCheckout(clientToken:)`
2. **Headless**: `Sources/.../Core/PrimerHeadlessUniversalCheckout/` — custom UI with SDK payment logic
3. **CheckoutComponents (iOS 15+)**: `Sources/.../CheckoutComponents/` — SwiftUI-based modular components with exact Android API parity, scope-based architecture
   - SwiftUI: `PrimerCheckout(clientToken:primerSettings:primerTheme:scope:onCompletion:)`
   - UIKit: `PrimerCheckoutPresenter.presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)`

## Payment Flow
1. Generate client token from backend (create client session)
2. Initialize SDK with `Primer.shared.configure(delegate:)`
3. Present checkout UI or use headless/components
4. SDK handles tokenization, 3DS (if required), and payment processing
5. Receive result via `PrimerDelegate` callbacks

## Error Handling
Three error types, all conforming to `PrimerErrorProtocol` (`errorId`, `diagnosticsId`, `exposedError`):
- **`PrimerError`** (`public enum`, ~40 cases) — merchant-facing errors
- **`PrimerValidationError`** (`public enum`) — field validation errors
- **`InternalError`** (internal) — network/decode errors, never exposed directly

Patterns:
- `async throws` throughout — no `Result` types
- `handled(error:)` / `handled(primerError:)` — log via `ErrorHandler` and return for rethrowing
- `error.normalizedForSDK` — boundary normalization before surfacing to merchants
- `PrimerDelegateProxy` calls `error.exposedError` before dispatching to merchant callbacks

Key files: `Sources/.../Error Handler/PrimerError.swift`, `PrimerInternalError.swift`, `ErrorExtension.swift`

## Public API Conventions
- `public` for merchant-facing API, no modifier for internal (never write `internal`)
- Drop-In delegates are `@objc public protocol` (ObjC interop)
- CheckoutComponents scopes are `public protocol` with `@available(iOS 15.0, *)`
- Adding or changing `public` API signatures requires careful review — breaking changes for merchants
