//
//  Networking.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 30/11/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import PrimerSDK

enum APIVersion: String {
    case v2 = "2021-09-27"
    case v3 = "2021-10-19"
    case v4 = "2021-12-01"
    case v5 = "2021-12-10"
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case missingParams
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case serializationError
}

class Networking {
    
    func request(
        apiVersion: APIVersion?,
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        queryParameters: [String: String]?,
        body: Data?,
        completion: @escaping (_ result: Result<Data, Error>) -> Void)
    {
        var msg = "REQUEST\n"
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        if let queryParameters = queryParameters {
            components.queryItems = queryParameters.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        msg += "URL: \(components.url!.absoluteString )\n"
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        
        request.addValue(environment.rawValue, forHTTPHeaderField: "environment")
        if method != .get {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let headers = headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if let apiVersion = apiVersion {
            request.addValue(apiVersion.rawValue, forHTTPHeaderField: "x-api-version")
        }
                
        msg += "Headers:\n\(request.allHTTPHeaderFields ?? [:])\n"
        
        if let body = body {
            request.httpBody = body
            
            let bodyJson = try? JSONSerialization.jsonObject(with: body, options: .allowFragments)
            msg += "Body:\n\(bodyJson ?? [:])\n"
        }
        
        print(msg)
        msg = ""
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
            msg += "RESPONSE\n"
            msg += "URL: \(request.url?.absoluteString ?? "Invalid")\n"
            
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
                msg += "Body:\n\(resJson)\n"
            } else {
                msg += "Body (String): \(String(describing: String(data: data, encoding: .utf8)))"
            }
            
            print(msg)

            completion(.success(data))
        }).resume()
    }
    
    func createPayment(with paymentMethod: PaymentMethodToken, completion: @escaping (Payment.Response?, Error?) -> Void) {
        guard let paymentMethodToken = paymentMethod.token else {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let url = environment.baseUrl.appendingPathComponent("/api/payments/")

        let body = Payment.CreateRequest(token: paymentMethodToken)

        var bodyData: Data!

        do {
            bodyData = try JSONEncoder().encode(body)
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }

        let networking = Networking()
        networking.request(
            apiVersion: .v2,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    do {
                        let paymentResponse = try JSONDecoder().decode(Payment.Response.self, from: data)
                        completion(paymentResponse, nil)
                    } catch {
                        completion(nil, error)
                    }

                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
    func requestClientSession(requestBody: ClientSessionRequestBody, completion: @escaping (String?, Error?) -> Void) {
        let url = environment.baseUrl.appendingPathComponent("/api/client-session")

        let bodyData: Data!
        
        do {
            if let requestBodyJson = requestBody.dictionaryValue {
                bodyData = try JSONSerialization.data(withJSONObject: requestBodyJson, options: .fragmentsAllowed)
            } else {
                completion(nil, NetworkError.serializationError)
                return
            }
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let networking = Networking()
        networking.request(
            apiVersion: .v3,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    do {
                        if let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])?["clientToken"] as? String {
                            completion(token, nil)
                        } else {
                            let err = NSError(domain: "example", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to find client token"])
                            completion(nil, err)
                        }
                        
                    } catch {
                        completion(nil, error)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
    func requestClientSessionWithActions(clientToken: String, actions: [PrimerSDK.ClientSession.Action], completion: @escaping (String?, Error?) -> Void) {
        let url = environment.baseUrl.appendingPathComponent("/api/client-session/actions")

        var merchantActions: [ClientSession.Action] = []
        for action in actions {
            if action.type == .setSurchargeFee {
                let newAction = ClientSession.Action(
                    type: .setSurchargeFee,
                    params: [
                        "amount": 456
                    ])
                merchantActions.append(newAction)
            } else if action.type == .setBillingAddress {
                if let _ = (action.params?["postalCode"] as? String) {
                    var billingAddress: [String: String] = [:]
                    
                    action.params?.forEach { entry in
                        if let value = entry.value as? String {
                            billingAddress[entry.key] = value
                        }
                    }
                    
                    let newAction = ClientSession.Action(
                        type: action.type,
                        params: [ "billingAddress": billingAddress ]
                    )
                    
                    merchantActions.append(newAction)
                }
            } else {
                merchantActions.append(action)
            }
        }
                
        var bodyData: Data!
        
        do {
            let bodyJson = ClientSessionActionsRequest(clientToken: clientToken, actions: merchantActions)
            bodyData = try JSONEncoder().encode(bodyJson)
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let networking = Networking()
        networking.request(
            apiVersion: nil,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                            completion(nil, NetworkError.missingParams)
                            return
                        }
                        
                        print("Client Token Response:\n\(json)")
                        
                        guard let clientToken = json["clientToken"] as? String else {
                            completion(nil, NetworkError.missingParams)
                            return
                        }

                        print("Client Token:\n\(clientToken)")
                        completion(clientToken, nil)

                    } catch {
                        completion(nil, error)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
}

internal extension String {
    func toDate(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil) -> Date? {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone(abbreviation: "UTC") : timeZone
        return df.date(from: self)
    }
}
