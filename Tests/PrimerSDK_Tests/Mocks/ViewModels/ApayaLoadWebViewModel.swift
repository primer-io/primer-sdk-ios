//
//  ApayaLoadWebViewController.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 04/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPrimerLoadWebViewModel: PrimerLoadWebViewModelProtocol {
    let url: String
    let shouldThrow: Bool
    let shouldCancel: Bool
    init(url: String, shouldThrow: Bool = false, shouldCancel: Bool = false) {
        self.url = url
        self.shouldThrow = shouldThrow
        self.shouldCancel = shouldCancel
    }
    var didCallGenerateWebViewUrl = false
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        didCallGenerateWebViewUrl = true
        if (shouldThrow) { return completion(.failure(PrimerError.generic)) }
        return completion(.success(url))
    }
    var didCallTokenize = false
    func tokenize() {
        didCallTokenize = true
    }
    var getWebViewModelCalled = false
    func getWebViewModel() -> PrimerWebViewModelProtocol {
        getWebViewModelCalled = true
        return ApayaWebViewModel()
    }
    var navigateCalled = false
    func navigate(_ result: Result<Bool, Error>?) {
        navigateCalled = true
    }
}

#endif
