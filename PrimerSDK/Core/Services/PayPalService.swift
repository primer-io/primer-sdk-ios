import Foundation

protocol PayPalServiceProtocol {
    var orderId: String? { get }
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { get }
    
    func getAccessToken(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<String, Error>) -> Void
    )
    
    func getBillingAgreementToken(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<String, Error>) -> Void
    )
    
    func confirmBillingAgreement(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void
    )
    
    func createPayPalOrder(_ completion: @escaping (Result<String, Error>) -> Void)
}

class PayPalService: PayPalServiceProtocol {
    
    private let api = APIClient()
    
    var accessToken: String?
    var billingAgreementToken: String?
    var orderId: String?
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    var approveURL: String?
    var amount: Int?
    var currency: Currency?
    
    var stringedAmount: String? {
        get {
            guard let amount = amount else { return nil }
            let dbl = Double(amount) / 100
            let str = String(format: "%.2f", dbl)
            print("str:", str)
            return str
        }
    }
    
    init(amount: Int, currency: Currency) {
        self.amount = amount
        self.currency = currency
    }
    
    func getAccessToken(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let coreURL = clientToken.coreUrl else { return }
        // /paypal/billing-agreements/create-agreement
        guard let url = URL(string: "\(coreURL)/paypal/access-tokens/create") else { return }
        let body = PayPalAccessTokenRequest(paymentMethodConfigId: configId)
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PayPalAccessTokenResponse.self, from: data)
                    self?.accessToken = config.accessToken
                    self?.createPayPalOrder(completion)
                } catch {
                    completion(.failure(error))
                }
            }
        })
    }
    
    func getBillingAgreementToken(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<String, Error>
    ) -> Void) {
        
        guard let coreURL = clientToken.coreUrl else { return }
        guard let url = URL(string: "\(coreURL)/paypal/billing-agreements/create-agreement") else { return }
        print("🚀 url:", url)
        let body = PayPalAccessTokenRequest(paymentMethodConfigId: configId)
        //
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PayPalCreateBillingAgreementResponse.self, from: data)
                    print("🚀 config:", config)
                    self?.billingAgreementToken = config.tokenId
                    guard let tokenId = self?.billingAgreementToken else { return }
                    let redirectUrl = "https://www.sandbox.paypal.com/agreements/approve?ba_token=\(tokenId)"
                    // https://www.sandbox.paypal.com/agreements/approve?ba_token=BA-31J36614L4673450Y
                    completion(.success(redirectUrl))
                } catch {
                    completion(.failure(error))
                }
            }
        })
    }
    
    func confirmBillingAgreement(
        with clientToken: ClientToken,
        configId: String,
        completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void
    ) {
        guard let coreURL = clientToken.coreUrl else { return }
        guard let tokenId = billingAgreementToken else { return }
        guard let url = URL(string: "\(coreURL)/paypal/billing-agreements/confirm-agreement") else { return }
        print("🚀🚀 url:", url)
        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(PayPalConfirmBillingAgreementResponse.self, from: data)
                    print("🚀🚀 response:", response)
                    self?.confirmedBillingAgreement = response
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            }
        })
    }
    
    func createPayPalOrder(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiURL = URL(string: "https://api.sandbox.paypal.com/v2/checkout/orders") else { return }
        guard let amount = stringedAmount else { return }
        guard let currency = currency else { return }
        let unit = PayPalPurchaseUnit(amount: PayPalAmount(currency_code: currency.rawValue, value: amount))
        let applicationContext = PayPalApplicationContext(return_url: "primer://primer.io", cancel_url: "primer://primer.io")
        let body = PayPalCreateOrderRequest(intent: "AUTHORIZE", purchase_units: [unit], application_context: applicationContext)
        
        guard let accessToken = self.accessToken else { return }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonBody = try JSONEncoder().encode(body)
            request.httpBody = jsonBody
        } catch {
            print(error)
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, err) in
            if let err = err {
                print("API GET request failed:", err)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else { return }
            print("statusCode: \(httpResponse.statusCode)")
            print("description: \(httpResponse.description)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                return
            }
            
            do {
                let res = try JSONDecoder().decode(PayPalCreateOrderResponse.self, from: data!)
                
                self?.orderId = res.id
                
                let approveLink = res.links?.first(where: { pplink in
                    return pplink.rel == "approve"
                })
                
                self?.approveURL = approveLink?.href
                
                guard let url = approveLink?.href else { return }
                
                completion(.success(url))
            } catch {
                print("😡😡😡😡", error)
            }
            
        }).resume()
    }
}

class MockPayPalService: PayPalServiceProtocol {
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    
    func confirmBillingAgreement(with clientToken: ClientToken, configId: String, completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
    }
    
    var getBillingAgreementTokenCalled = false
    
    func getBillingAgreementToken(with clientToken: ClientToken, configId: String, completion: @escaping (Result<String, Error>) -> Void) {
        getBillingAgreementTokenCalled = true
    }
    
    
    var orderId: String? { return "orderId" }
    
    var getAccessTokenCalled = false
    
    func getAccessToken(with clientToken: ClientToken, configId: String, completion: @escaping (Result<String, Error>) -> Void) {
        getAccessTokenCalled = true
    }
    
    var createPayPalOrderCalled = false
    
    func createPayPalOrder(_ completion: @escaping (Result<String, Error>) -> Void) {
        createPayPalOrderCalled = true
    }
}
