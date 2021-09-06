//
//  UIViewController+API.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

// MARK: - API HELPER

struct PaymentRequest: Encodable {
    let environment: Environment
    let paymentMethod: String
    let amount: Int
    let type: String?
    let currencyCode: String
}

class PaymentResponse: PaymentResponseProtocol {
    var amount: Int
    var id: String
    var date: String
    var status: PaymentStatus
    var requiredAction: RequiredActionProtocol?
    
    init(amount: Int, id: String, date: String, status: PaymentStatus, requiredAction: RequiredAction?) {
        self.amount = amount
        self.id = id
        self.date = date
        self.status = status
        self.requiredAction = requiredAction
    }
}

class RequiredAction: RequiredActionProtocol {
    var name: RequiredActionName
    var description: String
    var clientToken: String?
    
    init(name: RequiredActionName, description: String, clientToken: String?) {
        self.name = name
        self.description = description
        self.clientToken = clientToken
    }
}

enum NetworkError: Error {
    case missingParams
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case serializationError
}

extension UIViewController {
    
    func keyboardWillShow(notification: NSNotification) {
        let height = UIScreen.main.bounds.height - view.frame.height
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y.rounded() == height.rounded() {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        print("URL: \(req.url?.absoluteString)")
        print("Headers:\n\(req.allHTTPHeaderFields)")
        
        if let body = req.httpBody, let json = try? JSONSerialization.jsonObject(with: body, options: .allowFragments) {
            print("Body:\n\(json)")
        }
        
        URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in

            if err != nil {
                print("Error: \(err)")
                completion(.failure(NetworkError.serverError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No response")
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                print("Status code: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.invalidResponse))
                
                guard let data = data else {
                    print("No data")
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    print("Response body: \(json)")
                } catch {
                    print("Error: \(error)")
                }
                return
            }
            
            print("Status code: \(httpResponse.statusCode)")

            guard let data = data else {
                print("No data")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("Response body: \(json)")
            } catch {
                print("Error: \(error)")
            }
            
            let str = String(data: data, encoding: .utf8)
            print("Response str: \(str)")

            completion(.success(data))

        }).resume()
    }

}
