//
//  URLSessionStack.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

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

        #if DEBUG
        var msg = "\nHeaders: \(request.allHTTPHeaderFields ?? [:])"
        #endif

        if let data = endpoint.body {
            request.httpBody = data
            #if DEBUG
            msg += "\nBody: \((try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) ?? [:])"
            #endif
        }

        #if DEBUG
        if let queryParams = endpoint.queryParameters {
            msg += "\nQuery parameters: \(queryParams)"
        }

        log(logLevel: .debug, title: "NETWORK REQUEST [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
        #endif

        let dataTask = session.dataTask(with: request) { data, response, error in
            #if DEBUG
            msg = ""

            if let httpResponse = response as? HTTPURLResponse {
                msg += "\nStatus: \(httpResponse.statusCode)\nHeaders: \(httpResponse.allHeaderFields as! [String: String])"
            }
            #endif

            if let error = error {
                #if DEBUG
                msg += "\nError: \(error)"
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                DispatchQueue.main.async { completion(.failure(.underlyingError(error))) }
                return
            }

            guard let data = data else {
                #if DEBUG
                msg += "\nNo data received."
                log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                DispatchQueue.main.async { completion(.failure(.noData)) }
                return
            }

            do {
                #if DEBUG
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                msg += "\nData: \(json ?? "nil")"
                log(logLevel: .debug, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                #endif

                let result = try self.parser.parse(T.self, from: data)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any?],
                   let primerErrorJSON = json?["error"] as? [String: Any] {
                    let statusCode = (response as! HTTPURLResponse).statusCode

                    let primerErrorResponse = try? self.parser.parse(PrimerErrorResponse.self, from: try! JSONSerialization.data(withJSONObject: primerErrorJSON, options: .fragmentsAllowed))

                    if statusCode == 401 {
                        let err = NetworkServiceError.unauthorised(primerErrorResponse)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async {
                            ErrorHandler.shared.handle(error: err)
                            completion(.failure(err))
                        }

                        return

                    } else if (400...499).contains(statusCode) {
                        let err = NetworkServiceError.clientError(statusCode, info: primerErrorResponse)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async {
                            completion(.failure(err))
                        }

                        return

                    } else if (500...599).contains(statusCode) {
                        let err = NetworkServiceError.serverError(statusCode, info: primerErrorResponse)

                        #if DEBUG
                        msg += "\nError: Status code \(statusCode)\n\(err)"
                        log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                        #endif

                        DispatchQueue.main.async {
                            completion(.failure(err))
                        }

                        return

                    }

                    let nsErr = NSError(domain: "primer-client-error", code: statusCode, userInfo: primerErrorJSON)

                    #if DEBUG
                    msg += "\nError: Status code \(statusCode)\n\(nsErr)"
                    log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                    #endif

                    DispatchQueue.main.async {
                        completion(.failure(.underlyingError(nsErr)))
                    }
                } else {
                    #if DEBUG
                    msg += "\nError: Failed to parse."
                    log(logLevel: .error, title: "NETWORK RESPONSE [\(request.httpMethod!)] \(request.url!)", message: msg, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
                    #endif

                    DispatchQueue.main.async { completion(.failure(.parsing(error, data))) }
                }

            }
        }
        dataTask.resume()
    }
}

extension URLSessionStack {
    private func url(for endpoint: Endpoint) -> URL? {
        
        guard let urlStr = endpoint.baseURL else { return nil }
        
        guard let baseUrl = URL(string: urlStr) else { return nil }
        
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

#endif
