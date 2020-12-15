import UIKit
import PrimerSDK
import AuthenticationServices

class ViewController: UIViewController  {
    
    @IBAction func showDirectCheckout() {
        Primer.showCheckout(
            delegate: self,
            mode: .CHECKOUT,
            paymentMethod: .card,
            amount: 200,
            currency: Currency.GBP
        )
    }
    
    @IBAction func showVaultCheckout() {
        Primer.showCheckout(
            delegate: self,
            mode: .VAULT,
            paymentMethod: .card,
            amount: 200,
            currency: Currency.GBP,
            customerId: "customer_1"
        )
    }
    
    private func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in
            
            if err != nil {
                completion(.failure(NetworkError.serverError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            completion(.success(data))
            
        }).resume()
    }


}

// MARK: Required PrimerCheckoutDelegate methods

struct AuthorizationRequest: Encodable {
    var token: String
}

enum NetworkError: Error {
    case missingParams
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case serializationError
}

extension ViewController: PrimerCheckoutDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<ClientTokenResponse, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:8020/client-token") else {
            return completion(.failure(NetworkError.missingParams))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        callApi(request, completion: {
            result in
            switch result {
            case .success(let data):
                // serialize data
                do {
                    let token = try JSONDecoder().decode(ClientTokenResponse.self, from: data)
                    // call completion handler passing in token response as result
                    completion(.success(token))
                } catch {
                    completion(.failure(NetworkError.serializationError))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        })
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        guard let token = result.token else {
            return completion(NetworkError.missingParams)
        }
        guard let url = URL(string: "http://localhost:8020/authorize") else  {
            return completion(NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = AuthorizationRequest(token: token)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(NetworkError.missingParams)
        }
        callApi(request, completion: {
            result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let err):
                completion(err)
            }
        })
    }
}

