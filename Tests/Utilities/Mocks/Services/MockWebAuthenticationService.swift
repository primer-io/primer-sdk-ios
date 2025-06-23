//
//  MockWebAuthenticationService.swift
//  
//
//  Created by Onur Var on 18.06.2025.
//

import AuthenticationServices
import Foundation
@testable import PrimerSDK

class MockWebAuthenticationService: WebAuthenticationService {
    var session: ASWebAuthenticationSession?

    var onConnect: ((URL, String) -> URL)?

    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, any Error>) -> Void) {
        guard let onConnect = onConnect else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }

        completion(.success(onConnect(url, scheme)))
    }

    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL {
        guard let onConnect = onConnect else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        return onConnect(url, scheme)
    }
}
