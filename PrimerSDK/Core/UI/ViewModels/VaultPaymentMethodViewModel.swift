protocol VaultPaymentMethodViewModelProtocol: class {
    var paymentMethods: [PaymentMethodToken] { get }
    var selectedId: String { get set }
    var theme: PrimerTheme { get }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    
    var paymentMethods: [PaymentMethodToken] {
        return state.paymentMethods
    }
    var selectedId: String {
        get { return state.selectedPaymentMethod }
        set { state.selectedPaymentMethod = newValue }
    }
    private var clientToken: DecodedClientToken? { return state.decodedClientToken }
    
    var theme: PrimerTheme { return state.settings.theme }
    
    var vaultService: VaultServiceProtocol
    let clientTokenService: ClientTokenServiceProtocol
    var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol) {
        self.clientTokenService = context.serviceLocator.clientTokenService
        self.vaultService = context.serviceLocator.vaultService
        self.state = context.state
    }
    
    func reloadVault(with completion: @escaping (Error?) -> Void) {
        vaultService.loadVaultedPaymentMethods(completion)
    }
    
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {
        vaultService.deleteVaultedPaymentMethod(with: id) { [weak self] error in
            // reset selected payment method if that has been deleted
            if (id == self?.state.selectedPaymentMethod) {
                self?.state.selectedPaymentMethod = ""
            }
            
            // reload vaulted payment methods
            self?.vaultService.loadVaultedPaymentMethods(completion)
        }
    }
}

class MockVaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme.initialise() }
    
    var paymentMethods: [PaymentMethodToken] { return [] }
    
    var selectedId: String = "id"
    
    func reloadVault(with completion: @escaping (Error?) -> Void) {
        
    }
    
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {
        
    }
}
