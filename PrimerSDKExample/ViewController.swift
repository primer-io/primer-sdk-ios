//
//  ViewController.swift
//  PrimerSDKExample
//
//  Created by Carl Eriksson on 07/12/2020.
//

import UIKit
import PrimerSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func showCheckout() {
        Primer.showCheckout(
            delegate: self,
            paymentMethod: .card,
            amount: 200,
            currency: Currency.GBP,
            customerId: "customer_1"
        )
        
    }
    
    private func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in
            
            // handle errors
            
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
            
        })
        
        task.resume()
    }


}

// MARK: Required PrimerCheckoutDelegate methods

struct AuthorizationRequest: Encodable {
    var token: String
}

struct AuthorizationResponse: Decodable {
    var success: Bool
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
        
        let endpoint = "http://localhost:8020/client-token"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.missingParams))
            return
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
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Result<Bool, Error>) -> Void) {
        
        guard let token = result.token else {
            completion(.failure(NetworkError.missingParams))
            return
        }
        
        let endpoint = "http://localhost:8020/authorize"
        
        guard let url = URL(string: endpoint) else  {
            completion(.failure(NetworkError.missingParams))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(token: token)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(NetworkError.missingParams))
            return
        }
        
        callApi(request, completion: {
            result in
            switch result {
            case .success(let data):
                // serialize data
                do {
                    let res = try JSONDecoder().decode(AuthorizationResponse.self, from: data)
                    completion(.success(res.success))
                } catch {
                    completion(.failure(NetworkError.serializationError))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        })
    }
}
