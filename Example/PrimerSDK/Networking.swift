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
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Payment {
    
    struct Request: Encodable {
        let isV3: Bool?
        let environment: Environment
        let paymentMethodToken: String
        let amount: Int?
        let type: String?
        let currencyCode: Currency?
        let countryCode: CountryCode?
    }

    struct Response: Decodable {
        let id: String
        let amount: Int?
        let currency: String?
        let customer: ClientSessionRequestBody.Customer?
        let customerId: String?
        let dateStr: String?
        var date: Date? {
            return dateStr?.toDate()
        }
        let order: ClientSessionRequestBody.Order?
        let orderId: String?
        let requiredAction: Payment.Response.RequiredAction?
        let status: Status
        
        enum CodingKeys: String, CodingKey {
            case id, amount, currency, customer, customerId, order, orderId, requiredAction, status
            case dateStr = "date"
        }
        
        struct RequiredAction: Decodable {
            let clientToken: String
            let name: String
            let description: String?
        }
        
        enum Status: String, Codable {
            case authorized = "AUTHORIZED"
            case settled = "SETTLED"
            case declined = "DECLINED"
            case pending = "PENDING"
        }
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
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
