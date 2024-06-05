internal protocol VaultPaymentMethodViewModelProtocol: AnyObject {
    var paymentMethods: [PrimerPaymentMethodTokenData] { get }
    var selectedPaymentMethodId: String? { get set }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

internal class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {

    let vaultService: VaultServiceProtocol

    init(vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())) {
        self.vaultService = vaultService
    }

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

    func reloadVault(with completion: @escaping (Error?) -> Void) {
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
        firstly {
            vaultService.deleteVaultedPaymentMethod(with: paymentMethodToken)
        }
        .then { () -> Promise<Void> in
            if paymentMethodToken == AppState.current.selectedPaymentMethodId {
                AppState.current.selectedPaymentMethodId = nil
            }

            return self.vaultService.fetchVaultedPaymentMethods()
        }
        .done {
            completion(nil)
        }
        .catch { err in
            completion(err)
        }
    }
}
