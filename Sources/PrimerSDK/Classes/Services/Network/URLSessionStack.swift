//
//  URLSessionStack.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

internal class URLSessionStack: NetworkService {
    private let session: URLSession
    private let parser: Parser

    // MARK: - Object lifecycle

    init(session: URLSession = .shared, parser: Parser = JSONParser()) {
        self.session = session
        self.parser = parser
    }

    // MARK: - Network Stack logic

    // swiftlint:disable function_body_length
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>) {
        let urlStr: String = (endpoint.baseURL ?? "") + endpoint.path
        let id = String.randomString(length: 32)
        
        let reqEvent = Analytics.Event(
            eventType: .networkCall,
            properties: NetworkCallEventProperties(
                callType: .requestStart,
                id: id,
                url: urlStr,
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil))
        Analytics.Service.record(event: reqEvent)
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        Analytics.Service.record(event: connectivityEvent)
        
        guard let url = url(for: endpoint) else {
            let err = NetworkError.invalidUrl(url: "Base URL: \(endpoint.baseURL ?? "nil") | Endpoint: \(endpoint.path)", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let headers = endpoint.headers {
            request.allHTTPHeaderFields = headers
        }

        #if DEBUG
        var msg = "\nHeaders: \(request.allHTTPHeaderFields ?? [:])"
        #endif

        if let data = endpoint.body {
            request.httpBody = data
            let jsonStr = data.prettyPrintedJSONString
            #if DEBUG
            msg += "\nBody:\n\(jsonStr ?? "Empty body")"
            #endif
        }

        #if DEBUG
        if let queryParams = endpoint.queryParameters {
            msg += "\nQuery parameters: \(queryParams)"
        }

        log(logLevel: .debug, title: "NETWORK REQUEST [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
        #endif

        let dataTask = session.dataTask(with: request) { data, response, error in
            var resEventProperties = NetworkCallEventProperties(
                callType: .requestEnd,
                id: id,
                url: urlStr,
                method: endpoint.method,
                errorBody: nil,
                responseCode: (response as? HTTPURLResponse)?.statusCode
            )
            
            var resEvent = Analytics.Event(
                eventType: .networkCall,
                properties: resEventProperties)
            
            resEvent.properties = resEventProperties
            
            #if DEBUG
            msg = ""

            if let httpResponse = response as? HTTPURLResponse {
                msg += "\nStatus: \(httpResponse.statusCode)\nHeaders: \(httpResponse.allHeaderFields as! [String: String])"
            }
            #endif

            if let error = error {
                resEventProperties.errorBody = "\(error)"
                resEvent.properties = resEventProperties
                
                Analytics.Service.record(event: resEvent)
                
                #if DEBUG
                msg += "\nError: \(error)"
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                let err = NetworkError.underlyingErrors(errors: [error], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: error)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            guard let data = data else {
                resEventProperties.errorBody = "No data received"
                resEvent.properties = resEventProperties
                Analytics.Service.record(event: resEvent)
                
                #if DEBUG
                msg += "\nNo data received."
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                let err = NetworkError.noData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            do {
                resEvent.properties = resEventProperties
                Analytics.Service.record(event: resEvent)
                
                #if DEBUG
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                var jsonStr: String?
                if jsonData != nil {
                    jsonStr = String(data: jsonData!, encoding: .utf8 )
                }
                
                msg += "\nBody:\n\(jsonStr ?? "Empty body")"
                log(logLevel: .debug, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                let result = try self.parser.parse(T.self, from: data)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments), let jsonDic = json as? [String: Any?],
                   var primerErrorJSON = jsonDic["error"] as? [String: Any] {
                    let statusCode = (response as! HTTPURLResponse).statusCode

                    let primerErrorResponse = try? self.parser.parse(PrimerServerErrorResponse.self, from: try! JSONSerialization.data(withJSONObject: primerErrorJSON, options: .fragmentsAllowed))
                    
                    resEventProperties.errorBody = "\(primerErrorJSON)"
                    resEvent.properties = resEventProperties
                    Analytics.Service.record(event: resEvent)

                    if statusCode == 401 {
                        let err = NetworkError.unauthorized(url: urlStr, method: endpoint.method, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        _ = ErrorHandler.shared.handle(error: err)
                        
                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else if (400...499).contains(statusCode) {
                        let err = NetworkError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        _ = ErrorHandler.shared.handle(error: err)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else if (500...599).contains(statusCode) {
                        let err = NetworkError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        _ = ErrorHandler.shared.handle(error: err)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else {
                        let err = NetworkError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        _ = ErrorHandler.shared.handle(error: err)
                        
                        resEventProperties.errorBody = err.localizedDescription
                        resEvent.properties = resEventProperties
                        Analytics.Service.record(event: resEvent)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err.localizedDescription)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }
                    }

                } else {
                    let err = ParserError.failedToDecode(message: "Failed to decode response from URL: \(urlStr)", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    _ = ErrorHandler.shared.handle(error: err)
                    
                    resEventProperties.errorBody = err.localizedDescription
                    resEvent.properties = resEventProperties
                    Analytics.Service.record(event: resEvent)
                    
                    #if DEBUG
                    msg += "\nError: Failed to parse."
                    log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                    #endif

                    DispatchQueue.main.async { completion(.failure(NetworkError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]))) }
                }

            }
        }
        dataTask.resume()
    }
}

internal extension URLSessionStack {
    private func url(for endpoint: Endpoint) -> URL? {
        guard let urlStr = endpoint.baseURL else { return nil }
        guard let baseUrl = URL(string: urlStr) else { return nil }
        return baseUrl.appendingPathComponent(endpoint.path)
    }
}

#endif
