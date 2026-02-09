# Contract: PrimerBankSelectorScope API

**Feature Branch**: `003-bank-selector`
**Date**: 2026-02-09

## Public Protocol: PrimerBankSelectorScope

```swift
@available(iOS 15.0, *)
@MainActor
public protocol PrimerBankSelectorScope: PrimerPaymentMethodScope
where State == BankSelectorState {

    // MARK: - State Observation

    /// Asynchronous stream of bank selector state updates.
    /// Emits: loading → ready → selected
    var state: AsyncStream<BankSelectorState> { get }

    // MARK: - Presentation Context

    /// Determines navigation button behavior (back vs cancel).
    var presentationContext: PresentationContext { get }

    /// Dismissal mechanisms configured for this checkout session.
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Lifecycle (inherited from PrimerPaymentMethodScope)

    /// Fetches the bank list from the API and transitions state to ready.
    func start()

    /// Tokenizes with the selected bank and delegates to checkout scope.
    /// For bank selector, this is triggered internally by selectBank(_:).
    func submit()

    /// Cancels the bank selection flow.
    func cancel()

    // MARK: - Bank Selection Actions

    /// Filters the displayed bank list by the given query string.
    /// Filtering is case-insensitive and diacritics-insensitive.
    /// Pass empty string to restore the full list.
    func search(query: String)

    /// Selects a bank and immediately initiates the payment flow.
    /// - Parameter bank: The bank to select (must not be disabled).
    func selectBank(_ bank: Bank)

    // MARK: - Navigation

    /// Navigates back to payment method selection (if fromPaymentSelection)
    /// or dismisses the checkout (if direct).
    func onBack()

    /// Dismisses the checkout entirely.
    func onCancel()

    // MARK: - UI Customization

    /// Replace the entire bank selector screen with a custom view.
    var screen: BankSelectorScreenComponent? { get set }

    /// Customize individual bank item rendering.
    var bankItemComponent: BankItemComponent? { get set }

    /// Customize the search bar appearance.
    var searchBarComponent: Component? { get set }

    /// Customize the empty state (no search results).
    var emptyStateComponent: Component? { get set }
}
```

## Public Type Aliases (Customization Components)

```swift
/// Full screen replacement — receives the scope for state access.
/// Added to ComponentTypeAliases.swift alongside existing screen components.
public typealias BankSelectorScreenComponent = (any PrimerBankSelectorScope) -> any View

/// Custom bank item — receives the Bank model for rendering.
/// Added to ComponentTypeAliases.swift alongside existing item components.
public typealias BankItemComponent = (Bank) -> any View
```

**Note**: `searchBarComponent` and `emptyStateComponent` in the protocol use the existing `Component` typealias already defined in `ComponentTypeAliases.swift` as `() -> any View`. No new definition needed for those.

## Public State Model: BankSelectorState

```swift
@available(iOS 15.0, *)
public struct BankSelectorState: Equatable {

    public enum Status: Equatable {
        case loading
        case ready
        case selected(Bank)
    }

    public var status: Status
    public var banks: [Bank]
    public var filteredBanks: [Bank]
    public var selectedBank: Bank?
    public var searchQuery: String

    public init(
        status: Status = .loading,
        banks: [Bank] = [],
        filteredBanks: [Bank] = [],
        selectedBank: Bank? = nil,
        searchQuery: String = ""
    ) {
        self.status = status
        self.banks = banks
        self.filteredBanks = filteredBanks
        self.selectedBank = selectedBank
        self.searchQuery = searchQuery
    }
}
```

## Public Model: Bank

```swift
@available(iOS 15.0, *)
public struct Bank: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let iconUrl: URL?
    public let isDisabled: Bool
}
```

## Usage Example (SwiftUI)

```swift
PrimerCheckout(
    clientToken: clientToken,
    primerSettings: settings,
    scope: { checkout in
        checkout.bankSelector { bankSelector in
            // Option 1: Use default UI (no customization needed)

            // Option 2: Customize bank item rendering
            bankSelector.bankItemComponent = { bank in
                HStack {
                    AsyncImage(url: bank.iconUrl)
                    Text(bank.name)
                }
            }

            // Option 3: Observe state for fully custom UI
            // for await state in bankSelector.state { ... }
        }
    }
)
```
