import Foundation

protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

class VaultService: VaultServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: APIClientProtocol
    
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.VaultFetchFailed)
        }
        
        guard let pciURL = clientToken.pciUrl else {
            return completion(PrimerError.VaultFetchFailed)
        }
        
        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            return completion(PrimerError.VaultFetchFailed)
        }
        
        self.api.get(clientToken, url: url, completion: { [weak self] result in
            do {
                switch result {
                case .failure: completion(PrimerError.VaultFetchFailed)
                case .success(let data):
                    
                    let methods = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: data)
                    
                    self?.state.paymentMethods = methods.data
                    
                    guard let paymentMethods = self?.state.paymentMethods else { return }
                    
                    if (self?.state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false) {
                        guard let id = paymentMethods[0].token else { return }
                        self?.state.selectedPaymentMethod = id
                    }
                    
                    completion(nil)
                }
            } catch {
                print(error)
                completion(PrimerError.VaultFetchFailed)
            }
        })
        
    }
    
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.VaultDeleteFailed)
        }
        
        guard let pciURL = clientToken.pciUrl else {
            return completion(PrimerError.VaultDeleteFailed)
        }
        
        guard let url = URL(string: "\(pciURL)/payment-instruments/\(id)/vault") else {
            return completion(PrimerError.VaultDeleteFailed)
        }
        
        self.api.delete(clientToken, url: url, completion: { result in
            switch result {
            case .failure: completion(PrimerError.VaultDeleteFailed)
            case .success: completion(nil)
            }
        })
    }
}
