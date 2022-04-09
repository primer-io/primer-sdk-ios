#if canImport(UIKit)

internal protocol VaultPaymentMethodViewModelProtocol: AnyObject {
    var paymentMethods: [PaymentMethod.Tokenization.Response] { get }
    var selectedPaymentMethodId: String? { get set }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

internal class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {

    var paymentMethods: [PaymentMethod.Tokenization.Response] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.paymentMethods
    }
    var selectedPaymentMethodId: String? {
        get {
            let state: AppStateProtocol = DependencyContainer.resolve()
            return state.selectedPaymentMethodId
        }
        set {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.selectedPaymentMethodId = newValue
        }
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func reloadVault(with completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.loadVaultedPaymentMethods(completion)
    }

    func deletePaymentMethod(with paymentMethodToken: String, and completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.deleteVaultedPaymentMethod(with: paymentMethodToken) { _ in
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            // reset selected payment method if that has been deleted
            if paymentMethodToken == state.selectedPaymentMethodId {
                state.selectedPaymentMethodId = nil
            }

            // reload vaulted payment methods
            vaultService.loadVaultedPaymentMethods(completion)
        }
    }
}

internal class MockVaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    
    var theme: PrimerTheme { return PrimerTheme() }
    var paymentMethods: [PaymentMethod.Tokenization.Response] { return [] }
    var selectedPaymentMethodId: String? = "id"

    func reloadVault(with completion: @escaping (Error?) -> Void) {

    }

    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {

    }
    
}

#endif
