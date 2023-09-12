

internal protocol VaultPaymentMethodViewModelProtocol: AnyObject {
    var paymentMethods: [PrimerPaymentMethodTokenData] { get }
    var selectedPaymentMethodId: String? { get set }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

internal class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {

    var paymentMethods: [PrimerPaymentMethodTokenData] {
        return AppState.current.paymentMethods
    }
    var selectedPaymentMethodId: String? {
        get {
            return AppState.current.selectedPaymentMethodId
        }
        set {
            AppState.current.selectedPaymentMethodId = newValue
        }
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func reloadVault(with completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = VaultService()
        firstly {
            vaultService.fetchVaultedPaymentMethods()
        }
        .done {
            completion(nil)
        }
        .catch { err in
            completion(err)
        }
    }

    func deletePaymentMethod(with paymentMethodToken: String, and completion: @escaping (Error?) -> Void) {
        let vaultService: VaultServiceProtocol = VaultService()
        firstly {
            vaultService.deleteVaultedPaymentMethod(with: paymentMethodToken)
        }
        .then { () -> Promise<Void> in
            if paymentMethodToken == AppState.current.selectedPaymentMethodId {
                AppState.current.selectedPaymentMethodId = nil
            }
            
            return vaultService.fetchVaultedPaymentMethods()
        }
        .done {
            completion(nil)
        }
        .catch { err in
            completion(err)
        }
    }
}

internal class MockVaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    
    var theme: PrimerTheme { return PrimerTheme() }
    var paymentMethods: [PrimerPaymentMethodTokenData] { return [] }
    var selectedPaymentMethodId: String? = "id"

    func reloadVault(with completion: @escaping (Error?) -> Void) {

    }

    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {

    }
    
}


