import UIKit

protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    @Dependency private(set) var api: APIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    let primerAPI = PrimerAPIClient()
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.ConfigFetchFailed)
        }
        
        primerAPI.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                self?.state.paymentMethodConfig = config
                
                self?.state.viewModels = []
                
                config.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if type == .GOOGLE_PAY { return }
                    self?.state.viewModels.append(PaymentMethodViewModel(type: type))
                })
                
                // ensure Apple Pay is always first if present.
                guard let viewModels = self?.state.viewModels else { return }
                if (viewModels.contains(where: { model in model.type == .APPLE_PAY})) {
                    var arr = viewModels.filter({ model in model.type != .APPLE_PAY})
                    
                    if (self?.state.settings.applePayEnabled == true) {
                        arr.insert(PaymentMethodViewModel(type: .APPLE_PAY), at: 0)
                    }
                    
                    self?.state.viewModels = arr
                }
                
                completion(nil)
            }
        }
        
//        guard let configurationUrl = clientToken.configurationUrl else {
//            return completion(PrimerError.ConfigFetchFailed)
//        }
//        
//        guard let apiURL = URL(string: configurationUrl) else {
//            return completion(PrimerError.ConfigFetchFailed)
//        }
//        
//        self.api.get(clientToken, url: apiURL, completion: { [weak self] result in
//            switch result {
//            case .failure(let error): completion(error)
//            case .success(let data):
//                do {
//                    
//                    let config = try JSONDecoder().decode(PaymentMethodConfig.self, from: data)
//                    
//                    self?.state.paymentMethodConfig = config
//                    
//                    self?.state.viewModels = []
//                    
//                    config.paymentMethods?.forEach({ method in
//                        guard let type = method.type else { return }
//                        if type == .GOOGLE_PAY { return }
//                        self?.state.viewModels.append(PaymentMethodViewModel(type: type))
//                    })
//                    
//                    // ensure Apple Pay is always first if present.
//                    guard let viewModels = self?.state.viewModels else { return }
//                    if (viewModels.contains(where: { model in model.type == .APPLE_PAY})) {
//                        var arr = viewModels.filter({ model in model.type != .APPLE_PAY})
//                        
//                        if (self?.state.settings.applePayEnabled == true) {
//                            arr.insert(PaymentMethodViewModel(type: .APPLE_PAY), at: 0)
//                        }
//                        
//                        self?.state.viewModels = arr
//                    }
//                    
//                    completion(nil)
//                } catch {
//                    completion(error)
//                }
//            }
//        })
    }
}
