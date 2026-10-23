//
//  MockClientSessionActionsModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockClientSessionActionsModule: ClientSessionActionsProtocol {

    // Production code calls this from concurrent tasks; unguarded state here corrupts the heap and crashes the runner.
    private let lock = NSLock()
    private var _selectPaymentMethodError: Error?
    private var _selectPaymentMethodDelay: TimeInterval = 0
    private var _unselectPaymentMethodError: Error?
    private var _unselectPaymentMethodDelay: TimeInterval = 0
    private var _dispatchActionsError: Error?
    private var _selectPaymentMethodCalls: [(type: String, network: String?)] = []
    private var _unselectPaymentMethodCallCount = 0
    private var _dispatchActionsCalls: [[ClientSession.Action]] = []

    var selectPaymentMethodError: Error? {
        get { synchronized { _selectPaymentMethodError } }
        set { synchronized { _selectPaymentMethodError = newValue } }
    }

    var selectPaymentMethodDelay: TimeInterval {
        get { synchronized { _selectPaymentMethodDelay } }
        set { synchronized { _selectPaymentMethodDelay = newValue } }
    }

    var unselectPaymentMethodError: Error? {
        get { synchronized { _unselectPaymentMethodError } }
        set { synchronized { _unselectPaymentMethodError = newValue } }
    }

    var unselectPaymentMethodDelay: TimeInterval {
        get { synchronized { _unselectPaymentMethodDelay } }
        set { synchronized { _unselectPaymentMethodDelay = newValue } }
    }

    var dispatchActionsError: Error? {
        get { synchronized { _dispatchActionsError } }
        set { synchronized { _dispatchActionsError = newValue } }
    }

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
            _selectPaymentMethodError = nil
            _selectPaymentMethodDelay = 0
            _unselectPaymentMethodError = nil
            _unselectPaymentMethodDelay = 0
            _dispatchActionsError = nil
        }
    }

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        synchronized { _selectPaymentMethodCalls.append((paymentMethodType, cardNetwork)) }
        if selectPaymentMethodDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(selectPaymentMethodDelay * 1_000_000_000))
        }
        if let selectPaymentMethodError {
            throw selectPaymentMethodError
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {
        synchronized { _unselectPaymentMethodCallCount += 1 }
        if unselectPaymentMethodDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(unselectPaymentMethodDelay * 1_000_000_000))
        }
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
