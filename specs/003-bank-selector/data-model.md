# Data Model: Bank Selector Scope

**Feature Branch**: `003-bank-selector`
**Date**: 2026-02-09

## Entities

### Bank (Public — exposed to merchants via scope)

Represents a selectable bank institution in the bank selector UI.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique bank identifier (e.g., "1121" for ING) — used as issuer in tokenization |
| name | String | Yes | Display name (e.g., "ING Bank") |
| iconUrl | URL? | No | URL for bank logo image, loaded asynchronously |
| isDisabled | Bool | Yes | Whether the bank is currently unavailable for selection |

**Source**: Maps from existing `Response.Body.Adyen.Bank` (aliased as `AdyenBank`) returned by the bank list API.

**Mapping**:
- `Bank.id` ← `AdyenBank.id`
- `Bank.name` ← `AdyenBank.name`
- `Bank.iconUrl` ← `URL(string: AdyenBank.iconUrlStr)`
- `Bank.isDisabled` ← `AdyenBank.disabled`

**Notes**: This is a new public-facing model specific to CheckoutComponents. It decouples the public API from the internal `AdyenBank` type, matching how `IssuingBank` decouples the Headless API.

---

### BankSelectorState (Public — exposed via AsyncStream)

Represents the current state of the bank selection flow within the scope.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| status | BankSelectorStatus | Yes | Current phase of the bank selection flow |
| banks | [Bank] | Yes | Full list of available banks (empty during loading) |
| filteredBanks | [Bank] | Yes | Banks filtered by search query (equals `banks` when no search) |
| selectedBank | Bank? | No | The bank the customer selected (nil until selection) |
| searchQuery | String | Yes | Current search text (empty string by default) |

**State Machine**:

```
          start()
            │
            ▼
        ┌────────┐
        │loading │
        └───┬────┘
            │ banks fetched
            ▼
        ┌────────┐    search(query:)     ┌────────┐
        │ ready  │◄────────────────────►│ ready  │ (filteredBanks updated)
        └───┬────┘                       └────────┘
            │ selectBank(_:)
            ▼
        ┌──────────┐
        │ selected │ → delegates to checkout scope
        └──────────┘
```

**BankSelectorStatus Enum**:

| Case | Description |
|------|-------------|
| `.loading` | Bank list is being fetched from the API |
| `.ready` | Bank list loaded and displayed; user can search and select |
| `.selected(Bank)` | User has selected a bank; payment flow handed to checkout scope |

**Notes**:
- `selected` includes the selected bank for merchant observation convenience
- Processing, success, and failure states are managed by the parent checkout scope (per clarification)
- Error during bank list fetch delegates to checkout scope's standard ErrorScreen

---

### BankSelectorPaymentMethodType (Internal — used by interactor)

Maps CheckoutComponents payment method registration to API parameters.

| PrimerPaymentMethodType | API Parameter Value | Description |
|------------------------|---------------------|-------------|
| `.adyenIDeal` (`"ADYEN_IDEAL"`) | `"ideal"` | Dutch iDEAL bank payments |
| `.adyenDotPay` (`"ADYEN_DOTPAY"`) | `"dotpay"` | Polish Dotpay bank payments |

---

## Relationships

```
PrimerCheckoutScope
  └── owns ──► DefaultBankSelectorScope (via PaymentMethodRegistry)
                  ├── state: AsyncStream<BankSelectorState>
                  ├── uses ──► ProcessBankSelectorPaymentInteractor
                  │                └── uses ──► BankSelectorRepository
                  │                                ├── listBanks() → [AdyenBank] → mapped to [Bank]
                  │                                └── tokenize(bankId:) → PaymentResult
                  └── delegates to ──► DefaultCheckoutScope
                                        ├── handlePaymentSuccess(result)
                                        ├── handlePaymentError(error)
                                        └── startProcessing()
```

## Validation Rules

| Rule | Applies To | Description |
|------|-----------|-------------|
| Bank ID must exist in fetched list | `selectBank(_:)` | Selected bank ID must match one of the fetched banks |
| Bank must not be disabled | `selectBank(_:)` | Cannot select a bank where `isDisabled == true` |
| Search query filtering | `search(query:)` | Case-insensitive, diacritics-insensitive substring match on bank name |
| Config ID required | `start()` | Payment method configuration must have a valid `id` for the API call |
| Client token required | `start()` | Valid decoded JWT token must be available |
