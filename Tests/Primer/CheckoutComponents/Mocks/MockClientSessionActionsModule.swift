//
//  MockClientSessionActionsModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

final class MockClientSessionActionsModule: ClientSessionActionsProtocol {

    private let lock = NSLock()
    private var calls: [(type: String, network: String?)] = []
    var selectPaymentMethodError: Error?
    var onSelectPaymentMethod: (() async throws -> Void)?

    var selectPaymentMethodCalls: [(type: String, network: String?)] {
        lock.withLock { calls }
    }

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        lock.withLock { calls.append((paymentMethodType, cardNetwork)) }
        try await onSelectPaymentMethod?()
        if let selectPaymentMethodError {
            throw selectPaymentMethodError
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {}

    func dispatch(actions: [ClientSession.Action]) async throws {}
}
