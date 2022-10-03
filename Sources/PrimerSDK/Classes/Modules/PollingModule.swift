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
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    
    init(url: URL)
    
    func start() -> Promise<T>
    func cancel()
}

class PollingModule: Module {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    internal let url: URL
    internal private(set) var isCancelled: Bool = false
    internal var retryInterval: TimeInterval = 3
    
    deinit {
        self.cancel()
    }

    required init(url: URL) {
        self.url = url
    }
    
    func start() -> Promise<String> {
        return Promise { seal in
            self.startPolling() { (resumeToken, err) in
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
    
    private func startPolling(completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
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
        
        let apiClient: PrimerAPIClientProtocol = PollingModule.apiClient ?? PrimerAPIClient()
        
        apiClient.poll(clientToken: decodedJWTToken, url: self.url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(completion: completion)
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
                    self.startPolling(completion: completion)
                }
            }
        }
    }
}

#endif
