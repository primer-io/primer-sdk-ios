//
//  MockClientSessionActionsModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of ClientSessionActionsProtocol for testing HeadlessRepositoryImpl
@available(iOS 15.0, *)
final class MockClientSessionActionsModule: ClientSessionActionsProtocol {

    // MARK: - Call Tracking

    private(set) var selectPaymentMethodCalls: [(type: String, network: String?)] = []
    private(set) var unselectPaymentMethodCallCount = 0
    private(set) var dispatchActionsCalls: [[ClientSession.Action]] = []

    // MARK: - Error Configuration

    var selectPaymentMethodError: Error?
    var unselectPaymentMethodError: Error?
    var dispatchActionsError: Error?

    // MARK: - Protocol Implementation

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        selectPaymentMethodCalls.append((paymentMethodType, cardNetwork))
        if let error = selectPaymentMethodError {
            throw error
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {
        unselectPaymentMethodCallCount += 1
        if let error = unselectPaymentMethodError {
            throw error
        }
    }

    func dispatch(actions: [ClientSession.Action]) async throws {
        dispatchActionsCalls.append(actions)
        if let error = dispatchActionsError {
            throw error
        }
    }

    // MARK: - Test Helpers

    func reset() {
        selectPaymentMethodCalls = []
        unselectPaymentMethodCallCount = 0
        dispatchActionsCalls = []
        selectPaymentMethodError = nil
        unselectPaymentMethodError = nil
        dispatchActionsError = nil
    }

    var lastSelectPaymentMethodCall: (type: String, network: String?)? {
        selectPaymentMethodCalls.last
    }

    var lastDispatchActionsCall: [ClientSession.Action]? {
        dispatchActionsCalls.last
    }
}
