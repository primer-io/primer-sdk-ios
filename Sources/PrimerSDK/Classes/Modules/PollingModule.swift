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
    func start() -> Promise<T>
}

class PollingModule: Module {
    
    internal let url: URL
    internal private(set) var isCancelled: Bool = false
    internal var retryInterval: TimeInterval = 3
    
    init(url: URL) {
        self.url = url
    }
    
    func start() -> Promise<String> {
        return Promise { seal in
            self.startPolling { (resumeToken, err) in
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
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let client: PrimerAPIClientProtocol = PrimerAPIClient()
        client.poll(clientToken: decodedClientToken, url: self.url.absoluteString) { result in
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
