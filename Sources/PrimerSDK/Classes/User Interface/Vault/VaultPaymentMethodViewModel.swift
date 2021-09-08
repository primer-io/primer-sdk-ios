#if canImport(UIKit)

internal protocol VaultPaymentMethodViewModelProtocol: class {
    var paymentMethods: [PaymentInstrument] { get }
    var selectedId: String { get set }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

internal class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {

    var paymentMethods: [PaymentInstrument] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.paymentMethods
    }
    var selectedId: String {
        get {
            let state: AppStateProtocol = DependencyContainer.resolve()
            return state.selectedPaymentMethod
        }
        set {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.selectedPaymentMethod = newValue
        }
    }
    private var clientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func reloadVault(with completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.loadVaultedPaymentMethods(completion)
    }

    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.deleteVaultedPaymentMethod(with: id) { [weak self] _ in
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            // reset selected payment method if that has been deleted
            if id == state.selectedPaymentMethod {
                state.selectedPaymentMethod = ""
            }

            // reload vaulted payment methods
            vaultService.loadVaultedPaymentMethods(completion)
        }
    }
}

internal class MockVaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    
    var theme: PrimerTheme { return PrimerTheme() }
    var paymentMethods: [PaymentInstrument] { return [] }
    var selectedId: String = "id"

    func reloadVault(with completion: @escaping (Error?) -> Void) {

    }

    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {

    }
    
}

#endif
