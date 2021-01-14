protocol ClientTokenServiceProtocol {
    var decodedClientToken: ClientToken? { get }
    func loadCheckoutConfig(with completion: @escaping (Error?) -> Void)
}

class ClientTokenService: ClientTokenServiceProtocol {
    var decodedClientToken: ClientToken?
    var clientTokenRequestCallback: ClientTokenCallBack { return settings.clientTokenRequestCallback }
    
    let settings: PrimerSettings
    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    
    required init(with settings: PrimerSettings, and paymentMethodConfigService: PaymentMethodConfigServiceProtocol) {
        self.settings = settings
        self.paymentMethodConfigService = paymentMethodConfigService
    }
    
    func loadCheckoutConfig(with completion: @escaping (Error?) -> Void) {
        clientTokenRequestCallback({ [weak self] result in
            switch result {
            case .failure: completion(PrimerError.ClientTokenNull)
            case .success(let token):
                guard let clientToken = token.clientToken else { return completion(PrimerError.ClientTokenNull) }
                let provider = ClientTokenProvider(clientToken)
                var decodedToken = provider.getDecodedClientToken()
                
                // ⚠️ this is just for testing locally on live device, remove from production
                let gate = 50
                decodedToken.configurationUrl = "http://192.168.0.\(gate):8085/client-sdk/configuration"
                decodedToken.coreUrl = "http://192.168.0.\(gate):8085"
                decodedToken.pciUrl = "http://192.168.0.\(gate):8081"
                
                self?.decodedClientToken = decodedToken
                self?.paymentMethodConfigService.fetchConfig(with: decodedToken, completion)
            }
        })
    }
    
}

class MockClientTokenService: ClientTokenServiceProtocol {
    var decodedClientToken: ClientToken? {
        return ClientToken(
            accessToken: "bla",
            configurationUrl: "bla",
            paymentFlow: "bla",
            threeDSecureInitUrl: "bla",
            threeDSecureToken: "bla",
            coreUrl: "bla",
            pciUrl: "bla",
            env: "bla"
        )
    }
    
    var loadCheckoutConfigCalled = false
    
    func loadCheckoutConfig(with completion: @escaping (Error?) -> Void) {
        loadCheckoutConfigCalled = true
    }
}
