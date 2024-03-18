//
//  URLSessionStack.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation
// swiftlint:disable function_body_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable type_body_length

internal class URLSessionStack: NetworkService, LogReporter {

    private let session: URLSession
    private let parser: Parser

    // MARK: - Object lifecycle

    init(session: URLSession = .shared, parser: Parser = JSONParser()) {
        self.session = session
        self.parser = parser
    }

    // MARK: - Network Stack logic
    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>) -> PrimerCancellable? {

        let urlStr: String = (endpoint.baseURL ?? "") + endpoint.path
        let id = String.randomString(length: 32)

        if shouldReportNetworkEvents(for: endpoint) {
            let reqEvent = Analytics.Event.networkCall(
                callType: .requestStart,
                id: id,
                url: urlStr,
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil
            )
            Analytics.Service.record(event: reqEvent)

            let connectivityEvent = Analytics.Event.networkConnectivity(networkType: Connectivity.networkType)
            Analytics.Service.record(event: connectivityEvent)
        }

        guard let url = url(for: endpoint) else {
            let err = InternalError.invalidUrl(url: "Base URL: \(endpoint.baseURL ?? "nil") | Endpoint: \(endpoint.path)",
                                               userInfo: ["file": #file,
                                                          "class": "\(Self.self)",
                                                          "function": #function,
                                                          "line": "\(#line)"],
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let headers = endpoint.headers {
            request.allHTTPHeaderFields = headers
        }

        if let data = endpoint.body {
            request.httpBody = data
        }

        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout
        }

        #if DEBUG
        if let queryParams = endpoint.queryParameters {
            var urlQueryItems: [URLQueryItem] = []

            for (key, val) in queryParams {
                let urlQueryItem = URLQueryItem(name: key, value: val)
                urlQueryItems.append(urlQueryItem)
            }

            if !urlQueryItems.isEmpty {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                urlComponents.queryItems = urlQueryItems
            }
        }

        logger.debug(message: "🌎 Network request [\(request.httpMethod!)] \(request.url!)")
        let headerDescriptions = request.allHTTPHeaderFields?.map { key, value in
            return " - \(key) = \(value)"
        } ?? []
        logger.debug(message: "📃 Request Headers:\n\(headerDescriptions.joined(separator: "\n"))")
        #endif

        let dataTask = session.dataTask(with: request) { [logger] data, response, error in
            let httpResponse = response as? HTTPURLResponse

            var resEvent = Analytics.Event.networkCall(
                callType: .requestEnd,
                id: id,
                url: urlStr,
                method: endpoint.method,
                errorBody: nil,
                responseCode: (response as? HTTPURLResponse)?.statusCode
            )
            var resEventProperties: NetworkCallEventProperties? = resEvent.properties as? NetworkCallEventProperties

            #if DEBUG

            #endif

            if let error = error {
                if self.shouldReportNetworkEvents(for: endpoint) {
                    resEventProperties!.errorBody = "\(error)"
                    resEvent.properties = resEventProperties
                    Analytics.Service.record(event: resEvent)
                }

                #if DEBUG
                logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)", userInfo: ["ErrorMessage": error.localizedDescription])
                #endif

                let err = InternalError.underlyingErrors(errors: [error], userInfo: ["file": #file,
                                                                                     "class": "\(Self.self)",
                                                                                     "function": #function,
                                                                                     "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            guard let data = data else {
                if self.shouldReportNetworkEvents(for: endpoint) {
                    resEventProperties?.errorBody = "No data received"
                    resEvent.properties = resEventProperties
                    Analytics.Service.record(event: resEvent)
                }

                #if DEBUG
                self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                self.logger.error(message: "No data received.")
                #endif

                let err = InternalError.noData(userInfo: ["file": #file,
                                                          "class": "\(Self.self)",
                                                          "function": #function,
                                                          "line": "\(#line)"],
                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            do {
                if self.shouldReportNetworkEvents(for: endpoint) {
                    resEvent.properties = resEventProperties
                    Analytics.Service.record(event: resEvent)
                }

                #if DEBUG
                if endpoint.shouldParseResponseBody {
                    if let primerAPI = endpoint as? PrimerAPI, case .sendAnalyticsEvents = primerAPI {
                        logger.debug(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.debug(message: "Analytics event sent")
                    } else if !data.isEmpty {
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject as Any, options: .prettyPrinted)
                        var jsonStr: String?
                        if jsonData != nil {
                            jsonStr = String(data: jsonData!, encoding: .utf8 )
                        }
                        logger.debug(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        if let httpResponse = response as? HTTPURLResponse {
                            logger.debug(message: "✋ Status: \(httpResponse.statusCode)")
                            let headerDescriptions = httpResponse.allHeaderFields.map { key, value in
                                return " - \(key) = \(value)"
                            }
                            logger.debug(message: "📃 Response Headers:\n\(headerDescriptions.joined(separator: "\n"))")

                        }
                        let bodyDescription = jsonStr ?? "No body found"
                        logger.debug(message: "Body:\n\(bodyDescription)")
                    }
                }
                #endif

                if endpoint.shouldParseResponseBody == false, httpResponse?.statusCode == 200 {
                    guard let dummyRes: T = DummySuccess(success: true) as? T
                    else {
                        fatalError()
                    }
                    DispatchQueue.main.async { completion(.success(dummyRes)) }
                } else {
                    let result = try self.parser.parse(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(result)) }
                }
            } catch {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments), let jsonDic = json as? [String: Any?],
                   let primerErrorJSON = jsonDic["error"] as? [String: Any],
                   let primerErrorObject = try? JSONSerialization.data(withJSONObject: primerErrorJSON, options: .fragmentsAllowed),
                   let statusCode = (response as? HTTPURLResponse)?.statusCode {

                    let primerErrorResponse = try? self.parser.parse(PrimerServerErrorResponse.self, from: primerErrorObject)

                    if self.shouldReportNetworkEvents(for: endpoint) {
                        resEventProperties?.errorBody = "\(primerErrorJSON)"
                        Analytics.Service.record(event: resEvent)
                    }

                    if statusCode == 401 {
                        let err = InternalError.unauthorized(url: urlStr,
                                                             method: endpoint.method,
                                                             userInfo: ["file": #file,
                                                                        "class": "\(Self.self)",
                                                                        "function": #function,
                                                                        "line": "\(#line)"],
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)

                        #if DEBUG
                        logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else if (400...499).contains(statusCode) {
                        let err = InternalError.serverError(status: statusCode,
                                                            response: primerErrorResponse,
                                                            userInfo: ["file": #file,
                                                                       "class": "\(Self.self)",
                                                                       "function": #function,
                                                                       "line": "\(#line)"],
                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)

                        #if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else if (500...599).contains(statusCode) {
                        let err = InternalError.serverError(status: statusCode,
                                                            response: primerErrorResponse,
                                                            userInfo: ["file": #file,
                                                                       "class": "\(Self.self)",
                                                                       "function": #function,
                                                                       "line": "\(#line)"],
                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)

                        #if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }

                    } else {
                        let err = InternalError.serverError(status: statusCode,
                                                            response: primerErrorResponse,
                                                            userInfo: ["file": #file,
                                                                       "class": "\(Self.self)",
                                                                       "function": #function,
                                                                       "line": "\(#line)"],
                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)

                        resEventProperties?.errorBody = err.localizedDescription
                        Analytics.Service.record(event: resEvent)

                        #if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
                        #endif

                        DispatchQueue.main.async { completion(.failure(err)) }
                    }

                } else {
                    let err = InternalError.failedToDecode(message: "Failed to decode response from URL: \(urlStr)",
                                                           userInfo: ["file": #file,
                                                                      "class": "\(Self.self)",
                                                                      "function": #function,
                                                                      "line": "\(#line)"],
                                                           diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)

                    resEventProperties?.errorBody = err.localizedDescription
                    Analytics.Service.record(event: resEvent)

                    #if DEBUG
                    self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                    self.logger.error(message: "Error: Failed to parse")
                    if let stringResponse = String(data: data, encoding: .utf8) {
                        logger.error(message: "String response: \(stringResponse)")
                    }
                    #endif

                    let error = InternalError.underlyingErrors(errors: [err],
                                                               userInfo: ["file": #file,
                                                                          "class": "\(Self.self)",
                                                                          "function": #function,
                                                                          "line": "\(#line)"],
                                                               diagnosticsId: UUID().uuidString)

                    DispatchQueue.main.async { completion(.failure(error)) }
                }

            }
        }
        dataTask.resume()
        return dataTask
    }
}

private let disallowedTrackingPaths: [String] = [
    "/sdk-logs",
    "/checkout/track"
]

internal extension URLSessionStack {

    func url(for endpoint: Endpoint) -> URL? {
        guard let urlStr = endpoint.baseURL else { return nil }
        guard let baseUrl = URL(string: urlStr) else { return nil }
        var url = baseUrl

        if endpoint.path != "" {
            url = baseUrl.appendingPathComponent(endpoint.path)
        }

        if let queryParameters = endpoint.queryParameters, !queryParameters.keys.isEmpty {
            var urlComponents = URLComponents(string: url.absoluteString)!
            var urlQueryItems: [URLQueryItem] = []

            for (key, val) in queryParameters {
                let urlQueryItem = URLQueryItem(name: key, value: val)
                urlQueryItems.append(urlQueryItem)
            }

            if !urlQueryItems.isEmpty {
                urlComponents.queryItems = urlQueryItems
            }

            let tmpUrl = urlComponents.url ?? url
            return tmpUrl
        }

        return url
    }

    func shouldReportNetworkEvents(for endpoint: Endpoint) -> Bool {
        guard let primerAPI = endpoint as? PrimerAPI else {
            return false
        }
        // Don't report events for polling requests
        guard primerAPI != PrimerAPI.poll(clientToken: nil, url: "") else {
            return false
        }
        guard let baseURL = primerAPI.baseURL, let url = URL(string: baseURL),
              !disallowedTrackingPaths.contains(url.path) else {
            return false
        }
        return true
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable type_body_length
