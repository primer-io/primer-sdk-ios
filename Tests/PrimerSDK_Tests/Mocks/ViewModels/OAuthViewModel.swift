//
//  OAuthViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockOAuthViewModel: OAuthViewModelProtocol {
    var urlSchemeIdentifier: String { return "urlSchemeIdentifier" }
    
    var generateOAuthURLCalled = false
    var tokenizeCalled = false
    
    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void) {
        generateOAuthURLCalled = true
    }
    
    func tokenize(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) {
        tokenizeCalled = true
    }
}

#endif
