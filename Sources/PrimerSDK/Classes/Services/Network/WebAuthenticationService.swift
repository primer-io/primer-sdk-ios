//
//  WebAuthenticationService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 28/05/2024.
//

import Foundation
import AuthenticationServices
import SafariServices

protocol WebAuthenticationService {
    var session: ASWebAuthenticationSession? { get }
    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void)
    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL
}

class DefaultWebAuthenticationService: NSObject, WebAuthenticationService {

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

    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            connect(paymentMethodType: paymentMethodType, url: url, scheme: scheme) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@available(iOS 11.0, *)
extension DefaultWebAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }

}

fileprivate extension UIApplication {
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
