# CheckoutComponents API Migration Guide

This document summarizes all breaking changes to the CheckoutComponents public API. Use this to update public documentation and integration guides.

---

## 1. `onSubmit()` / `onCancel()` / `pay()` removed — use `submit()` / `cancel()`

All payment method scopes now use `submit()` and `cancel()` consistently. Duplicate methods have been removed.

| Scope | Removed | Replacement |
|---|---|---|
| `PrimerCardFormScope` | `onSubmit()` | `submit()` (inherited from base) |
| `PrimerCardFormScope` | `onCancel()` | `cancel()` (inherited from base) |
| `PrimerApplePayScope` | `pay()` | `submit()` (inherited from base) |
| `PrimerPayPalScope` | `onCancel()` | `cancel()` (inherited from base) |
| `PrimerKlarnaScope` | `onCancel()` | `cancel()` (inherited from base) |
| `PrimerAchScope` | `onCancel()` | `cancel()` (inherited from base) |
| `PrimerPaymentMethodSelectionScope` | `onCancel()` | `cancel()` |
| `PrimerSelectCountryScope` | `onCancel()` | `cancel()` |

**Before:**
```swift
cardFormScope.onSubmit()
applePayScope.pay()
scope.onCancel()
```

**After:**
```swift
cardFormScope.submit()
applePayScope.submit()
scope.cancel()
```

---

## 2. `onBack()` / `onCancel()` removed from payment method scope protocols

`onBack()` and `onCancel()` declarations have been removed from `PrimerPayPalScope`, `PrimerKlarnaScope`, and `PrimerAchScope`. These methods are inherited from the base `PrimerPaymentMethodScope` protocol.

---

## 3. `presentationContext` / `dismissalMechanism` moved to base protocol

These properties are no longer declared in individual scope protocols. They are now part of `PrimerPaymentMethodScope` with defaults:

- `presentationContext`: defaults to `.fromPaymentSelection`
- `dismissalMechanism`: defaults to `[]`

**Removed from:** `PrimerCardFormScope`, `PrimerPayPalScope`, `PrimerKlarnaScope`, `PrimerAchScope`

No code changes needed if you access these properties on scope instances — they still exist via the base protocol.

---

## 4. Property renames

| Scope | Old Name | New Name |
|---|---|---|
| `PrimerCardFormScope` | `errorView` | `errorScreen` |
| `PrimerCardFormScope` | `submitButtonSection` | `submitButton` |
| `PrimerCheckoutScope` | `loading` | `loadingScreen` |
| `PrimerPayPalState` | `Status` (enum) | `Step` |
| `PrimerPayPalState` | `status` (property) | `step` |

**Before:**
```swift
cardFormScope.errorView = { message in ... }
cardFormScope.submitButtonSection = { ... }
checkoutScope.loading = { ... }
payPalState.status == .loading
```

**After:**
```swift
cardFormScope.errorScreen = { message in ... }
cardFormScope.submitButton = { ... }
checkoutScope.loadingScreen = { ... }
payPalState.step == .loading
```

---

## 5. Apple Pay scope properties removed — use state instead

The following properties have been removed from `PrimerApplePayScope` protocol. Access them through the `state` AsyncStream via `PrimerApplePayState`:

| Removed Property | Access via State |
|---|---|
| `isAvailable` | `state.isAvailable` |
| `availabilityError` | `state.availabilityError` |
| `buttonStyle` | `state.buttonStyle` |
| `buttonType` | `state.buttonType` |
| `cornerRadius` | `state.cornerRadius` |

**Before:**
```swift
if applePayScope.isAvailable {
    // ...
}
```

**After:**
```swift
for await state in applePayScope.state {
    if state.isAvailable {
        // ...
    }
}
```

---

## 6. `selectedVaultedPaymentMethod` removed from `PrimerPaymentMethodSelectionScope`

Access the selected vaulted payment method through the state instead:

**Before:**
```swift
if let method = selectionScope.selectedVaultedPaymentMethod { ... }
```

**After:**
```swift
for await state in selectionScope.state {
    if let method = state.selectedVaultedPaymentMethod { ... }
}
```

---

## 7. `CheckoutPaymentResult` removed from public API

`CheckoutPaymentResult` has been replaced by `PaymentResult` in all public-facing APIs.

**Affected API:** `CardFormProvider.onSuccess` callback

**Before:**
```swift
CardFormProvider(
    onSuccess: { (result: CheckoutPaymentResult) in
        print(result.paymentId)
        print(result.amount)  // String
    }
)
```

**After:**
```swift
CardFormProvider(
    onSuccess: { (result: PaymentResult) in
        print(result.paymentId)
        print(result.status)          // PaymentStatus enum
        print(result.amount)          // Int? (minor units)
        print(result.currencyCode)    // String?
        print(result.paymentMethodType) // String?
    }
)
```
