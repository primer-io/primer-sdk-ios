import Foundation

struct PayPalCreateOrderRequest: Encodable {
    let intent: String
    let purchase_units: [PayPalPurchaseUnit]
    let application_context: PayPalApplicationContext
}

struct PayPalPurchaseUnit: Encodable {
    let amount: PayPalAmount
}

struct PayPalAmount: Encodable {
    let currency_code: String
    let value: String
}

struct PayPalApplicationContext: Encodable {
    let return_url: String
    let cancel_url: String
}

struct PayPalAccessTokenRequest: Encodable {
    let paymentMethodConfigId: String
}

struct PayPalAccessTokenResponse: Decodable {
    let accessToken: String?
}

struct PayPalCreateOrderResponse: Decodable {
    let id: String?
    let status: String?
    let links: [PayPalOrderLink]?
}

struct PayPalOrderLink: Decodable {
    let href: String?
    let rel: String?
    let method: String?
}

class PayPalService {
    
//    private let pciEndpoint = "https://api.sandbox.primer.io"
    private let coreEndpoint = "https://api.sandbox.primer.io"
//    private let coreEndpoint = "http://192.168.0.50:8085"
    
    private let clientId: String
    private let clientToken: ClientToken
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
    
    init(clientId: String, clientToken: ClientToken, amount: Int, currency: Currency) {
        self.clientId = clientId
        self.clientToken = clientToken
        self.amount = amount
        self.currency = currency
    }
    
    func getAccessToken(_ completion: @escaping (Result<String, Error>) -> Void) {
        print("getting PayPal Access Token!")
        guard let url = URL(string: "\(coreEndpoint)/paypal/access-tokens/create") else { return }
        let body = PayPalAccessTokenRequest(paymentMethodConfigId: clientId)
        self.api.post(self.clientToken, body: body, url: url, completion: { result in
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
