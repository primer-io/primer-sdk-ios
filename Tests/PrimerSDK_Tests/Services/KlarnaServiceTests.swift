//
//  KlarnaServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class KlarnaServiceTests: XCTestCase {
    
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"

    override func setUp() {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
    }
    
}

extension KlarnaServiceTests: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientToken") else {
            return completion(nil, NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(customerId: "customer123")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(nil, NetworkError.missingParams)
        }
        
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String])["clientToken"]!
                    completion(token, nil)
                    
                } catch {
                    completion(nil, error)
                }
            case .failure(let err):
                completion(nil, err)
            }
        })
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onCheckoutDismissed() {
        
    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
    func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
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
    
    enum NetworkError: Error {
        case missingParams
        case unauthorised
        case timeout
        case serverError
        case invalidResponse
        case serializationError
    }
    
    struct CreateClientTokenRequest: Codable {
        let customerId: String
    }
    
}

#endif
