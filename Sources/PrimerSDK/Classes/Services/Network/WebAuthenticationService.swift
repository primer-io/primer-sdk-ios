//
//  WebAuthenticationService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import AuthenticationServices
import Foundation
import SafariServices

protocol WebAuthenticationService {
    var session: ASWebAuthenticationSession? { get }
    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void)
    @MainActor
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
                    completion(.failure(PrimerError.cancelled(paymentMethodType: paymentMethodType)))
                } else {
                    completion(.failure(PrimerError.unknown(message: "Failed to create web authentication session")))
                }
            }
        )
        session = webAuthSession

        webAuthSession.presentationContextProvider = self
        webAuthSession.start()
    }

    @MainActor
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
                        continuation.resume(throwing: PrimerError.unknown(message: "Failed to create web authentication session"))
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
        UIApplication.shared.keyWindow ?? ASPresentationAnchor()
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
        windows.last
    }
}
