//
//  URLHandler.swift
//  PrimerSDK
//
//  Created by Boris on 18.7.23..
//

#if canImport(UIKit)
import UIKit

struct URLHandler {
    static func handleNonHttpUrl(url: URL) -> Promise<Void> {
        return Promise { seal in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                seal.fulfill(())
            } else {
                let error = PrimerError.failedToOpenAppUsingRedirectUrl(redirectUrl: url,
                                                                        userInfo: nil,
                                                                        diagnosticsId: UUID().uuidString)
                seal.reject(error)
            }
        }
    }
}

#endif
