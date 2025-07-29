//
//  BankSelectorTokenizationProviding.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol TokenizationSetupAndCleaning {
    func setupNotificationObservers()
    func cleanup()
    func cancel()
}

protocol BankSelectorTokenizationProviding: TokenizationSetupAndCleaning {
    var paymentMethodType: PrimerPaymentMethodType { get }
    func validateReturningPromise() -> Promise<Void>
    func validate() async throws
    func retrieveListOfBanks() -> Promise<[AdyenBank]>
    func retrieveListOfBanks() async throws -> [AdyenBank]
    func filterBanks(query: String) -> [AdyenBank]
    func tokenize(bankId: String) -> Promise<Void>
    func tokenize(bankId: String) async throws
    func handlePaymentMethodTokenData() -> Promise<Void>
    func handlePaymentMethodTokenData() async throws
}

protocol WebRedirectTokenizationDelegate: TokenizationSetupAndCleaning, AnyObject {
    var didFinishPayment: ((Error?) -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
}
