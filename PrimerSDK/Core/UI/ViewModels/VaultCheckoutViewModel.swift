protocol VaultCheckoutViewModelProtocol {
    var paymentMethods: [VaultedPaymentMethodViewModel] { get }
    var selectedPaymentMethodId: String { get }
    var theme: PrimerTheme { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol { get }
    var applePayViewModel: ApplePayViewModelProtocol { get }
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var theme: PrimerTheme { return settings.theme }
    
    var paymentMethods: [VaultedPaymentMethodViewModel] {
        return vaultService.paymentMethodVMs
    }
    var selectedPaymentMethodId: String {
        return vaultService.selectedPaymentMethod
    }
    var clientTokenService: ClientTokenServiceProtocol
    var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol
    var applePayViewModel: ApplePayViewModelProtocol
    var vaultService: VaultServiceProtocol
    var settings: PrimerSettings
    
    init(
        with clientTokenService: ClientTokenServiceProtocol,
        and vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol,
        and applePayViewModel: ApplePayViewModelProtocol,
        and vaultService: VaultServiceProtocol,
        and settings: PrimerSettings
    ) {
        self.clientTokenService = clientTokenService
        self.vaultPaymentMethodViewModel = vaultPaymentMethodViewModel
        self.applePayViewModel = applePayViewModel
        self.vaultService = vaultService
        self.settings = settings
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if (clientTokenService.decodedClientToken == nil) {
            clientTokenService.loadCheckoutConfig(with: completion)
            return
        }
        completion(nil)
        return
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        let id = vaultService.selectedPaymentMethod
        
        // find vaulted payment method token of selected ID
        let selectedToken = vaultService.paymentMethods.first(where: { token in
            guard let tokenId = token.token else { return false }
            return tokenId == id
        })
        
        guard let token = selectedToken else { return }
        
        self.settings.onTokenizeSuccess(token, completion)
    }
    
}

class MockVaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
    
    var paymentMethods: [VaultedPaymentMethodViewModel] {
        return []
    }
    
    var selectedPaymentMethodId: String {
        return "id"
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        
    }
    
    var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {
        return MockVaultPaymentMethodViewModel()
    }
    
    var applePayViewModel: ApplePayViewModelProtocol {
        return MockApplePayViewModel()
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        
    }
}
