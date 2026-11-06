//
//  MockKlarnaProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import KlarnaMobileSDK
import PrimerKlarnaSDK

final class MockKlarnaProvider: PrimerKlarnaProviding {
    enum Call: Equatable {
        case createPaymentView
        case readPaymentView
        case initializePaymentView
    }

    weak var paymentViewDelegate: PrimerKlarnaProviderPaymentViewDelegate?
    weak var authorizationDelegate: PrimerKlarnaProviderAuthorizationDelegate?
    weak var finalizationDelegate: PrimerKlarnaProviderFinalizationDelegate?
    weak var errorDelegate: PrimerKlarnaProviderErrorDelegate?
    private(set) var calls: [Call] = []
    private(set) var authorizeCallCount = 0
    private(set) var finaliseCallCount = 0

    // A real KlarnaPaymentView can't be built in unit tests, so the read is logged instead.
    var paymentView: KlarnaPaymentView? {
        calls.append(.readPaymentView)
        return nil
    }

    func createPaymentView() { calls.append(.createPaymentView) }
    func initializePaymentView() { calls.append(.initializePaymentView) }
    func loadPaymentReview() {}
    func loadPaymentView(jsonData: String?) {}
    func removePaymentView() {}
    func authorize(autoFinalize: Bool, jsonData: String?) { authorizeCallCount += 1 }
    func reauthorize(jsonData: String?) {}
    func finalise(jsonData: String?) { finaliseCallCount += 1 }
}
#endif
