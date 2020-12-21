import UIKit

struct PaymentMethodConfig: Decodable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
}

struct ConfigPaymentMethod: Decodable {
    let id: String?
    let type: ConfigPaymentMethodType?
}

enum ConfigPaymentMethodType: String, Decodable {
    case APPLE_PAY = "APPLE_PAY"
    case PAYPAL = "PAYPAL"
    case PAYMENT_CARD = "PAYMENT_CARD"
    case GOOGLE_PAY = "GOOGLE_PAY"
}

class PaymentMethodConfigService {
    
    private let coreEndpoint = "https://api.sandbox.primer.io"
//    private let coreEndpoint = "http://192.168.0.50:8085"
    private let clientToken: ClientToken
    private let api: APIClientProtocol
    private let router: Router
    
    var paymentMethodConfig: PaymentMethodConfig?
    var viewModels: [PaymentMethodViewModel] = []
    
    
    init(clientToken: ClientToken, api: APIClientProtocol, router: Router) {
        self.clientToken = clientToken
        self.api = api
        self.router = router
    }
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        guard let apiURL = URL(string: "\(coreEndpoint)/client-sdk/configuration") else { return }
        self.api.get(clientToken, url: apiURL, completion: { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PaymentMethodConfig.self, from: data)
                    self.paymentMethodConfig = config
                    print("🎁 config:", config)
                    completion(nil)
                } catch {
                    completion(error)
                }
                
            }
        })
    }
    
}
