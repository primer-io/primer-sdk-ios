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

private let logger = PrimerLogging.shared.logger

class Networking {
    
    var endpoint: String {
        get {
            if environment == .local {
                return "https://primer-mock-back-end.herokuapp.com"
            } else {
                return "https://us-central1-primerdemo-8741b.cloudfunctions.net"
            }
        }
    }
    
    func request(
        apiVersion: APIVersion?,
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        queryParameters: [String: String]?,
        body: Data?,
        completion: @escaping (_ result: Result<Data, Error>) -> Void) {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            
            if let queryParameters = queryParameters {
                components.queryItems = queryParameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            
            logger.debug(message: "URL: \(components.url!.absoluteString )")
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = method.rawValue
            
            request.addValue(environment.rawValue, forHTTPHeaderField: "environment")
            if method != .get {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if let customDefinedApiKey = customDefinedApiKey {
                request.addValue(customDefinedApiKey, forHTTPHeaderField: "x-api-key")
            }
            
            if let headers = headers {
                // We have a dedicated argument that takes x-api-key into account
                // in case a custom one gets defined before SDK initialization
                // so in case this array contains the same key, it won't be added
                for header in headers.filter({ $0.value != "x-api-key"}) {
                    request.addValue(header.value, forHTTPHeaderField: header.key)
                }
            }
            
            if let apiVersion = apiVersion {
                request.addValue(apiVersion.rawValue, forHTTPHeaderField: "x-api-version")
                request.addValue("IOS", forHTTPHeaderField: "Client")
            }
            
            let headerDescriptions = request.allHTTPHeaderFields?.map { key, value in
                return "\(key) = \(value)"
            } ?? []
            logger.debug(message: "Request Headers:\n\(headerDescriptions.joined(separator: "\n"))")
            
            if let body = body {
                request.httpBody = body
                if let bodyJson = try? JSONSerialization.jsonObject(with: body, options: .allowFragments) {
                    logger.debug(message: "Request Body (json):\n\(bodyJson)")
                }
            }
            
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
                DispatchQueue.main.async {
                    logger.debug(message: "Url: \(request.url?.absoluteString ?? "unknown")")
                    
                    if err != nil {
                        logger.debug(message: "Error: \(err!)")
                        completion(.failure(err!))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        logger.debug(message: "Error: Invalid response")
                        completion(.failure(NetworkError.invalidResponse))
                        return
                    }
                    
                    if httpResponse.statusCode < 200 || httpResponse.statusCode > 399 {
                        logger.debug(message: "Status Code: \(httpResponse.statusCode)")
                        if let data = data, let resJson = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                            logger.debug(message: "Response Body (json):\n\(resJson)")
                        }
                        
                        guard let data = data else {
                            logger.error(message: "No data")
                            completion(.failure(NetworkError.invalidResponse))
                            return
                        }
                        
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            logger.debug(message: "Response Body (json):\n\(json)")
                        } catch {
                            logger.error(message: "Failed to parse response body: \(error)")
                        }
                        completion(.failure(NetworkError.invalidResponse))
                        return
                    }
                    
                    guard let data = data else {
                        logger.debug(message: "Status Code: \(httpResponse.statusCode)")
                        logger.debug(message: "Response Body: No data")
                        completion(.failure(NetworkError.invalidResponse))
                        return
                    }
                    
                    logger.debug(message: "Status Code: \(httpResponse.statusCode)")
                    if let resJson = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                        logger.debug(message: "Response Body (json):\n\(resJson)")
                    } else {
                        logger.debug(message: "Response Body (text):\n\(String(describing: String(data: data, encoding: .utf8)))")
                    }
                    
                    completion(.success(data))
                }
            }).resume()
        }
    
    static func resumePayment(_ paymentId: String,
                              withToken resumeToken: String,
                              completion: @escaping (Payment.Response?, Error?) -> Void) {
        let url = environment.baseUrl.appendingPathComponent("/api/payments/\(paymentId)/resume")
        
        let body = Payment.ResumeRequest(token: resumeToken)
        
        var bodyData: Data!
        
        do {
            bodyData = try JSONEncoder().encode(body)
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
    
    static func createPayment(
        with paymentMethodTokenData: PrimerPaymentMethodTokenData,
        customDefinedApiKey: String? = nil,
        completion: @escaping (Payment.Response?, Error?) -> Void
    ) {
        let url = environment.baseUrl.appendingPathComponent("/api/payments/")
        
        guard let token = paymentMethodTokenData.token else {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            completion(nil, err)
            return
        }
        
        let body = Payment.CreateRequest(token: token)
        
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
    
    static func requestClientSession(requestBody: ClientSessionRequestBody, customDefinedApiKey: String? = nil, completion: @escaping (String?, Error?) -> Void) {
        let url = environment.baseUrl.appendingPathComponent("/api/client-session")
        
        var bodyData: Data!
        
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
            apiVersion: .v2_2,
            url: url,
            method: .post,
            headers: URL.requestSessionHTTPHeaders(useNewWorkflows: useNewWorkflows),
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
    
    static func patchClientSession(clientToken: String, requestBody: ClientSessionRequestBody, customDefinedApiKey: String? = nil, completion: @escaping (String?, Error?) -> Void) {
        let url = environment.baseUrl.appendingPathComponent("/api/client-session")
        
        var tmpRequestBody = requestBody
        tmpRequestBody.clientToken = clientToken
        
        let bodyData: Data!
        
        do {
            if let requestBodyJson = tmpRequestBody.dictionaryValue {
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
            apiVersion: .v2_1,
            url: url,
            method: .patch,
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

public struct Payment {
    
    public struct CreateRequest: Encodable {
        let paymentMethodToken: String
        
        public init(token: String) {
            self.paymentMethodToken = token
        }
    }
    
    public struct ResumeRequest: Encodable {
        let resumeToken: String
        
        public init(token: String) {
            self.resumeToken = token
        }
    }
    
    public struct Response: Codable {
        public let id: String?
        public let paymentId: String?
        public let amount: Int?
        public let currencyCode: String?
        public let customer: Request.Body.ClientSession.Customer?
        public let customerId: String?
        public let dateStr: String?
        public var date: Date? {
            return dateStr?.toDate()
        }
        public let order: Request.Body.ClientSession.Order?
        public let orderId: String?
        public let requiredAction: Payment.Response.RequiredAction?
        public let status: Status
        public let paymentFailureReason: PrimerPaymentErrorCode.RawValue?
        
        public enum CodingKeys: String, CodingKey {
            case id, paymentId, amount, currencyCode, customer, customerId, order, orderId, requiredAction, status, paymentFailureReason
            case dateStr = "date"
        }
        
        public struct RequiredAction: Codable {
            public let clientToken: String
            public let name: RequiredActionName
            public let description: String?
        }
        
        /// This enum is giong to be simplified removing the following cases:
        /// - authorized
        /// - settled
        /// - declined
        /// We are going to have only the following
        /// - pending
        /// - success
        /// - failed
        public enum Status: String, Codable {
            case authorized = "AUTHORIZED"
            case settled = "SETTLED"
            case settling = "SETTLING"
            case declined = "DECLINED"
            case failed = "FAILED"
            case pending = "PENDING"
            case success = "SUCCESS"
        }
    }
}
