# Quickstart: Bank Selector Scope for CheckoutComponents

**Feature Branch**: `003-bank-selector`
**Date**: 2026-02-09

## Overview

The bank selector scope enables bank-based payment methods (iDEAL, Dotpay) in CheckoutComponents. Customers see a searchable list of banks, select one, and are redirected to the bank's authentication page to complete the payment.

## Integration (Merchant Perspective)

### Minimal — Default UI

No additional code needed. If iDEAL or Dotpay is enabled in the client session, the bank selector appears automatically in the payment method selection screen.

```swift
PrimerCheckout(
    clientToken: clientToken,
    primerSettings: settings,
    scope: { checkout in
        // Bank selector works automatically when iDEAL/Dotpay is enabled
    },
    onCompletion: { result in
        // Handle payment result
    }
)
```

### Custom Bank Item Appearance

```swift
PrimerCheckout(
    clientToken: clientToken,
    primerSettings: settings,
    scope: { checkout in
        checkout.bankSelector { bankSelector in
            bankSelector.bankItemComponent = { bank in
                HStack {
                    AsyncImage(url: bank.iconUrl) { image in
                        image.resizable().frame(width: 32, height: 32)
                    } placeholder: {
                        Color.gray.frame(width: 32, height: 32)
                    }
                    Text(bank.name)
                        .font(.body)
                    Spacer()
                    if bank.isDisabled {
                        Text("Unavailable")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
)
```

### Fully Custom Screen

```swift
checkout.bankSelector { bankSelector in
    bankSelector.screen = { scope in
        MyCustomBankSelectorView(scope: scope)
    }
}
```

### State Observation (Custom UI)

```swift
// In a custom view observing bank selector state:
Task {
    for await state in bankSelectorScope.state {
        switch state.status {
        case .loading:
            showLoadingIndicator()
        case .ready:
            updateBankList(state.filteredBanks)
        case .selected(let bank):
            showSelectedBank(bank)
        }
    }
}

// Search
bankSelectorScope.search(query: searchText)

// Select a bank (immediately triggers payment)
bankSelectorScope.selectBank(bank)
```

## Architecture

### File Structure

```
Sources/PrimerSDK/Classes/CheckoutComponents/
├── Scope/
│   ├── PrimerBankSelectorScope.swift            # Public protocol
│   └── ComponentTypeAliases.swift               # Modified: + BankSelectorScreenComponent, BankItemComponent
├── PaymentMethods/
│   └── BankSelector/
│       ├── BankSelectorPaymentMethod.swift       # PaymentMethodProtocol + registration
│       ├── BankSelectorState.swift               # Public state model
│       └── Bank.swift                            # Public bank model
└── Internal/
    ├── Domain/
    │   ├── Interactors/
    │   │   └── ProcessBankSelectorPaymentInteractor.swift
    │   └── Repositories/
    │       └── BankSelectorRepository.swift
    ├── Presentation/
    │   ├── Scope/
    │   │   └── DefaultBankSelectorScope.swift     # Scope implementation
    │   └── Screens/
    │       └── BankSelectorScreen.swift           # Default SwiftUI screen
    ├── Constants/
    │   └── CheckoutComponentsStrings.swift        # Modified: + bank selector strings
    └── Accessibility/Domain/
        └── AccessibilityIdentifiers.swift         # Modified: + BankSelector enum

Tests/Primer/CheckoutComponents/BankSelector/
├── ProcessBankSelectorPaymentInteractorTests.swift
├── DefaultBankSelectorScopeTests.swift
├── BankSelectorStateTests.swift
└── Mocks/
    └── MockProcessBankSelectorPaymentInteractor.swift
```

### Data Flow

```
1. start() called
   → Interactor.fetchBanks() → Repository.listBanks() → API
   → State: .loading → .ready(banks)

2. search(query:) called
   → Local filtering (case/diacritics-insensitive)
   → State: .ready (filteredBanks updated)

3. selectBank(bank) called
   → State: .selected(bank)
   → checkoutScope.startProcessing()
   → Interactor.execute(bankId:) → Repository.tokenizeAndProcess()
   → On success: checkoutScope.handlePaymentSuccess(result)
   → On failure: checkoutScope.handlePaymentError(error)
```

### Key Patterns

- **Scope lifecycle**: `start()` fetches banks, `selectBank()` triggers payment, `cancel()`/`onBack()` navigates away
- **Error handling**: All errors delegated to checkout scope's standard ErrorScreen
- **State scope**: Only loading/ready/selected; processing/success/failure handled by checkout scope
- **Registration**: `BankSelectorPaymentMethod.registerAll()` registers both iDEAL and Dotpay
- **Customization**: 2-level — screen replacement via `screen` or component-level via `bankItemComponent`, `searchBarComponent`, `emptyStateComponent`
- **Accessibility**: All interactive elements annotated with `AccessibilityIdentifiers.BankSelector.*` + VoiceOver labels/hints from `CheckoutComponentsStrings`
- **Analytics**: Reuses existing event types — `paymentMethodSelection`, `paymentSubmitted`, `paymentRedirectToThirdParty` — fire-and-forget via `analyticsInteractor`
- **Translations**: All user-facing text via `CheckoutComponentsStrings` with `NSLocalizedString` (41 languages)

## Testing

### Unit Tests (Phase 9 — ~20 tests across 3 files)
- `ProcessBankSelectorPaymentInteractorTests`: AdyenBank→Bank mapping, execute delegation, error propagation
- `DefaultBankSelectorScopeTests`: State transitions (loading→ready→selected), search filtering (case/diacritics-insensitive), disabled bank rejection, error delegation, empty bank list handling
- `BankSelectorStateTests`: Default initialization, Status equality, Equatable conformance

### Integration Tests
- End-to-end flow with ADYEN_IDEAL via Debug App
- End-to-end flow with ADYEN_DOTPAY via Debug App
- Back/cancel navigation in both direct and fromPaymentSelection contexts
- VoiceOver navigation through all interactive elements
- Analytics event capture verification
