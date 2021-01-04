import UIKit

protocol PaymentMethodConfigServiceProtocol {
    var viewModels: [PaymentMethodViewModel] { get }
    func fetchConfig(with clientToken: ClientToken, _ completion: @escaping (Error?) -> Void)
    func getConfigId(for type: ConfigPaymentMethodType) -> String?
}

class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    let api: APIClientProtocol
    let vaultService: VaultServiceProtocol
    let settings: PrimerSettings
    
    var paymentMethodConfig: PaymentMethodConfig?
    var viewModels: [PaymentMethodViewModel] = []
    
    init(
        with api: APIClientProtocol,
        and vaultService: VaultServiceProtocol,
        and settings: PrimerSettings
    ) {
        self.api = api
        self.vaultService = vaultService
        self.settings = settings
    }
    
    func fetchConfig(with clientToken: ClientToken, _ completion: @escaping (Error?) -> Void) {
        guard let configurationUrl = clientToken.configurationUrl else { return }
        guard let apiURL = URL(string: configurationUrl) else { return }
        
        self.api.get(clientToken, url: apiURL, completion: { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PaymentMethodConfig.self, from: data)
                    
                    self?.paymentMethodConfig = config
                    
                    self?.viewModels = []
                    
                    config.paymentMethods?.forEach({ method in
                        guard let type = method.type else { return }
                        if type == .GOOGLE_PAY { return }
                        self?.viewModels.append(PaymentMethodViewModel(type: type))
                    })
                    
                    // ensure Apple Pay is always first if present.
                    
                    guard let viewModels = self?.viewModels else { return }
                    
                    if (viewModels.contains(where: { model in model.type == .APPLE_PAY})) {
                        var arr = viewModels.filter({ model in model.type != .APPLE_PAY})
                        arr.insert(PaymentMethodViewModel(type: .APPLE_PAY), at: 0)
                        self?.viewModels = arr
                    }
                    
                    guard let uxMode = self?.settings.uxMode else { return }
                    
                    switch uxMode {
                    case .CHECKOUT: completion(nil)
                    case .VAULT:
                        
                        self?.vaultService.loadVaultedPaymentMethods(with: clientToken, and: completion)
                    }
                } catch {
                    completion(error)
                }
            }
        })
    }
    
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethodConfig?.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil}
        return method.id
    }
    
}

class MockPaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    var viewModels: [PaymentMethodViewModel] = []
    
    var fetchConfigCalled = false
    var getConfigIdCalled = false
    
    func fetchConfig(with clientToken: ClientToken, _ completion: @escaping (Error?) -> Void) {
        fetchConfigCalled = true
    }
    
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        getConfigIdCalled = true
        return "id"
    }
}
