//
//  UIViewController+API.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

// MARK: - API HELPER

struct AuthorizationRequest: Encodable {
    let paymentMethod: String
    let amount: Int
    let type: String?
    var capture: Bool
    let currencyCode: String
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
