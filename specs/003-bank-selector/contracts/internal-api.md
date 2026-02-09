# Contract: Internal APIs (Interactor, Repository, DI)

**Feature Branch**: `003-bank-selector`
**Date**: 2026-02-09

## Interactor: ProcessBankSelectorPaymentInteractor

```swift
@available(iOS 15.0, *)
protocol ProcessBankSelectorPaymentInteractor {
    /// Fetches the list of available banks for the given payment method type.
    func fetchBanks(paymentMethodType: String) async throws -> [Bank]

    /// Tokenizes a payment with the selected bank and processes the payment.
    /// Returns PaymentResult on success; throws PrimerError on failure.
    func execute(bankId: String, paymentMethodType: String) async throws -> PaymentResult
}
```

### Implementation: ProcessBankSelectorPaymentInteractorImpl

```swift
@available(iOS 15.0, *)
final class ProcessBankSelectorPaymentInteractorImpl: ProcessBankSelectorPaymentInteractor {
    private let repository: BankSelectorRepository

    init(repository: BankSelectorRepository) {
        self.repository = repository
    }

    func fetchBanks(paymentMethodType: String) async throws -> [Bank] {
        let adyenBanks = try await repository.listBanks(paymentMethodType: paymentMethodType)
        return adyenBanks.map { Bank(from: $0) }
    }

    func execute(bankId: String, paymentMethodType: String) async throws -> PaymentResult {
        return try await repository.tokenizeAndProcess(
            bankId: bankId,
            paymentMethodType: paymentMethodType
        )
    }
}
```

## Repository: BankSelectorRepository

```swift
@available(iOS 15.0, *)
protocol BankSelectorRepository {
    /// Fetches bank list from the Adyen checkout API.
    func listBanks(paymentMethodType: String) async throws -> [AdyenBank]

    /// Tokenizes with the selected bank ID and processes the full payment flow
    /// (tokenization → redirect → poll).
    func tokenizeAndProcess(bankId: String, paymentMethodType: String) async throws -> PaymentResult
}
```

### Implementation Notes

`BankSelectorRepositoryImpl` wraps:
1. **Bank list fetch**: Uses `PrimerAPIClient.listAdyenBanks()` with:
   - `DecodedJWTToken` from `PrimerAPIConfigurationModule.decodedJWTToken`
   - `Request.Body.Adyen.BanksList` with config ID and payment method parameter
   - Payment method mapping: `"ADYEN_IDEAL"` → `"ideal"`, `"ADYEN_DOTPAY"` → `"dotpay"`

2. **Tokenization + payment**: Delegates to existing `BankSelectorTokenizationProviding` or directly wraps `TokenizationService` + payment creation + redirect/polling via the core SDK's existing infrastructure.

## DI Registration (ComposableContainer)

```swift
// In ComposableContainer.registerData():
try? await container.register(BankSelectorRepository.self)
    .asTransient()
    .with { _ in BankSelectorRepositoryImpl() }

// In ComposableContainer.registerDomain():
try? await container.register(ProcessBankSelectorPaymentInteractor.self)
    .asTransient()
    .with { resolver in
        ProcessBankSelectorPaymentInteractorImpl(
            repository: try await resolver.resolve(BankSelectorRepository.self)
        )
    }
```

## Payment Method Registration

```swift
@available(iOS 15.0, *)
struct BankSelectorPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = DefaultBankSelectorScope

    let paymentMethodType: String  // Instance property (not static) for multi-type support

    static var paymentMethodType: String {
        // Default for protocol conformance; actual type set per registration
        PrimerPaymentMethodType.adyenIDeal.rawValue
    }

    // Bulk registration for all supported bank selector APMs
    @MainActor
    static func registerAll() {
        for type in [PrimerPaymentMethodType.adyenIDeal, .adyenDotPay] {
            PaymentMethodRegistry.shared.register(
                paymentMethodType: type.rawValue,
                scopeCreator: { checkoutScope, diContainer in
                    try Self.createScopeForType(type.rawValue, checkoutScope: checkoutScope, diContainer: diContainer)
                },
                viewCreator: { checkoutScope in
                    Self.createViewForType(type.rawValue, checkoutScope: checkoutScope)
                }
            )
        }
    }
}

// In DefaultCheckoutScope.registerPaymentMethods():
BankSelectorPaymentMethod.registerAll()
```

**Note**: The exact registration mechanism may need to adapt to the current `PaymentMethodRegistry.register()` API. If the registry only accepts `PaymentMethodProtocol` types (not closures), each APM may need its own thin struct (e.g., `IDealPaymentMethod`, `DotpayPaymentMethod`) that delegates to shared `BankSelectorPaymentMethod` logic.
