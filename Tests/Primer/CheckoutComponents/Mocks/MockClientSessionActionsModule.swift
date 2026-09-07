//
//  MockClientSessionActionsModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class MockClientSessionActionsModule: ClientSessionActionsProtocol {

    var selectPaymentMethodError: Error?
    var unselectPaymentMethodError: Error?
    var dispatchActionsError: Error?

    // Production callers fire these methods from concurrent tasks, so the recorded calls are
    // guarded; an unguarded array here corrupts the heap and crashes the test runner.
    private let lock = NSLock()
    private var _selectPaymentMethodCalls: [(type: String, network: String?)] = []
    private var _unselectPaymentMethodCallCount = 0
    private var _dispatchActionsCalls: [[ClientSession.Action]] = []

    var selectPaymentMethodCalls: [(type: String, network: String?)] {
        synchronized { _selectPaymentMethodCalls }
    }

    var unselectPaymentMethodCallCount: Int {
        synchronized { _unselectPaymentMethodCallCount }
    }

    var dispatchActionsCalls: [[ClientSession.Action]] {
        synchronized { _dispatchActionsCalls }
    }

    var lastSelectPaymentMethodCall: (type: String, network: String?)? {
        selectPaymentMethodCalls.last
    }

    var lastDispatchActionsCall: [ClientSession.Action]? {
        dispatchActionsCalls.last
    }

    func reset() {
        synchronized {
            _selectPaymentMethodCalls = []
            _unselectPaymentMethodCallCount = 0
            _dispatchActionsCalls = []
        }
        selectPaymentMethodError = nil
        unselectPaymentMethodError = nil
        dispatchActionsError = nil
    }

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        synchronized { _selectPaymentMethodCalls.append((paymentMethodType, cardNetwork)) }
        if let selectPaymentMethodError {
            throw selectPaymentMethodError
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {
        synchronized { _unselectPaymentMethodCallCount += 1 }
        if let unselectPaymentMethodError {
            throw unselectPaymentMethodError
        }
    }

    func dispatch(actions: [ClientSession.Action]) async throws {
        synchronized { _dispatchActionsCalls.append(actions) }
        if let dispatchActionsError {
            throw dispatchActionsError
        }
    }

    private func synchronized<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
