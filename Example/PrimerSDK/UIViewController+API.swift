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

enum ClientSessionVersion: String {
    case v2 = "2021-09-27"
    case v3 = "2021-10-19"
}

struct PaymentRequest: Encodable {
    let environment: Environment
    let paymentMethod: String
    let amount: Int
    let type: String?
    let currencyCode: Currency
    let countryCode: CountryCode
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
        var msg = "REQUEST\n"
        msg += "URL: \(req.url?.absoluteString ?? "Invalid")\n"
        msg += "Headers:\n\(req.allHTTPHeaderFields ?? [:])\n"
        
        if let body = req.httpBody,
           let reqJson = try? JSONSerialization.jsonObject(with: body, options: .allowFragments)
        {
            msg += "Body:\n\(reqJson)\n"
        }
        
        print(msg)
        msg = ""
        
        URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in
            msg += "RESPONSE\n"
            msg += "URL: \(req.url?.absoluteString ?? "Invalid")\n"
            
            if err != nil {
                msg += "Error: \(err!)\n"
                print(msg)
                completion(.failure(err!))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                msg += "Error: Invalid response\n"
                print(msg)
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                msg += "Status code: \(httpResponse.statusCode)\n"
                if let data = data, let resJson = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                    msg += "Body:\n\(resJson)\n"
                }
                print(msg)
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
                msg += "Status code: \(httpResponse.statusCode)\n"
                msg += "Body:\nNo data\n"
                print(msg)
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            msg += "Status code: \(httpResponse.statusCode)\n"
            if let resJson = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                let jsonData = try? JSONSerialization.data(withJSONObject: resJson, options: .prettyPrinted)
                var jsonStr: String?
                if jsonData != nil {
                    jsonStr = String(data: jsonData!, encoding: .utf8 )
                }
                msg += "Body:\n\(jsonStr)\n"
            } else {
                msg += "Body (String): \(String(data: data, encoding: .utf8))"
            }
            
            print(msg)

            completion(.success(data))

        }).resume()
    }

}
