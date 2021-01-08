protocol VaultPaymentMethodViewModelProtocol {
    var paymentMethods: [VaultedPaymentMethodViewModel] { get }
    var selectedId: String { get set }
    var cardFormViewModel: CardFormViewModelProtocol { get }
    var theme: PrimerTheme { get }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    
    var paymentMethods: [VaultedPaymentMethodViewModel] {
        return vaultService.paymentMethodVMs
    }
    var selectedId: String {
        get { return vaultService.selectedPaymentMethod }
        set { vaultService.selectedPaymentMethod = newValue }
    }
    private var clientToken: ClientToken? { return clientTokenService.decodedClientToken }
    
    var cardFormViewModel: CardFormViewModelProtocol
    var theme: PrimerTheme { return settings.theme }
    
    var vaultService: VaultServiceProtocol
    let clientTokenService: ClientTokenServiceProtocol
    let settings: PrimerSettings
    
    init(
        with clientTokenService: ClientTokenServiceProtocol,
        and vaultService: VaultServiceProtocol,
        and cardFormViewModel: CardFormViewModelProtocol,
        and settings: PrimerSettings
    ) {
        self.clientTokenService = clientTokenService
        self.vaultService = vaultService
        self.cardFormViewModel = cardFormViewModel
        self.settings = settings
    }
    
    func reloadVault(with completion: @escaping (Error?) -> Void) {
        guard let clientToken = self.clientToken else { return }
        vaultService.loadVaultedPaymentMethods(with: clientToken, and: completion)
    }
    
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {
        guard let clientToken = self.clientToken else { return }
        vaultService.deleteVaultedPaymentMethod(with: clientToken, and: id) { [weak self] error in
            self?.vaultService.loadVaultedPaymentMethods(with: clientToken, and: completion)
        }
    }
}

class MockVaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
    
    var paymentMethods: [VaultedPaymentMethodViewModel] { return [] }
    
    var selectedId: String = "id"
    
    var cardFormViewModel: CardFormViewModelProtocol { return MockCardFormViewModel() }
    
    func reloadVault(with completion: @escaping (Error?) -> Void) {
        
    }
    
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void) {
        
    }
}
