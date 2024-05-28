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
    func connect(url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void)
}

class DefaultWebAuthenticationService: NSObject, WebAuthenticationService {

    var session: ASWebAuthenticationSession?

    func connect(url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void) {
        let webAuthSession =  ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: scheme,
            completionHandler: { (url, error) in
                if let url = url {
                    completion(.success(url))
                } else if let error = error {
                    completion(.failure(PrimerError.underlyingErrors(errors: [error],
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)))
                } else {
                    completion(.failure(PrimerError.generic(message: "Failed to create web authentication session",
                                                            userInfo: .errorUserInfoDictionary(),
                                                            diagnosticsId: UUID().uuidString)))
                }
            }
        )
        session = webAuthSession

        webAuthSession.presentationContextProvider = self
        webAuthSession.start()
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
        return windows.first
    }
}
