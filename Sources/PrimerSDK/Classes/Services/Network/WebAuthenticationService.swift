//
//  WebAuthenticationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import AuthenticationServices
import SafariServices

protocol WebAuthenticationService {
    var session: ASWebAuthenticationSession? { get }
    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void)
    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL
}
// MARK: MISSING_TESTS
final class DefaultWebAuthenticationService: NSObject, WebAuthenticationService {

    var session: ASWebAuthenticationSession?

    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void) {
        let webAuthSession =  ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: scheme,
            completionHandler: { (url, error) in
                if let url = url {
                    completion(.success(url))
                } else if error != nil {
                    completion(.failure(PrimerError.cancelled(paymentMethodType: paymentMethodType,
                                                              userInfo: .errorUserInfoDictionary(),
                                                              diagnosticsId: UUID().uuidString)))
                } else {
                    let additionalInfo: [String: String] = [ "message": "Failed to create web authentication session" ]
                    completion(.failure(PrimerError.unknown(userInfo: .errorUserInfoDictionary(additionalInfo: additionalInfo),
                                                            diagnosticsId: UUID().uuidString)))
                }
            }
        )
        session = webAuthSession

        webAuthSession.presentationContextProvider = self
        webAuthSession.start()
    }

    func connect(
        paymentMethodType: String,
        url: URL,
        scheme: String
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let webAuthSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: { url, error in
                    if let url {
                        continuation.resume(returning: url)
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let additionalInfo = ["message": "Failed to create web authentication session"]
                        continuation.resume(throwing: PrimerError.unknown(userInfo: .errorUserInfoDictionary(additionalInfo: additionalInfo),
                                                                          diagnosticsId: UUID().uuidString))
                    }
                }
            )

            self.session = webAuthSession

            webAuthSession.presentationContextProvider = self
            webAuthSession.start()
        }
    }
}

extension DefaultWebAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }

}

extension UIApplication {
    var windows: [UIWindow] {
        let windowScene = self.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let windows = windowScene?.windows else {
            return []
        }
        return windows
    }

    var keyWindow: UIWindow? {
        return windows.last
    }
}
