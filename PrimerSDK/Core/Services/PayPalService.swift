import Foundation

protocol PayPalServiceProtocol {
    
    var orderId: String? { get }
    
    func getAccessToken(
        with clientToken: ClientToken,
        and configId: String,
        and completion: @escaping (Result<String, Error>) -> Void
    )
    
    func createPayPalOrder(_ completion: @escaping (Result<String, Error>) -> Void)
    
}

class PayPalService: PayPalServiceProtocol {
    
//    private let clientId: String
    private let api = APIClient()
    
    var accessToken: String?
    var orderId: String?
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
        and configId: String,
        and completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let coreURL = clientToken.coreUrl else { return }
        guard let url = URL(string: "\(coreURL)/paypal/access-tokens/create") else { return }
        let body = PayPalAccessTokenRequest(paymentMethodConfigId: configId)
        self.api.post(clientToken, body: body, url: url, completion: { result in
            switch result {
            case .failure(let error):
                print("😡😡", error)
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PayPalAccessTokenResponse.self, from: data)
                    self.accessToken = config.accessToken
                    self.createPayPalOrder(completion)
                } catch {
                    print("😡😡😡", error)
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
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
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
                self.orderId = res.id
                let approveLink = res.links?.first(where: {
                    pplink in
                    return pplink.rel == "approve"
                })
                self.approveURL = approveLink?.href
                
                guard let url = approveLink?.href else { return }
                
                completion(.success(url))
            } catch {
                print("😡😡😡😡", error)
            }
            
        }).resume()
    }
}

class MockPayPalService: PayPalServiceProtocol {
    
    var orderId: String? { return "orderId" }
    
    var getAccessTokenCalled = false
    
    func getAccessToken(with clientToken: ClientToken, and configId: String, and completion: @escaping (Result<String, Error>) -> Void) {
        getAccessTokenCalled = true
    }
    
    var createPayPalOrderCalled = false
    
    func createPayPalOrder(_ completion: @escaping (Result<String, Error>) -> Void) {
        createPayPalOrderCalled = true
    }
}
