//
//  Networking.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 22/3/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

enum APIVersion: String {
    case v2     = "2021-09-27"
    case v2_1   = "2.1"
    case v2_2   = "2.2"
    case v3     = "2021-10-19"
    case v4     = "2021-12-01"
    case v5     = "2021-12-10"
}

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case patch  = "PATCH"
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
    
    let baseUrl: URL = URL(string: "https://us-central1-primerdemo-8741b.cloudfunctions.net")!
    let environment: String = "sandbox"
    
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
        
        request.addValue(environment, forHTTPHeaderField: "environment")
        if method != .get {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let apiVersion = apiVersion {
            request.addValue(apiVersion.rawValue, forHTTPHeaderField: "x-api-version")
            request.addValue("IOS", forHTTPHeaderField: "Client")
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
            DispatchQueue.main.async {
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
            }
        }).resume()
    }
    
    func requestClientSession(clientSessionRequestBody: ClientSessionRequestBody, customDefinedApiKey: String? = nil, completion: @escaping (String?, Error?) -> Void) {
        let url = self.baseUrl.appendingPathComponent("/api/client-session")

        let bodyData: Data
        
        do {
            bodyData = try JSONEncoder().encode(clientSessionRequestBody)

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
            body: bodyData
        ) { result in
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

struct ClientSessionRequestBody: Codable {
    
    static let demoClientSessionRequestBody = ClientSessionRequestBody(
        customerId: "customer-id",
        orderId: "order-id",
        currencyCode: "EUR",
        amount: nil,
        metadata: nil,
        customer: Customer(
            firstName: "John",
            lastName: "Smith",
            emailAddress: "john@primer.io",
            mobileNumber: nil,
            billingAddress: nil,
            shippingAddress: nil),
        order: Order(
        countryCode: "DE",
        lineItems: [
            Order.LineItem(
                itemId: "item-id",
                description: "description",
                amount: 100,
                quantity: 1)
        ]))
    
    var customerId: String?
    var orderId: String?
    var currencyCode: String?
    var amount: Int?
    var metadata: [String: String]?
    var customer: ClientSessionRequestBody.Customer?
    var order: ClientSessionRequestBody.Order?
    
    struct Customer: Codable {
        var firstName: String?
        var lastName: String?
        var emailAddress: String?
        var mobileNumber: String?
        var billingAddress: Address?
        var shippingAddress: Address?
        
        struct Address: Codable {
            
            var firstName: String?
            var lastName: String?
            var addressLine1: String?
            var addressLine2: String?
            var city: String?
            var state: String?
            var countryCode: String?
            var postalCode: String?
        }
    }
    
    struct Order: Codable {
        var countryCode: String?
        var lineItems: [LineItem]?
        
        struct LineItem: Codable {
            var itemId: String?
            var description: String?
            var amount: Int?
            var quantity: Int?
        }
    }
}

extension Encodable {
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}
