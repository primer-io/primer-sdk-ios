//
//  LongPollingModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 30/6/22.
//

#if canImport(UIKit)

import Foundation

protocol Module {
    associatedtype T
    init(url: URL, apiClient: PrimerAPIClientProtocol)
    func start() -> Promise<T>
    func cancel()
}

class PollingModule: Module {
    
    internal let url: URL
    private let apiClient: PrimerAPIClientProtocol
    internal private(set) var isCancelled: Bool = false
    internal var retryInterval: TimeInterval = 3

    required init(url: URL, apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.url = url
        self.apiClient = apiClient
    }
    
    func start() -> Promise<String> {
        return Promise { seal in
            self.startPolling(apiClient: self.apiClient) { (resumeToken, err) in
                if let err = err {
                    seal.reject(err)
                } else if let resumeToken = resumeToken {
                    seal.fulfill(resumeToken)
                } else {
                    precondition(false, "Should always return an id or an error")
                }
            }
        }
    }
    
    func cancel() {
        self.isCancelled = true
    }
    
    private func startPolling(apiClient: PrimerAPIClientProtocol, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        
        if isCancelled {
            let err = PrimerError.cancelled(
                paymentMethodType: "WEB_REDIRECT",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        apiClient.poll(clientToken: decodedJWTToken, url: self.url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(apiClient: apiClient, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                Timer.scheduledTimer(withTimeInterval: self.retryInterval, repeats: false) { _ in
                    self.startPolling(apiClient: apiClient, completion: completion)
                }
            }
        }
    }
}

#endif
