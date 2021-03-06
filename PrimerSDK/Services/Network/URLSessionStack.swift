//
//  URLSessionStack.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

class URLSessionStack: NetworkService {
    private let session: URLSession
    private let parser: Parser
    
    // MARK: - Object lifecycle
    
    init(session: URLSession = .shared, parser: Parser = JSONParser()) {
        self.session = session
        self.parser = parser
    }
    
    // MARK: - Network Stack logic
    
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>) {
        guard let url = url(for: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let headers = endpoint.headers {
            request.allHTTPHeaderFields = headers
        }
        
        var msg = "\nHeaders: \(request.allHTTPHeaderFields ?? [:])"
        
        
        if let data = endpoint.body {
            request.httpBody = data
            msg += "\nBody: \((try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) ?? [:])"
        }
        
        if let queryParams = endpoint.queryParameters {
            msg += "\nQuery parameters: \(queryParams)"
        }
        
        log(logLevel: .debug, title: "NETWORK REQUEST [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
        
        let dataTask = session.dataTask(with: request) { data, response, error in
            msg = ""
            
            if let httpResponse = response as? HTTPURLResponse {
                msg += "\nStatus: \(httpResponse.statusCode)\nHeaders: \(httpResponse.allHeaderFields as! [String: String])"
            }
            
            if let error = error {
                msg += "\nError: \(error)"
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                DispatchQueue.main.async { completion(.failure(.error(error))) }
                return
            }
            
            guard let data = data else {
                msg += "\nNo data received."
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                DispatchQueue.main.async { completion(.failure(.noData)) }
                return
            }
            
            do {
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                msg += "\nData: \(json ?? "nil")"
                log(logLevel: .debug, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                
                let result = try self.parser.parse(T.self, from: data)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any?],
                   let primerErrorJSON = json?["error"] as? [String: Any] {
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    let nsErr = NSError(domain: "Primer", code: 100, userInfo: primerErrorJSON)
                    
                    msg += "\nError: Status code \(statusCode)\n\(nsErr)"
                    
                    log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                    
                    DispatchQueue.main.async {
                        completion(.failure(.error(nsErr)))
                    }
                } else {
                    msg += "\nError: Failed to parse."
                    log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                    DispatchQueue.main.async { completion(.failure(.parsing(error, data))) }
                }
                
            }
        }
        dataTask.resume()
    }
}

extension URLSessionStack {
    private func url(for endpoint: Endpoint) -> URL? {
        guard let baseUrl = URL(string: endpoint.baseURL) else { return nil }
        return baseUrl.appendingPathComponent(endpoint.path)

//        var urlComponents = URLComponents()
//        urlComponents.scheme = endpoint.sc
//
//        let host = endpoint.baseURL
//        if endpoint.baseURL.starts(with: "https://") {
//            urlComponents.scheme = "https"
//            urlComponents.host = String(host.dropFirst(8))
//        } else {
//            urlComponents.scheme = "http"
//            urlComponents.host = String(host.dropFirst(7))
//        }
//
//        urlComponents.path = endpoint.path
////        urlComponents.scheme = endpoint.scheme
////        urlComponents.host = endpoint.baseURL
////        urlComponents.port = endpoint.port
//
//        if let queryItems = endpoint.queryParameters {
//            urlComponents.queryItems = queryItems.map({ URLQueryItem(name: $0, value: $1) })
//        }
//
//        print(urlComponents.url)
//
//        return urlComponents.url!
    }
}
