# Fix Failing Tests — Commit & Apply to PR Branches

## Changes ready (already applied, verified passing)

4 files changed, 8 insertions, 2 deletions:

1. **`DefaultCheckoutScope.swift`** — `paymentMethodScopeCache` from `private` to internal, moved to correct member order position
2. **`ApplePayPaymentMethodTests.swift`** — Pre-populate Apple Pay scope in test helper to avoid async race
3. **`PrimerDelegate.swift`** — Restore deprecated `primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod` call for backward compatibility
4. **`MockPrimerHeadlessUniversalCheckoutDelegate.swift`** — No net change (reverted to original typo name since deprecated call restored)

## Steps

1. Commit on `bn/feature/checkout-components`
2. Apply fixes to stacked PR branches:
   - `DefaultCheckoutScope.swift` → cc-13-scopes-container
   - `ApplePayPaymentMethodTests.swift` → cc-12-payment-methods
   - `PrimerDelegate.swift` → cc-03-sdk-refactors (already has this file's other changes)
   - `MockPrimerHeadlessUniversalCheckoutDelegate.swift` → cc-03-sdk-refactors (test utilities)
3. Push all affected branches
